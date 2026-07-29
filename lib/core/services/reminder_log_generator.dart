import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../services/app_logger.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/reminders_repository.dart';

/// Генерує ReminderLogs (per-occurrence стан виконання) для повторюваних
/// нагадувань (repeatType != 'none') на вказаний день — той самий принцип,
/// що й ActivityLogGenerator/IntakesRepository.generateForDate, але БЕЗ
/// планування сповіщення (воно нативно-повторюване, вже заплановане один
/// раз при збереженні нагадування — див. NotificationService.
/// scheduleDailyReminderSlots/scheduleWeeklyReminderSlots/
/// scheduleMonthlyReminder/scheduleYearlyReminder).
class ReminderLogGenerator {
  final AppDatabase _db;
  final Ref _ref;
  ReminderLogGenerator(this._db, this._ref);

  Future<void>? _inFlight;

  // Захист від дублікатів при паралельних викликах (напр. кілька
  // ref.invalidate(generateTodayReminderLogsProvider) поспіль до того, як
  // попередній виклик встиг завершитись) — без цього дві одночасні
  // генерації могли обидві побачити "запису ще немає" ще до того, як
  // перша встигла його вставити, і створити дублікат ReminderLog (саме
  // так з'являлись повторювані картки на Сьогодні). Поки попередній виклик
  // ще виконується — повертаємо той самий Future замість запуску нового.
  Future<void> generateForDay(DateTime date) {
    return _inFlight ??= _generateForDay(date).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _generateForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final remindersRepo = _ref.read(remindersRepositoryProvider);
    final reminders = await (_db.select(_db.reminders)).get();

    for (final r in reminders) {
      if (r.repeatType == 'none') continue;
      try {
        final occurrences = await remindersRepo.occurrencesOnDate(r, day);
        for (final at in occurrences) {
          // Не створюємо записи більш ніж на годину в минулому — інакше
          // щойно додане нагадування одразу заповнило б сьогоднішній
          // розклад пропущеними слотами (той самий принцип, що й в
          // ActivityLogGenerator/IntakesRepository).
          if (at.isBefore(cutoff)) continue;
          // Одна невдала спроба не повинна обривати генерацію для решти
          // нагадувань — див. аналогічний коментар у ActivityLogGenerator.
          try {
            // Транзакція — перевірка "чи вже є" і вставка мають бути єдиною
            // атомарною операцією, інакше навіть із захистом generateForDay
            // вище лишається вікно для дублікату (напр. виклик з іншого
            // provider container).
            await _db.transaction(() async {
              final exists = await (_db.select(_db.reminderLogs)
                    ..where((t) =>
                        t.reminderId.equals(r.id) & t.scheduledAt.equals(at)))
                  .getSingleOrNull();
              if (exists != null) return;

              await _db.into(_db.reminderLogs).insert(
                    ReminderLogsCompanion.insert(
                      reminderId: r.id,
                      memberId: r.memberId,
                      scheduledAt: at,
                    ),
                  );
            });
          } catch (e, st) {
            AppLogger.logError(
              'ReminderLogGenerator.occurrence(reminderId=${r.id})',
              e,
              st,
            );
          }
        }
      } catch (e, st) {
        AppLogger.logError(
          'ReminderLogGenerator.reminder(id=${r.id})',
          e,
          st,
        );
      }
    }
  }
}

final reminderLogGeneratorProvider = Provider<ReminderLogGenerator>((ref) {
  return ReminderLogGenerator(ref.watch(databaseProvider), ref);
});
