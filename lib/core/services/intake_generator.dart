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

      // Determine times to generate
      List<String> times;

      if (med.phases != null) {
        // Phase-based: find active phase
        final phases = List<Map<String, dynamic>>.from(
          jsonDecode(med.phases!) as List,
        );
        final daysElapsed = day
            .difference(DateTime(
              med.startDate.year,
              med.startDate.month,
              med.startDate.day,
            ))
            .inDays;

        int accumulated = 0;
        Map<String, dynamic>? activePhase;
        for (final phase in phases) {
          final dur = phase['durationDays'] as int?;
          if (dur == null) {
            activePhase = phase;
            break;
          }
          accumulated += dur;
          if (daysElapsed < accumulated) {
            activePhase = phase;
            break;
          }
        }
        if (activePhase == null) continue; // past all phases
        times = List<String>.from(activePhase['times'] as List);
      } else {
        // Legacy: use schedules table
        final schedules = await (_db.select(_db.schedules)
              ..where((t) => t.medicationId.equals(med.id))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
        times = schedules.map((s) => s.timeOfDay).toList();
      }

      // Generate intakes for each time
      for (final timeStr in times) {
        final parts = timeStr.split(':');
        final scheduledAt = DateTime(
          day.year, day.month, day.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );

        // Check duplicate using medication + scheduledAt
        final exists = await (_db.select(_db.intakes)
              ..where((t) =>
                  t.medicationId.equals(med.id) &
                  t.scheduledAt.equals(scheduledAt)))
            .getSingleOrNull();
        if (exists != null) continue;

        // For phase-based meds, use scheduleId = 0
        final scheduleId = med.phases != null
            ? 0
            : (await (_db.select(_db.schedules)
                      ..where((t) => t.medicationId.equals(med.id))
                      ..limit(1))
                  .getSingleOrNull())
                  ?.id ??
                0;

        await _db.into(_db.intakes).insert(IntakesCompanion.insert(
          scheduleId: scheduleId,
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

    // Compute effective endDate: prefer stored endDate, fallback to phase sum
    DateTime? effectiveEnd = med.endDate;
    if (effectiveEnd == null && med.phases != null) {
      final phases = List<Map<String, dynamic>>.from(
        jsonDecode(med.phases!) as List,
      );
      int totalDays = 0;
      bool hasPermanent = false;
      for (final p in phases) {
        final dur = p['durationDays'] as int?;
        if (dur == null) {
          hasPermanent = true;
          break;
        }
        totalDays += dur;
      }
      if (!hasPermanent) {
        effectiveEnd = DateTime(
          med.startDate.year,
          med.startDate.month,
          med.startDate.day,
        ).add(Duration(days: totalDays));
      }
    }

    if (effectiveEnd != null && date.isAfter(effectiveEnd)) return false;

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
