import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import 'account_service.dart';
import 'photo_service.dart';
import 'photo_sync_queue.dart';
import 'sync_api_client.dart';
import 'sync_crypto_service.dart';

/// Оркеструє push/pull зашифрованої синхронізації. Кожен рядок таблиці —
/// окрема зашифрована сутність на сервері (`entity_type` + `local_id`), не
/// один великий blob — це дозволяє заливати лише те, що змінилось з
/// `updatedAt` (а не все щоразу).
///
/// ⚠️ Відоме обмеження цієї фази: `local_id` — це локальний автоінкремент
/// Drift, який НЕ є глобально унікальним між пристроями. Це безпечно для
/// сценарію "відновити СВОЇ Ж дані після переустановки/на новому телефоні"
/// (один акаунт активний на одному пристрої за раз), але НЕ розраховане на
/// одночасну синхронізацію одного акаунта з двох живих пристроїв одразу —
/// це окрема задача (потрібні глобально унікальні ідентифікатори рядків),
/// не плутати з пейрингом (`PairingApiClient`/`RelayApiClient`), який і так
/// призначений для обміну між РІЗНИМИ людьми/пристроями.
class SyncService {
  static const _lastSyncedAtKey = 'sync_last_synced_at';

  final AppDatabase _db;
  final _accountService = AccountService();
  final SyncApiClient _api = const SyncApiClient();

  SyncService(this._db);

  Future<DateTime?> _lastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_lastSyncedAtKey);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<void> _setLastSyncedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncedAtKey, value.toIso8601String());
  }

  /// Заливає на сервер усе, що змінилось з часу останньої синхронізації.
  /// Нічого не робить, якщо синхронізація не увімкнена (режим `local`).
  Future<void> pushChanges() async {
    final key = await _accountService.currentSyncKey();
    final accountId = await _accountService.currentAccountId();
    if (key == null || accountId == null) return;

    final since = await _lastSyncedAt();
    final now = DateTime.now();
    final entities = <Map<String, dynamic>>[];

    Future<void> collect<T extends Table, D>(
      String type,
      TableInfo<T, D> table,
      GeneratedColumn<DateTime> Function(T) updatedAtOf,
      int Function(D) idOf,
      Map<String, dynamic> Function(D) toJsonOf,
    ) async {
      final query = _db.select(table);
      if (since != null) {
        query.where((tbl) => updatedAtOf(tbl).isBiggerThanValue(since));
      }
      final rows = await query.get();
      for (final row in rows) {
        final blob = await SyncCryptoService.encryptEntity(key, toJsonOf(row));
        entities.add({'type': type, 'local_id': idOf(row), 'ciphertext': base64Encode(blob)});
      }
    }

    await collect('member', _db.members, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('medication', _db.medications, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('schedule', _db.schedules, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('intake', _db.intakes, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('symptom', _db.symptoms, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('wellbeing_log', _db.wellbeingLogs, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect(
        'wellbeing_schedule', _db.wellbeingSchedules, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('activity', _db.activities, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('activity_slot', _db.activitySlots, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('activity_log', _db.activityLogs, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect(
        'doctor_appointment', _db.doctorAppointments, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('lab_result', _db.labResults, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('allergy', _db.allergies, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect(
        'chronic_condition', _db.chronicConditions, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('vaccination', _db.vaccinations, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());
    await collect('surgery', _db.surgeries, (t) => t.updatedAt, (r) => r.id, (r) => r.toJson());

    // Фото — окремо від сутностей: чергу "що ще не залито/видалено" веде
    // `PhotoSyncQueue` (заповнюється в `PhotoService.pickAndSave`/`delete`),
    // а не `updatedAt` — самі файли зберігаються без окремої дати зміни.
    final pendingUploads = await PhotoSyncQueue.pendingUploads();
    final pendingDeletes = await PhotoSyncQueue.pendingDeletes();
    final photos = <Map<String, dynamic>>[];
    for (final relativePath in pendingUploads) {
      final file = File(await PhotoService.absolutePath(relativePath));
      if (!await file.exists()) continue; // видалено локально ще до заливки
      final bytes = await file.readAsBytes();
      photos.add({'photo_id': relativePath, 'bytes': base64Encode(bytes)});
    }
    for (final relativePath in pendingDeletes) {
      photos.add({'photo_id': relativePath, 'deleted': true});
    }

    if (entities.isEmpty && photos.isEmpty) {
      await _setLastSyncedAt(now);
      return;
    }

    // Сервер приймає максимум 500 сутностей / 100 фото за раз — б'ємо на
    // шматки, якщо накопичилось більше (напр. перша синхронізація великої
    // існуючої бази).
    for (var i = 0; i < entities.length; i += 500) {
      final chunk = entities.sublist(i, i + 500 > entities.length ? entities.length : i + 500);
      await _api.push(accountId: accountId, entities: chunk);
    }
    for (var i = 0; i < photos.length; i += 100) {
      final chunk = photos.sublist(i, i + 100 > photos.length ? photos.length : i + 100);
      await _api.push(accountId: accountId, photos: chunk);
    }

    for (final path in pendingUploads) {
      await PhotoSyncQueue.clearUpload(path);
    }
    for (final path in pendingDeletes) {
      await PhotoSyncQueue.clearDelete(path);
    }

    await _setLastSyncedAt(now);
  }

  /// Забирає з сервера все (при відновленні на новому пристрої, [since] не
  /// передається) чи лише нове, і записує в локальну БД (upsert за
  /// `local_id`, конфлікт по first-class primary key `id` кожної таблиці).
  Future<void> pullChanges({bool fullRestore = false}) async {
    final key = await _accountService.currentSyncKey();
    final accountId = await _accountService.currentAccountId();
    if (key == null || accountId == null) return;

    final since = fullRestore ? null : await _lastSyncedAt();
    final response = await _api.pull(accountId: accountId, since: since);

    for (final entity in response.entities) {
      if (entity.deleted) {
        await _softDeleteLocally(entity.type, entity.localId);
        continue;
      }
      final json = await SyncCryptoService.decryptEntity(key, entity.ciphertext);
      json['id'] = entity.localId;
      await _upsertLocally(entity.type, json);
    }

    for (final photo in response.photos) {
      final file = File(await PhotoService.absolutePath(photo.photoId));
      if (photo.deleted) {
        if (await file.exists()) await file.delete();
        continue;
      }
      // Байти вже зашифровані file_encryption_service.dart на пристрої, що
      // їх заливав — записуємо як є, розшифровка станеться як завжди при показі.
      await file.parent.create(recursive: true);
      await file.writeAsBytes(photo.bytes);
    }

    await _setLastSyncedAt(DateTime.now());
  }

  Future<void> _upsertLocally(String type, Map<String, dynamic> json) async {
    switch (type) {
      case 'member':
        await _db.members.insertOnConflictUpdate(Member.fromJson(json));
      case 'medication':
        await _db.medications.insertOnConflictUpdate(Medication.fromJson(json));
      case 'schedule':
        await _db.schedules.insertOnConflictUpdate(Schedule.fromJson(json));
      case 'intake':
        await _db.intakes.insertOnConflictUpdate(Intake.fromJson(json));
      case 'symptom':
        await _db.symptoms.insertOnConflictUpdate(Symptom.fromJson(json));
      case 'wellbeing_log':
        await _db.wellbeingLogs.insertOnConflictUpdate(WellbeingLog.fromJson(json));
      case 'wellbeing_schedule':
        await _db.wellbeingSchedules.insertOnConflictUpdate(WellbeingSchedule.fromJson(json));
      case 'activity':
        await _db.activities.insertOnConflictUpdate(Activity.fromJson(json));
      case 'activity_slot':
        await _db.activitySlots.insertOnConflictUpdate(ActivitySlot.fromJson(json));
      case 'activity_log':
        await _db.activityLogs.insertOnConflictUpdate(ActivityLog.fromJson(json));
      case 'doctor_appointment':
        await _db.doctorAppointments.insertOnConflictUpdate(DoctorAppointment.fromJson(json));
      case 'lab_result':
        await _db.labResults.insertOnConflictUpdate(LabResult.fromJson(json));
      case 'allergy':
        await _db.allergies.insertOnConflictUpdate(Allergy.fromJson(json));
      case 'chronic_condition':
        await _db.chronicConditions.insertOnConflictUpdate(ChronicCondition.fromJson(json));
      case 'vaccination':
        await _db.vaccinations.insertOnConflictUpdate(Vaccination.fromJson(json));
      case 'surgery':
        await _db.surgeries.insertOnConflictUpdate(Surgery.fromJson(json));
    }
  }

  Future<void> _softDeleteLocally(String type, int localId) async {
    switch (type) {
      case 'member':
        await (_db.delete(_db.members)..where((t) => t.id.equals(localId))).go();
      case 'medication':
        await (_db.delete(_db.medications)..where((t) => t.id.equals(localId))).go();
      case 'schedule':
        await (_db.delete(_db.schedules)..where((t) => t.id.equals(localId))).go();
      case 'intake':
        await (_db.delete(_db.intakes)..where((t) => t.id.equals(localId))).go();
      case 'symptom':
        await (_db.delete(_db.symptoms)..where((t) => t.id.equals(localId))).go();
      case 'wellbeing_log':
        await (_db.delete(_db.wellbeingLogs)..where((t) => t.id.equals(localId))).go();
      case 'wellbeing_schedule':
        await (_db.delete(_db.wellbeingSchedules)..where((t) => t.id.equals(localId))).go();
      case 'activity':
        await (_db.delete(_db.activities)..where((t) => t.id.equals(localId))).go();
      case 'activity_slot':
        await (_db.delete(_db.activitySlots)..where((t) => t.id.equals(localId))).go();
      case 'activity_log':
        await (_db.delete(_db.activityLogs)..where((t) => t.id.equals(localId))).go();
      case 'doctor_appointment':
        await (_db.delete(_db.doctorAppointments)..where((t) => t.id.equals(localId))).go();
      case 'lab_result':
        await (_db.delete(_db.labResults)..where((t) => t.id.equals(localId))).go();
      case 'allergy':
        await (_db.delete(_db.allergies)..where((t) => t.id.equals(localId))).go();
      case 'chronic_condition':
        await (_db.delete(_db.chronicConditions)..where((t) => t.id.equals(localId))).go();
      case 'vaccination':
        await (_db.delete(_db.vaccinations)..where((t) => t.id.equals(localId))).go();
      case 'surgery':
        await (_db.delete(_db.surgeries)..where((t) => t.id.equals(localId))).go();
    }
  }
}
