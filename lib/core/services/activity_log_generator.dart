import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_service.dart';
import '../../data/db/app_database.dart';

class ActivityLogGenerator {
  final AppDatabase _db;
  final Ref _ref;
  ActivityLogGenerator(this._db, this._ref);

  Future<void> generateForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final weekday = date.weekday; // 1=Пн … 7=Нд
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));

    final activities = await (_db.select(_db.activities)
          ..where((t) => t.isActive.equals(true)))
        .get();

    for (final activity in activities) {
      final repeatDays =
          List<int>.from(jsonDecode(activity.repeatDays) as List);
      if (!repeatDays.contains(weekday)) continue;

      final slots = await (_db.select(_db.activitySlots)
            ..where((t) => t.activityId.equals(activity.id))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

      for (final slot in slots) {
        final parts = slot.timeOfDay.split(':');
        final scheduledAt = DateTime(
          day.year, day.month, day.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );

        // Не створюємо записи більш ніж на годину в минулому —
        // це заважає щойно доданій активності одразу заповнити
        // сьогоднішній розклад пропущеними слотами.
        if (scheduledAt.isBefore(cutoff)) continue;

        final exists = await (_db.select(_db.activityLogs)
              ..where((t) =>
                  t.activityId.equals(activity.id) &
                  t.scheduledAt.equals(scheduledAt)))
            .getSingleOrNull();
        if (exists != null) continue;

        final logId =
            await _db.into(_db.activityLogs).insert(ActivityLogsCompanion.insert(
                  activityId: activity.id,
                  memberId: activity.memberId,
                  scheduledAt: scheduledAt,
                ));

        final settings = _ref.read(notificationSettingsProvider);
        final remindAt =
            settings.adjust(scheduledAt, memberId: activity.memberId);
        if (remindAt != null) {
          await NotificationService.scheduleActivityReminder(
            logId: logId,
            activityName: activity.name,
            scheduledAt: remindAt,
            vibrationEnabled: settings.vibrationEnabled,
            repeatMinutes: settings.repeatMinutes,
          );
        }
      }
    }
  }
}

final activityLogGeneratorProvider = Provider<ActivityLogGenerator>((ref) {
  return ActivityLogGenerator(ref.watch(databaseProvider), ref);
});
