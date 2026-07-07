import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/family_sync_delete_queue.dart';
import '../../core/services/family_sync_service.dart';

class SchedulesRepository {
  final AppDatabase _db;
  SchedulesRepository(this._db);

  Future<List<Schedule>> getByMedication(int medicationId) =>
      (_db.select(_db.schedules)
            ..where((t) => t.medicationId.equals(medicationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<Schedule>> watchByMedication(int medicationId) =>
      (_db.select(_db.schedules)
            ..where((t) => t.medicationId.equals(medicationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insert(SchedulesCompanion schedule) async {
    final id = await _db.into(_db.schedules).insert(schedule);
    if (schedule.medicationId.present) {
      await _triggerFamilySyncForMedication(schedule.medicationId.value);
    }
    return id;
  }

  Future<void> replaceAll(int medicationId, List<SchedulesCompanion> schedules) async {
    // Ті, що видаляються тут, могли бути частиною family_sync — якщо не
    // запам'ятати це до видалення, інший пристрій ніколи не дізнається,
    // що старий розклад зник.
    await _enqueueTombstonesForMedication(medicationId);
    await (_db.delete(_db.schedules)
          ..where((t) => t.medicationId.equals(medicationId)))
        .go();
    for (final s in schedules) {
      await _db.into(_db.schedules).insert(s);
    }
    await _triggerFamilySyncForMedication(medicationId);
  }

  Future<int> delete(int id) async {
    final schedule =
        await (_db.select(_db.schedules)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (schedule != null) {
      await _enqueueTombstonesForSchedule(schedule);
    }
    final result = await (_db.delete(_db.schedules)..where((t) => t.id.equals(id))).go();
    if (schedule != null) await _triggerFamilySyncForMedication(schedule.medicationId);
    return result;
  }

  Future<void> _enqueueTombstonesForMedication(int medicationId) async {
    final existing = await (_db.select(_db.schedules)
          ..where((t) => t.medicationId.equals(medicationId)))
        .get();
    for (final schedule in existing) {
      await _enqueueTombstonesForSchedule(schedule);
    }
  }

  /// Видалення розкладу тягне за собою каскадне видалення повʼязаних
  /// Intakes (FK `onDelete: cascade`) — якщо вони теж вже були частиною
  /// family_sync, про їхнє зникнення теж треба повідомити, інакше інший
  /// пристрій назавжди лишиться з "привидом" старого прийому.
  Future<void> _enqueueTombstonesForSchedule(Schedule schedule) async {
    final medication = await (_db.select(_db.medications)
          ..where((t) => t.id.equals(schedule.medicationId)))
        .getSingleOrNull();
    if (medication == null) return;
    final channel = await (_db.select(_db.sharedChannels)
          ..where((t) => t.memberId.equals(medication.memberId)))
        .getSingleOrNull();
    if (channel == null) return;

    if (schedule.syncUuid != null) {
      await FamilySyncDeleteQueue.enqueue(
        channelId: channel.channelId,
        entityType: 'schedule',
        syncUuid: schedule.syncUuid!,
      );
    }

    final relatedIntakes =
        await (_db.select(_db.intakes)..where((t) => t.scheduleId.equals(schedule.id))).get();
    for (final intake in relatedIntakes) {
      if (intake.syncUuid == null) continue;
      await FamilySyncDeleteQueue.enqueue(
        channelId: channel.channelId,
        entityType: 'intake',
        syncUuid: intake.syncUuid!,
      );
    }
  }

  Future<void> _triggerFamilySyncForMedication(int medicationId) async {
    final medication = await (_db.select(_db.medications)..where((t) => t.id.equals(medicationId)))
        .getSingleOrNull();
    if (medication != null) {
      unawaited(FamilySyncService(_db).syncChannelForMember(medication.memberId));
    }
  }
}

final schedulesRepositoryProvider = Provider<SchedulesRepository>((ref) {
  return SchedulesRepository(ref.watch(databaseProvider));
});
