import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/activity_log_generator.dart';
import '../../core/services/intake_generator.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import 'schedule_category.dart';

enum CalendarItemType { medication, reminder, routine, wellbeing }

// Один пункт календарного вигляду Розкладу — уже "сплющений" в конкретний
// час(або без часу) для КОНКРЕТНОГО дня, на відміну від Medication/Activity/
// Reminder, які описують курс/серію в цілому. title навмисно НЕ включає
// локалізовані підписи (напр. "Самопочуття") — це рівень UI (schedule_
// calendar_view.dart має BuildContext, цей файл — ні).
class CalendarItem {
  final DateTime? time; // null = "Без часу"
  final String title;
  final bool recurring;
  final ScheduleCategory category;
  final CalendarItemType type;
  final int id; // medicationId / reminderId / activityId / memberId (wellbeing)
  final int memberId;
  // Тайбрейк при однаковому часі: спершу дата створення батьківського
  // запису (курсу/рутини/нагадування), далі — id самого запису дня
  // (Intake/ActivityLog/Reminder), що й так монотонний.
  final DateTime? createdAt;
  final int sortId;

  const CalendarItem({
    required this.time,
    required this.title,
    required this.recurring,
    required this.category,
    required this.type,
    required this.id,
    required this.memberId,
    required this.createdAt,
    required this.sortId,
  });
}

int compareCalendarItems(CalendarItem a, CalendarItem b) {
  final at = a.time;
  final bt = b.time;
  if (at != null && bt != null) {
    final byTime = at.compareTo(bt);
    if (byTime != 0) return byTime;
  }
  final ac = a.createdAt;
  final bc = b.createdAt;
  if (ac != null && bc != null) {
    final byCreated = ac.compareTo(bc);
    if (byCreated != 0) return byCreated;
  }
  return a.sortId.compareTo(b.sortId);
}

// Всі пункти конкретного дня для конкретного профілю — ліки, рутини,
// нагадування (включно з daily/weekly/yearly повторами) і слоти
// самопочуття. Той самий підхід, що й tomorrowXxxProvider у
// today_providers.dart: FutureProvider (не Stream) — довільний день, не
// лише "сьогодні"/"завтра", генератори викликаються перед читанням, щоб
// Intakes/ActivityLogs для цього дня вже існували в базі.
final scheduleCalendarDayProvider =
    FutureProvider.family<List<CalendarItem>, ({int memberId, DateTime date})>(
        (ref, params) async {
  final date = DateTime(params.date.year, params.date.month, params.date.day);
  final memberId = params.memberId;

  await ref.read(intakeGeneratorProvider).generateForDay(date);
  await ref.read(activityLogGeneratorProvider).generateForDay(date);

  final intakesRepo = ref.read(intakesRepositoryProvider);
  final activitiesRepo = ref.read(activitiesRepositoryProvider);
  final remindersRepo = ref.read(remindersRepositoryProvider);
  final wellbeingRepo = ref.read(wellbeingRepositoryProvider);
  final medsRepo = ref.read(medicationsRepositoryProvider);

  final intakes = await intakesRepo.getByMemberAndDate(memberId, date);
  final activityLogs = await activitiesRepo.getLogsByMemberAndDate(memberId, date);
  final reminders = await remindersRepo.watchActiveOnDate(memberId, date).first;
  final wbSchedule = await wellbeingRepo.watchScheduleByMember(memberId).first;
  final meds = await medsRepo.watchByMember(memberId).first;
  final activities = await activitiesRepo.watchByMember(memberId).first;
  final noFixedTimeIds = await activitiesRepo.watchNoFixedTimeActivityIds(memberId).first;

  final medsById = {for (final m in meds) m.id: m};
  final activitiesById = {for (final a in activities) a.id: a};

  final items = <CalendarItem>[];

  for (final i in intakes) {
    final med = medsById[i.medicationId];
    if (med == null) continue;
    items.add(CalendarItem(
      time: i.scheduledAt,
      title: med.name,
      recurring: med.repeatType != 'none',
      category: ScheduleCategory.meds,
      type: CalendarItemType.medication,
      id: med.id,
      memberId: memberId,
      createdAt: med.createdAt,
      sortId: i.id,
    ));
  }

  for (final log in activityLogs) {
    final activity = activitiesById[log.activityId];
    if (activity == null) continue;
    final noTime = noFixedTimeIds.contains(activity.id);
    items.add(CalendarItem(
      time: noTime ? null : log.scheduledAt,
      title: activity.name,
      recurring: activity.repeatType != 'none',
      category: ScheduleCategory.routine,
      type: CalendarItemType.routine,
      id: activity.id,
      memberId: memberId,
      createdAt: activity.createdAt,
      sortId: log.id,
    ));
  }

  for (final r in reminders) {
    items.add(CalendarItem(
      time: r.scheduledAt,
      title: r.doctorType,
      recurring: r.repeatType != 'none',
      category: ScheduleCategory.reminders,
      type: CalendarItemType.reminder,
      id: r.id,
      memberId: memberId,
      createdAt: r.createdAt,
      sortId: r.id,
    ));
  }

  if (wbSchedule != null && wbSchedule.isActive) {
    List<String> times;
    try {
      times = List<String>.from(jsonDecode(wbSchedule.times) as List);
    } catch (_) {
      times = const [];
    }
    for (final t in times) {
      final parts = t.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      // title порожній — schedule_calendar_view.dart підставляє
      // context.l10n.sectionWellbeing (див. коментар класу вище).
      items.add(CalendarItem(
        time: DateTime(date.year, date.month, date.day, h, m),
        title: '',
        recurring: true,
        category: ScheduleCategory.wellbeing,
        type: CalendarItemType.wellbeing,
        id: memberId,
        memberId: memberId,
        createdAt: wbSchedule.updatedAt,
        sortId: h * 60 + m,
      ));
    }
  }

  items.sort(compareCalendarItems);
  return items;
});
