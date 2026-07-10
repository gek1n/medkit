import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../../data/db/app_database.dart';
import 'notification_service.dart';

/// На відміну від IntakeGenerator/ActivityLogGenerator — тут немає "логу
/// на день", який можна створити наперед (WellbeingLog з'являється лише
/// коли людина сама щось відмітила). Тому на пристрої того, хто наглядає
/// за автономним профілем, просто плануються перевірки на сьогоднішні
/// слоти — самі WellbeingLog-рядки тут не створюються.
class WellbeingCheckGenerator {
  final AppDatabase _db;
  WellbeingCheckGenerator(this._db);

  Future<void> generateForToday() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final cutoff = now.subtract(const Duration(hours: 1));

    final schedules =
        await (_db.select(_db.wellbeingSchedules)..where((t) => t.isActive.equals(true))).get();

    for (final schedule in schedules) {
      final member =
          await (_db.select(_db.members)..where((t) => t.id.equals(schedule.memberId))).getSingleOrNull();
      if (member?.role != 'member') continue; // перевірка потрібна лише для автономних

      // Уже є хоч один лог сьогодні — усі слоти на сьогодні вважаються
      // закритими (той самий спрощений принцип, що й у
      // NotificationService.cancelTodayWellbeingChecks).
      final existingLog = await (_db.select(_db.wellbeingLogs)
            ..where((t) => t.memberId.equals(schedule.memberId) & t.loggedAt.isBiggerOrEqualValue(day)))
          .getSingleOrNull();
      if (existingLog != null) continue;

      List<String> times;
      try {
        times = List<String>.from(jsonDecode(schedule.times) as List);
      } catch (_) {
        continue;
      }

      for (var i = 0; i < times.length; i++) {
        final parts = times[i].split(':');
        final scheduledAt =
            DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
        if (scheduledAt.isBefore(cutoff)) continue;

        await NotificationService.scheduleFamilyWellbeingCheckReminder(
          memberId: schedule.memberId,
          memberName: member!.name,
          slotIndex: i,
          scheduledAt: scheduledAt,
        );
      }
    }
  }
}

final wellbeingCheckGeneratorProvider = Provider<WellbeingCheckGenerator>((ref) {
  return WellbeingCheckGenerator(ref.watch(databaseProvider));
});
