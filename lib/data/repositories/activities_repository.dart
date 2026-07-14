import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/notification_service.dart';

class ActivitiesRepository {
  final AppDatabase _db;
  final Ref _ref;
  ActivitiesRepository(this._db, this._ref);

  void _triggerFamilySync(int memberId) {
    unawaited(FamilySyncService(_db).syncChannelForMember(memberId));
    unawaited(FamilyPeerSyncService(_db).syncAllPeers());
  }

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

  Future<int> insertActivity(ActivitiesCompanion activity) async {
    final id = await _db.into(_db.activities).insert(activity);
    if (activity.memberId.present) _triggerFamilySync(activity.memberId.value);
    return id;
  }

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
        .write(ActivityLogsCompanion(status: const Value('done'), updatedAt: Value(DateTime.now())));
    await NotificationService.cancelActivityReminder(id);
    await _triggerFamilySyncForLog(id);
  }

  Future<void> markLogSkipped(int id) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id)))
        .write(ActivityLogsCompanion(status: const Value('skipped'), updatedAt: Value(DateTime.now())));
    await NotificationService.cancelActivityReminder(id);
    await _triggerFamilySyncForLog(id);
  }

  Future<void> _triggerFamilySyncForLog(int id) async {
    final log = await (_db.select(_db.activityLogs)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (log != null) _triggerFamilySync(log.memberId);
  }

  Future<void> snoozeLog(int id, DateTime newScheduledAt) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id)))
        .write(ActivityLogsCompanion(scheduledAt: Value(newScheduledAt), updatedAt: Value(DateTime.now())));
    await NotificationService.cancelActivityReminder(id);

    final log = await (_db.select(_db.activityLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (log == null) return;
    final activity = await (_db.select(_db.activities)
          ..where((t) => t.id.equals(log.activityId)))
        .getSingleOrNull();
    if (activity == null) return;
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(log.memberId)))
        .getSingleOrNull();

    final settings = _ref.read(notificationSettingsProvider);
    final remindAt = settings.adjust(newScheduledAt, memberId: log.memberId);
    if (remindAt != null) {
      await NotificationService.scheduleActivityReminder(
        logId: id,
        memberName: member?.name ?? '',
        activityName: activity.name,
        scheduledAt: remindAt,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
    _triggerFamilySync(log.memberId);
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

  Future<int> insertLog(ActivityLogsCompanion log) async {
    final id = await _db.into(_db.activityLogs).insert(log);
    if (log.memberId.present) _triggerFamilySync(log.memberId.value);
    return id;
  }

  Future<void> updateActivity(ActivitiesCompanion activity) async {
    await (_db.update(_db.activities)..where((t) => t.id.equals(activity.id.value)))
        .write(activity);
    final row = await (_db.select(_db.activities)..where((t) => t.id.equals(activity.id.value)))
        .getSingleOrNull();
    if (row != null) _triggerFamilySync(row.memberId);
  }

  Future<int> softDelete(int id) async {
    final pending = await (_db.select(_db.activityLogs)
          ..where((t) => t.activityId.equals(id) & t.status.equals('pending')))
        .get();
    for (final log in pending) {
      await NotificationService.cancelActivityReminder(log.id);
    }

    final activity = await (_db.select(_db.activities)..where((t) => t.id.equals(id))).getSingleOrNull();
    final result = await (_db.update(_db.activities)..where((t) => t.id.equals(id)))
        .write(const ActivitiesCompanion(isActive: Value(false)));
    if (activity != null) _triggerFamilySync(activity.memberId);
    return result;
  }
}

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(ref.watch(databaseProvider), ref);
});
