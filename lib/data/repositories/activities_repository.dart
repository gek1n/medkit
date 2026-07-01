import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class ActivitiesRepository {
  final AppDatabase _db;
  ActivitiesRepository(this._db);

  Stream<List<Activity>> watchByMember(int memberId) =>
      (_db.select(_db.activities)
            ..where((t) =>
                t.memberId.equals(memberId) & t.isActive.equals(true)))
          .watch();

  Future<List<ActivitySlot>> getSlotsForActivity(int activityId) =>
      (_db.select(_db.activitySlots)
            ..where((t) => t.activityId.equals(activityId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<ActivityLog>> getLogsByMemberAndDate(
    int memberId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.activityLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end)))
        .get();
  }

  Stream<List<ActivityLog>> watchLogsByMemberAndDate(
    int memberId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.activityLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end)))
        .watch();
  }

  Future<int> insertActivity(ActivitiesCompanion activity) =>
      _db.into(_db.activities).insert(activity);

  Future<void> insertSlots(List<ActivitySlotsCompanion> slots) async {
    for (final s in slots) {
      await _db.into(_db.activitySlots).insert(s);
    }
  }

  Future<void> replaceSlots(
    int activityId,
    List<ActivitySlotsCompanion> slots,
  ) async {
    await (_db.delete(_db.activitySlots)
          ..where((t) => t.activityId.equals(activityId)))
        .go();
    await insertSlots(slots);
  }

  Future<void> markLogDone(int id) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id)))
        .write(const ActivityLogsCompanion(status: Value('done')));
  }

  Future<void> markLogSkipped(int id) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id)))
        .write(const ActivityLogsCompanion(status: Value('skipped')));
  }

  Future<List<ActivityLog>> getLogsByMemberAndDateRange(
    int memberId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.activityLogs)
            ..where((t) =>
                t.memberId.equals(memberId) &
                t.scheduledAt.isBiggerOrEqualValue(from) &
                t.scheduledAt.isSmallerThanValue(to)))
          .get();

  Future<int> insertLog(ActivityLogsCompanion log) =>
      _db.into(_db.activityLogs).insert(log);

  Future<int> softDelete(int id) =>
      (_db.update(_db.activities)..where((t) => t.id.equals(id)))
          .write(const ActivitiesCompanion(isActive: Value(false)));
}

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(ref.watch(databaseProvider));
});
