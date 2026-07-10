import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import 'family_sync_api_client.dart';
import 'family_visibility_service.dart';
import 'push_token_service.dart';
import 'relay_api_client.dart';
import 'shared_channel_key_storage.dart';
import 'sync_crypto_service.dart';

/// N-way обмін реальними даними між учасниками сімейної групи (Фаза 4) —
/// на відміну від `FamilyGroupService` (лише "візитівки": ім'я/аватар,
/// Фаза 2), тут ідеться про медикаменти й медкартку, відфільтровані per-peer
/// через `FamilyVisibilityService` (Фаза 3, deny-by-default). Кожен пір
/// отримує лише те, на що subject явно дав дозвіл view — і саме те, що
/// subject перестав дозволяти (чи видалив), автоматично прилітає піру як
/// tombstone на наступному ж раунді (той самий diff-підхід, що й
/// `FamilySyncService._photosForPush`).
///
/// Отримані дані НЕ потрапляють у Members/Medications/тощо — свідомо живуть
/// в `SharedSubjects`/`SharedEntities` (read-only), щоб не змішувати "чуже,
/// поділене зі мною" з профілями, якими керує цей пристрій.
class FamilyPeerSyncService {
  final AppDatabase _db;
  final _api = const FamilySyncApiClient();
  final _relayApi = const RelayApiClient();

  FamilyPeerSyncService(this._db);

  static const _entityTypes = [
    'medication',
    'doctor_appointment',
    'lab_result',
    'allergy',
    'chronic_condition',
    'vaccination',
    'surgery',
  ];

  Future<void> syncAllPeers() async {
    final peers = await FamilyPeersRepository(_db).allPeers();
    for (final peer in peers) {
      try {
        await _syncPeer(peer);
      } catch (_) {
        // Локальні дані лишаються джерелом правди — спробуємо ще раз при
        // наступному тригері, той самий підхід, що й FamilySyncService.
      }
    }
  }

  Future<void> _syncPeer(FamilyPeer peer) async {
    final keyBytes = await SharedChannelKeyStorage.read(peer.channelId);
    if (keyBytes == null) return;
    final key = SecretKey(keyBytes);

    final pushed = await _push(peer, key);
    await _pull(peer, key);
    await FamilyPeersRepository(_db).updateLastSynced(peer.personUuid, DateTime.now());

    if (pushed) await _ping(peer.channelId, key);
  }

  // ── Push: мої субʼєкти → цей пір, лише те, що дозволено ─────────────────

  String _pushedKey(String channelId) => 'family_peer_pushed_$channelId';

  Future<Set<String>> _previouslyPushed(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pushedKey(channelId));
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> _setPreviouslyPushed(String channelId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pushedKey(channelId), jsonEncode(ids.toList()));
  }

  Future<bool> _push(FamilyPeer peer, SecretKey key) async {
    final subjects = await _db.select(_db.members).get();
    final since = peer.lastSyncedAt;
    final previouslyPushed = await _previouslyPushed(peer.channelId);
    final currentIds = <String>{};
    final entities = <Map<String, dynamic>>[];

    for (final subject in subjects) {
      final subjectUuid = subject.personUuid;
      if (subjectUuid == null) continue;
      final allowed = await FamilyVisibilityService.isAllowed(
        _db,
        subjectUuid,
        peer.personUuid,
        FamilyPermission.view,
      );
      if (!allowed) continue;

      for (final type in _entityTypes) {
        final rows = await _rowsFor(type, subject.id);
        for (final row in rows) {
          final id = '$subjectUuid|$type|${row['uuid']}';
          currentIds.add(id);
          final changed = !previouslyPushed.contains(id) ||
              (since == null || DateTime.parse(row['updatedAt'] as String).isAfter(since));
          if (!changed) continue;

          final json = Map<String, dynamic>.from(row)
            ..remove('updatedAt')
            ..['subjectPersonUuid'] = subjectUuid
            ..['subjectName'] = subject.name
            ..['subjectAvatarIndex'] = subject.avatarIndex;
          entities.add({
            'type': type,
            'uuid': row['uuid'],
            'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
          });
        }
      }
    }

    for (final goneId in previouslyPushed.difference(currentIds)) {
      final parts = goneId.split('|');
      if (parts.length != 3) continue;
      entities.add({'type': parts[1], 'uuid': parts[2], 'ciphertext': '', 'deleted': true});
    }

    if (entities.isEmpty) return false;

    for (var i = 0; i < entities.length; i += 500) {
      final chunk = entities.sublist(i, i + 500 > entities.length ? entities.length : i + 500);
      await _api.push(channelId: peer.channelId, entities: chunk);
    }
    await _setPreviouslyPushed(peer.channelId, currentIds);
    return true;
  }

  /// Одна сира вибірка на (тип, memberId) — повертає generic Map (json +
  /// syncUuid як 'uuid'), щоб уникнути 7 майже однакових типізованих гілок.
  /// Рядки без syncUuid пропускаються — їх ще не бачив жоден pull/push.
  Future<List<Map<String, dynamic>>> _rowsFor(String type, int memberId) async {
    switch (type) {
      case 'medication':
        final rows = await (_db.select(_db.medications)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'doctor_appointment':
        final rows =
            await (_db.select(_db.doctorAppointments)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'lab_result':
        final rows = await (_db.select(_db.labResults)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'allergy':
        final rows = await (_db.select(_db.allergies)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'chronic_condition':
        final rows =
            await (_db.select(_db.chronicConditions)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'vaccination':
        final rows = await (_db.select(_db.vaccinations)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'surgery':
        final rows = await (_db.select(_db.surgeries)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
    }
    return const [];
  }

  Map<String, dynamic> _withUuid(Map<String, dynamic> json, String uuid) {
    json['uuid'] = uuid;
    json.remove('id');
    json.remove('memberId');
    json.remove('syncUuid');
    return json;
  }

  Future<void> _ping(String channelId, SecretKey key) async {
    try {
      final token = await PushTokenService.getToken();
      if (token == null) return;
      final ping = await SyncCryptoService.encryptEntity(key, {'t': DateTime.now().toIso8601String()});
      await _relayApi.send(
        channelId: channelId,
        senderToken: token,
        encryptedPayloadBase64: base64Encode(ping),
      );
    } catch (_) {
      // Не критично — пір підхопить зміни при наступному відкритті застосунку.
    }
  }

  // ── Pull: те, що поділив цей пір, → SharedSubjects/SharedEntities ───────

  Future<void> _pull(FamilyPeer peer, SecretKey key) async {
    final result = await _api.pull(channelId: peer.channelId, since: peer.lastSyncedAt);
    final repo = FamilyPeersRepository(_db);

    for (final entity in result.entities) {
      if (entity.deleted) {
        await repo.deleteSharedEntity(entity.uuid);
        continue;
      }
      final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
      final subjectUuid = json['subjectPersonUuid'] as String?;
      if (subjectUuid == null) continue;

      await repo.upsertSharedSubject(SharedSubjectsCompanion.insert(
        personUuid: subjectUuid,
        peerChannelId: peer.channelId,
        name: json['subjectName'] as String? ?? peer.name,
        avatarIndex: Value(json['subjectAvatarIndex'] as int? ?? peer.avatarIndex),
      ));
      await repo.upsertSharedEntity(SharedEntitiesCompanion.insert(
        subjectPersonUuid: subjectUuid,
        entityType: entity.type,
        uuid: entity.uuid,
        dataJson: jsonEncode(json),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  // ── Вихід із групи / відʼєднання одного піра ─────────────────────────────

  /// Проактивно надсилає tombstone на ВСЕ, що я коли-небудь ділив із цим
  /// піром (а не чекає наступного диференційного раунду push) — бо після
  /// видалення піра наступного раунду може вже не бути.
  Future<void> _tombstoneEverythingFor(FamilyPeer peer, SecretKey key) async {
    final previouslyPushed = await _previouslyPushed(peer.channelId);
    if (previouslyPushed.isEmpty) return;
    final entities = <Map<String, dynamic>>[];
    for (final id in previouslyPushed) {
      final parts = id.split('|');
      if (parts.length != 3) continue;
      entities.add({'type': parts[1], 'uuid': parts[2], 'ciphertext': '', 'deleted': true});
    }
    try {
      await _api.push(channelId: peer.channelId, entities: entities);
    } catch (_) {
      // Best-effort — без мережі пір лишиться зі старими даними до ручного
      // видалення на своєму боці; це прийнятний компроміс, той самий, що
      // вже описаний для FamilySyncService.deleteMemberEverywhere.
    }
    await _setPreviouslyPushed(peer.channelId, {});
  }

  Future<void> removePeer(String personUuid) async {
    final repo = FamilyPeersRepository(_db);
    final peer = await repo.getByUuid(personUuid);
    if (peer == null) return;

    final keyBytes = await SharedChannelKeyStorage.read(peer.channelId);
    if (keyBytes != null) {
      await _tombstoneEverythingFor(peer, SecretKey(keyBytes));
    }
    await SharedChannelKeyStorage.delete(peer.channelId);
    await repo.delete(personUuid);
    await repo.deleteSharedSubjectsForChannel(peer.channelId);
  }

  /// Вийти з сімейної групи повністю: відʼєднатись від УСІХ пірів і
  /// очистити власний familyId — на відміну від [removePeer] (один пір),
  /// тут прибирається геть усе, включно з даними, поділеними мені будь-ким.
  Future<void> leaveGroup() async {
    final repo = FamilyPeersRepository(_db);
    final peers = await repo.allPeers();
    for (final peer in peers) {
      await removePeer(peer.personUuid);
    }
    final owner = await (_db.select(_db.members)..where((t) => t.role.equals('owner'))).getSingleOrNull();
    if (owner != null) {
      await (_db.update(_db.members)..where((t) => t.id.equals(owner.id)))
          .write(const MembersCompanion(familyId: Value(null)));
    }
  }
}
