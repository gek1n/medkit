import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../../data/db/app_database.dart';

// Генерує записи intakes для конкретного дня на основі schedules і налаштувань повтору
class IntakeGenerator {
  final AppDatabase _db;
  IntakeGenerator(this._db);

  Future<void> generateForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);

    final meds = await _db.select(_db.medications).get();
    for (final med in meds) {
      if (!med.isActive) continue;
      if (!_shouldTakeOnDate(med, day)) continue;

      final schedules = await (_db.select(_db.schedules)
            ..where((t) => t.medicationId.equals(med.id))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

      for (final schedule in schedules) {
        final parts = schedule.timeOfDay.split(':');
        final scheduledAt = DateTime(
          day.year, day.month, day.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );

        // Не дублюємо якщо вже є
        final exists = await (_db.select(_db.intakes)
              ..where((t) =>
                  t.scheduleId.equals(schedule.id) &
                  t.scheduledAt.equals(scheduledAt)))
            .getSingleOrNull();
        if (exists != null) continue;

        await _db.into(_db.intakes).insert(IntakesCompanion.insert(
          scheduleId: schedule.id,
          medicationId: med.id,
          memberId: med.memberId,
          scheduledAt: scheduledAt,
        ));
      }
    }
  }

  bool _shouldTakeOnDate(Medication med, DateTime date) {
    if (date.isBefore(DateTime(
        med.startDate.year, med.startDate.month, med.startDate.day))) {
      return false;
    }
    if (med.endDate != null && date.isAfter(med.endDate!)) return false;

    final config = jsonDecode(med.repeatConfig) as Map<String, dynamic>;

    switch (med.repeatType) {
      case 'daily':
        return true;

      case 'alternate':
        final diff = date.difference(DateTime(
          med.startDate.year, med.startDate.month, med.startDate.day,
        )).inDays;
        return diff % 2 == 0;

      case 'weekdays':
        final days = List<int>.from(config['days'] as List);
        // 1=Пн ... 7=Нд
        return days.contains(date.weekday);

      case 'every_n':
        final n = config['n'] as int;
        final diff = date.difference(DateTime(
          med.startDate.year, med.startDate.month, med.startDate.day,
        )).inDays;
        return diff % n == 0;

      case 'cycle':
        final on = config['on'] as int;
        final off = config['off'] as int;
        final diff = date.difference(DateTime(
          med.startDate.year, med.startDate.month, med.startDate.day,
        )).inDays;
        return diff % (on + off) < on;

      default:
        return true;
    }
  }
}

final intakeGeneratorProvider = Provider<IntakeGenerator>((ref) {
  return IntakeGenerator(ref.watch(databaseProvider));
});
