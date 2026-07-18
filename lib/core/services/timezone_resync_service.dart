import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import '../../features/today/providers/today_providers.dart';
import '../providers/database_provider.dart';
import 'activity_log_generator.dart';
import 'app_logger.dart';
import 'intake_generator.dart';
import 'notification_service.dart';

/// Виправляє "часовий зсув" нагадувань про ліки/активності після зміни
/// часового поясу пристрою (подорож). Реальний звіт: розклад на 22:00
/// (український час) після переїзду у В'єтнам (UTC+7 проти UTC+3) починав
/// спрацьовувати о 2:00 ночі — `Schedules.timeOfDay`/`Activities` зберігають
/// лише текст "HH:mm" (плаваючий, без прив'язки до поясу), але
/// `IntakeGenerator`/`ActivityLogGenerator` перетворюють його на конкретний
/// `DateTime` ОДИН РАЗ, у момент генерації, наївною локальною конструкцією
/// `DateTime(year, month, day, hour, minute)`. Ця конкретна мить далі
/// зберігається/синхронізується як абсолютний момент — і при зміні поясу
/// пристрою (чи то через синхронізацію з іншого пристрою в іншому поясі,
/// чи через фізичну подорож із тим самим пристроєм) стає видимою вже в
/// НОВОМУ поясі, тобто "з'їжджає" на різницю зсувів.
///
/// Рішення (підтверджено користувачем): час прийому ліків завжди має
/// означати "за поточним локальним часом пристрою", а не "фіксована мить
/// із моменту створення розкладу". Тому при виявленні зміни зсуву — не
/// намагаємось "полагодити" вже згенеровані (потенційно зіпсовані) рядки
/// заднім числом (сам зсув могло з'їсти й календарний день, не лише
/// годину/хвилину — довіряти збереженому значенню вже не можна), а
/// видаляємо ще не оброблені (`pending`/`snoozed`) прийоми в широкому вікні
/// навколо "зараз" і генеруємо їх наново — `IntakeGenerator`/
/// `ActivityLogGenerator` й так завжди рахують від ПОТОЧНОГО локального
/// часу, тож свіжа генерація автоматично виходить коректною для нового
/// поясу.
class TimezoneResyncService {
  static const _lastOffsetKey = 'last_known_utc_offset_minutes';

  final AppDatabase _db;
  final Ref _ref;
  TimezoneResyncService(this._db, this._ref);

  Future<void> resyncIfTimezoneChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentOffset = DateTime.now().timeZoneOffset.inMinutes;
      final lastOffset = prefs.getInt(_lastOffsetKey);

      // Перший запуск (lastOffset ще нема) — просто запам'ятовуємо базове
      // значення, ремонтувати нічого: жодного розкладу, згенерованого в
      // "іншому" поясі, ще не могло бути.
      if (lastOffset != null && lastOffset != currentOffset) {
        AppLogger.log(
          'TimezoneResyncService: UTC offset changed '
          '($lastOffset -> $currentOffset min) — repairing pending schedule',
        );
        await _repairPendingSchedule();
      }
      await prefs.setInt(_lastOffsetKey, currentOffset);
    } catch (e, st) {
      AppLogger.logError('TimezoneResyncService.resyncIfTimezoneChanged', e, st);
    }
  }

  Future<void> _repairPendingSchedule() async {
    final now = DateTime.now();
    // Достатньо широке вікно, щоб зловити зсув в обидва боки (зміна поясу
    // могла як відкинути мить у "вчора", так і в "післязавтра" залежно від
    // напрямку й величини зсуву) — не займає минулі, вже оброблені прийоми.
    final windowStart = now.subtract(const Duration(hours: 30));
    final windowEnd = now.add(const Duration(hours: 54));

    final staleIntakes = await (_db.select(_db.intakes)..where(
          (t) =>
              (t.status.equals('pending') | t.status.equals('snoozed')) &
              t.scheduledAt.isBiggerOrEqualValue(windowStart) &
              t.scheduledAt.isSmallerThanValue(windowEnd),
        ))
        .get();
    for (final intake in staleIntakes) {
      await NotificationService.cancelIntakeReminder(intake.id);
      await (_db.delete(_db.intakes)..where((t) => t.id.equals(intake.id))).go();
    }

    final staleLogs = await (_db.select(_db.activityLogs)..where(
          (t) =>
              t.status.equals('pending') &
              t.scheduledAt.isBiggerOrEqualValue(windowStart) &
              t.scheduledAt.isSmallerThanValue(windowEnd),
        ))
        .get();
    for (final log in staleLogs) {
      await NotificationService.cancelActivityReminder(log.id);
      await (_db.delete(_db.activityLogs)..where((t) => t.id.equals(log.id))).go();
    }

    final intakeGenerator = IntakeGenerator(_db, _ref);
    final activityGenerator = ActivityLogGenerator(_db, _ref);
    for (final day in [now, now.add(const Duration(days: 1))]) {
      await intakeGenerator.generateForDay(day);
      await activityGenerator.generateForDay(day);
    }

    // Today screen кешує "Сьогодні"/"Коротко про завтра" через FutureProvider —
    // без інвалідації вже відкритий екран показував би застарілий (до
    // ремонту) список аж до наступного pull-to-refresh.
    _ref.invalidate(generateTodayIntakesProvider);
    _ref.invalidate(generateTodayActivityLogsProvider);
    _ref.invalidate(tomorrowIntakesProvider);
    _ref.invalidate(tomorrowActivityLogsProvider);
  }
}

final timezoneResyncServiceProvider = Provider<TimezoneResyncService>((ref) {
  return TimezoneResyncService(ref.watch(databaseProvider), ref);
});
