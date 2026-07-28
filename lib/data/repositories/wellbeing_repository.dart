import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/notification_service.dart';

class WellbeingRepository {
  final AppDatabase _db;
  final Ref _ref;
  WellbeingRepository(this._db, this._ref);

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

  Future<void> setActive(int memberId, bool active) async {
    await (_db.update(_db.wellbeingSchedules)
          ..where((t) => t.memberId.equals(memberId)))
        .write(WellbeingSchedulesCompanion(isActive: Value(active)));
    _triggerFamilySync(memberId);
  }

  // Планує щоденні сповіщення для вже збереженого розкладу — спільна логіка
  // для форми створення й фіналізації онбординг-чернетки (де сповіщення
  // відкладені до появи реального профілю), щоб не дублювати цикл у двох
  // місцях.
  Future<void> scheduleNotificationsForSchedule(
    WellbeingSchedule schedule,
  ) async {
    final settings = _ref.read(notificationSettingsProvider);
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(schedule.memberId)))
        .getSingleOrNull();
    final memberName = member?.name ?? '';
    final times = List<String>.from(jsonDecode(schedule.times) as List);
    for (var i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      final now = DateTime.now();
      final raw = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final at = settings.adjust(raw, memberId: schedule.memberId);
      if (at == null) continue;
      await NotificationService.scheduleWellbeingDaily(
        memberId: schedule.memberId,
        memberName: memberName,
        slotIndex: i,
        hour: at.hour,
        minute: at.minute,
        vibrationEnabled: settings.vibrationEnabled,
      );
    }
  }
}

final wellbeingRepositoryProvider = Provider<WellbeingRepository>((ref) {
  return WellbeingRepository(ref.watch(databaseProvider), ref);
});
