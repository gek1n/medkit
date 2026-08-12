import 'dart:convert';

import '../../data/db/app_database.dart';

// Чиста логіка "чи потрібно X у цей день" / "у які часи" — винесена з
// IntakeGenerator (_shouldTakeOnDate + вибір times) та дзеркалить
// ActivitiesRepository.occursOnDate, щоб ту саму логіку можна було
// застосувати і для пірів (Крок 11), де немає локального Intake/ActivityLog
// рядка для симуляції — лише синхронізовані визначення
// Medication/Schedule/Activity/ActivitySlot. Локальні IntakeGenerator/
// ActivitiesRepository делегують сюди ж, щоб не тримати логіку в двох
// місцях.

bool medicationOccursOnDate(Medication med, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final start = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
  if (day.isBefore(start)) return false;

  DateTime? effectiveEnd = med.endDate;
  if (effectiveEnd == null && med.phases != null) {
    List<Map<String, dynamic>> phases;
    try {
      phases = List<Map<String, dynamic>>.from(jsonDecode(med.phases!) as List);
    } catch (_) {
      phases = const [];
    }
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
      effectiveEnd = start.add(Duration(days: totalDays));
    }
  }
  if (effectiveEnd != null && day.isAfter(effectiveEnd)) return false;

  Map<String, dynamic> config;
  try {
    config = jsonDecode(med.repeatConfig) as Map<String, dynamic>;
  } catch (_) {
    config = const {};
  }

  switch (med.repeatType) {
    case 'daily':
      return true;
    case 'alternate':
      final diff = day.difference(start).inDays;
      return diff % 2 == 0;
    case 'weekdays':
      List<int> days;
      try {
        days = List<int>.from(config['days'] as List);
      } catch (_) {
        days = const [];
      }
      return days.contains(day.weekday);
    case 'every_n':
      final n = config['n'] as int? ?? 1;
      if (n <= 0) return false;
      final diff = day.difference(start).inDays;
      return diff % n == 0;
    case 'cycle':
      final on = config['on'] as int? ?? 1;
      final off = config['off'] as int? ?? 0;
      final cycleLen = on + off;
      if (cycleLen <= 0) return false;
      final diff = day.difference(start).inDays;
      return diff % cycleLen < on;
    default:
      return true;
  }
}

// Медикамент може мати або фазовий графік (phases на самому Medication),
// або "класичний" список Schedule-рядків — той самий вибір, що й у
// IntakeGenerator._generateForMedication. [schedules] мають бути вже
// відфільтровані по medicationId (і відсортовані — тут сортуємо самі, щоб
// викликач міг передати їх у довільному порядку).
List<String> medicationTimesForDate(
  Medication med,
  List<Schedule> schedules,
  DateTime date,
) {
  final day = DateTime(date.year, date.month, date.day);
  if (med.phases != null) {
    List<Map<String, dynamic>> phases;
    try {
      phases = List<Map<String, dynamic>>.from(jsonDecode(med.phases!) as List);
    } catch (_) {
      return const [];
    }
    final start = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
    final daysElapsed = day.difference(start).inDays;
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
    if (activePhase == null) return const [];
    try {
      return List<String>.from(activePhase['times'] as List);
    } catch (_) {
      return const [];
    }
  }

  final sorted = [...schedules]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return sorted.map((s) => s.timeOfDay).toList();
}

bool activityOccursOnDate(Activity a, DateTime date) {
  final anchor = a.rotationAnchorDate ?? a.createdAt;
  final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day.isBefore(anchorDay)) return false;
  switch (a.repeatType) {
    case 'daily':
      return true;
    case 'monthly':
      final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
      final targetDay = a.repeatDayOfMonth ?? anchorDay.day;
      final clamped = targetDay > daysInMonth ? daysInMonth : targetDay;
      return date.day == clamped;
    case 'everyNDays':
      final interval = a.repeatIntervalDays ?? 1;
      if (interval <= 0) return false;
      final diff = day.difference(anchorDay).inDays;
      return diff % interval == 0;
    case 'weeklyGoal':
      return false;
    case 'weekly':
    default:
      var days = <int>{};
      try {
        days = Set<int>.from(jsonDecode(a.repeatDays) as List);
      } catch (_) {}
      return days.contains(date.weekday);
  }
}
