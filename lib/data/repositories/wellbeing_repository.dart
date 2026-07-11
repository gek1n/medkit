import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';

class WellbeingRepository {
  final AppDatabase _db;
  WellbeingRepository(this._db);

  void _triggerFamilySync(int memberId) {
    unawaited(FamilySyncService(_db).syncChannelForMember(memberId));
    unawaited(FamilyPeerSyncService(_db).syncAllPeers());
  }

  // Logs
  Stream<List<WellbeingLog>> watchByMember(int memberId) =>
      (_db.select(_db.wellbeingLogs)
            ..where((t) => t.memberId.equals(memberId))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
          .watch();

  Future<List<WellbeingLog>> getByMemberAndDateRange(
    int memberId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.wellbeingLogs)
            ..where((t) =>
                t.memberId.equals(memberId) &
                t.loggedAt.isBiggerOrEqualValue(from) &
                t.loggedAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
          .get();

  Future<WellbeingLog?> getLastByMember(int memberId) =>
      (_db.select(_db.wellbeingLogs)
            ..where((t) => t.memberId.equals(memberId))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertLog(WellbeingLogsCompanion log) async {
    final id = await _db.into(_db.wellbeingLogs).insert(log);
    if (log.memberId.present) _triggerFamilySync(log.memberId.value);
    return id;
  }

  Future<int> deleteLog(int id) =>
      (_db.delete(_db.wellbeingLogs)..where((t) => t.id.equals(id))).go();

  Stream<List<WellbeingLog>> watchTodayLogs(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.wellbeingLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.loggedAt.isBiggerOrEqualValue(start) &
              t.loggedAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .watch();
  }

  // Schedules
  Future<WellbeingSchedule?> getScheduleByMember(int memberId) =>
      (_db.select(_db.wellbeingSchedules)
            ..where((t) => t.memberId.equals(memberId))
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  Stream<WellbeingSchedule?> watchScheduleByMember(int memberId) =>
      (_db.select(_db.wellbeingSchedules)
            ..where((t) => t.memberId.equals(memberId))
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .watchSingleOrNull();

  Future<void> upsertSchedule(WellbeingSchedulesCompanion schedule) async {
    final existing = await getScheduleByMember(schedule.memberId.value);
    if (existing != null) {
      await (_db.update(_db.wellbeingSchedules)
            ..where((t) => t.memberId.equals(schedule.memberId.value)))
          .write(schedule);
    } else {
      await _db.into(_db.wellbeingSchedules).insert(schedule);
    }
    _triggerFamilySync(schedule.memberId.value);
  }
}

final wellbeingRepositoryProvider = Provider<WellbeingRepository>((ref) {
  return WellbeingRepository(ref.watch(databaseProvider));
});
