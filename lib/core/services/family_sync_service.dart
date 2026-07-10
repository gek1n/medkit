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
    await _assignMissingLabResultUuids(memberId);
    await _assignMissingAllergyUuids(memberId);
    await _assignMissingChronicConditionUuids(memberId);
    await _assignMissingVaccinationUuids(memberId);
    await _assignMissingSurgeryUuids(memberId);

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
        await (_db.select(_db.doctorAppointments)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in appointments) {
      if (a.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'doctor_appointment', syncUuid: a.syncUuid!);
      }
    }

    final labResults = await (_db.select(_db.labResults)..where((t) => t.memberId.equals(memberId))).get();
    for (final l in labResults) {
      if (l.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'lab_result', syncUuid: l.syncUuid!);
      }
    }

    final allergyRows = await (_db.select(_db.allergies)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in allergyRows) {
      if (a.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'allergy', syncUuid: a.syncUuid!);
      }
    }

    final conditionRows =
        await (_db.select(_db.chronicConditions)..where((t) => t.memberId.equals(memberId))).get();
    for (final c in conditionRows) {
      if (c.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'chronic_condition', syncUuid: c.syncUuid!);
      }
    }

    final vaccinationRows =
        await (_db.select(_db.vaccinations)..where((t) => t.memberId.equals(memberId))).get();
    for (final v in vaccinationRows) {
      if (v.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'vaccination', syncUuid: v.syncUuid!);
      }
    }

    final surgeryRows = await (_db.select(_db.surgeries)..where((t) => t.memberId.equals(memberId))).get();
    for (final s in surgeryRows) {
      if (s.syncUuid != null) {
        await FamilySyncDeleteQueue.enqueue(
            channelId: channel.channelId, entityType: 'surgery', syncUuid: s.syncUuid!);
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

    for (final m in await _medicationsForPush(memberId, since)) {
      final json = m.toJson()..remove('id')..remove('memberId');
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

    // Медкартка — усі плоскі, прив'язані напряму до memberId (без дочірніх
    // uuid, на відміну від schedule/intake/symptom), тому пушаться так само
    // просто, як і medication. Керується окремим прапорцем
    // FamilyVisibilityService.isMedcardSyncAllowed — на відміну від ліків і
    // розкладу, які завжди синхронізуються, дані медкартки можна повністю
    // виключити з передачі на інші пристрої.
    if (medcardSyncAllowed) {
      for (final a in await _appointmentsForPush(memberId, since)) {
        final json = a.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'doctor_appointment',
          'uuid': a.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final l in await _labResultsForPush(memberId, since)) {
        final json = l.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'lab_result',
          'uuid': l.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final a in await _allergiesForPush(memberId, since)) {
        final json = a.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'allergy',
          'uuid': a.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final c in await _chronicConditionsForPush(memberId, since)) {
        final json = c.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'chronic_condition',
          'uuid': c.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final v in await _vaccinationsForPush(memberId, since)) {
        final json = v.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'vaccination',
          'uuid': v.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
      for (final s in await _surgeriesForPush(memberId, since)) {
        final json = s.toJson()..remove('id')..remove('memberId');
        entities.add({
          'type': 'surgery',
          'uuid': s.syncUuid,
          'ciphertext': base64Encode(await SyncCryptoService.encryptEntity(key, json)),
        });
      }
    }

    final tombstones = await FamilySyncDeleteQueue.pendingForChannel(channel.channelId);
    for (final t in tombstones) {
      entities.add({'type': t['entityType'], 'uuid': t['syncUuid'], 'ciphertext': '', 'deleted': true});
    }

    final photos = await _photosForPush(channel, medcardSyncAllowed);

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

  // ── Медкартка (плоскі сутності, memberId напряму) ────────────────────────

  Future<void> _assignMissingAppointmentUuids(int memberId) async {
    final rows = await (_db.select(_db.doctorAppointments)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final a in rows) {
      await (_db.update(_db.doctorAppointments)..where((t) => t.id.equals(a.id))).write(
        DoctorAppointmentsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<DoctorAppointment>> _appointmentsForPush(int memberId, DateTime? since) async {
    await _assignMissingAppointmentUuids(memberId);
    final query = _db.select(_db.doctorAppointments)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingLabResultUuids(int memberId) async {
    final rows = await (_db.select(_db.labResults)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final l in rows) {
      await (_db.update(_db.labResults)..where((t) => t.id.equals(l.id))).write(
        LabResultsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<LabResult>> _labResultsForPush(int memberId, DateTime? since) async {
    await _assignMissingLabResultUuids(memberId);
    final query = _db.select(_db.labResults)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingAllergyUuids(int memberId) async {
    final rows = await (_db.select(_db.allergies)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final a in rows) {
      await (_db.update(_db.allergies)..where((t) => t.id.equals(a.id))).write(
        AllergiesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Allergy>> _allergiesForPush(int memberId, DateTime? since) async {
    await _assignMissingAllergyUuids(memberId);
    final query = _db.select(_db.allergies)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingChronicConditionUuids(int memberId) async {
    final rows = await (_db.select(_db.chronicConditions)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final c in rows) {
      await (_db.update(_db.chronicConditions)..where((t) => t.id.equals(c.id))).write(
        ChronicConditionsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<ChronicCondition>> _chronicConditionsForPush(int memberId, DateTime? since) async {
    await _assignMissingChronicConditionUuids(memberId);
    final query = _db.select(_db.chronicConditions)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingVaccinationUuids(int memberId) async {
    final rows = await (_db.select(_db.vaccinations)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final v in rows) {
      await (_db.update(_db.vaccinations)..where((t) => t.id.equals(v.id))).write(
        VaccinationsCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Vaccination>> _vaccinationsForPush(int memberId, DateTime? since) async {
    await _assignMissingVaccinationUuids(memberId);
    final query = _db.select(_db.vaccinations)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

  Future<void> _assignMissingSurgeryUuids(int memberId) async {
    final rows = await (_db.select(_db.surgeries)
          ..where((t) => t.memberId.equals(memberId) & t.syncUuid.isNull()))
        .get();
    for (final s in rows) {
      await (_db.update(_db.surgeries)..where((t) => t.id.equals(s.id))).write(
        SurgeriesCompanion(syncUuid: Value(_uuid.v4()), updatedAt: Value(DateTime.now())),
      );
    }
  }

  Future<List<Surgery>> _surgeriesForPush(int memberId, DateTime? since) async {
    await _assignMissingSurgeryUuids(memberId);
    final query = _db.select(_db.surgeries)..where((t) => t.memberId.equals(memberId));
    if (since != null) query.where((t) => t.updatedAt.isBiggerThanValue(since));
    return query.get();
  }

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

  Future<List<Map<String, dynamic>>> _photosForPush(SharedChannel channel, bool medcardSyncAllowed) async {
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
          await (_db.select(_db.doctorAppointments)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final a in appointments) {
        addDocumentPaths(a.documentPaths);
      }
      final labResults =
          await (_db.select(_db.labResults)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final l in labResults) {
        addDocumentPaths(l.documentPaths);
      }
      final surgeries =
          await (_db.select(_db.surgeries)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final s in surgeries) {
        addDocumentPaths(s.documentPaths);
      }
      final allergyRows =
          await (_db.select(_db.allergies)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final a in allergyRows) {
        addDocumentPaths(a.documentPaths);
      }
      final conditionRows = await (_db.select(_db.chronicConditions)
            ..where((t) => t.memberId.equals(channel.memberId)))
          .get();
      for (final c in conditionRows) {
        addDocumentPaths(c.documentPaths);
      }
      final vaccinationRows =
          await (_db.select(_db.vaccinations)..where((t) => t.memberId.equals(channel.memberId))).get();
      for (final v in vaccinationRows) {
        addDocumentPaths(v.documentPaths);
      }
    }

    final previouslyPushed = await _pushedPhotoIds(channel.channelId);
    final photos = <Map<String, dynamic>>[];

    for (final path in currentPaths.difference(previouslyPushed)) {
      final file = File(await PhotoService.absolutePath(path));
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      photos.add({'photo_id': path, 'bytes': base64Encode(bytes)});
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
    // medication гарантовано не пізніше за своїх дітей. Решта медкартки —
    // плоскі (memberId напряму), порядок між ними не має значення.
    const order = [
      'medication', 'schedule', 'intake', 'symptom',
      'doctor_appointment', 'lab_result', 'allergy', 'chronic_condition',
      'vaccination', 'surgery',
    ];
    final byType = <String, List<FamilySyncEntity>>{for (final t in order) t: []};
    for (final e in result.entities) {
      (byType[e.type] ??= []).add(e);
    }

    for (final type in order) {
      for (final entity in byType[type] ?? const []) {
        if (entity.deleted) {
          await _deleteLocally(type, entity.uuid);
          continue;
        }
        final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
        await _upsertLocally(type, entity.uuid, json, channel.memberId);
      }
    }

    for (final photo in result.photos) {
      final file = File(await PhotoService.absolutePath(photo.photoId));
      if (photo.deleted) {
        if (await file.exists()) await file.delete();
        continue;
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(photo.bytes);
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

      case 'doctor_appointment':
        final existing = await (_db.select(_db.doctorAppointments)
              ..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = DoctorAppointment.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.doctorAppointments).replace(companion);
        } else {
          await _db.into(_db.doctorAppointments).insert(companion);
        }

      case 'lab_result':
        final existing =
            await (_db.select(_db.labResults)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = LabResult.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.labResults).replace(companion);
        } else {
          await _db.into(_db.labResults).insert(companion);
        }

      case 'allergy':
        final existing =
            await (_db.select(_db.allergies)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = Allergy.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.allergies).replace(companion);
        } else {
          await _db.into(_db.allergies).insert(companion);
        }

      case 'chronic_condition':
        final existing = await (_db.select(_db.chronicConditions)
              ..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = ChronicCondition.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.chronicConditions).replace(companion);
        } else {
          await _db.into(_db.chronicConditions).insert(companion);
        }

      case 'vaccination':
        final existing = await (_db.select(_db.vaccinations)..where((t) => t.syncUuid.equals(syncUuid)))
            .getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = Vaccination.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.vaccinations).replace(companion);
        } else {
          await _db.into(_db.vaccinations).insert(companion);
        }

      case 'surgery':
        final existing =
            await (_db.select(_db.surgeries)..where((t) => t.syncUuid.equals(syncUuid))).getSingleOrNull();
        json['id'] = existing?.id ?? 0;
        json['memberId'] = memberId;
        final row = Surgery.fromJson(json);
        var companion = row.toCompanion(false);
        companion = existing != null
            ? companion.copyWith(id: Value(existing.id))
            : companion.copyWith(id: const Value.absent());
        if (existing != null) {
          await _db.update(_db.surgeries).replace(companion);
        } else {
          await _db.into(_db.surgeries).insert(companion);
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
      case 'doctor_appointment':
        await (_db.delete(_db.doctorAppointments)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'lab_result':
        await (_db.delete(_db.labResults)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'allergy':
        await (_db.delete(_db.allergies)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'chronic_condition':
        await (_db.delete(_db.chronicConditions)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'vaccination':
        await (_db.delete(_db.vaccinations)..where((t) => t.syncUuid.equals(syncUuid))).go();
      case 'surgery':
        await (_db.delete(_db.surgeries)..where((t) => t.syncUuid.equals(syncUuid))).go();
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
}
