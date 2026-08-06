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
import 'app_logger.dart';
import 'family_join_popup_service.dart';
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
    'activity_assignee',
    'activity_log',
    'wellbeing_log',
    'wellbeing_schedule',
    'doctor_appointment',
    'reminder_log',
    'reminder_slot',
    'medcard_section',
    'medcard_entry',
  ];

  // Той самий пріоритет, що й у family_sync_service.dart (пейринг 1:1):
  // ліки/розклад/активності — завжди, бо саме заради нагляду за прийомом
  // взагалі створюється зв'язок; решта підпорядкована прапорцю "Синхронізувати
  // медкартку".
  static const _alwaysSyncedTypes = {
    'medication', 'schedule', 'intake', 'activity', 'activity_slot', 'activity_assignee', 'activity_log',
  };

  // Intake/activity_log генеруються щодня — без вікна кеш SharedEntities на
  // пристрої піра ріс би необмежено. Для перевірки "чи пропущено" достатньо
  // зовсім свіжих записів.
  static const _recentWindow = Duration(days: 2);
  static const _wellbeingWindow = Duration(days: 7);

  Future<void> syncAllPeers() async {
    final peers = await FamilyPeersRepository(_db).allPeers();
    AppLogger.log('FamilyPeerSyncService.syncAllPeers: syncing ${peers.length} peer(s): '
        '${peers.map((p) => "${p.personUuid}(${p.channelId})").join(", ")}');
    for (final peer in peers) {
      try {
        await _syncPeer(peer);
      } catch (e, st) {
        // Раніше повністю мовчазний catch — якщо _push()/_pull() кидали
        // виняток (мережа, таймаут, будь-що), решта раунду (зокрема
        // _pushGrantsSummary) просто не відбувалась БЕЗ жодного сліду, тож
        // "дозволи не долетіли" було неможливо відрізнити від "успішно
        // нічого нового". Локальні дані лишаються джерелом правди —
        // спробуємо ще раз при наступному тригері, той самий підхід, що й
        // FamilySyncService — але тепер хоча б видно, чому саме.
        AppLogger.logError('FamilyPeerSyncService.syncAllPeers(personUuid=${peer.personUuid})', e, st);
      }
    }
  }

  Future<void> _syncPeer(FamilyPeer peer) async {
    final keyBytes = await SharedChannelKeyStorage.read(peer.channelId);
    if (keyBytes == null) {
      // Тимчасове діагностичне логування (той самий клас багів, що й
      // refreshPeers: "ще нема ключа" — тихий continue раніше без сліду).
      AppLogger.log(
          'FamilyPeerSyncService._syncPeer: SKIP (no local sync key) channelId=${peer.channelId} personUuid=${peer.personUuid}');
      return;
    }
    final key = SecretKey(keyBytes);

    await _push(peer, key);
    await _pushGrantsSummary(peer, key);
    final peerLeft = await _pull(peer, key);
    if (peerLeft) {
      // Симетрична частина Кроку 3.4: пір сам вийшов із сім'ї чи був
      // виключений на своєму боці — прибираємо його тут же, а не чекаємо,
      // поки хтось помітить застарілий рядок вручну.
      AppLogger.log(
          'FamilyPeerSyncService._syncPeer: peer signaled peer_left, removing channelId=${peer.channelId} personUuid=${peer.personUuid}');
      await removePeer(peer.personUuid);
      return;
    }
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
    await _ping(peer.channelId, key, identityFamilyId: peer.familyId);
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
      'viewSchedule': await FamilyVisibilityService.isSectionAllowed(
          _db, ownerUuid, peer.personUuid, FamilySection.schedule, edit: false),
      'editSchedule': await FamilyVisibilityService.isSectionAllowed(
          _db, ownerUuid, peer.personUuid, FamilySection.schedule, edit: true),
      'viewMedcard': await FamilyVisibilityService.isSectionAllowed(
          _db, ownerUuid, peer.personUuid, FamilySection.medcard, edit: false),
      'editMedcard': await FamilyVisibilityService.isSectionAllowed(
          _db, ownerUuid, peer.personUuid, FamilySection.medcard, edit: true),
      'viewShelves': await FamilyVisibilityService.isSectionAllowed(
          _db, ownerUuid, peer.personUuid, FamilySection.shelves, edit: false),
      'editShelves': await FamilyVisibilityService.isSectionAllowed(
          _db, ownerUuid, peer.personUuid, FamilySection.shelves, edit: true),
      'payerPlanActive': payerPlanActive,
    };
    final entity = {
      'type': 'grants_summary',
      'uuid': _stableUuid('grants_summary'),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    try {
      await _api.push(channelId: peer.channelId, entities: [entity]);
      AppLogger.log(
          'FamilyPeerSyncService._pushGrantsSummary: sent OK channelId=${peer.channelId} personUuid=${peer.personUuid} $json');
    } catch (e, st) {
      AppLogger.logError('FamilyPeerSyncService._pushGrantsSummary(channelId=${peer.channelId})', e, st);
    }
  }

  // ── Push: мої субʼєкти → цей пір, лише те, що дозволено ─────────────────

  String _pushedKey(String channelId) => 'family_peer_pushed_$channelId';

  // Реальний баг (06.08, знайдено через логи): row['updatedAt'] тут —
  // значення з Drift-згенерованого .toJson(), а НЕ типізований DateTime із
  // самого рядка. Drift за замовчуванням серіалізує DateTime у
  // millisecondsSinceEpoch (int), не в ISO-рядок (див.
  // ValueSerializer._DefaultValueSerializer у пакеті drift) — окрім
  // activity_assignee нижче, де рядок будується вручну й updatedAt навмисно
  // вже String. DateTime.parse(... as String) падав на КОЖНОМУ інкрементному
  // раунді синку (since != null) для будь-якого типу, окрім самого першого
  // разу (since == null пропускає цю гілку через короткий цикл ||) — тобто
  // жодна family-sync пара ніколи не переживала другий раунд push. Приймаємо
  // обидва формати замість здогадуватись, який саме Drift поверне цього разу.
  DateTime _rowUpdatedAt(dynamic value) =>
      value is int ? DateTime.fromMillisecondsSinceEpoch(value) : DateTime.parse(value as String);

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

      // Крок 4.1: додатковий, ТОЧНІШИЙ бар'єр поверх загального "view" вище —
      // по кожному з двох розділів окремо для САМЕ ЦЬОГО глядача (view вище
      // лише "чи бачить мене взагалі", ці — "чи бачить САМЕ ЦЕЙ розділ").
      final viewScheduleAllowed = await FamilyVisibilityService.isSectionAllowed(
          _db, subjectUuid, peer.personUuid, FamilySection.schedule, edit: false);
      final viewMedcardAllowed = await FamilyVisibilityService.isSectionAllowed(
          _db, subjectUuid, peer.personUuid, FamilySection.medcard, edit: false);
      // Крок 4.3.4 плану: Полички — окремий розділ від Медкартки (візити/
      // самопочуття), той самий master-перемикач medcardAllowed і далі діє
      // як спільний "вимикач усього, крім ліків/розкладу" зверху.
      final viewShelvesAllowed = await FamilyVisibilityService.isSectionAllowed(
          _db, subjectUuid, peer.personUuid, FamilySection.shelves, edit: false);

      for (final type in _entityTypes) {
        if (!_alwaysSyncedTypes.contains(type) && !medcardAllowed) continue;
        final sectionAllowed = _alwaysSyncedTypes.contains(type)
            ? viewScheduleAllowed
            : (type == 'medcard_section' || type == 'medcard_entry')
                ? viewShelvesAllowed
                : viewMedcardAllowed;
        if (!sectionAllowed) continue;
        final rows = await _rowsFor(type, subject.id);
        for (final row in rows) {
          final id = '$subjectUuid|$type|${row['uuid']}';
          currentIds.add(id);
          final changed = !previouslyPushed.contains(id) ||
              (since == null || _rowUpdatedAt(row['updatedAt']).isAfter(since));
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

  // Сервер (FamilySyncController.upsertEntity) валідує ЗОВНІШНІЙ 'uuid'
  // сутності суворим регекспом справжнього UUID — а частина типів тут
  // історично використовувала стабільні смислові рядки замість нього
  // ('grants_summary', 'peer_removed_$uuid' тощо, навмисно завжди
  // ОДНАКОВІ для одного й того самого логічного слоту, щоб REPLACE INTO на
  // сервері перезаписував той самий рядок, а не плодив нові). v5
  // (детермінований, за іменем) зберігає цю властивість "той самий вхід →
  // той самий вихід", але вже проходить валідацію. Реальний баг (06.08),
  // знайдено через логи: без цього push_grantsSummary/peer_left/
  // known_member/introduction/kicked_from_family/peer_removed і
  // activity_assignee (ротація) отримували 422 "uuid має бути UUID" на
  // КОЖНОМУ раунді синку, назавжди.
  static String _stableUuid(String seed) => const Uuid().v5(Namespace.url.value, seed);

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
          final rows = await (_db.select(_db.reminders)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.reminders)..where((t) => t.id.equals(r.id)))
                .write(RemindersCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'medcard_section':
          final rows = await (_db.select(_db.medcardSections)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.medcardSections)..where((t) => t.id.equals(r.id)))
                .write(MedcardSectionsCompanion(syncUuid: Value(_uuid.v4())));
          }
        case 'reminder_log':
          final rows = await (_db.select(_db.reminderLogs)
                ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
              .get();
          for (final r in rows) {
            await (_db.update(_db.reminderLogs)..where((t) => t.id.equals(r.id)))
                .write(ReminderLogsCompanion(syncUuid: Value(_uuid.v4())));
          }
      }
    }

    Future<void> medcardEntries() async {
      final rows = await (_db.select(_db.medcardEntries)
            ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
          .get();
      for (final r in rows) {
        await (_db.update(_db.medcardEntries)..where((t) => t.id.equals(r.id)))
            .write(MedcardEntriesCompanion(syncUuid: Value(_uuid.v4())));
      }
    }

    Future<void> reminderSlots() async {
      final query = _db.select(_db.reminderSlots).join([
        innerJoin(_db.reminders, _db.reminders.id.equalsExp(_db.reminderSlots.reminderId)),
      ])
        ..where(_db.reminders.memberId.equals(memberId) & _db.reminderSlots.syncUuid.isNull());
      for (final r in await query.get()) {
        final s = r.readTable(_db.reminderSlots);
        await (_db.update(_db.reminderSlots)..where((t) => t.id.equals(s.id)))
            .write(ReminderSlotsCompanion(syncUuid: Value(_uuid.v4())));
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
    await medcardEntries();
    await reminderSlots();
    for (final t in const ['doctor_appointment', 'medcard_section', 'reminder_log']) {
      await flat(t);
    }
  }

  Future<String?> _medicationSyncUuidFor(int medicationId) async {
    final row = await (_db.select(_db.medications)..where((t) => t.id.equals(medicationId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _scheduleSyncUuidFor(int scheduleId) async {
    final row = await (_db.select(_db.schedules)..where((t) => t.id.equals(scheduleId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _reminderSyncUuidFor(int reminderId) async {
    final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(reminderId))).getSingleOrNull();
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
        final result = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          result.add(json);
        }
        return result;
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
          final schedUuid = await _scheduleSyncUuidFor(i.scheduleId);
          if (medUuid == null || schedUuid == null) continue;
          final json = _withUuid(i.toJson(), i.syncUuid!)
            ..remove('medicationId')
            ..remove('scheduleId');
          json['medicationSyncUuid'] = medUuid;
          json['scheduleSyncUuid'] = schedUuid;
          result.add(json);
        }
        return result;
      case 'activity':
        final rows = await (_db.select(_db.activities)..where((t) => t.memberId.equals(memberId))).get();
        final result = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          result.add(json);
        }
        return result;
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
      case 'activity_assignee':
        // Крок 7.1 плану: пул ротації рутинної справи — на відміну від
        // решти типів тут немає власного syncUuid/updatedAt (весь пул
        // завжди замінюється цілком через ActivitiesRepository.
        // replaceAssignees, окремого редагування "на місці" не буває),
        // тож "uuid" для дифу пушів — детермінований, зібраний із
        // syncUuid активності + стабільної ідентичності самого рядка
        // (personUuid дійсного члена/тіньового піра), а не autoincrement
        // id (той міняється щоразу, як пул перезаписують).
        final query = _db.select(_db.activityAssignees).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activityAssignees.activityId)),
          innerJoin(_db.members, _db.members.id.equalsExp(_db.activityAssignees.memberId)),
        ])
          ..where(_db.activities.memberId.equals(memberId));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final assignee = r.readTable(_db.activityAssignees);
          final act = r.readTable(_db.activities);
          final assigneeMember = r.readTable(_db.members);
          if (act.syncUuid == null) continue;
          final identity = assigneeMember.linkedPeerPersonUuid ?? 'm${assigneeMember.id}';
          result.add({
            'uuid': _stableUuid('${act.syncUuid}:$identity'),
            'activitySyncUuid': act.syncUuid,
            'sortOrder': assignee.sortOrder,
            'name': assigneeMember.name,
            'avatarIndex': assigneeMember.avatarIndex,
            'assigneeLinkedPeerPersonUuid': assigneeMember.linkedPeerPersonUuid,
            'updatedAt': act.updatedAt.toIso8601String(),
          });
        }
        return result;
      case 'activity_log':
        // ⚠️ Фільтруємо по ВЛАСНИКУ РУТИНИ (activities.memberId), а не по
        // ActivityLogs.memberId — той при ротації може бути будь-ким із
        // пулу (дитина, тіньовий пір), не обов'язково subject. Фільтр по
        // власному memberId лога пропускав би саме ті дні, які найбільше
        // цікавлять піра — коли черга не на subject-а.
        final query = _db.select(_db.activityLogs).join([
          innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activityLogs.activityId)),
        ])
          ..where(_db.activities.memberId.equals(memberId) &
              _db.activityLogs.scheduledAt.isBiggerOrEqualValue(recentCutoff));
        final result = <Map<String, dynamic>>[];
        for (final r in await query.get()) {
          final l = r.readTable(_db.activityLogs);
          final act = r.readTable(_db.activities);
          if (l.syncUuid == null || act.syncUuid == null) continue;
          final assigneeMember =
              await (_db.select(_db.members)..where((t) => t.id.equals(l.memberId))).getSingleOrNull();
          final json = _withUuid(l.toJson(), l.syncUuid!)..remove('activityId');
          json['activitySyncUuid'] = act.syncUuid;
          // Крок 7.2 плану: та сама 'identity', що й у push activity_assignee
          // — щоб пір міг звірити "чи це я" і щоб record_proposal-реквест на
          // передачу черги знав, кого саме передавати.
          json['assigneeIdentity'] = assigneeMember?.linkedPeerPersonUuid ?? 'm${l.memberId}';
          json['assigneeName'] = assigneeMember?.name;
          json['assigneeAvatarIndex'] = assigneeMember?.avatarIndex;
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
        final wsResult = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          wsResult.add(json);
        }
        return wsResult;
      case 'doctor_appointment':
        final rows =
            await (_db.select(_db.reminders)..where((t) => t.memberId.equals(memberId))).get();
        final daResult = <Map<String, dynamic>>[];
        for (final r in rows) {
          if (r.syncUuid == null) continue;
          final json = _withUuid(r.toJson(), r.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(r.sectionId);
          daResult.add(json);
        }
        return daResult;
      case 'reminder_log':
        final rows = await (_db.select(_db.reminderLogs)
              ..where((t) => t.memberId.equals(memberId) & t.scheduledAt.isBiggerOrEqualValue(recentCutoff)))
            .get();
        final result = <Map<String, dynamic>>[];
        for (final l in rows) {
          if (l.syncUuid == null) continue;
          final reminderUuid = await _reminderSyncUuidFor(l.reminderId);
          if (reminderUuid == null) continue;
          final json = _withUuid(l.toJson(), l.syncUuid!)..remove('reminderId');
          json['reminderSyncUuid'] = reminderUuid;
          result.add(json);
        }
        return result;
      case 'reminder_slot':
        final rows = await (_db.select(_db.reminderSlots).join([
          innerJoin(_db.reminders, _db.reminders.id.equalsExp(_db.reminderSlots.reminderId)),
        ])..where(_db.reminders.memberId.equals(memberId))).get();
        final slotResult = <Map<String, dynamic>>[];
        for (final r in rows) {
          final s = r.readTable(_db.reminderSlots);
          if (s.syncUuid == null) continue;
          final reminderUuid = await _reminderSyncUuidFor(s.reminderId);
          if (reminderUuid == null) continue;
          final json = _withUuid(s.toJson(), s.syncUuid!)..remove('reminderId');
          json['reminderSyncUuid'] = reminderUuid;
          slotResult.add(json);
        }
        return slotResult;
      case 'medcard_section':
        final rows = await (_db.select(_db.medcardSections)..where((t) => t.memberId.equals(memberId))).get();
        return rows.where((r) => r.syncUuid != null).map((r) => _withUuid(r.toJson(), r.syncUuid!)).toList();
      case 'medcard_entry':
        final rows = await (_db.select(_db.medcardEntries)..where((t) => t.memberId.equals(memberId))).get();
        final result = <Map<String, dynamic>>[];
        for (final e in rows) {
          if (e.syncUuid == null) continue;
          final sectionUuid = await _medcardSectionSyncUuidFor(e.sectionId);
          if (sectionUuid == null) continue;
          final json = _withUuid(e.toJson(), e.syncUuid!)..remove('sectionId');
          json['sectionSyncUuid'] = sectionUuid;
          result.add(json);
        }
        return result;
    }
    return const [];
  }

  Future<String?> _medcardSectionSyncUuidFor(int sectionId) async {
    final row = await (_db.select(_db.medcardSections)..where((t) => t.id.equals(sectionId))).getSingleOrNull();
    return row?.syncUuid;
  }

  // Крок 4.3 плану: medication/activity/wellbeing_schedule/doctor_appointment
  // раніше передавали сирий локальний sectionId як є (без перекладу через
  // syncUuid) — те саме упущення, що вже виправили для 1:1-синку в Кроці
  // 5.5, тут просто не було зроблено. Виправляю зараз, бо перекладач чужих
  // даних (peer view) читатиме саме це поле.
  Future<String?> _sectionSyncUuidOrNull(int? sectionId) =>
      sectionId == null ? Future.value(null) : _medcardSectionSyncUuidFor(sectionId);

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

    // Крок 4.1/4.3.4: точніше, по розділу (medication → Розклад,
    // doctor_appointment → Медкартка, medcard_entry → Полички) — той самий
    // бар'єр, що й для push у _push() вище.
    final section = _alwaysSyncedTypes.contains(entityType)
        ? FamilySection.schedule
        : entityType == 'medcard_entry'
            ? FamilySection.shelves
            : FamilySection.medcard;
    final sectionAllowed = await FamilyVisibilityService.isSectionAllowed(
      _db,
      subjectUuid,
      fromPeer.personUuid,
      section,
      edit: true,
    );
    if (!sectionAllowed) return;

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
        final row = await (_db.select(_db.reminders)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return;
        await (_db.update(_db.reminders)..where((t) => t.id.equals(row.id))).write(
            RemindersCompanion(notes: Value(normalized), updatedAt: Value(DateTime.now())));
    }
  }

  // ── Крок 4.4.1 плану: справжнє створення/редагування "за іншого" ────────
  // На відміну від proposeEdit/_applyEditProposal вище (лише 2 текстові
  // поля, compare-and-swap), record_proposal несе ПОВНИЙ запис — і для
  // 'create' (новий запис від імені субʼєкта), і для 'edit' (той самий
  // compare-and-swap за baseUpdatedAt, але по всіх полях одразу, а не лише
  // notes/instructions). fields — уже готова, типізована під конкретний
  // entityType мапа (формує викликач у AddXScreen на боці глядача,
  // _fieldsFromCompanion-подібним способом — Крок 4.4.2+).

  static const _recordProposalTypes = {
    'medication',
    'activity',
    'doctor_appointment',
    'wellbeing_schedule',
    'medcard_entry',
    'activity_log',
  };

  Future<void> proposeRecord({
    required String channelId,
    required String subjectPersonUuid,
    required String entityType,
    required String action, // 'create' | 'edit'
    required String targetUuid,
    DateTime? baseUpdatedAt,
    String? sectionSyncUuid,
    required Map<String, dynamic> fields,
  }) async {
    assert(_recordProposalTypes.contains(entityType));
    assert(action == 'create' || action == 'edit');
    final keyBytes = await SharedChannelKeyStorage.read(channelId);
    if (keyBytes == null) throw StateError('Немає ключа каналу для цього піра');
    final key = SecretKey(keyBytes);

    final json = <String, dynamic>{
      'subjectPersonUuid': subjectPersonUuid,
      'entityType': entityType,
      'action': action,
      'uuid': targetUuid,
      'baseUpdatedAt': ?baseUpdatedAt?.toIso8601String(),
      'sectionSyncUuid': ?sectionSyncUuid,
      'fields': fields,
    };
    final entity = {
      'type': 'record_proposal',
      'uuid': _uuid.v4(),
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    await _api.push(channelId: channelId, entities: [entity]);
    await _ping(channelId, key);
  }

  Future<void> _applyRecordProposal(Map<String, dynamic> json, FamilyPeer fromPeer) async {
    final subjectUuid = json['subjectPersonUuid'] as String?;
    final entityType = json['entityType'] as String?;
    final action = json['action'] as String?;
    final targetUuid = json['uuid'] as String?;
    final fields = json['fields'] as Map<String, dynamic>?;
    if (subjectUuid == null ||
        entityType == null ||
        !_recordProposalTypes.contains(entityType) ||
        action == null ||
        targetUuid == null ||
        fields == null) {
      return;
    }

    // Це справді мій профіль (не чужий subject, про якого пір щось вигадав)?
    final subject =
        await (_db.select(_db.members)..where((t) => t.personUuid.equals(subjectUuid))).getSingleOrNull();
    if (subject == null) return;

    // Пір досі має право edit на цей subject — не довіряємо тому, що
    // написано в payload, перевіряємо на своєму боці (той самий підхід, що
    // й у _applyEditProposal).
    final allowed =
        await FamilyVisibilityService.isAllowed(_db, subjectUuid, fromPeer.personUuid, FamilyPermission.edit);
    if (!allowed) return;

    final section = _alwaysSyncedTypes.contains(entityType)
        ? FamilySection.schedule
        : entityType == 'medcard_entry'
            ? FamilySection.shelves
            : FamilySection.medcard;
    final sectionAllowed =
        await FamilyVisibilityService.isSectionAllowed(_db, subjectUuid, fromPeer.personUuid, section, edit: true);
    if (!sectionAllowed) return;

    final sectionSyncUuid = json['sectionSyncUuid'] as String?;
    final localSectionId = await _localSectionIdFor(sectionSyncUuid, subject.id);
    // MedcardEntries.sectionId — NOT NULL у схемі: якщо розділ ще не встиг
    // дійти до цього пристрою (розсинхрон черговості пушів), краще тихо
    // пропустити зараз — пір надішле знову на наступному раунді синку
    // (best-effort, той самий компроміс, що й для photo_request).
    if (entityType == 'medcard_entry' && localSectionId == null) return;

    String? title;
    if (action == 'create') {
      // Idempotent — якщо цей самий uuid уже прилетів раніше (повторний
      // push після збою мережі), не дублюємо рядок.
      if (await _recordExistsByUuid(entityType, targetUuid, subject.id)) return;
      title = await _insertRecord(entityType, subject.id, localSectionId, targetUuid, fields);
    } else if (action == 'edit') {
      final baseUpdatedAtRaw = json['baseUpdatedAt'] as String?;
      final baseUpdatedAt = baseUpdatedAtRaw != null ? DateTime.tryParse(baseUpdatedAtRaw) : null;
      if (baseUpdatedAt == null) return;
      title =
          await _updateRecordIfUnchanged(entityType, targetUuid, subject.id, localSectionId, fields, baseUpdatedAt);
    } else {
      return;
    }
    if (title == null) return; // не застосувалось (версія розійшлась/не знайдено)

    await NotificationService.showPeerRecordApplied(
      peerName: fromPeer.name,
      recordTitle: title,
      isNew: action == 'create',
    );
  }

  Future<int?> _localSectionIdFor(String? sectionSyncUuid, int memberId) async {
    if (sectionSyncUuid == null) return null;
    final row = await (_db.select(_db.medcardSections)
          ..where((t) => t.syncUuid.equals(sectionSyncUuid) & t.memberId.equals(memberId)))
        .getSingleOrNull();
    return row?.id;
  }

  Future<bool> _recordExistsByUuid(String entityType, String uuid, int memberId) async {
    switch (entityType) {
      case 'medication':
        return await (_db.select(_db.medications)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'activity':
        return await (_db.select(_db.activities)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'doctor_appointment':
        return await (_db.select(_db.reminders)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'wellbeing_schedule':
        return await (_db.select(_db.wellbeingSchedules)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
      case 'medcard_entry':
        return await (_db.select(_db.medcardEntries)
                  ..where((t) => t.syncUuid.equals(uuid) & t.memberId.equals(memberId)))
                .getSingleOrNull() !=
            null;
    }
    return false;
  }

  // ── Читання типізованих полів із fields-мапи (JSON з мережі) ────────────

  String? _fS(Map<String, dynamic> f, String k) => f[k] as String?;
  String _fSReq(Map<String, dynamic> f, String k, String fallback) => (f[k] as String?) ?? fallback;
  double _fD(Map<String, dynamic> f, String k, double fallback) => (f[k] as num?)?.toDouble() ?? fallback;
  int _fI(Map<String, dynamic> f, String k, int fallback) => (f[k] as num?)?.toInt() ?? fallback;
  bool _fB(Map<String, dynamic> f, String k, bool fallback) => (f[k] as bool?) ?? fallback;
  DateTime? _fDtN(Map<String, dynamic> f, String k) {
    final v = f[k] as String?;
    return v == null ? null : DateTime.tryParse(v);
  }

  DateTime _fDtReq(Map<String, dynamic> f, String k, DateTime fallback) => _fDtN(f, k) ?? fallback;

  /// Повертає людяну назву застосованого запису (для тексту сповіщення
  /// власнику) — null, якщо entityType не підтримується.
  Future<String?> _insertRecord(
    String entityType,
    int memberId,
    int? sectionId,
    String syncUuid,
    Map<String, dynamic> f,
  ) async {
    final now = DateTime.now();
    switch (entityType) {
      case 'medication':
        final name = _fSReq(f, 'name', '');
        if (name.isEmpty) return null;
        await _db.into(_db.medications).insert(MedicationsCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              name: name,
              form: Value(_fSReq(f, 'form', '')),
              doseAmount: _fD(f, 'doseAmount', 1),
              doseUnit: Value(_fSReq(f, 'doseUnit', 'мг')),
              repeatType: Value(_fSReq(f, 'repeatType', 'daily')),
              repeatConfig: Value(_fSReq(f, 'repeatConfig', '{}')),
              startDate: _fDtReq(f, 'startDate', now),
              endDate: Value(_fDtN(f, 'endDate')),
              totalCount: Value(_fI(f, 'totalCount', 0)),
              remainingCount: Value(_fI(f, 'remainingCount', 0)),
              photoPaths: Value(_fSReq(f, 'photoPaths', '[]')),
              instructions: Value(_fS(f, 'instructions')),
              phases: Value(_fS(f, 'phases')),
              trackStock: Value(_fB(f, 'trackStock', false)),
              stockUnit: Value(_fS(f, 'stockUnit')),
              iconKey: Value(_fS(f, 'iconKey')),
              color: Value(_fS(f, 'color')),
              sideEffects: Value(_fS(f, 'sideEffects')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        return name;
      case 'activity':
        final name = _fSReq(f, 'name', '');
        if (name.isEmpty) return null;
        await _db.into(_db.activities).insert(ActivitiesCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              name: name,
              type: const Value('routine'),
              durationMin: Value(_fI(f, 'durationMin', 30)),
              repeatDays: Value(_fSReq(f, 'repeatDays', '[1,2,3,4,5]')),
              reminderBeforeMin: Value(_fI(f, 'reminderBeforeMin', 10)),
              color: Value(_fS(f, 'color')),
              repeatType: Value(_fSReq(f, 'repeatType', 'weekly')),
              repeatDayOfMonth: Value(f['repeatDayOfMonth'] as int?),
              repeatIntervalDays: Value(f['repeatIntervalDays'] as int?),
              weeklyGoalCount: Value(f['weeklyGoalCount'] as int?),
              // Ротаційний пул (ActivityAssignees) не входить у цю
              // пропозицію (взагалі ще не синхронізується між пірами,
              // задокументований пробіл) — рутина від піра завжди
              // створюється як 'fixed' на самого субʼєкта.
              rotationAnchorDate: Value(now),
              rotationMode: const Value('fixed'),
              stepsJson: Value(_fS(f, 'stepsJson')),
              tags: Value(_fSReq(f, 'tags', '[]')),
              documentPaths: Value(_fSReq(f, 'documentPaths', '[]')),
              location: Value(_fS(f, 'location')),
              iconKey: Value(_fSReq(f, 'iconKey', 'task_routine')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        return name;
      case 'doctor_appointment':
        final title = _fSReq(f, 'doctorType', '');
        if (title.isEmpty) return null;
        final reminderId = await _db.into(_db.reminders).insert(RemindersCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              doctorType: title,
              tags: Value(_fSReq(f, 'tags', '[]')),
              location: Value(_fS(f, 'location')),
              scheduledAt: _fDtReq(f, 'scheduledAt', now),
              remindBeforeMin: Value(_fI(f, 'remindBeforeMin', 60)),
              notes: Value(_fS(f, 'notes')),
              documentPaths: Value(_fSReq(f, 'documentPaths', '[]')),
              color: Value(_fS(f, 'color')),
              iconKey: Value(_fSReq(f, 'iconKey', 'calendar')),
              repeatType: Value(_fSReq(f, 'repeatType', 'none')),
              repeatConfig: Value(_fSReq(f, 'repeatConfig', '{}')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        await _replaceReminderSlots(reminderId, f);
        return title;
      case 'wellbeing_schedule':
        await _db.into(_db.wellbeingSchedules).insert(WellbeingSchedulesCompanion.insert(
              memberId: memberId,
              sectionId: Value(sectionId),
              timesPerDay: Value(_fI(f, 'timesPerDay', 2)),
              times: Value(_fSReq(f, 'times', '["08:00","20:00"]')),
              isActive: Value(_fB(f, 'isActive', true)),
              color: Value(_fS(f, 'color')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        return null; // немає окремої "назви" для сповіщення — самопочуття завжди один запис на людину
      case 'medcard_entry':
        if (sectionId == null) return null;
        final title = _fSReq(f, 'title', '');
        if (title.isEmpty) return null;
        await _db.into(_db.medcardEntries).insert(MedcardEntriesCompanion.insert(
              sectionId: sectionId,
              memberId: memberId,
              title: title,
              recordDate: _fDtReq(f, 'recordDate', now),
              notes: Value(_fS(f, 'notes')),
              tags: Value(_fSReq(f, 'tags', '[]')),
              location: Value(_fS(f, 'location')),
              documentPaths: Value(_fSReq(f, 'documentPaths', '[]')),
              updatedAt: Value(now),
              syncUuid: Value(syncUuid),
            ));
        return title;
    }
    return null;
  }

  Future<String?> _updateRecordIfUnchanged(
    String entityType,
    String targetUuid,
    int memberId,
    int? sectionId,
    Map<String, dynamic> f,
    DateTime baseUpdatedAt,
  ) async {
    final now = DateTime.now();
    switch (entityType) {
      case 'medication':
        final row = await (_db.select(_db.medications)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final name = _fSReq(f, 'name', row.name);
        await (_db.update(_db.medications)..where((t) => t.id.equals(row.id))).write(MedicationsCompanion(
          sectionId: Value(sectionId),
          name: Value(name),
          form: Value(_fSReq(f, 'form', row.form)),
          doseAmount: Value(_fD(f, 'doseAmount', row.doseAmount)),
          doseUnit: Value(_fSReq(f, 'doseUnit', row.doseUnit)),
          repeatType: Value(_fSReq(f, 'repeatType', row.repeatType)),
          repeatConfig: Value(_fSReq(f, 'repeatConfig', row.repeatConfig)),
          startDate: Value(_fDtReq(f, 'startDate', row.startDate)),
          endDate: Value(_fDtN(f, 'endDate')),
          totalCount: Value(_fI(f, 'totalCount', row.totalCount)),
          remainingCount: Value(_fI(f, 'remainingCount', row.remainingCount)),
          photoPaths: Value(_fSReq(f, 'photoPaths', row.photoPaths)),
          instructions: Value(_fS(f, 'instructions') ?? row.instructions),
          phases: Value(_fS(f, 'phases') ?? row.phases),
          trackStock: Value(_fB(f, 'trackStock', row.trackStock)),
          stockUnit: Value(_fS(f, 'stockUnit') ?? row.stockUnit),
          iconKey: Value(_fS(f, 'iconKey') ?? row.iconKey),
          color: Value(_fS(f, 'color') ?? row.color),
          sideEffects: Value(_fS(f, 'sideEffects') ?? row.sideEffects),
          updatedAt: Value(now),
        ));
        return name;
      case 'activity':
        final row = await (_db.select(_db.activities)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final name = _fSReq(f, 'name', row.name);
        await (_db.update(_db.activities)..where((t) => t.id.equals(row.id))).write(ActivitiesCompanion(
          sectionId: Value(sectionId),
          name: Value(name),
          durationMin: Value(_fI(f, 'durationMin', row.durationMin)),
          repeatDays: Value(_fSReq(f, 'repeatDays', row.repeatDays)),
          reminderBeforeMin: Value(_fI(f, 'reminderBeforeMin', row.reminderBeforeMin)),
          color: Value(_fS(f, 'color') ?? row.color),
          repeatType: Value(_fSReq(f, 'repeatType', row.repeatType)),
          repeatDayOfMonth: Value(f['repeatDayOfMonth'] as int? ?? row.repeatDayOfMonth),
          repeatIntervalDays: Value(f['repeatIntervalDays'] as int? ?? row.repeatIntervalDays),
          weeklyGoalCount: Value(f['weeklyGoalCount'] as int? ?? row.weeklyGoalCount),
          stepsJson: Value(_fS(f, 'stepsJson') ?? row.stepsJson),
          tags: Value(_fSReq(f, 'tags', row.tags)),
          documentPaths: Value(_fSReq(f, 'documentPaths', row.documentPaths)),
          location: Value(_fS(f, 'location') ?? row.location),
          iconKey: Value(_fSReq(f, 'iconKey', row.iconKey)),
          updatedAt: Value(now),
        ));
        return name;
      case 'doctor_appointment':
        final row = await (_db.select(_db.reminders)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final title = _fSReq(f, 'doctorType', row.doctorType);
        await (_db.update(_db.reminders)..where((t) => t.id.equals(row.id))).write(RemindersCompanion(
          sectionId: Value(sectionId),
          doctorType: Value(title),
          tags: Value(_fSReq(f, 'tags', row.tags)),
          location: Value(_fS(f, 'location') ?? row.location),
          scheduledAt: Value(_fDtReq(f, 'scheduledAt', row.scheduledAt)),
          remindBeforeMin: Value(_fI(f, 'remindBeforeMin', row.remindBeforeMin)),
          notes: Value(_fS(f, 'notes') ?? row.notes),
          documentPaths: Value(_fSReq(f, 'documentPaths', row.documentPaths)),
          color: Value(_fS(f, 'color') ?? row.color),
          iconKey: Value(_fSReq(f, 'iconKey', row.iconKey)),
          repeatType: Value(_fSReq(f, 'repeatType', row.repeatType)),
          repeatConfig: Value(_fSReq(f, 'repeatConfig', row.repeatConfig)),
          updatedAt: Value(now),
        ));
        if (f.containsKey('slotTimes')) await _replaceReminderSlots(row.id, f);
        return title;
      case 'wellbeing_schedule':
        final row = await (_db.select(_db.wellbeingSchedules)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        await (_db.update(_db.wellbeingSchedules)..where((t) => t.id.equals(row.id))).write(
            WellbeingSchedulesCompanion(
          sectionId: Value(sectionId),
          timesPerDay: Value(_fI(f, 'timesPerDay', row.timesPerDay)),
          times: Value(_fSReq(f, 'times', row.times)),
          isActive: Value(_fB(f, 'isActive', row.isActive)),
          color: Value(_fS(f, 'color') ?? row.color),
          updatedAt: Value(now),
        ));
        return null;
      case 'medcard_entry':
        final row = await (_db.select(_db.medcardEntries)
              ..where((t) => t.syncUuid.equals(targetUuid) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final title = _fSReq(f, 'title', row.title);
        await (_db.update(_db.medcardEntries)..where((t) => t.id.equals(row.id))).write(MedcardEntriesCompanion(
          sectionId: Value(sectionId ?? row.sectionId),
          title: Value(title),
          recordDate: Value(_fDtReq(f, 'recordDate', row.recordDate)),
          notes: Value(_fS(f, 'notes') ?? row.notes),
          tags: Value(_fSReq(f, 'tags', row.tags)),
          location: Value(_fS(f, 'location') ?? row.location),
          documentPaths: Value(_fSReq(f, 'documentPaths', row.documentPaths)),
          updatedAt: Value(now),
        ));
        return title;
      case 'activity_log':
        // ⚠️ На відміну від решти типів вище, ActivityLogs.memberId — НЕ
        // subject (memberId тут може бути будь-хто з пулу ротації, зокрема
        // тіньовий пір чи сам subject) — належність до subject-а
        // перевіряємо через батьківську Activity, а не напряму.
        final row = await (_db.select(_db.activityLogs)
              ..where((t) => t.syncUuid.equals(targetUuid)))
            .getSingleOrNull();
        if (row == null || !_sameVersion(row.updatedAt, baseUpdatedAt)) return null;
        final act = await (_db.select(_db.activities)
              ..where((t) => t.id.equals(row.activityId) & t.memberId.equals(memberId)))
            .getSingleOrNull();
        if (act == null) return null;
        final identity = _fS(f, 'assigneeIdentity');
        if (identity == null) return null;
        final newAssigneeId = await _resolveAssigneeIdentity(identity);
        if (newAssigneeId == null) return null;
        await (_db.update(_db.activityLogs)..where((t) => t.id.equals(row.id))).write(
            ActivityLogsCompanion(memberId: Value(newAssigneeId), updatedAt: Value(now)));
        return act.name;
    }
    return null;
  }

  /// Крок 7.2 плану: перекладає рядок-ідентичність із пулу ротації
  /// (той самий формат, що й у push activity_assignee — 'm123' для
  /// звичайного локального члена, або personUuid для тіньового піра) назад
  /// у локальний Members.id на боці субʼєкта.
  Future<int?> _resolveAssigneeIdentity(String identity) async {
    if (identity.startsWith('m')) {
      final id = int.tryParse(identity.substring(1));
      if (id != null) return id;
    }
    final row = await (_db.select(_db.members)
          ..where((t) => t.linkedPeerPersonUuid.equals(identity)))
        .getSingleOrNull();
    return row?.id;
  }

  // Reminders daily/weekly (кілька разів на день) бере час(и) з окремої
  // дочірньої таблиці ReminderSlots, не з самого запису — без цього рядок
  // record_proposal лишав би такий peer-нагадування зовсім без часу
  // спрацювання. 'slotTimes' — необов'язкове поле fields-мапи, json-масив
  // "HH:mm"; відсутнє в мапі (проти порожнього списку) — не чіпаємо наявні
  // слоти зовсім (edit міг стосуватись лише інших полів).
  Future<void> _replaceReminderSlots(int reminderId, Map<String, dynamic> f) async {
    final raw = f['slotTimes'] as String?;
    if (raw == null) return;
    List<String> times;
    try {
      times = List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return;
    }
    await (_db.delete(_db.reminderSlots)..where((t) => t.reminderId.equals(reminderId))).go();
    for (var i = 0; i < times.length; i++) {
      await _db.into(_db.reminderSlots).insert(ReminderSlotsCompanion.insert(
            reminderId: reminderId,
            timeOfDay: times[i],
            sortOrder: Value(i),
            syncUuid: Value(_uuid.v4()),
          ));
    }
  }

  // Реальний баг (06.08, знайдено через діагностичні логи): channel_state на
  // сервері — ОДИН рядок на канал (REPLACE, не черга). _syncPeer() викликає
  // _ping() НАПРИКІНЦІ кожного раунду синку для ВЖЕ підтвердженого локально
  // піра — але щойно прийняте запрошення (acceptInvite()) створює FamilyPeers
  // запис МИТТЄВО й АСИМЕТРИЧНО лише на боці того, хто приєднався: той самий
  // channelId, яким щойно пішла картка знайомства (_sendMyCard), для
  // адміністратора все ще лише "очікує на відповідь" (PendingGroupInvites),
  // поки він сам не встигне її прочитати через refreshPeers(). Якщо
  // запрошений відкриє застосунок ще раз до того — його ж _ping() перезаписує
  // channel_state порожнім {'t': ...}, назавжди стираючи непрочитану картку
  // (introductionSent вже true, повторної відправки більше не буде —
  // постійний глухий кут). Рішення: коли викликач знає familyId цього
  // конкретного зв'язку (лише _syncPeer — там пір уже є), пінг несе ту саму
  // картку ідентичності, що й _sendMyCard, а не порожній таймстамп — тоді
  // навіть перезапис ніколи не губить корисні дані.
  Future<void> _ping(String channelId, SecretKey key, {String? identityFamilyId}) async {
    try {
      final token = await PushTokenService.getToken();
      if (token == null) return;
      Map<String, dynamic> payload = {'t': DateTime.now().toIso8601String()};
      if (identityFamilyId != null) {
        final owner =
            await (_db.select(_db.members)..where((t) => t.role.equals('owner'))).getSingleOrNull();
        if (owner != null) {
          payload = {
            'v': 3,
            'familyId': identityFamilyId,
            'personUuid': owner.personUuid,
            'name': owner.name,
            'avatarIndex': owner.avatarIndex,
          };
        }
      }
      final ping = await SyncCryptoService.encryptEntity(key, payload);
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

  // Повертає true, якщо цей пір щойно сигналізував 'peer_left' (сам вийшов
  // із сім'ї чи був виключений) — викликач (_syncPeer) має симетрично
  // прибрати його й на цьому пристрої, а не продовжувати синк як зазвичай.
  Future<bool> _pull(FamilyPeer peer, SecretKey key) async {
    final result = await _api.pull(channelId: peer.channelId, since: peer.lastSyncedAt);
    final repo = FamilyPeersRepository(_db);
    var peerLeft = false;

    // Тимчасове діагностичне логування — одне зведення на раунд синку (не
    // на кожну сутність), щоб бачити, що САМЕ прилетіло цим каналом: чи
    // взагалі дійшли grants_summary/peer_removed/kicked_from_family/
    // introduction тощо, перш ніж копатись у кожному обробнику окремо.
    if (result.entities.isNotEmpty) {
      AppLogger.log(
          'FamilyPeerSyncService._pull: channelId=${peer.channelId} personUuid=${peer.personUuid} got ${result.entities.length} entities: ${result.entities.map((e) => "${e.type}${e.deleted ? "(tombstone)" : ""}").join(", ")}');
    }

    for (final entity in result.entities) {
      if (entity.type == 'peer_left') {
        if (!entity.deleted) peerLeft = true;
        continue;
      }
      if (entity.type == 'edit_proposal') {
        if (entity.deleted) continue; // tombstone для edit_proposal не буває
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _applyEditProposal(json, peer);
        continue;
      }
      if (entity.type == 'record_proposal') {
        if (entity.deleted) continue; // tombstone для record_proposal не буває
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _applyRecordProposal(json, peer);
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
          viewSchedule: json['viewSchedule'] as bool? ?? false,
          editSchedule: json['editSchedule'] as bool? ?? false,
          viewMedcard: json['viewMedcard'] as bool? ?? false,
          editMedcard: json['editMedcard'] as bool? ?? false,
          viewShelves: json['viewShelves'] as bool? ?? false,
          editShelves: json['editShelves'] as bool? ?? false,
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
      if (entity.type == 'peer_removed') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handlePeerRemoved(json, peer);
        continue;
      }
      if (entity.type == 'kicked_from_family') {
        if (entity.deleted) continue;
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _handleKickedFromFamily(json, peer);
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
    return peerLeft;
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

    for (final a in await _db.select(_db.reminders).get()) {
      if (_documentPathsContain(a.documentPaths, photoPath) && await memberAllowed(a.memberId)) return true;
    }
    for (final e in await _db.select(_db.medcardEntries).get()) {
      if (_documentPathsContain(e.documentPaths, photoPath) && await memberAllowed(e.memberId)) return true;
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

  /// Викликати ЛИШЕ адміністратором (платящим-хабом) цієї сімейної групи —
  /// на відміну від [removePeer] (виключно локальна дія "я більше не бачу
  /// цю людину", доступна будь-кому про будь-кого), тут виключення
  /// поширюється на ВСІХ інших учасників тієї самої familyId: кожному з них
  /// (тим самим каналом, яким я їх звів при автопредставленні) летить
  /// сигнал прибрати цю людину і в себе, а не лише в мене локально.
  Future<void> kickPeer(String personUuid) async {
    final repo = FamilyPeersRepository(_db);
    final target = await repo.getByUuid(personUuid);
    if (target == null) {
      AppLogger.log('FamilyPeerSyncService.kickPeer: target not found personUuid=$personUuid');
      return;
    }
    final siblings = (await repo.allPeers())
        .where((p) => p.familyId == target.familyId && p.personUuid != personUuid)
        .toList();
    AppLogger.log(
        'FamilyPeerSyncService.kickPeer: kicking personUuid=$personUuid familyId=${target.familyId}, notifying ${siblings.length} sibling(s)');
    for (final sibling in siblings) {
      await _sendCard(
        toChannelId: sibling.channelId,
        type: 'peer_removed',
        uuid: _stableUuid('peer_removed_$personUuid'),
        json: {'removedPersonUuid': personUuid},
      );
      final keyBytes = await SharedChannelKeyStorage.read(sibling.channelId);
      if (keyBytes != null) await _ping(sibling.channelId, SecretKey(keyBytes));
    }
    // Самому Х недостатньо знати лише "адміна більше немає" (звичайний
    // 'peer_left' нижче, в removePeer) — його пристрій усе одно лишився б
    // із застарілими попарними зв'язками з рештою сім'ї (ті самі канали, що
    // й ті сиблінги вище отримали тим самим автопредставленням). Явно
    // кажемо Х прибрати ВСІХ учасників familyId, не лише мене.
    final targetKeyBytes = await SharedChannelKeyStorage.read(target.channelId);
    if (targetKeyBytes != null) {
      await _sendCard(
        toChannelId: target.channelId,
        type: 'kicked_from_family',
        uuid: _stableUuid('kicked_from_family_${target.familyId}'),
        json: {'familyId': target.familyId},
      );
      await _ping(target.channelId, SecretKey(targetKeyBytes));
    }
    await removePeer(personUuid);
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
      final key = SecretKey(keyBytes);
      await _tombstoneEverythingFor(peer, key);
      // Крок 3.4 плану: без явного сигналу інша сторона цього зв'язку ніколи
      // не дізнається, що я пішов/мене виключили — її власний рядок
      // FamilyPeers для мене просто лишався б висіти назавжди зі старими
      // даними (tombstone-и вище стирають лише МОЇ раніше поділені сутності,
      // не сам факт зв'язку). 'peer_left' — сигнал "прибери мене як піра
      // теж", оброблюється симетрично на прийомі нижче в _pull.
      try {
        await _api.push(channelId: peer.channelId, entities: [
          {
            'type': 'peer_left',
            'uuid': _stableUuid('peer_left'),
            'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, {})),
          }
        ]);
      } catch (_) {
        // Best-effort — той самий компроміс, що й tombstone-и вище.
      }
    }
    await SharedChannelKeyStorage.delete(peer.channelId);
    await repo.delete(personUuid);
    // Кеш SharedEntities раніше чистився лише на холодному старті
    // (clearSharedCache) — до наступного перезапуску вихід/виключення з
    // сім'ї чи відкликаний доступ лишали чужі дані видимими в тій самій
    // сесії. Прибираємо явно тут же, разом із SharedSubjects.
    await repo.deleteSharedEntitiesForSubjects(subjects.map((s) => s.personUuid).toList());
    await repo.deleteSharedSubjectsForChannel(peer.channelId);
    // Реальний баг (05.08): без цього старі дозволи (FamilyGrants) і
    // прапорець "поп-ап уже показано" (FamilyJoinPopupService) переживали
    // видалення піра — при повторному приєднанні тієї самої людини (той
    // самий personUuid) поп-ап "налаштувати видимість" більше не з'являвся,
    // а щойно приєднаному могли тихо лишитись старі права доступу, ніколи
    // явно не надані заново. Обидва напрями (я комусь дозволяв / хтось мені)
    // прибираються тут — цей рядок в FamilyGrants виникає лише на пристрої,
    // що керує subject'ом, тож symmetric-виклик з боку іншої людини (коли
    // вона отримає peer_left і сама викличе removePeer) прибере свою половину.
    await (_db.delete(_db.familyGrants)
          ..where((t) => t.viewerPersonUuid.equals(personUuid) | t.subjectPersonUuid.equals(personUuid)))
        .go();
    await FamilyJoinPopupService.clearShownFor(personUuid);
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

  // Спільна точка відправки для автопредставлення (Фаза 5) І для
  // kickPeer()'s peer_removed/kicked_from_family — тому логування тут одразу
  // покриває всі ці типи повідомлень, а не лише один.
  Future<void> _sendCard({
    required String toChannelId,
    required String type,
    required String uuid,
    required Map<String, dynamic> json,
  }) async {
    final keyBytes = await SharedChannelKeyStorage.read(toChannelId);
    if (keyBytes == null) {
      AppLogger.log('FamilyPeerSyncService._sendCard: SKIP (no local sync key) type=$type toChannelId=$toChannelId');
      return;
    }
    final key = SecretKey(keyBytes);
    final entity = {
      'type': type,
      'uuid': uuid,
      'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
    };
    try {
      await _api.push(channelId: toChannelId, entities: [entity]);
      AppLogger.log('FamilyPeerSyncService._sendCard: sent OK type=$type toChannelId=$toChannelId');
    } catch (e, st) {
      // Best-effort, той самий компроміс, що й для proposeEdit/photo_request —
      // без черги повторних спроб. Пропущене знайомство не критичне: людина
      // просто не побачить цього учасника у списку "Видимість", поки не
      // станеться інший привід для синку (напр. ще один новий учасник).
      AppLogger.logError('FamilyPeerSyncService._sendCard(type=$type, toChannelId=$toChannelId)', e, st);
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
        uuid: _stableUuid('known_member_${newPeer.personUuid}'),
        json: cardOf(newPeer),
      );
      await _sendCard(
        toChannelId: newPeer.channelId,
        type: 'known_member',
        uuid: _stableUuid('known_member_${existing.personUuid}'),
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
      uuid: _stableUuid('introduction_${target.personUuid}'),
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
      uuid: _stableUuid('introduction_${fromPeer.personUuid}'),
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

  /// Прийшло від МОГО прямого адміністратора (invitedMe==true) цієї сім'ї —
  /// він виключив когось із групи через [kickPeer], прибираю цю людину і в
  /// себе. Довіряю сигналу лише з каналу самого адміністратора — інакше
  /// звичайний співучасник міг би підробити чуже виключення через наш
  /// спільний (брокерений) канал.
  Future<void> _handlePeerRemoved(Map<String, dynamic> json, FamilyPeer fromPeer) async {
    if (!fromPeer.invitedMe) {
      AppLogger.log(
          'FamilyPeerSyncService._handlePeerRemoved: IGNORED (sender is not my admin, invitedMe=false) fromPersonUuid=${fromPeer.personUuid}');
      return;
    }
    final removedUuid = json['removedPersonUuid'] as String?;
    if (removedUuid == null || removedUuid == fromPeer.personUuid) return;
    final target = await FamilyPeersRepository(_db).getByUuid(removedUuid);
    if (target == null || target.familyId != fromPeer.familyId) {
      AppLogger.log(
          'FamilyPeerSyncService._handlePeerRemoved: SKIP (target unknown or familyId mismatch) removedUuid=$removedUuid');
      return;
    }
    AppLogger.log('FamilyPeerSyncService._handlePeerRemoved: removing personUuid=$removedUuid on admin instruction');
    await removePeer(removedUuid);
  }

  /// Прийшло від МОГО прямого адміністратора (invitedMe==true) — він
  /// виключив мене з УСІЄЇ сімейної групи (не просто розірвав зв'язок зі
  /// мною особисто через [kickPeer]): прибираю кожного учасника цього
  /// familyId зі свого списку, включно з самим адміном, а не чекаю на
  /// окремий 'peer_left' по кожному з них. Той самий захист від підробки
  /// (лише від справжнього invitedMe-адміна), що й у [_handlePeerRemoved].
  Future<void> _handleKickedFromFamily(Map<String, dynamic> json, FamilyPeer fromPeer) async {
    if (!fromPeer.invitedMe) {
      AppLogger.log(
          'FamilyPeerSyncService._handleKickedFromFamily: IGNORED (sender is not my admin, invitedMe=false) fromPersonUuid=${fromPeer.personUuid}');
      return;
    }
    final familyId = json['familyId'] as String?;
    if (familyId == null || familyId != fromPeer.familyId) return;
    final toRemove = (await FamilyPeersRepository(_db).allPeers())
        .where((p) => p.familyId == familyId)
        .toList();
    AppLogger.log(
        'FamilyPeerSyncService._handleKickedFromFamily: removing ${toRemove.length} peer(s) from familyId=$familyId');
    for (final p in toRemove) {
      await removePeer(p.personUuid);
    }
  }
}
