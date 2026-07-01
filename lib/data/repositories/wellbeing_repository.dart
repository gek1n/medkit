import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class WellbeingRepository {
  final AppDatabase _db;
  WellbeingRepository(this._db);

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

  Future<int> insertLog(WellbeingLogsCompanion log) =>
      _db.into(_db.wellbeingLogs).insert(log);

  Future<int> deleteLog(int id) =>
      (_db.delete(_db.wellbeingLogs)..where((t) => t.id.equals(id))).go();

  // Schedules
  Future<WellbeingSchedule?> getScheduleByMember(int memberId) =>
      (_db.select(_db.wellbeingSchedules)
            ..where((t) => t.memberId.equals(memberId)))
          .getSingleOrNull();

  Future<void> upsertSchedule(WellbeingSchedulesCompanion schedule) async {
    await _db.into(_db.wellbeingSchedules).insertOnConflictUpdate(schedule);
  }
}

final wellbeingRepositoryProvider = Provider<WellbeingRepository>((ref) {
  return WellbeingRepository(ref.watch(databaseProvider));
});
