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

        // "Чия черга" сьогодні — з урахуванням ротації; rotationMode=='all'
        // (#325-доробка) — це ВСІ учасники пулу одразу, не один по черзі,
        // тож тут завжди список (звичайні режими — список з одного).
        final assigneeIds = await repo.assigneesForDate(activity, day);

        final slots = await repo.getSlotsForActivity(activity.id);

        for (final assigneeId in assigneeIds) {
          final member = await (_db.select(_db.members)
                ..where((t) => t.id.equals(assigneeId)))
              .getSingleOrNull();
          final memberName = member?.name ?? '';

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
              // Виняток — день створення рутини (#312, той самий фікс, що й
              // у IntakeGenerator): інакше рутина, додана сьогодні з часом,
              // що вже минув, не отримує лог на сьогодні й зникає з
              // календарного виду Розкладу.
              final isCreationDay = day.year == activity.createdAt.year &&
                  day.month == activity.createdAt.month &&
                  day.day == activity.createdAt.day;
              if (scheduledAt.isBefore(cutoff) && !isCreationDay) continue;
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
    // memberId — теж частина унікальності (не лише activityId+scheduledAt):
    // rotationMode=='all' (#325-доробка) створює по одному логу НА КОЖНОГО
    // учасника пулу для того самого occurrence/часу — без memberId тут
    // другий і подальші виклики цієї функції для того самого слоту
    // помилково вважали б лог "уже існує" й пропускали решту учасників.
    final exists = await (_db.select(_db.activityLogs)..where(
          (t) =>
              t.activityId.equals(activity.id) &
              t.memberId.equals(memberId) &
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
    final rawReminderAt =
        scheduledAt.subtract(Duration(minutes: activity.reminderBeforeMin));
    final remindAt = settings.adjust(
      rawReminderAt,
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
