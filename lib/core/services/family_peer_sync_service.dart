import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/plan_provider.dart';
import 'family_sync_api_client.dart';
import 'family_visibility_service.dart';
import 'file_encryption_service.dart';
import 'notification_service.dart';
import 'peer_photo_service.dart';
import 'photo_service.dart';
import 'push_token_service.dart';
import 'relay_api_client.dart';
import 'shared_channel_key_storage.dart';
import 'subscription_service.dart';
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
    'schedule',
    'intake',
    'activity',
    'activity_slot',
    'activity_log',
    'wellbeing_log',
    'wellbeing_schedule',
    'doctor_appointment',
    'lab_result',
    'allergy',
    'chronic_condition',
    'vaccination',
    'surgery',
  ];

  // Той самий пріоритет, що й у family_sync_service.dart (пейринг 1:1):
  // ліки/розклад/активності — завжди, бо саме заради нагляду за прийомом
  // взагалі створюється зв'язок; решта підпорядкована прапорцю "Синхронізувати
  // медкартку".
  static const _alwaysSyncedTypes = {
    'medication', 'schedule', 'intake', 'activity', 'activity_slot', 'activity_log',
  };

  // Intake/activity_log генеруються щодня — без вікна кеш SharedEntities на
  // пристрої піра ріс би необмежено. Для перевірки "чи пропущено" достатньо
  // зовсім свіжих записів.
  static const _recentWindow = Duration(days: 2);
  static const _wellbeingWindow = Duration(days: 7);

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

    await _push(peer, key);
    await _pushGrantsSummary(peer, key);
    await _pull(peer, key);
    await FamilyPeersRepository(_db).updateLastSynced(peer.personUuid, DateTime.now());
    await _scheduleMissedChecks(peer);

    // Раніше пінгувався лише якщо _push() повернув true (є нові
    // ліки/розклад/тощо для цього піра) — але _pushGrantsSummary() вище
    // шле оновлення payerPlanActive/notify/view/edit НЕЗАЛЕЖНО від цього і
    // якраз одразу після конверсії "Локальний → Автономний" типово немає
    // жодної нової сутності для push (видимість/грант для щойно
    // з'явленого піра ще не налаштована), тож пінг мовчки пропускався — а
    // без нього пір дізнавався про свій новий Family-статус лише
    // випадково, при наступному самостійному відкритті застосунку.
    await _ping(peer.channelId, key);
  }

  // ── Grants summary: "що я дозволив цьому піру" → його пристрій ─────────
  // FamilyGrants живе лише на пристрої субʼєкта — без цього обміну пір не
  // мав би жодного способу дізнатись, що йому дозволено (напр. щоб показати
  // себе у списку "Сповіщення" отримувача). Надсилається щоразу — дешево,
  // без діффу, бо це лише кілька булевих значень.
  Future<void> _pushGrantsSummary(FamilyPeer peer, SecretKey key) async {
    final owner =
        await (_db.select(_db.members)..where((t) => t.role.equals('owner'))).getSingleOrNull();
    final ownerUuid = owner?.personUuid;
    if (ownerUuid == null) return;

    // payerPlanActive — per-peer, НЕ глобальний прапорець: включається лише
    // для пірів, яких я сам запросив (invitedMe==false) у МОЮ оплачувану
    // сім'ю (peer.familyId == owner.familyId) — інакше я б розкривав свій
    // білінг-статус і тим, хто мене запросив, кому це знати не потрібно.
    final payerPlanActive = owner!.familyId != null &&
        peer.familyId == owner.familyId &&
        !peer.invitedMe &&
        await SubscriptionService.cachedPlan() == AppPlan.family;

    final json = {
      'notify': await FamilyVisibilityService.isAllowed(_db, ownerUuid, peer.personUuid, FamilyPermission.notify),
      'view': await FamilyVisibilityService.isAllowed(_db, ownerUuid, peer.personUuid, FamilyPermission.view),
      'edit': await FamilyVisibilityService.isAllowed(_db, ownerUuid, peer.personUuid, FamilyPermission.edit),
      'payerPlanActive': payerPlanActive,
    };
    final entity = {
      'type': 'grants_summary',
      'uuid': 'grants_summary',
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    try {
      await _api.push(channelId: peer.channelId, entities: [entity]);
    } catch (_) {
      // Пір отримає актуальний стан на наступному раунді синку.
    }
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

      await _assignMissingUuids(subject.id);

      // Медкартка (усе, крім ліків) додатково підпорядкована окремому
      // master-перемикачу "Синхронізувати медкартку" — той самий бар'єр,
      // що й для старого 1:1 SharedChannels, тепер узгоджено і тут.
      final medcardAllowed = await FamilyVisibilityService.isMedcardSyncAllowed(subjectUuid);

      for (final type in _entityTypes) {
        if (!_alwaysSyncedTypes.contains(type) && !medcardAllowed) continue;
        final rows = await _rowsFor(type, subject.id);
        for (final row in rows) {
          final id = '$subjectUuid|$type|${row['uuid']}';
          currentIds.add(id);
          final changed = !previouslyPushed.contains(id) ||
              (since == null || DateTime.parse(row['updatedAt'] as String).isAfter(since));
          if (!changed) continue;

          final json = Map<String, dynamic>.from(row)
            ..['subjectPersonUuid'] = subjectUuid
            ..['subjectName'] = subject.name
            ..['subjectAvatarIndex'] = subject.avatarIndex;
          // updatedAt лишається в payload (не видаляємо) — пір використовує
          // його як baseUpdatedAt при пропозиції правки (compare-and-swap,
          // див. proposeEdit/_applyFieldIfUnchanged нижче).
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

  // ── Присвоєння syncUuid ──────────────────────────────────────────────
  // На відміну від FamilySyncService (пейринг 1:1), тут це єдине місце, де
  // такі uuid взагалі призначаються для груп-пірів — без цього кроку рядки
  // без пари ніколи не мали 1:1 SharedChannel просто ніколи не набули б
  // uuid і мовчки не потрапляли б у групу.
  static const _uuid = Uuid();

  Future<void> _assignMissingUuids(int memberId) async {
    Future<void> medications() async {
      final rows = await (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.medications)..where((t) => t.id.equals(r.id)))
            .write(MedicationsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> schedules() async {
      final query = _db.select(_db.schedules).join([
        innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
      ])
        ..where(_db.medications.memberId.equals(memberId) & _db.schedules.syncUuid.isNull());
      for (final r in await query.get()) {
        final s = r.readTable(_db.schedules);
        await (_db.update(_db.schedules)..where((t) => t.id.equals(s.id)))
            .write(SchedulesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> intakes() async {
      final rows = await (_db.select(_db.intakes)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.intakes)..where((t) => t.id.equals(r.id)))
            .write(IntakesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> activities() async {
      final rows = await (_db.select(_db.activities)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.activities)..where((t) => t.id.equals(r.id)))
            .write(ActivitiesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> activitySlots() async {
      final query = _db.select(_db.activitySlots).join([
        innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
      ])
        ..where(_db.activities.memberId.equals(memberId) & _db.activitySlots.syncUuid.isNull());
      for (final r in await query.get()) {
        final s = r.readTable(_db.activitySlots);
        await (_db.update(_db.activitySlots)..where((t) => t.id.equals(s.id)))
            .write(ActivitySlotsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> activityLogs() async {
      final rows = await (_db.select(_db.activityLogs)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.activityLogs)..where((t) => t.id.equals(r.id)))
            .write(ActivityLogsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> wellbeingLogs() async {
      final rows = await (_db.select(_db.wellbeingLogs)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.wellbeingLogs)..where((t) => t.id.equals(r.id)))
            .write(WellbeingLogsCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> wellbeingSchedules() async {
      final rows = await (_db.select(_db.wellbeingSchedules)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.wellbeingSchedules)..where((t) => t.id.equals(r.id)))
            .write(WellbeingSchedulesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> flat(String table) async {
      switch (table) {
        case 'doctor_appointment':
          final rows = await (_db.select(_db.doctorAppointments)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.doctorAppointments)..where((t) => t.id.equals(r.id)))
                .write(DoctorAppointmentsCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'lab_result':
          final rows = await (_db.select(_db.labResults)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.labResults)..where((t) => t.id.equals(r.id)))
                .write(LabResultsCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'allergy':
          final rows = await (_db.select(_db.allergies)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.allergies)..where((t) => t.id.equals(r.id)))
                .write(AllergiesCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'chronic_condition':
          final rows = await (_db.select(_db.chronicConditions)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.chronicConditions)..where((t) => t.id.equals(r.id)))
                .write(ChronicConditionsCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'vaccination':
          final rows = await (_db.select(_db.vaccinations)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.vaccinations)..where((t) => t.id.equals(r.id)))
                .write(VaccinationsCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'surgery':
          final rows = await (_db.select(_db.surgeries)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.surgeries)..where((t) => t.id.equals(r.id)))
                .write(SurgeriesCompanion(syncUuid: Value(_uuid.v4())));
          }
      }
    }

    await medications();
    await schedules();
    await intakes();
    await activities();
    await activitySlots();
    await activityLogs();
    await wellbeingLogs();
    await wellbeingSchedules();
    for (final t in const [
      'doctor_appointment', 'lab_result', 'allergy', 'chronic_condition', 'vaccination', 'surgery',
    ]) {
      await flat(t);
    }
  }

  Future<String?> _medicationSyncUuidFor(int medicationId) async {
    final row = await (_db.select(_db.medications)..where((t) => t.id.equals(medicationId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _activitySyncUuidFor(int activityId) async {
    final row = await (_db.select(_db.activities)..where((t) => t.id.equals(activityId))).getSingleOrNull();
    return row?.syncUuid;
  }

  /// Одна сира вибірка на (тип, memberId) — повертає generic Map (json +
  /// syncUuid як 'uuid'), щоб уникнути майже однакових типізованих гілок.
  /// Рядки без syncUuid пропускаються (щойно призначені [_assignMissingUuids]
  /// вище — цей виклик завжди йде першим у [_push]).
  Future<List<Map<String, dynamic>>> _rowsFor(String type, int memberId) async {
    final recentCutoff = DateTime.now().subtract(_recentWindow);
    final wellbeingCutoff = DateTime.now().subtract(_wellbeingWindow);

    switch (type) {
      case 'medication':
        final rows = await (_db.select(_db.medications)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'schedule':
        final query = _db.select(_db.schedules).join([
          innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
        ])
          ..where(_db.medications.memberId.equals(memberId));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final s = r.readTable(_db.schedules);
          final med = r.readTable(_db.medications);
          if (s.syncUuid == null || med.syncUuid == null) continue;
          final json = _withUuid(s.toJson(), s.syncUuid!)..remove('medicationId');
          json['medicationSyncUuid'] = med.syncUuid;
          result.add(json);
        }
        return result;
      case 'intake':
        final rows = await (_db.select(_db.intakes)
              ..where((t) => t.memberId.equals(memberId) & t.scheduledAt.isBiggerOrEqualValue(recentCutoff)))
            .get();
        final result = <Map<String, dynamic>>[];
        for (final i in rows) {
          if (i.syncUuid == null) continue;
          final medUuid = await _medicationSyncUuidFor(i.medicationId);
          if (medUuid == null) continue;
          final json = _withUuid(i.toJson(), i.syncUuid!)
            ..remove('medicationId')
            ..remove('scheduleId');
          json['medicationSyncUuid'] = medUuid;
          result.add(json);
        }
        return result;
      case 'activity':
        final rows = await (_db.select(_db.activities)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'activity_slot':
        final query = _db.select(_db.activitySlots).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
        ])
          ..where(_db.activities.memberId.equals(memberId));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final slot = r.readTable(_db.activitySlots);
          final act = r.readTable(_db.activities);
          if (slot.syncUuid == null || act.syncUuid == null) continue;
          final json = _withUuid(slot.toJson(), slot.syncUuid!)..remove('activityId');
          json['activitySyncUuid'] = act.syncUuid;
          result.add(json);
        }
        return result;
      case 'activity_log':
        final rows = await (_db.select(_db.activityLogs)
              ..where((t) => t.memberId.equals(memberId) & t.scheduledAt.isBiggerOrEqualValue(recentCutoff)))
            .get();
        final result = <Map<String, dynamic>>[];
        for (final l in rows) {
          if (l.syncUuid == null) continue;
          final actUuid = await _activitySyncUuidFor(l.activityId);
          if (actUuid == null) continue;
          final json = _withUuid(l.toJson(), l.syncUuid!)..remove('activityId');
          json['activitySyncUuid'] = actUuid;
          result.add(json);
        }
        return result;
      case 'wellbeing_log':
        final rows = await (_db.select(_db.wellbeingLogs)
              ..where((t) => t.memberId.equals(memberId) & t.loggedAt.isBiggerOrEqualValue(wellbeingCutoff)))
            .get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'wellbeing_schedule':
        final rows = await (_db.select(_db.wellbeingSchedules)..where((t) => t.memberId.equals(memberId))).get();
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

  // ── Edit: пір → subject, тільки поле нотаток, з compare-and-swap ───────
  // Мінімально ризиковий перший крок для "edit"-права: щоб не будувати
  // повноцінний merge/conflict UI (свідомо відкладено), редагувати можна
  // лише notes/instructions — воно є в усіх типів, і застосовується ТІЛЬКИ
  // якщо запис не змінювався локально з моменту, коли пір його побачив
  // (baseUpdatedAt == поточний updatedAt). Інакше правка пира тихо
  // відкидається — гірший випадок: правка загубилась, а не що вона затерла
  // свіжішу локальну зміну.

  static const Map<String, String> _notesFields = {
    'medication': 'instructions',
    'doctor_appointment': 'notes',
    'lab_result': 'notes',
    'allergy': 'notes',
    'chronic_condition': 'notes',
    'vaccination': 'notes',
    'surgery': 'notes',
  };

  /// Викликає пір, коли редагує notes/instructions спільного запису.
  /// Best-effort — якщо мережі немає, правка просто губиться (черги
  /// повторних спроб тут свідомо немає, це наступний крок допрацювання).
  Future<void> proposeEdit({
    required String channelId,
    required String subjectPersonUuid,
    required String entityType,
    required String targetUuid,
    required String? value,
    required DateTime baseUpdatedAt,
  }) async {
    final keyBytes = await SharedChannelKeyStorage.read(channelId);
    if (keyBytes == null) throw StateError('Немає ключа каналу для цього піра');
    final key = SecretKey(keyBytes);

    final json = {
      'subjectPersonUuid': subjectPersonUuid,
      'entityType': entityType,
      'uuid': targetUuid,
      'field': _notesFields[entityType] ?? 'notes',
      'value': value,
      'baseUpdatedAt': baseUpdatedAt.toIso8601String(),
    };
    final entity = {
      'type': 'edit_proposal',
      'uuid': const Uuid().v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    await _api.push(channelId: channelId, entities: [entity]);
  }

  Future<void> _applyEditProposal(Map<String, dynamic> json, FamilyPeer fromPeer) async {
    final subjectUuid = json['subjectPersonUuid'] as String?;
    final entityType = json['entityType'] as String?;
    final targetUuid = json['uuid'] as String?;
    final field = json['field'] as String?;
    final baseUpdatedAtRaw = json['baseUpdatedAt'] as String?;
    if (subjectUuid == null || entityType == null || targetUuid == null || field == null || baseUpdatedAtRaw == null) {
      return;
    }
    final baseUpdatedAt = DateTime.tryParse(baseUpdatedAtRaw);
    if (baseUpdatedAt == null) return;

    // Це справді мій профіль (не чужий subject, про якого пір щось вигадав)?
    final subject = await (_db.select(_db.members)..where((t) => t.personUuid.equals(subjectUuid))).getSingleOrNull();
    if (subject == null) return;

    // Пір досі має право edit на цей subject — не довіряємо тому, що
    // написано в payload, перевіряємо на своєму боці.
    final allowed = await FamilyVisibilityService.isAllowed(
      _db,
      subjectUuid,
      fromPeer.personUuid,
      FamilyPermission.edit,
    );
    if (!allowed) return;

    final value = json['value'] as String?;
    await _applyFieldIfUnchanged(entityType, targetUuid, subject.id, field, value, baseUpdatedAt);
  }

  // Порівняння з точністю до секунди — SQLite/Drift можуть не зберігати
  // мікросекунди, тож рівність "до мікросекунди" між тим, що прийшло з
  // JSON, і живим рядком у БД, ненадійна.
  bool _sameVersion(DateTime a, DateTime b) =>
      a.millisecondsSinceEpoch ~/ 1000 == b.millisecondsSinceEpoch ~/ 1000;

  Future<void> _applyFieldIfUnchanged(
    String entityType,
    String targetUuid,
    int memberId,
    String field,
    String? value,
    DateTime baseUpdatedAt,
  ) async {
    final trimmed = value?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;

    switch (entityType) {
      case 'medication':
        final row = await (_db.select(_db.medications)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.medications)..where((t) => t.id.equals(row.id))).write(
            MedicationsCompanion(instructions: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'doctor_appointment':
        final row = await (_db.select(_db.doctorAppointments)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.doctorAppointments)..where((t) => t.id.equals(row.id))).write(
            DoctorAppointmentsCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'lab_result':
        final row = await (_db.select(_db.labResults)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.labResults)..where((t) => t.id.equals(row.id)))
            .write(LabResultsCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'allergy':
        final row = await (_db.select(_db.allergies)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.allergies)..where((t) => t.id.equals(row.id)))
            .write(AllergiesCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'chronic_condition':
        final row = await (_db.select(_db.chronicConditions)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.chronicConditions)..where((t) => t.id.equals(row.id))).write(
            ChronicConditionsCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'vaccination':
        final row = await (_db.select(_db.vaccinations)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.vaccinations)..where((t) => t.id.equals(row.id)))
            .write(VaccinationsCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
      case 'surgery':
        final row = await (_db.select(_db.surgeries)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.surgeries)..where((t) => t.id.equals(row.id)))
            .write(SurgeriesCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
    }
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
      if (entity.type == 'edit_proposal') {
        if (entity.deleted) continue; // tombstone для edit_proposal не буває
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _applyEditProposal(json, peer);
        continue;
      }
      if (entity.type == 'grants_summary') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await repo.updateGrantedToMe(
          peer.personUuid,
          notify: json['notify'] as bool? ?? false,
          view: json['view'] as bool? ?? false,
          edit: json['edit'] as bool? ?? false,
          payerPlanActive: json['payerPlanActive'] as bool? ?? false,
        );
        continue;
      }
      if (entity.type == 'photo_request') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handlePhotoRequest(json, peer, key);
        continue;
      }
      if (entity.type == 'photo_response') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handlePhotoResponse(json, peer);
        continue;
      }
      if (entity.type == 'remind_now') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handleRemoteReminder(json, entity);
        continue;
      }
      if (entity.type == 'known_member') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handleKnownMember(json);
        continue;
      }
      if (entity.type == 'request_introduction') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handleIntroductionRequest(json, peer);
        continue;
      }
      if (entity.type == 'introduction') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handleIntroduction(json, peer);
        continue;
      }
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

  // ── "🔔 Нагадати": миттєвий пуш пиру, коли наглядач натиснув кнопку ──────
  // На відміну від _scheduleMissedChecks (заплановано наперед на пристрої
  // НАГЛЯДАЧА, скасовується мовчки) — це разовий, явний виклик: показується
  // одразу на пристрої СУБ'ЄКТА, щойно долетить.
  Future<void> sendRemoteReminder({
    required String channelId,
    required String title,
    required String body,
  }) async {
    final keyBytes = await SharedChannelKeyStorage.read(channelId);
    if (keyBytes == null) throw StateError('Немає ключа каналу для цього піра');
    final key = SecretKey(keyBytes);

    final entity = {
      'type': 'remind_now',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, {'title': title, 'body': body})),
    };
    await _api.push(channelId: channelId, entities: [entity]);
    await _ping(channelId, key);
  }

  // Сервер зберігає кожну надіслану сутність і повторно віддає її при
  // будь-якому "since: null" пулі (напр. після переустановки) — без цієї
  // перевірки старий "Нагадати" міг би спливти як нове сповіщення значно
  // пізніше, ніж його справді натиснули.
  Future<void> _handleRemoteReminder(Map<String, dynamic> json, FamilySyncEntity entity) async {
    final updatedAt = DateTime.tryParse(entity.updatedAt);
    if (updatedAt == null || DateTime.now().difference(updatedAt) > const Duration(minutes: 5)) return;
    await NotificationService.showRemoteReminder(
      title: json['title'] as String? ?? '🔔 Вам нагадують',
      body: json['body'] as String? ?? '',
    );
  }

  // ── Фото/документи на запит ──────────────────────────────────────────
  // Data minimization (GDPR ст. 5.1.c): самі файли НЕ пушаться разом з
  // текстовими полями медкартки (лише documentPaths — список "ось що є") —
  // пір отримує байти лише коли сам явно попросив конкретний файл.

  /// Викликає пір (переглядач), коли хоче отримати конкретний файл, шлях до
  /// якого вже бачить у dataJson поділеного запису.
  Future<void> requestPhoto({
    required String channelId,
    required String photoPath,
  }) async {
    final keyBytes = await SharedChannelKeyStorage.read(channelId);
    if (keyBytes == null) throw StateError('Немає ключа каналу для цього піра');
    final key = SecretKey(keyBytes);

    final entity = {
      'type': 'photo_request',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, {'photoPath': photoPath})),
    };
    await _api.push(channelId: channelId, entities: [entity]);
    await PeerPhotoService.markRequested(channelId, photoPath);
    await _ping(channelId, key);
  }

  bool _documentPathsContain(String documentPathsJson, String photoPath) {
    try {
      return (jsonDecode(documentPathsJson) as List).cast<String>().contains(photoPath);
    } catch (_) {
      return false;
    }
  }

  /// true лише якщо [photoPath] реально належить запису, до якого пір з
  /// [peerPersonUuid] має право view — не довіряємо шляху з payload наосліп,
  /// інакше запит міг би витягнути довільний файл із med_photos/.
  Future<bool> _photoRequestAllowed(String photoPath, String peerPersonUuid) async {
    Future<bool> memberAllowed(int memberId) async {
      final subject = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingleOrNull();
      final subjectUuid = subject?.personUuid;
      if (subjectUuid == null) return false;
      return FamilyVisibilityService.isAllowed(_db, subjectUuid, peerPersonUuid, FamilyPermission.view);
    }

    for (final a in await _db.select(_db.doctorAppointments).get()) {
      if (_documentPathsContain(a.documentPaths, photoPath) && await memberAllowed(a.memberId)) return true;
    }
    for (final l in await _db.select(_db.labResults).get()) {
      if (_documentPathsContain(l.documentPaths, photoPath) && await memberAllowed(l.memberId)) return true;
    }
    for (final a in await _db.select(_db.allergies).get()) {
      if (_documentPathsContain(a.documentPaths, photoPath) && await memberAllowed(a.memberId)) return true;
    }
    for (final c in await _db.select(_db.chronicConditions).get()) {
      if (_documentPathsContain(c.documentPaths, photoPath) && await memberAllowed(c.memberId)) return true;
    }
    for (final v in await _db.select(_db.vaccinations).get()) {
      if (_documentPathsContain(v.documentPaths, photoPath) && await memberAllowed(v.memberId)) return true;
    }
    for (final s in await _db.select(_db.surgeries).get()) {
      if (_documentPathsContain(s.documentPaths, photoPath) && await memberAllowed(s.memberId)) return true;
    }
    return false;
  }

  Future<void> _handlePhotoRequest(Map<String, dynamic> json, FamilyPeer peer, SecretKey key) async {
    final photoPath = json['photoPath'] as String?;
    if (photoPath == null) return;
    if (!await _photoRequestAllowed(photoPath, peer.personUuid)) return;

    final abs = await PhotoService.absolutePath(photoPath);
    final file = File(abs);
    if (!await file.exists()) return;
    Uint8List plainBytes;
    try {
      plainBytes = await FileEncryptionService.decryptBytes(await file.readAsBytes());
    } catch (_) {
      return;
    }

    final entity = {
      'type': 'photo_response',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(
        await SyncCryptoService.encryptEntity(key, {'photoPath': photoPath, 'bytes': base64Encode(plainBytes)}),
      ),
    };
    try {
      await _api.push(channelId: peer.channelId, entities: [entity]);
      await _ping(peer.channelId, key);
    } catch (_) {
      // Пір спробує ще раз наступним запитом — черги повторних спроб тут
      // свідомо немає, той самий компроміс, що й у proposeEdit.
    }
  }

  Future<void> _handlePhotoResponse(Map<String, dynamic> json, FamilyPeer peer) async {
    final photoPath = json['photoPath'] as String?;
    final bytesB64 = json['bytes'] as String?;
    if (photoPath == null || bytesB64 == null) return;
    try {
      await PeerPhotoService.save(peer.channelId, photoPath, base64Decode(bytesB64));
    } catch (_) {
      return;
    }
    await PeerPhotoService.clearRequested(peer.channelId, photoPath);
  }

  // ── Перевірка пропущеного: intake/activity_log/doctor_appointment/
  // wellbeing для пірів ────────────────────────────────────────────────
  // Той самий принцип "заплановано на +30 хв, скасовано якщо прийшло
  // підтвердження", що й у family_sync_service.dart (пейринг 1:1) — але тут
  // немає типізованих локальних рядків, лише кеш SharedEntities, тож
  // рішення "планувати/скасувати" приймається щоразу заново з ОСТАННЬОГО
  // відомого стану (ідемпотентно — попереднього стану порівнювати не треба).
  // Двостороння згода: subject дав notify (peer.notifyGranted, з
  // grants_summary) І сам peer особисто дозволив собі сповіщення від нього
  // (NotificationSettings.peerAlerts).
  Future<void> _scheduleMissedChecks(FamilyPeer peer) async {
    final settings = await NotificationSettings.load();
    // Раніше при відкликаному доступі/вимкненому сповіщенні тут одразу було
    // `return` — це зупиняло ПЛАНУВАННЯ нового, але нічого не скасовувало з
    // того, що вже було заплановано, поки дозвіл ще діяв: check, поставлений
    // до відкликання, лишався жити в OS-планувальнику назавжди (чи доки сам
    // не спрацює один раз). Тепер замість "нічого не робити" — активно
    // скасовуємо все заплановане для цього піра нижче.
    final allowed = peer.notifyGranted && settings.isPeerEnabled(peer.personUuid);

    final subjects = await (_db.select(_db.sharedSubjects)
          ..where((t) => t.peerChannelId.equals(peer.channelId)))
        .get();

    for (final subject in subjects) {
      final entities = await (_db.select(_db.sharedEntities)
            ..where((t) => t.subjectPersonUuid.equals(subject.personUuid)))
          .get();
      if (entities.isEmpty) continue;

      if (!allowed) {
        for (final e in entities) {
          switch (e.entityType) {
            case 'intake':
              await NotificationService.cancelPeerIntakeCheck(e.uuid);
            case 'activity_log':
              await NotificationService.cancelPeerActivityCheck(e.uuid);
            case 'doctor_appointment':
              await NotificationService.cancelPeerAppointmentCheck(e.uuid);
          }
        }
        await NotificationService.cancelTodayPeerWellbeingChecks(subject.personUuid);
        continue;
      }

      Map<String, dynamic>? decode(SharedEntity e) {
        try {
          return jsonDecode(e.dataJson) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }

      String? nameFor(String entityType, String? uuid) {
        if (uuid == null) return null;
        for (final e in entities) {
          if (e.entityType == entityType && e.uuid == uuid) {
            return decode(e)?['name'] as String?;
          }
        }
        return null;
      }

      var hasWellbeingLogToday = false;
      final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      for (final e in entities) {
        if (e.entityType == 'wellbeing_log') {
          final json = decode(e);
          final loggedAtRaw = json?['loggedAt'] as String?;
          final loggedAt = loggedAtRaw != null ? DateTime.tryParse(loggedAtRaw) : null;
          if (loggedAt != null && !loggedAt.isBefore(todayStart)) hasWellbeingLogToday = true;
        }
      }
      if (hasWellbeingLogToday) {
        await NotificationService.cancelTodayPeerWellbeingChecks(subject.personUuid);
      }

      for (final e in entities) {
        final json = decode(e);
        if (json == null) continue;

        switch (e.entityType) {
          case 'intake':
            final status = json['status'] as String?;
            if (status == null || status == 'pending') {
              final scheduledAtRaw = json['scheduledAt'] as String?;
              final scheduledAt = scheduledAtRaw != null ? DateTime.tryParse(scheduledAtRaw) : null;
              if (scheduledAt == null) break;
              final medName = nameFor('medication', json['medicationSyncUuid'] as String?) ?? 'Ліки';
              final doseAmount = json['doseAmount'];
              final doseUnit = json['doseUnit'] as String? ?? '';
              await NotificationService.schedulePeerIntakeCheck(
                uuid: e.uuid,
                subjectName: subject.name,
                medName: medName,
                dose: doseAmount != null ? '$doseAmount $doseUnit' : '',
                scheduledAt: scheduledAt,
              );
            } else {
              await NotificationService.cancelPeerIntakeCheck(e.uuid);
            }
          case 'activity_log':
            final status = json['status'] as String?;
            if (status == null || status == 'pending') {
              final scheduledAtRaw = json['scheduledAt'] as String?;
              final scheduledAt = scheduledAtRaw != null ? DateTime.tryParse(scheduledAtRaw) : null;
              if (scheduledAt == null) break;
              final activityName = nameFor('activity', json['activitySyncUuid'] as String?) ?? 'Активність';
              await NotificationService.schedulePeerActivityCheck(
                uuid: e.uuid,
                subjectName: subject.name,
                activityName: activityName,
                scheduledAt: scheduledAt,
              );
            } else {
              await NotificationService.cancelPeerActivityCheck(e.uuid);
            }
          case 'doctor_appointment':
            final status = json['status'] as String?;
            if (status == null || status == 'pending') {
              final scheduledAtRaw = json['scheduledAt'] as String?;
              final scheduledAt = scheduledAtRaw != null ? DateTime.tryParse(scheduledAtRaw) : null;
              if (scheduledAt == null) break;
              final doctorType = json['doctorType'] as String? ?? 'Лікар';
              await NotificationService.schedulePeerAppointmentCheck(
                uuid: e.uuid,
                subjectName: subject.name,
                doctorType: doctorType,
                scheduledAt: scheduledAt,
              );
            } else {
              await NotificationService.cancelPeerAppointmentCheck(e.uuid);
            }
          case 'wellbeing_schedule':
            if (hasWellbeingLogToday) break;
            final now = DateTime.now();
            final day = DateTime(now.year, now.month, now.day);
            final cutoff = now.subtract(const Duration(hours: 1));
            List<String> times;
            try {
              times = List<String>.from(json['times'] as List);
            } catch (_) {
              break;
            }
            for (var i = 0; i < times.length; i++) {
              final parts = times[i].split(':');
              final scheduledAt =
                  DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
              if (scheduledAt.isBefore(cutoff)) continue;
              await NotificationService.schedulePeerWellbeingCheck(
                subjectPersonUuid: subject.personUuid,
                subjectName: subject.name,
                slotIndex: i,
                scheduledAt: scheduledAt,
              );
            }
        }
      }
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

    // Пір прибирається з allPeers() назавжди щойно репозиторій нижче видалить
    // рядок — _scheduleMissedChecks більше НІКОЛИ не викличеться для нього,
    // тож усе, що вже було заплановано (perr-check на intake/activity/
    // appointment/wellbeing), лишилось би висіти в OS-планувальнику без
    // жодного шансу самоскасуватись пізніше. Скасовуємо явно тут, поки ще
    // знаємо, які subjects/entities взагалі належали цьому піру.
    final subjects = await (_db.select(_db.sharedSubjects)
          ..where((t) => t.peerChannelId.equals(peer.channelId)))
        .get();
    for (final subject in subjects) {
      final entities = await (_db.select(_db.sharedEntities)
            ..where((t) => t.subjectPersonUuid.equals(subject.personUuid)))
          .get();
      for (final e in entities) {
        switch (e.entityType) {
          case 'intake':
            await NotificationService.cancelPeerIntakeCheck(e.uuid);
          case 'activity_log':
            await NotificationService.cancelPeerActivityCheck(e.uuid);
          case 'doctor_appointment':
            await NotificationService.cancelPeerAppointmentCheck(e.uuid);
        }
      }
      await NotificationService.cancelTodayPeerWellbeingChecks(subject.personUuid);
    }

    final keyBytes = await SharedChannelKeyStorage.read(peer.channelId);
    if (keyBytes != null) {
      await _tombstoneEverythingFor(peer, SecretKey(keyBytes));
    }
    await SharedChannelKeyStorage.delete(peer.channelId);
    await repo.delete(personUuid);
    await repo.deleteSharedSubjectsForChannel(peer.channelId);
  }

  /// Вийти з ОДНІЄЇ конкретної сімейної групи: відʼєднатись лише від пірів
  /// цієї [familyId] — на відміну від [removePeer] (один пір), тут
  /// прибирається все, поділене мені всередині цієї групи. З мультисімейністю
  /// пристрій може одночасно бути в кількох групах (`FamilyPeers.familyId`
  /// різний по рядках) — вихід з однієї не повинен чіпати інші.
  ///
  /// Якщо [familyId] збігається з власною `owner.familyId` (я платник цієї
  /// групи) — додатково скидається й вона: я більше не веду цю сім'ю.
  Future<void> leaveGroup(String familyId) async {
    final repo = FamilyPeersRepository(_db);
    final peers = await repo.allPeers();
    for (final peer in peers.where((p) => p.familyId == familyId)) {
      await removePeer(peer.personUuid);
    }
    final owner = await (_db.select(_db.members)..where((t) => t.role.equals('owner'))).getSingleOrNull();
    if (owner != null && owner.familyId == familyId) {
      await (_db.update(_db.members)..where((t) => t.id.equals(owner.id)))
          .write(const MembersCompanion(familyId: Value(null)));
    }
  }

  // ── Автопредставлення + лениве створення каналів (Фаза 5) ────────────────
  // Топологія "зірка через платящого": двоє запрошених НЕ бачать одне одного
  // взагалі, поки платящий (хаб, через якого обидва приєднались) не
  // познайомить їх — розсилка ЛИШЕ візитівок (ім'я/аватар/personUuid), без
  // доступу до даних. Справжній попарний канал створюється лениво, тільки
  // коли хтось явно вмикає видимість для когось із цього списку.

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  Future<void> _sendCard({
    required String toChannelId,
    required String type,
    required String uuid,
    required Map<String, dynamic> json,
  }) async {
    final keyBytes = await SharedChannelKeyStorage.read(toChannelId);
    if (keyBytes == null) return;
    final key = SecretKey(keyBytes);
    final entity = {
      'type': type,
      'uuid': uuid,
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    try {
      await _api.push(channelId: toChannelId, entities: [entity]);
    } catch (_) {
      // Best-effort, той самий компроміс, що й для proposeEdit/photo_request —
      // без черги повторних спроб. Пропущене знайомство не критичне: людина
      // просто не побачить цього учасника у списку "Видимість", поки не
      // станеться інший привід для синку (напр. ще один новий учасник).
    }
  }

  /// Викликати з [FamilyGroupService.refreshPeers] одразу після підтвердження
  /// НОВОГО піра — я (платящий-хаб цієї сімʼї) знайомлю його з усіма, хто вже
  /// в групі, і навпаки, обміном візитівок в обидва боки.
  Future<void> introduceNewPeer(String newPeerPersonUuid) async {
    final repo = FamilyPeersRepository(_db);
    final newPeer = await repo.getByUuid(newPeerPersonUuid);
    if (newPeer == null) return;
    final allPeers = await repo.allPeers();
    final existingPeers = allPeers
        .where((p) => p.familyId == newPeer.familyId && p.personUuid != newPeer.personUuid)
        .toList();
    if (existingPeers.isEmpty) return;

    Map<String, dynamic> cardOf(FamilyPeer p) => {
          'personUuid': p.personUuid,
          'name': p.name,
          'avatarIndex': p.avatarIndex,
          'familyId': p.familyId,
        };

    for (final existing in existingPeers) {
      await _sendCard(
        toChannelId: existing.channelId,
        type: 'known_member',
        uuid: 'known_member_${newPeer.personUuid}',
        json: cardOf(newPeer),
      );
      await _sendCard(
        toChannelId: newPeer.channelId,
        type: 'known_member',
        uuid: 'known_member_${existing.personUuid}',
        json: cardOf(existing),
      );
    }
  }

  Future<void> _handleKnownMember(Map<String, dynamic> json) async {
    final personUuid = json['personUuid'] as String?;
    final familyId = json['familyId'] as String?;
    if (personUuid == null || familyId == null) return;
    await FamilyPeersRepository(_db).upsertKnownMember(KnownFamilyMembersCompanion.insert(
      personUuid: personUuid,
      familyId: familyId,
      name: json['name'] as String? ?? 'Учасник родини',
      avatarIndex: Value(json['avatarIndex'] as int? ?? 0),
    ));
  }

  /// Викликати з UI ("Видимість для сім'ї"), коли субʼєкт вмикає видимість
  /// для когось із [KnownFamilyMembers] — надсилає прохання платящому (моєму
  /// прямому запрошувачу в цій сім'ї) звести мене з цільовим учасником.
  Future<void> requestIntroduction(String targetPersonUuid) async {
    final repo = FamilyPeersRepository(_db);
    final known = await repo.getKnownMember(targetPersonUuid);
    if (known == null) return;
    final peers = await repo.allPeers();
    final broker = peers.where((p) => p.familyId == known.familyId && p.invitedMe).firstOrNull;
    if (broker == null) return;

    await _sendCard(
      toChannelId: broker.channelId,
      type: 'request_introduction',
      uuid: _uuid.v4(),
      json: {'targetPersonUuid': targetPersonUuid},
    );
    final keyBytes = await SharedChannelKeyStorage.read(broker.channelId);
    if (keyBytes != null) await _ping(broker.channelId, SecretKey(keyBytes));
  }

  /// На боці платящого (брокера): [fromPeer] попросив звести його з
  /// `targetPersonUuid` — обидва вже мої прямі пірі (я їх запрошував), тож
  /// генерую свіжий канал+ключ для цієї ПАРИ і пересилаю обом їхніми
  /// існуючими каналами зі мною. Я сам у цьому новому каналі не берусь —
  /// лише одноразово брокерю знайомство.
  Future<void> _handleIntroductionRequest(Map<String, dynamic> json, FamilyPeer fromPeer) async {
    final targetUuid = json['targetPersonUuid'] as String?;
    if (targetUuid == null || targetUuid == fromPeer.personUuid) return;
    final repo = FamilyPeersRepository(_db);
    final target = await repo.getByUuid(targetUuid);
    if (target == null || target.familyId != fromPeer.familyId) return;

    final newChannelId = _uuid.v4();
    final newKeyBytes = _randomBytes(32);
    final newKeyB64 = base64Encode(newKeyBytes);

    await _sendCard(
      toChannelId: fromPeer.channelId,
      type: 'introduction',
      uuid: 'introduction_${target.personUuid}',
      json: {
        'peerPersonUuid': target.personUuid,
        'peerName': target.name,
        'peerAvatarIndex': target.avatarIndex,
        'channelId': newChannelId,
        'key': newKeyB64,
      },
    );
    await _sendCard(
      toChannelId: target.channelId,
      type: 'introduction',
      uuid: 'introduction_${fromPeer.personUuid}',
      json: {
        'peerPersonUuid': fromPeer.personUuid,
        'peerName': fromPeer.name,
        'peerAvatarIndex': fromPeer.avatarIndex,
        'channelId': newChannelId,
        'key': newKeyB64,
      },
    );
  }

  /// На боці одного з двох знайомлених: платящий-брокер [fromPeer] надіслав
  /// готовий канал+ключ до нового піра — встановлюю справжній [FamilyPeers]
  /// запис і прибираю тимчасову візитівку з [KnownFamilyMembers].
  /// invitedMe=false для ОБОХ сторін: знайомство через платящого не дає
  /// жодній зі сторін права дарувати Family-плюшки одна одній — дарує лише
  /// прямий інвайтер.
  Future<void> _handleIntroduction(Map<String, dynamic> json, FamilyPeer fromPeer) async {
    final peerUuid = json['peerPersonUuid'] as String?;
    final newChannelId = json['channelId'] as String?;
    final keyB64 = json['key'] as String?;
    if (peerUuid == null || newChannelId == null || keyB64 == null) return;

    final repo = FamilyPeersRepository(_db);
    await SharedChannelKeyStorage.store(newChannelId, base64Decode(keyB64));
    await repo.upsert(FamilyPeersCompanion.insert(
      personUuid: peerUuid,
      familyId: fromPeer.familyId,
      name: json['peerName'] as String? ?? 'Учасник родини',
      avatarIndex: Value(json['peerAvatarIndex'] as int? ?? 0),
      channelId: newChannelId,
      invitedMe: const Value(false),
    ));
    await repo.removeKnownMember(peerUuid);
  }
}
