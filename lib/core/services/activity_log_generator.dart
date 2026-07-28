import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/app_logger.dart';
import '../services/notification_service.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';

class ActivityLogGenerator {
  final AppDatabase _db;
  final Ref _ref;
  ActivityLogGenerator(this._db, this._ref);

  Future<void> generateForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final repo = _ref.read(activitiesRepositoryProvider);

    final activities = await (_db.select(
      _db.activities,
    )..where((t) => t.isActive.equals(true))).get();

    for (final activity in activities) {
      try {
        // weeklyGoal — без наперед згенерованих логів, "на льоту" при
        // відмітці (див. today_providers.dart).
        if (activity.repeatType == 'weeklyGoal') continue;
        if (!await repo.occursOnDate(activity, day)) continue;

        // "Чия черга" сьогодні — з урахуванням ротації, не завжди
        // Activities.memberId (той лише власник/розділ).
        final assigneeId = await repo.assigneeForDate(activity, day);
        final member = await (_db.select(_db.members)
              ..where((t) => t.id.equals(assigneeId)))
            .getSingleOrNull();
        final memberName = member?.name ?? '';

        final slots = await repo.getSlotsForActivity(activity.id);

        if (slots.isEmpty) {
          // "Будь-коли сьогодні" — без конкретного часу. Якірний час 09:00
          // лише для зберігання/сортування; cutoff не застосовуємо, бо
          // задача лишається актуальною весь день незалежно від того, коли
          // саме відбулась генерація.
          await _createLogIfMissing(
            activity: activity,
            memberId: assigneeId,
            memberName: memberName,
            scheduledAt: DateTime(day.year, day.month, day.day, 9, 0),
          );
          continue;
        }

        for (final slot in slots) {
          // Одна невдала спроба не повинна обривати генерацію для решти
          // слотів/активностей — див. коментар у попередній версії.
          try {
            final parts = slot.timeOfDay.split(':');
            final scheduledAt = DateTime(
              day.year,
              day.month,
              day.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
            if (scheduledAt.isBefore(cutoff)) continue;
            await _createLogIfMissing(
              activity: activity,
              memberId: assigneeId,
              memberName: memberName,
              scheduledAt: scheduledAt,
            );
          } catch (e, st) {
            AppLogger.logError(
              'ActivityLogGenerator.slot(activityId=${activity.id})',
              e,
              st,
            );
          }
        }
      } catch (e, st) {
        AppLogger.logError(
          'ActivityLogGenerator.activity(id=${activity.id})',
          e,
          st,
        );
      }
    }
  }

  Future<void> _createLogIfMissing({
    required Activity activity,
    required int memberId,
    required String memberName,
    required DateTime scheduledAt,
  }) async {
    final exists = await (_db.select(_db.activityLogs)..where(
          (t) =>
              t.activityId.equals(activity.id) &
              t.scheduledAt.equals(scheduledAt),
        ))
        .getSingleOrNull();
    if (exists != null) return;

    final logId = await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            activityId: activity.id,
            memberId: memberId,
            scheduledAt: scheduledAt,
          ),
        );

    // Налаштування сповіщень (тихі години тощо) завжди беремо для власника
    // рутини — сповіщення про чергу лунає на ЙОГО пристрої, з іменем
    // фактичного виконавця в тексті (memberName).
    final settings = _ref.read(notificationSettingsProvider);
    final remindAt = settings.adjust(
      scheduledAt,
      memberId: activity.memberId,
    );
    if (remindAt != null) {
      await NotificationService.scheduleActivityReminder(
        logId: logId,
        memberName: memberName,
        activityName: activity.name,
        scheduledAt: remindAt,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
  }
}

final activityLogGeneratorProvider = Provider<ActivityLogGenerator>((ref) {
  return ActivityLogGenerator(ref.watch(databaseProvider), ref);
});
