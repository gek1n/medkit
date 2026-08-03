import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import 'family_sync_api_client.dart';
import 'family_sync_delete_queue.dart';
import 'family_visibility_service.dart';
import 'file_encryption_service.dart';
import 'photo_service.dart';
import 'push_token_service.dart';
import 'relay_api_client.dart';
import 'shared_channel_key_storage.dart';
import 'sync_crypto_service.dart';

/// Оркеструє бідирекційну синхронізацію одного профілю сім'ї (family_sync)
/// між двома РІЗНИМИ пристроями після пейрингу — на відміну від
/// `SyncService` (account-sync), де один акаунт відновлює СВОЇ Ж дані на
/// новому телефоні. Тому тут: ідентифікатор рядка — `syncUuid` (не local
/// autoincrement id, бо обидва пристрої живі одночасно), а область
/// видимості — `channelId` (з таблиці `SharedChannels`), не `accountId`.
///
/// Дочірні сутності (`Schedules`/`Intakes`/`Symptoms`) несуть у зашифрованому
/// JSON `medicationSyncUuid`/`scheduleSyncUuid` замість сирих локальних FK —
/// на прийомі це резолвиться в ЛОКАЛЬНИЙ id через пошук за syncUuid. Це
/// гарантовано безпечно, бо на push-стороні дочірня сутність ніколи не
/// відправляється, поки в батьківської немає syncUuid (тобто вона вже була
/// відправлена цього ж або попереднього разу) — а обробка одного pull-
/// відповіді завжди йде в порядку medication → schedule/intake/symptom.
class FamilySyncService {
  static const _uuid = Uuid();

  final AppDatabase _db;
  final FamilySyncApiClient _api = const FamilySyncApiClient();
  final RelayApiClient _relayApi = const RelayApiClient();

  FamilySyncService(this._db);

  Future<void> syncAll() async {
    final channels = await _db.select(_db.sharedChannels).get();
    for (final channel in channels) {
      try {
        await _syncChannel(channel);
      } catch (_) {
        // Локальні дані лишаються джерелом правди — просто спробуємо ще раз
        // при наступному тригері (mutation/resume/FCM-пробудження).
      }
    }
  }

  Future<void> syncChannelForMember(int memberId) async {
    final channel = await (_db.select(_db.sharedChannels)..where((t) => t.memberId.equals(memberId)))
        .getSingleOrNull();
    if (channel == null) return;
    try {
      await _syncChannel(channel);
    } catch (_) {
      // Див. коментар у syncAll().
    }
  }

  /// Викликати ДО `MembersRepository.delete(memberId)` — коли профіль
  /// прив'язаний до family_sync-каналу (пейринг з іншим пристроєм тієї ж
  /// людини), інший пристрій сам ніколи не дізнається про видалення, якщо не
  /// надіслати tombstone на кожну його сутність. Локальний каскад (FK
  /// `onDelete: cascade`) видаляє рядки одразу після цього виклику, тому
  /// syncUuid-и потрібно зібрати саме тут, поки рядки ще існують.
  Future<void> deleteMemberEverywhere(int memberId) async {
    final channel = await (_db.select(_db.sharedChannels)..where((t) => t.memberId.equals(memberId)))
        .getSingleOrNull();
    if (channel == null) return; // немає прив'язки — нема кому повідомляти на сервері

    await _assignMissingMedicationUuids(memberId);
    await _assignMissingScheduleUuids(memberId);
    await _assignMissingIntakeUuids(memberId);
    await _assignMissingSymptomUuids(memberId);
    await _assignMissingAppointmentUuids(memberId);
    await _assignMissingActivityUuids(memberId);
    await _assignMissingActivitySlotUuids(memberId);
    await _assignMissingActivityLogUuids(memberId);
    await _assignMissingWellbeingLogUuids(memberId);
    await _assignMissingWellbeingScheduleUuids(memberId);
    await _assignMissingMedcardSectionUuids(memberId);
    await _assignMissingMedcardEntryUuids(memberId);
    await _assignMissingReminderLogUuids(memberId);

    final medications = await (_db.select(_db.medications)..where((t) => t.memberId.equals(memberId))).get();
    for (final m in medications) {
      if (m.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'medication', syncUuid: m.syncUuid!);
      }
    }

    final scheduleRows = await (_db.select(_db.schedules).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
    ])
          ..where(_db.medications.memberId.equals(memberId)))
        .get();
    for (final r in scheduleRows) {
      final s = r.readTable(_db.schedules);
      if (s.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'schedule', syncUuid: s.syncUuid!);
      }
    }

    final intakes = await (_db.select(_db.intakes)..where((t) => t.memberId.equals(memberId))).get();
    for (final i in intakes) {
      if (i.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'intake', syncUuid: i.syncUuid!);
      }
    }

    final symptomRows = await (_db.select(_db.symptoms).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.symptoms.medicationId)),
    ])
          ..where(_db.medications.memberId.equals(memberId)))
        .get();
    for (final r in symptomRows) {
      final s = r.readTable(_db.symptoms);
      if (s.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'symptom', syncUuid: s.syncUuid!);
      }
    }

    final appointments =
        await (_db.select(_db.reminders)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in appointments) {
      if (a.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'doctor_appointment', syncUuid: a.syncUuid!);
      }
    }

    final activityRows = await (_db.select(_db.activities)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in activityRows) {
      if (a.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'activity', syncUuid: a.syncUuid!);
      }
    }

    final activitySlotRows = await (_db.select(_db.activitySlots).join([
      innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
    ])
          ..where(_db.activities.memberId.equals(memberId)))
        .get();
    for (final r in activitySlotRows) {
      final s = r.readTable(_db.activitySlots);
      if (s.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'activity_slot', syncUuid: s.syncUuid!);
      }
    }

    final activityLogRows = await (_db.select(_db.activityLogs)..where((t) => t.memberId.equals(memberId))).get();
    for (final l in activityLogRows) {
      if (l.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'activity_log', syncUuid: l.syncUuid!);
      }
    }

    final wellbeingLogRows = await (_db.select(_db.wellbeingLogs)..where((t) => t.memberId.equals(memberId))).get();
    for (final l in wellbeingLogRows) {
      if (l.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(channelId: channel.channelId, entityType: 'wellbeing_log', syncUuid: l.syncUuid!);
      }
    }

    final wellbeingScheduleRows =
        await (_db.select(_db.wellbeingSchedules)..where((t) => t.memberId.equals(memberId))).get();
    for (final s in wellbeingScheduleRows) {
      if (s.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'wellbeing_schedule', syncUuid: s.syncUuid!);
      }
    }

    final medcardSectionRows =
        await (_db.select(_db.medcardSections)..where((t) => t.memberId.equals(memberId))).get();
    for (final s in medcardSectionRows) {
      if (s.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'medcard_section', syncUuid: s.syncUuid!);
      }
    }

    final medcardEntryRows =
        await (_db.select(_db.medcardEntries)..where((t) => t.memberId.equals(memberId))).get();
    for (final e in medcardEntryRows) {
      if (e.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'medcard_entry', syncUuid: e.syncUuid!);
      }
    }

    final reminderLogRows =
        await (_db.select(_db.reminderLogs)..where((t) => t.memberId.equals(memberId))).get();
    for (final l in reminderLogRows) {
      if (l.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'reminder_log', syncUuid: l.syncUuid!);
      }
    }

    try {
      await _syncChannel(channel);
    } catch (_) {
      // Найкращий можливий варіант без мережі — tombstone-и лишаються в черзі,
      // але канал буде видалений каскадом разом з member нижче, тож наступного
      // разу їх вже нікому буде відправити. Прийнятний компроміс: локальне
      // видалення не можна блокувати відсутністю мережі.
    }
  }

  Future<void> _syncChannel(SharedChannel channel) async {
    final keyBytes = await SharedChannelKeyStorage.read(channel.channelId);
    if (keyBytes == null) return; // канал без ключа — не мали б трапитись, ігноруємо безпечно
    final key = SecretKey(keyBytes);

    final pushed = await _push(channel, key);
    await _pull(channel, key);
    await (_db.update(_db.sharedChannels)..where((t) => t.channelId.equals(channel.channelId)))
        .write(SharedChannelsCompanion(lastSyncedAt: Value(DateTime.now())));

    if (pushed) {
      await _pingOtherDevice(channel.channelId, key);
    }
  }

  // ── Push ──────────────────────────────────────────────────────────────────

  /// Повертає true, якщо було реально щось відправлено (є сенс "будити"
  /// інший пристрій).
  Future<bool> _push(SharedChannel channel, SecretKey key) async {
    final since = channel.lastSyncedAt;
    final memberId = channel.memberId;
    final entities = <Map<String, dynamic>>[];
    final subjectMember = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingleOrNull();
    final medcardSyncAllowed = subjectMember?.personUuid == null
        ? true
        : await FamilyVisibilityService.isMedcardSyncAllowed(subjectMember!.personUuid!);

    // Крок 5-6 плану: Полички тепер синхронізуються (нижче), тож перш ніж
    // резолвити sectionSyncUuid для медикаментів/рутин/нагадувань/самопочуття,
    // усі наявні розділи мають вже отримати свій syncUuid.
    await _assignMissingMedcardSectionUuids(memberId);

    for (final m in await _medicationsForPush(memberId, since)) {
      // sectionId — Крок 5-6: Полички тепер синхронізуються (вище), тож
      // передаємо прив'язку до розділу через його syncUuid — так само, як
      // medicationSyncUuid для розкладу. null, якщо розділ не обрано.
      final json = m.toJson()..remove('id')..remove('memberId')..remove('sectionId');
      json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(m.sectionId);
      entities.add({
        'type': 'medication',
        'uuid': m.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }

    for (final s in await _schedulesForPush(memberId, since)) {
      final medUuid = await _medicationSyncUuidFor(s.medicationId);
      if (medUuid == null) continue; // медикамент ще не отримав syncUuid — почекаємо наступного разу
      final json = s.toJson()..remove('id')..remove('medicationId');
      json['medicationSyncUuid'] = medUuid;
      entities.add({
        'type': 'schedule',
        'uuid': s.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }

    for (final i in await _intakesForPush(memberId, since)) {
      final medUuid = await _medicationSyncUuidFor(i.medicationId);
      final schedUuid = await _scheduleSyncUuidFor(i.scheduleId);
      if (medUuid == null || schedUuid == null) continue;
      final json = i.toJson()..remove('id')..remove('medicationId')..remove('memberId')..remove('scheduleId');
      json['medicationSyncUuid'] = medUuid;
      json['scheduleSyncUuid'] = schedUuid;
      entities.add({
        'type': 'intake',
        'uuid': i.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }

    for (final s in await _symptomsForPush(memberId, since)) {
      final medUuid = await _medicationSyncUuidFor(s.medicationId);
      if (medUuid == null) continue;
      final json = s.toJson()..remove('id')..remove('medicationId');
      json['medicationSyncUuid'] = medUuid;
      entities.add({
        'type': 'symptom',
        'uuid': s.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }

    // Активності — завжди синхронізуються, той самий пріоритет, що й ліки:
    // саме "виконав/пропустив активність" — ключова причина, чому за
    // автономним профілем взагалі наглядають.
    for (final a in await _activitiesForPush(memberId, since)) {
      // sectionId — див. коментар у блоці medication вище.
      final json = a.toJson()..remove('id')..remove('memberId')..remove('sectionId');
      json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(a.sectionId);
      entities.add({
        'type': 'activity',
        'uuid': a.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }
    for (final s in await _activitySlotsForPush(memberId, since)) {
      final actUuid = await _activitySyncUuidFor(s.activityId);
      if (actUuid == null) continue;
      final json = s.toJson()..remove('id')..remove('activityId');
      json['activitySyncUuid'] = actUuid;
      entities.add({
        'type': 'activity_slot',
        'uuid': s.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }
    for (final l in await _activityLogsForPush(memberId, since)) {
      final actUuid = await _activitySyncUuidFor(l.activityId);
      if (actUuid == null) continue;
      final json = l.toJson()..remove('id')..remove('activityId')..remove('memberId');
      json['activitySyncUuid'] = actUuid;
      entities.add({
        'type': 'activity_log',
        'uuid': l.syncUuid,
        'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
      });
    }

    // Самопочуття — настрій/симптоми ближчі до медкартки, ніж до
    // виконання завдань, тож підпорядковані тому самому прапорцю нижче.
    if (medcardSyncAllowed) {
      for (final l in await _wellbeingLogsForPush(memberId, since)) {
        final json = l.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'wellbeing_log',
          'uuid': l.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final s in await _wellbeingSchedulesForPush(memberId, since)) {
        // sectionId — див. коментар у блоці medication вище.
        final json = s.toJson()..remove('id')..remove('memberId')..remove('sectionId');
        json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(s.sectionId);
        entities.add({
          'type': 'wellbeing_schedule',
          'uuid': s.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
    }

    // Медкартка — плоскі, прив'язані напряму до memberId (без дочірніх
    // uuid, на відміну від schedule/intake/symptom), тому пушаться так само
    // просто, як і medication. Керується окремим прапорцем
    // FamilyVisibilityService.isMedcardSyncAllowed — на відміну від ліків і
    // розкладу, які завжди синхронізуються, дані медкартки можна повністю
    // виключити з передачі на інші пристрої.
    if (medcardSyncAllowed) {
      for (final a in await _appointmentsForPush(memberId, since)) {
        // sectionId — див. коментар у блоці medication вище.
        final json = a.toJson()..remove('id')..remove('memberId')..remove('sectionId');
        json['sectionSyncUuid'] = await _sectionSyncUuidOrNull(a.sectionId);
        entities.add({
          'type': 'doctor_appointment',
          'uuid': a.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      // Позначки "виконано/пропущено" по кожному конкретному разу
      // повторюваного нагадування — Крок 5-6 плану, раніше взагалі не
      // синхронізувались, тож автономний член сім'ї бачив на Сьогодні
      // повторювані нагадування завжди "як нові".
      for (final l in await _reminderLogsForPush(memberId, since)) {
        final reminderUuid = await _reminderSyncUuidFor(l.reminderId);
        if (reminderUuid == null) continue; // нагадування ще не отримало syncUuid — почекаємо наступного разу
        final json = l.toJson()..remove('id')..remove('reminderId')..remove('memberId');
        json['reminderSyncUuid'] = reminderUuid;
        entities.add({
          'type': 'reminder_log',
          'uuid': l.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
    }

    // Полички — Крок 5-6 плану: власні розділи архіву й записи в них раніше
    // взагалі не синхронізувались між пристроями одного профілю. Розділ —
    // плоска сутність (як medication), запис усередині нього — дочірня (як
    // schedule), тож несе не сирий sectionId, а syncUuid розділу.
    if (medcardSyncAllowed) {
      for (final s in await _medcardSectionsForPush(memberId, since)) {
        final json = s.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'medcard_section',
          'uuid': s.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final e in await _medcardEntriesForPush(memberId, since)) {
        final sectionUuid = await _medcardSectionSyncUuidFor(e.sectionId);
        if (sectionUuid == null) continue; // розділ ще не отримав syncUuid — почекаємо наступного разу
        final json = e.toJson()..remove('id')..remove('memberId')..remove('sectionId');
        json['sectionSyncUuid'] = sectionUuid;
        entities.add({
          'type': 'medcard_entry',
          'uuid': e.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
    }

    final tombstones = await FamilySyncDeleteQueue.pendingForChannel(channel.channelId);
    for (final t in tombstones) {
      entities.add({'type': t['entityType'], 'uuid': t['syncUuid'], 'ciphertext': '', 'deleted': true});
    }

    final photos = await _photosForPush(channel, medcardSyncAllowed, key);

    if (entities.isEmpty && photos.isEmpty) return false;

    for (var i = 0; i < entities.length; i += 500) {
      final chunk = entities.sublist(i, i + 500 > entities.length ? entities.length : i + 500);
      await _api.push(channelId: channel.channelId, entities: chunk);
    }
    for (var i = 0; i < photos.length; i += 100) {
      final chunk = photos.sublist(i, i + 100 > photos.length ? photos.length : i + 100);
      await _api.push(channelId: channel.channelId, photos: chunk);
    }

    for (final t in tombstones) {
      await FamilySyncDeleteQueue.clear(
        channelId: channel.channelId,
        entityType: t['entityType']!,
        syncUuid: t['syncUuid']!,
      );
    }

    return true;
  }

  Future<void> _assignMissingMedicationUuids(int memberId) async {
    final rows = await (_db.select(_db.medications)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final m in rows) {
      await (_db.update(_db.medications)..where((t) => t.id.equals(m.id))).write(
        MedicationsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Medication>> _medicationsForPush(int memberId, DateTime? since) async {
    await _assignMissingMedicationUuids(memberId);
    final query = _db.select(_db.medications)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingScheduleUuids(int memberId) async {
    final query = _db.select(_db.schedules).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
    ])
      ..where(_db.medications.memberId.equals(memberId) & _db.schedules.syncUuid.isNull());
    final rows = await query.get();
    for (final r in rows) {
      final schedule = r.readTable(_db.schedules);
      await (_db.update(_db.schedules)..where((t) => t.id.equals(schedule.id))).write(
        SchedulesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Schedule>> _schedulesForPush(int memberId, DateTime? since) async {
    await _assignMissingScheduleUuids(memberId);
    final query = _db.select(_db.schedules).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.schedules.medicationId)),
    ])
      ..where(_db.medications.memberId.equals(memberId));
    if (since != null) query.where(_db.schedules.updatedAt.isBiggerThanValue(since));
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.schedules)).toList();
  }

  Future<void> _assignMissingIntakeUuids(int memberId) async {
    final rows = await (_db.select(_db.intakes)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final i in rows) {
      await (_db.update(_db.intakes)..where((t) => t.id.equals(i.id))).write(
        IntakesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Intake>> _intakesForPush(int memberId, DateTime? since) async {
    await _assignMissingIntakeUuids(memberId);
    final query = _db.select(_db.intakes)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingSymptomUuids(int memberId) async {
    final query = _db.select(_db.symptoms).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.symptoms.medicationId)),
    ])
      ..where(_db.medications.memberId.equals(memberId) & _db.symptoms.syncUuid.isNull());
    final rows = await query.get();
    for (final r in rows) {
      final symptom = r.readTable(_db.symptoms);
      await (_db.update(_db.symptoms)..where((t) => t.id.equals(symptom.id))).write(
        SymptomsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Symptom>> _symptomsForPush(int memberId, DateTime? since) async {
    await _assignMissingSymptomUuids(memberId);
    final query = _db.select(_db.symptoms).join([
      innerJoin(_db.medications, _db.medications.id.equalsExp(_db.symptoms.medicationId)),
    ])
      ..where(_db.medications.memberId.equals(memberId));
    if (since != null) query.where(_db.symptoms.updatedAt.isBiggerThanValue(since));
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.symptoms)).toList();
  }

  // ── Активності ────────────────────────────────────────────────────────

  Future<void> _assignMissingActivityUuids(int memberId) async {
    final rows = await (_db.select(_db.activities)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final a in rows) {
      await (_db.update(_db.activities)..where((t) => t.id.equals(a.id))).write(
        ActivitiesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Activity>> _activitiesForPush(int memberId, DateTime? since) async {
    await _assignMissingActivityUuids(memberId);
    final query = _db.select(_db.activities)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingActivitySlotUuids(int memberId) async {
    final query = _db.select(_db.activitySlots).join([
      innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
    ])
      ..where(_db.activities.memberId.equals(memberId) & _db.activitySlots.syncUuid.isNull());
    final rows = await query.get();
    for (final r in rows) {
      final slot = r.readTable(_db.activitySlots);
      await (_db.update(_db.activitySlots)..where((t) => t.id.equals(slot.id))).write(
        ActivitySlotsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<ActivitySlot>> _activitySlotsForPush(int memberId, DateTime? since) async {
    await _assignMissingActivitySlotUuids(memberId);
    final query = _db.select(_db.activitySlots).join([
      innerJoin(_db.activities, _db.activities.id.equalsExp(_db.activitySlots.activityId)),
    ])
      ..where(_db.activities.memberId.equals(memberId));
    if (since != null) query.where(_db.activitySlots.updatedAt.isBiggerThanValue(since));
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.activitySlots)).toList();
  }

  Future<void> _assignMissingActivityLogUuids(int memberId) async {
    final rows = await (_db.select(_db.activityLogs)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final l in rows) {
      await (_db.update(_db.activityLogs)..where((t) => t.id.equals(l.id))).write(
        ActivityLogsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<ActivityLog>> _activityLogsForPush(int memberId, DateTime? since) async {
    await _assignMissingActivityLogUuids(memberId);
    final query = _db.select(_db.activityLogs)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<String?> _activitySyncUuidFor(int activityId) async {
    final row = await (_db.select(_db.activities)..where((t) => t.id.equals(activityId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<int?> _localActivityIdForUuid(String syncUuid) async {
    final row = await (_db.select(_db.activities)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
    return row?.id;
  }

  // ── Самопочуття ───────────────────────────────────────────────────────

  Future<void> _assignMissingWellbeingLogUuids(int memberId) async {
    final rows = await (_db.select(_db.wellbeingLogs)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final l in rows) {
      await (_db.update(_db.wellbeingLogs)..where((t) => t.id.equals(l.id))).write(
        WellbeingLogsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<WellbeingLog>> _wellbeingLogsForPush(int memberId, DateTime? since) async {
    await _assignMissingWellbeingLogUuids(memberId);
    final query = _db.select(_db.wellbeingLogs)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingWellbeingScheduleUuids(int memberId) async {
    final rows = await (_db.select(_db.wellbeingSchedules)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final s in rows) {
      await (_db.update(_db.wellbeingSchedules)..where((t) => t.id.equals(s.id))).write(
        WellbeingSchedulesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<WellbeingSchedule>> _wellbeingSchedulesForPush(int memberId, DateTime? since) async {
    await _assignMissingWellbeingScheduleUuids(memberId);
    final query = _db.select(_db.wellbeingSchedules)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  // ── Медкартка (плоскі сутності, memberId напряму) ────────────────────────

  Future<void> _assignMissingAppointmentUuids(int memberId) async {
    final rows = await (_db.select(_db.reminders)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final a in rows) {
      await (_db.update(_db.reminders)..where((t) => t.id.equals(a.id))).write(
        RemindersCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Reminder>> _appointmentsForPush(int memberId, DateTime? since) async {
    await _assignMissingAppointmentUuids(memberId);
    final query = _db.select(_db.reminders)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingReminderLogUuids(int memberId) async {
    final rows = await (_db.select(_db.reminderLogs)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final l in rows) {
      await (_db.update(_db.reminderLogs)..where((t) => t.id.equals(l.id))).write(
        ReminderLogsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<ReminderLog>> _reminderLogsForPush(int memberId, DateTime? since) async {
    await _assignMissingReminderLogUuids(memberId);
    final query = _db.select(_db.reminderLogs)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<String?> _reminderSyncUuidFor(int reminderId) async {
    final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(reminderId))).getSingleOrNull();
    return row?.syncUuid;
  }

  // ── Полички (розділи архіву + записи в них) ──────────────────────────────

  Future<void> _assignMissingMedcardSectionUuids(int memberId) async {
    final rows = await (_db.select(_db.medcardSections)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final s in rows) {
      await (_db.update(_db.medcardSections)..where((t) => t.id.equals(s.id))).write(
        MedcardSectionsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<MedcardSection>> _medcardSectionsForPush(int memberId, DateTime? since) async {
    await _assignMissingMedcardSectionUuids(memberId);
    final query = _db.select(_db.medcardSections)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingMedcardEntryUuids(int memberId) async {
    final rows = await (_db.select(_db.medcardEntries)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final e in rows) {
      await (_db.update(_db.medcardEntries)..where((t) => t.id.equals(e.id))).write(
        MedcardEntriesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<MedcardEntry>> _medcardEntriesForPush(int memberId, DateTime? since) async {
    await _assignMissingMedcardEntryUuids(memberId);
    final query = _db.select(_db.medcardEntries)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<String?> _medcardSectionSyncUuidFor(int sectionId) async {
    final row = await (_db.select(_db.medcardSections)..where((t) => t.id.equals(sectionId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _sectionSyncUuidOrNull(int? sectionId) =>
      sectionId == null ? Future.value(null) : _medcardSectionSyncUuidFor(sectionId);

  Future<String?> _medicationSyncUuidFor(int medicationId) async {
    final row = await (_db.select(_db.medications)..where((t) => t.id.equals(medicationId))).getSingleOrNull();
    return row?.syncUuid;
  }

  Future<String?> _scheduleSyncUuidFor(int scheduleId) async {
    final row = await (_db.select(_db.schedules)..where((t) => t.id.equals(scheduleId))).getSingleOrNull();
    return row?.syncUuid;
  }

  // ── Фото ──────────────────────────────────────────────────────────────────
  // Без окремої черги мутацій (на відміну від account-sync/PhotoSyncQueue) —
  // для одного члена сім'ї фото зазвичай кілька штук, тож звірити поточний
  // список photoPaths із тим, що вже було відправлено цього каналу, дешевше
  // й простіше, ніж проводити memberId через усі виклики PhotoService.

  String _photoStateKey(String channelId) => 'family_sync_pushed_photos_$channelId';

  Future<Set<String>> _pushedPhotoIds(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_photoStateKey(channelId));
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> _setPushedPhotoIds(String channelId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoStateKey(channelId), jsonEncode(ids.toList()));
  }

  Future<List<Map<String, dynamic>>> _photosForPush(
      SharedChannel channel, bool medcardSyncAllowed, SecretKey key) async {
    final medications =
        await (_db.select(_db.medications)..where((t) => t.memberId.equals(channel.memberId))).get();
    final currentPaths = <String>{};
    for (final m in medications) {
      try {
        final paths = (jsonDecode(m.photoPaths) as List).cast<String>();
        currentPaths.addAll(paths);
      } catch (_) {
        // photoPaths пошкоджений/порожній — пропускаємо цей медикамент
      }
    }

    // Медкартка — documentPaths, той самий json-список формат, що й
    // photoPaths вище (кілька фото/PDF на один запис). Пропускаємо весь блок,
    // якщо синхронізація медкартки вимкнена — інакше вкладення все одно
    // долетіли б до іншого пристрою в обхід прапорця.
    if (medcardSyncAllowed) {
      void addDocumentPaths(String json) {
        try {
          currentPaths.addAll((jsonDecode(json) as List).cast<String>());
        } catch (_) {
          // documentPaths пошкоджений/порожній — пропускаємо цей рядок
        }
      }

      final appointments =
          await (_db.select(_db.reminders)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final a in appointments) {
        addDocumentPaths(a.documentPaths);
      }

      final medcardEntries =
          await (_db.select(_db.medcardEntries)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final e in medcardEntries) {
        addDocumentPaths(e.documentPaths);
      }
    }

    final previouslyPushed = await _pushedPhotoIds(channel.channelId);
    final photos = <Map<String, dynamic>>[];

    for (final path in currentPaths.difference(previouslyPushed)) {
      final file = File(await PhotoService.absolutePath(path));
      if (!await file.exists()) continue;
      // Файл на диску зашифрований ЛОКАЛЬНИМ ключем цього пристрою — інший
      // пристрій його прочитати не зможе. Розшифровуємо тут (лише в пам'яті)
      // і шифруємо ключем каналу, спільним для обох сторін, перш ніж
      // відправити.
      final diskBytes = await file.readAsBytes();
      Uint8List plainBytes;
      try {
        plainBytes = await FileEncryptionService.decryptBytes(diskBytes);
      } catch (_) {
        continue; // пошкоджений/чужий файл — пропускаємо, а не ламаємо весь push
      }
      final channelBytes = await SyncCryptoService.encryptBytes(key, plainBytes);
      photos.add({'photo_id': path, 'bytes': base64Encode(channelBytes)});
    }
    for (final path in previouslyPushed.difference(currentPaths)) {
      photos.add({'photo_id': path, 'deleted': true});
    }

    if (photos.isNotEmpty) {
      await _setPushedPhotoIds(channel.channelId, currentPaths);
    }

    return photos;
  }

  Future<void> _pingOtherDevice(String channelId, SecretKey key) async {
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
      // Не критично — інший пристрій все одно підхопить зміни при
      // наступному відкритті застосунку (resume-хук).
    }
  }

  // ── Pull ──────────────────────────────────────────────────────────────────

  Future<void> _pull(SharedChannel channel, SecretKey key) async {
    final since = channel.lastSyncedAt;
    final result = await _api.pull(channelId: channel.channelId, since: since);

    // Порядок важливий для medication/schedule/intake/symptom: дочірні
    // сутності посилаються лише коли в батьківської вже є syncUuid, тож
    // medication гарантовано не пізніше за своїх дітей. medcard_section —
    // першою: medication/activity/wellbeing_schedule/doctor_appointment
    // тепер теж резолвлять sectionSyncUuid (Крок 5-6), а medcard_entry
    // (дочірня щодо medcard_section) — останньою.
    const order = [
      'medcard_section',
      'medication', 'schedule', 'intake', 'symptom',
      'activity', 'activity_slot', 'activity_log',
      'wellbeing_log', 'wellbeing_schedule',
      'doctor_appointment',
      'reminder_log',
      'medcard_entry',
    ];
    final byType = <String, List<FamilySyncEntity>>{for (final t in order) t: []};
    for (final e in result.entities) {
      (byType[e.type] ??= []).add(e);
    }

    for (final type in order) {
      for (final entity in byType[type] ?? const []) {
        try {
          if (entity.deleted) {
            await _deleteLocally(type, entity.uuid);
            continue;
          }
          final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
          await _upsertLocally(type, entity.uuid, json, channel.memberId);
        } catch (_) {
          // Один пошкоджений/несумісний запис не має права заморозити весь
          // канал — lastSyncedAt все одно просунеться після цього проходу,
          // тож пропущений запис просто не з'явиться (краще, ніж жоден запис
          // не синхронізується назавжди).
        }
      }
    }

    for (final photo in result.photos) {
      final file = File(await PhotoService.absolutePath(photo.photoId));
      if (photo.deleted) {
        if (await file.exists()) await file.delete();
        continue;
      }
      // photo.bytes прийшли зашифровані ключем КАНАЛУ (спільним для обох
      // сторін) — розшифровуємо і одразу шифруємо СВОЇМ локальним ключем,
      // перш ніж записати на диск, інакше PhotoService.decryptedBytes()
      // пізніше не зможе це прочитати (в іншого пристрою інший локальний
      // ключ).
      Uint8List plainBytes;
      try {
        plainBytes = await SyncCryptoService.decryptBytes(key, photo.bytes);
      } catch (_) {
        continue; // пошкоджений блок — пропускаємо, спробуємо наступного разу
      }
      final diskBytes = await FileEncryptionService.encryptBytes(plainBytes);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(diskBytes);
    }
  }

  Future<void> _upsertLocally(
    String type,
    String syncUuid,
    Map<String, dynamic> json,
    int memberId,
  ) async {
    switch (type) {
      case 'medication':
        final existing =
            await (_db.select(_db.medications)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        json['sectionId'] = await _localSectionIdOrNull(json['sectionSyncUuid'] as String?);
        final row = Medication.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.medications).replace(companion);
        } else {
          await _db.into(_db.medications).insert(companion);
        }

      case 'schedule':
        final medUuid = json['medicationSyncUuid'] as String?;
        final medicationId = medUuid == null ? null : await _localMedicationIdForUuid(medUuid);
        if (medicationId == null) return; // медикамент ще не прийшов — пропускаємо, прийде наступного разу
        final existing =
            await (_db.select(_db.schedules)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['medicationId'] = medicationId;
        final row = Schedule.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.schedules).replace(companion);
        } else {
          await _db.into(_db.schedules).insert(companion);
        }

      case 'intake':
        final medUuid = json['medicationSyncUuid'] as String?;
        final schedUuid = json['scheduleSyncUuid'] as String?;
        final medicationId = medUuid == null ? null : await _localMedicationIdForUuid(medUuid);
        final scheduleId = schedUuid == null ? null : await _localScheduleIdForUuid(schedUuid);
        if (medicationId == null || scheduleId == null) return;
        final existing =
            await (_db.select(_db.intakes)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['medicationId'] = medicationId;
        json['scheduleId'] = scheduleId;
        json['memberId'] = memberId;
        final row = Intake.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.intakes).replace(companion);
        } else {
          await _db.into(_db.intakes).insert(companion);
        }

      case 'symptom':
        final medUuid = json['medicationSyncUuid'] as String?;
        final medicationId = medUuid == null ? null : await _localMedicationIdForUuid(medUuid);
        if (medicationId == null) return;
        final existing =
            await (_db.select(_db.symptoms)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['medicationId'] = medicationId;
        final row = Symptom.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.symptoms).replace(companion);
        } else {
          await _db.into(_db.symptoms).insert(companion);
        }

      case 'activity':
        final existing =
            await (_db.select(_db.activities)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        json['sectionId'] = await _localSectionIdOrNull(json['sectionSyncUuid'] as String?);
        final row = Activity.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.activities).replace(companion);
        } else {
          await _db.into(_db.activities).insert(companion);
        }

      case 'activity_slot':
        final actUuid = json['activitySyncUuid'] as String?;
        final activityId = actUuid == null ? null : await _localActivityIdForUuid(actUuid);
        if (activityId == null) return;
        final existing =
            await (_db.select(_db.activitySlots)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['activityId'] = activityId;
        final row = ActivitySlot.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.activitySlots).replace(companion);
        } else {
          await _db.into(_db.activitySlots).insert(companion);
        }

      case 'activity_log':
        final actUuid = json['activitySyncUuid'] as String?;
        final activityId = actUuid == null ? null : await _localActivityIdForUuid(actUuid);
        if (activityId == null) return;
        final existing =
            await (_db.select(_db.activityLogs)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['activityId'] = activityId;
        json['memberId'] = memberId;
        final row = ActivityLog.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.activityLogs).replace(companion);
        } else {
          await _db.into(_db.activityLogs).insert(companion);
        }

      case 'wellbeing_log':
        final existing =
            await (_db.select(_db.wellbeingLogs)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = WellbeingLog.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.wellbeingLogs).replace(companion);
        } else {
          await _db.into(_db.wellbeingLogs).insert(companion);
        }

      case 'wellbeing_schedule':
        final existing = await (_db.select(_db.wellbeingSchedules)
              ..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        json['sectionId'] = await _localSectionIdOrNull(json['sectionSyncUuid'] as String?);
        final row = WellbeingSchedule.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.wellbeingSchedules).replace(companion);
        } else {
          await _db.into(_db.wellbeingSchedules).insert(companion);
        }

      case 'doctor_appointment':
        final existing = await (_db.select(_db.reminders)
              ..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        json['sectionId'] = await _localSectionIdOrNull(json['sectionSyncUuid'] as String?);
        final row = Reminder.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.reminders).replace(companion);
        } else {
          await _db.into(_db.reminders).insert(companion);
        }

      case 'reminder_log':
        final reminderUuid = json['reminderSyncUuid'] as String?;
        final reminderId = reminderUuid == null ? null : await _localReminderIdForUuid(reminderUuid);
        if (reminderId == null) return; // нагадування ще не прийшло — пропускаємо, прийде наступного разу
        final existing =
            await (_db.select(_db.reminderLogs)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['reminderId'] = reminderId;
        json['memberId'] = memberId;
        final row = ReminderLog.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.reminderLogs).replace(companion);
        } else {
          await _db.into(_db.reminderLogs).insert(companion);
        }

      case 'medcard_section':
        final existing = await (_db.select(_db.medcardSections)
              ..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = MedcardSection.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.medcardSections).replace(companion);
        } else {
          await _db.into(_db.medcardSections).insert(companion);
        }

      case 'medcard_entry':
        final sectionUuid = json['sectionSyncUuid'] as String?;
        final sectionId = sectionUuid == null ? null : await _localMedcardSectionIdForUuid(sectionUuid);
        if (sectionId == null) return; // розділ ще не прийшов — пропускаємо, прийде наступного разу
        final existing = await (_db.select(_db.medcardEntries)
              ..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['sectionId'] = sectionId;
        json['memberId'] = memberId;
        final row = MedcardEntry.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.medcardEntries).replace(companion);
        } else {
          await _db.into(_db.medcardEntries).insert(companion);
        }

    }
  }

  Future<void> _deleteLocally(String type, String syncUuid) async {
    switch (type) {
      case 'medication':
        await (_db.delete(_db.medications)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'schedule':
        await (_db.delete(_db.schedules)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'intake':
        await (_db.delete(_db.intakes)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'symptom':
        await (_db.delete(_db.symptoms)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'activity':
        await (_db.delete(_db.activities)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'activity_slot':
        await (_db.delete(_db.activitySlots)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'activity_log':
        await (_db.delete(_db.activityLogs)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'wellbeing_log':
        await (_db.delete(_db.wellbeingLogs)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'wellbeing_schedule':
        await (_db.delete(_db.wellbeingSchedules)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'doctor_appointment':
        await (_db.delete(_db.reminders)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'reminder_log':
        await (_db.delete(_db.reminderLogs)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'medcard_section':
        await (_db.delete(_db.medcardSections)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'medcard_entry':
        await (_db.delete(_db.medcardEntries)..where((t) => t.syncUuid.equals(syncUuid))).go();
    }
  }

  Future<int?> _localMedicationIdForUuid(String syncUuid) async {
    final row = await (_db.select(_db.medications)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localScheduleIdForUuid(String syncUuid) async {
    final row = await (_db.select(_db.schedules)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localReminderIdForUuid(String syncUuid) async {
    final row = await (_db.select(_db.reminders)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
    return row?.id;
  }

  Future<int?> _localMedcardSectionIdForUuid(String syncUuid) async {
    final row =
        await (_db.select(_db.medcardSections)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
    return row?.id;
  }

  /// null, якщо запис не мав розділу (sectionSyncUuid відсутній) АБО розділ
  /// ще не дійшов до цього пристрою — у другому випадку прив'язка просто
  /// не встановиться цього разу й підхопиться на наступному синку, коли
  /// medcard_section вже буде локально (той самий компроміс, що й для
  /// medicationSyncUuid/scheduleSyncUuid вище).
  Future<int?> _localSectionIdOrNull(String? sectionSyncUuid) =>
      sectionSyncUuid == null ? Future.value(null) : _localMedcardSectionIdForUuid(sectionSyncUuid);
}
