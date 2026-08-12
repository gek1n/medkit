import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/activity_log_generator.dart';
import '../../core/services/intake_generator.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../family/peer_view_providers.dart';
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

typedef _DayKey = ({int memberId, DateTime date});

// Проміжні "живі" (Stream) джерела для scheduleCalendarDayProvider нижче —
// watchByMember/watchXxxByMemberAndDate замість одноразового Future-читання,
// щоб щойно додане завдання (ліки/рутина/нагадування) з'являлось в
// календарі одразу, а не лише після перезапуску застосунку.
final _intakesForDayProvider =
    StreamProvider.family<List<Intake>, _DayKey>((ref, key) {
  return ref.watch(intakesRepositoryProvider).watchByMemberAndDate(key.memberId, key.date);
});

final _activityLogsForDayProvider =
    StreamProvider.family<List<ActivityLog>, _DayKey>((ref, key) {
  return ref
      .watch(activitiesRepositoryProvider)
      .watchLogsByMemberAndDate(key.memberId, key.date);
});

final _remindersActiveOnDayProvider =
    StreamProvider.family<List<Reminder>, _DayKey>((ref, key) {
  return ref.watch(remindersRepositoryProvider).watchActiveOnDate(key.memberId, key.date);
});

final _medsForMemberProvider = StreamProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).watchByMember(memberId);
});

final _activitiesForMemberProvider = StreamProvider.family<List<Activity>, int>((ref, memberId) {
  return ref.watch(activitiesRepositoryProvider).watchByMember(memberId);
});

final _noFixedTimeIdsForMemberProvider =
    StreamProvider.family<Set<int>, int>((ref, memberId) {
  return ref.watch(activitiesRepositoryProvider).watchNoFixedTimeActivityIds(memberId);
});

final _wellbeingScheduleForMemberProvider =
    StreamProvider.family<WellbeingSchedule?, int>((ref, memberId) {
  return ref.watch(wellbeingRepositoryProvider).watchScheduleByMember(memberId);
});

// Всі пункти конкретного дня для конкретного профілю — ліки, рутини,
// нагадування (включно з daily/weekly/yearly повторами) і слоти
// самопочуття. На відміну від першої версії (одноразовий Future-зліпок,
// як tomorrowXxxProvider у today_providers.dart) — тут ref.watch на живі
// Stream-провайдери вище, тож щойно з'являється нове завдання (чи міняється
// існуюче), увесь список для цього дня перераховується сам, без потреби
// перезапускати застосунок чи вручну інвалідувати провайдер.
final scheduleCalendarDayProvider =
    FutureProvider.family<List<CalendarItem>, _DayKey>((ref, params) async {
  final date = DateTime(params.date.year, params.date.month, params.date.day);
  final memberId = params.memberId;

  // Побічний ефект — дозаповнити Intakes/ActivityLogs для цього дня, якщо
  // генератор ще не встиг. Ідемпотентно (вставляє лише відсутнє), тож
  // безпечно викликати щоразу, коли провайдер перераховується через будь-
  // який watch нижче.
  await ref.read(intakeGeneratorProvider).generateForDay(date);
  await ref.read(activityLogGeneratorProvider).generateForDay(date);

  final dayKey = (memberId: memberId, date: date);
  final intakes = ref.watch(_intakesForDayProvider(dayKey)).valueOrNull ?? const [];
  final activityLogs = ref.watch(_activityLogsForDayProvider(dayKey)).valueOrNull ?? const [];
  final reminders = ref.watch(_remindersActiveOnDayProvider(dayKey)).valueOrNull ?? const [];
  final wbSchedule = ref.watch(_wellbeingScheduleForMemberProvider(memberId)).valueOrNull;
  final meds = ref.watch(_medsForMemberProvider(memberId)).valueOrNull ?? const [];
  final activities = ref.watch(_activitiesForMemberProvider(memberId)).valueOrNull ?? const [];
  final noFixedTimeIds =
      ref.watch(_noFixedTimeIdsForMemberProvider(memberId)).valueOrNull ?? const {};

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

typedef _PeerDayKey = ({String personUuid, DateTime date});

// Той самий принцип, що й scheduleCalendarDayProvider вище, але з уже
// перекладеного кешу даних піра (Крок 4.3/Крок 11), а не з локальної БД.
// intake/activity_log НЕ беруться напряму з синку піра — ці типи windowed
// (FamilyServerSyncService._windowedTypes) і існують лише якщо суб'єкт сам
// відкривав застосунок і синкався сьогодні; замість цього
// peerVirtual*ForDateProvider (peer_view_providers.dart) обчислює
// "сьогоднішні" екземпляри тут же з визначень (Medication/Schedule,
// Activity/ActivitySlot) — той самий принцип, що вже й так
// застосовувався для Нагадувань (occurrencesOnDateForSlots нижче).
final peerScheduleCalendarDayProvider =
    Provider.family<List<CalendarItem>, _PeerDayKey>((ref, params) {
  final date = DateTime(params.date.year, params.date.month, params.date.day);
  final end = date.add(const Duration(days: 1));
  bool onDay(DateTime dt) => !dt.isBefore(date) && dt.isBefore(end);

  final memberId = peerSyntheticId(params.personUuid);
  // Віртуальні (обчислені локально з визначень) екземпляри — не напряму
  // peerIntakesProvider/peerActivityLogsProvider, ті порожні для конкретного
  // дня, доки суб'єкт сам не згенерує+засинкає його (windowed-типи, див.
  // peer_view_providers.dart). Дублює today_screen.dart peer-гілку.
  final intakes = ref.watch(peerVirtualIntakesForDateProvider((params.personUuid, date)));
  final activityLogs =
      ref.watch(peerVirtualActivityLogsForDateProvider((params.personUuid, date)));
  final activities = ref.watch(peerActivitiesProvider(params.personUuid));
  final noFixedTimeIds = ref.watch(peerNoFixedTimeActivityIdsProvider(params.personUuid));
  final meds = ref.watch(peerMedicationsProvider(params.personUuid));
  final reminders = ref.watch(peerRemindersProvider(params.personUuid));
  final reminderSlots = ref.watch(peerReminderSlotsProvider(params.personUuid));
  final wbSchedule = ref.watch(peerWellbeingSchedulesProvider(params.personUuid)).firstOrNull;
  final remindersRepo = ref.watch(remindersRepositoryProvider);

  final medsById = {for (final m in meds) m.id: m};
  final activitiesById = {for (final a in activities) a.id: a};

  final items = <CalendarItem>[];

  for (final i in intakes) {
    if (!onDay(i.scheduledAt)) continue;
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
    if (!onDay(log.scheduledAt)) continue;
    final activity = activitiesById[log.activityId];
    if (activity == null || !activity.isActive) continue;
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
    final slots = reminderSlots.where((s) => s.reminderId == r.id).toList();
    List<DateTime> occurrences;
    try {
      occurrences = remindersRepo.occurrencesOnDateForSlots(r, date, slots);
    } catch (_) {
      occurrences = const [];
    }
    for (final at in occurrences) {
      items.add(CalendarItem(
        time: at,
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
