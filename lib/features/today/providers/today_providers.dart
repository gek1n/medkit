import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/members_repository.dart';
import '../../../data/repositories/intakes_repository.dart';
import '../../../data/repositories/activities_repository.dart';
import '../../../data/repositories/medications_repository.dart';
import '../../../data/repositories/reminders_repository.dart';
import '../../../data/repositories/wellbeing_repository.dart';
import '../../../core/services/intake_generator.dart';
import '../../../core/services/activity_log_generator.dart';
import '../../../core/services/reminder_log_generator.dart';

// Активний профіль (null = власник за замовчуванням)
final activeMemberIdProvider = StateProvider<int?>((_) => null);

// Запит на перемикання вкладки нижньої навігації з екрана, що не є _Shell
// (напр. "Переглянути як X" з Сім'ї одразу відкриває Сьогодні). _Shell в
// main.dart слухає цей провайдер і скидає його в null одразу після переходу.
final requestedTabIndexProvider = StateProvider<int?>((_) => null);

// Поточний власник (перший запуск — null)
final currentMemberProvider = StreamProvider<Member?>((ref) {
  final activeId = ref.watch(activeMemberIdProvider);
  return ref.watch(membersRepositoryProvider).watchAll().map(
        (members) {
          if (members.isEmpty) return null;
          if (activeId != null) {
            return members.firstWhere(
              (m) => m.id == activeId,
              orElse: () => members.firstWhere(
                (m) => m.role == 'owner',
                orElse: () => members.first,
              ),
            );
          }
          return members.firstWhere(
            (m) => m.role == 'owner',
            orElse: () => members.first,
          );
        },
      );
});

// Розмір шрифту, який реально застосовується для поточного профілю.
// Кожен профіль (включно з dependent) має власне поле fontSize, і екран
// налаштувань дозволяє його редагувати завжди (canEditFontSize = true в
// ProfileScreen) — тож тут просто читаємо значення активного профілю, без
// підміни на власника. (Раніше тут форсовано підставлялось fontSize
// власника для dependent-профілів — через що зміна розміру шрифту, поки
// активний саме dependent, візуально взагалі нічого не міняла.)
final effectiveFontSizeProvider = Provider<int>((ref) {
  final current = ref.watch(currentMemberProvider).valueOrNull;
  return current?.fontSize ?? 2;
});

// Всі члени сім'ї
final allMembersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(membersRepositoryProvider).watchAll();
});

// Прийоми на сьогодні для конкретного члена
final todayIntakesProvider =
    StreamProvider.family<List<Intake>, int>((ref, memberId) {
  return ref
      .watch(intakesRepositoryProvider)
      .watchByMemberAndDate(memberId, DateTime.now());
});

// Активності на сьогодні для конкретного члена
final todayActivityLogsProvider =
    StreamProvider.family<List<ActivityLog>, int>((ref, memberId) {
  return ref
      .watch(activitiesRepositoryProvider)
      .watchLogsByMemberAndDate(memberId, DateTime.now());
});

// Останній запис самопочуття
final lastWellbeingProvider =
    FutureProvider.family<WellbeingLog?, int>((ref, memberId) {
  return ref.watch(wellbeingRepositoryProvider).getLastByMember(memberId);
});

// Розклад самопочуття для члена сім'ї
final todayWellbeingScheduleProvider =
    StreamProvider.family<WellbeingSchedule?, int>((ref, memberId) {
  return ref.watch(wellbeingRepositoryProvider).watchScheduleByMember(memberId);
});

// Зрізи самопочуття за сьогодні
final todayWellbeingLogsProvider =
    StreamProvider.family<List<WellbeingLog>, int>((ref, memberId) {
  return ref.watch(wellbeingRepositoryProvider).watchTodayLogs(memberId, DateTime.now());
});

// Агреговані показники виконання ЛЮБИХ завдань (ліки + нагадування + рутини
// + самопочуття) на сьогодні для члена сім'ї — те саме часове вікно
// "пропущено" (>15хв прострочено), що й бакетинг на Сьогодні (_TodayContent),
// але тут лише голі лічильники для бейджів у стрічці сім'ї/на екрані Сім'я.
// Рутини без фіксованого часу враховуються у виконано/всього, але ніколи в
// пропущено — так само, як окрема секція "будь-коли" на Сьогодні.
final familyMemberTodayProgressProvider =
    Provider.family<({int done, int total, int missed}), int>((ref, memberId) {
  final intakes = ref.watch(todayIntakesProvider(memberId)).valueOrNull ?? [];
  final activityLogs =
      ref.watch(todayActivityLogsProvider(memberId)).valueOrNull ?? [];
  final noFixedTimeIds =
      ref.watch(todayNoFixedTimeActivityIdsProvider(memberId)).valueOrNull ??
          <int>{};
  // watchActiveOnDate дає окрему копію Reminder (той самий id) на кожен
  // слот мультислотового daily/weekly — дедуп за id обов'язковий тут,
  // інакше .where(reminderId==r.id) нижче знайде ті самі ReminderLogs по
  // кілька разів (по копії на слот) і роздує total/done/missed.
  final reminders = {
    for (final r in ref.watch(todayAppointmentsProvider(memberId)).valueOrNull ?? <Reminder>[])
      r.id: r,
  }.values.toList();
  final reminderLogs =
      ref.watch(todayReminderLogsProvider(memberId)).valueOrNull ?? [];
  final wbSchedule =
      ref.watch(todayWellbeingScheduleProvider(memberId)).valueOrNull;
  final wbLogs =
      ref.watch(todayWellbeingLogsProvider(memberId)).valueOrNull ?? [];

  final now = DateTime.now();
  final activeWindowStart = now.subtract(const Duration(minutes: 15));

  var done = 0;
  var total = 0;
  var missed = 0;

  DateTime effectiveDue(Intake i) =>
      i.status == 'snoozed' && i.snoozedUntil != null
          ? i.snoozedUntil!
          : i.scheduledAt;

  total += intakes.length;
  done += intakes.where((i) => i.status == 'taken').length;
  missed += intakes
      .where((i) =>
          (i.status == 'pending' || i.status == 'snoozed') &&
          effectiveDue(i).isBefore(activeWindowStart))
      .length;

  // Той самий expand, що й _ApptOccurrence на Сьогодні: repeatType=='none' —
  // з самого Reminder, повторювані — по одному запису на кожен ReminderLog.
  final occurrences = reminders.expand((r) {
    if (r.repeatType == 'none') {
      return [(status: r.status, scheduledAt: r.scheduledAt)];
    }
    return reminderLogs.where((l) => l.reminderId == r.id).map(
          (l) =>
              (status: l.status, scheduledAt: l.snoozedUntil ?? l.scheduledAt),
        );
  });
  for (final o in occurrences) {
    total++;
    if (o.status == 'attended' || o.status == 'done') done++;
    if (o.status == 'pending' && o.scheduledAt.isBefore(activeWindowStart)) {
      missed++;
    }
  }

  total += activityLogs.length;
  done += activityLogs
      .where((l) => l.status == 'done' || l.status == 'skipped')
      .length;
  missed += activityLogs
      .where((l) =>
          l.status == 'pending' &&
          !noFixedTimeIds.contains(l.activityId) &&
          l.scheduledAt.isBefore(activeWindowStart))
      .length;

  if (wbSchedule != null && wbSchedule.isActive) {
    List<String> times;
    try {
      times = List<String>.from(jsonDecode(wbSchedule.times) as List);
    } catch (_) {
      times = const [];
    }
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final slots = times.map((t) {
      final p = t.split(':');
      return DateTime(
          today.year, today.month, today.day, int.parse(p[0]), int.parse(p[1]));
    }).toList()
      ..sort();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final windowEnd = i + 1 < slots.length ? slots[i + 1] : endOfDay;
      final hasLog = wbLogs.any((l) =>
          l.loggedAt.isAfter(slot.subtract(const Duration(minutes: 30))) &&
          l.loggedAt.isBefore(windowEnd));
      if (slot.isAfter(now) && !hasLog) continue;
      total++;
      if (hasLog) {
        done++;
      } else if (slot.isBefore(activeWindowStart)) {
        missed++;
      }
    }
  }

  return (done: done, total: total, missed: missed);
});

// Генерація прийомів при відкритті екрану
final generateTodayIntakesProvider = FutureProvider<void>((ref) async {
  await ref.watch(intakeGeneratorProvider).generateForDay(DateTime.now());
});

// Генерація логів активностей при відкритті екрану
final generateTodayActivityLogsProvider = FutureProvider<void>((ref) async {
  await ref.watch(activityLogGeneratorProvider).generateForDay(DateTime.now());
});

// Генерація per-occurrence логів повторюваних нагадувань при відкритті екрану
final generateTodayReminderLogsProvider = FutureProvider<void>((ref) async {
  await ref.watch(reminderLogGeneratorProvider).generateForDay(DateTime.now());
});

// Активні ліки члена сім'ї (для відображення фото та деталей)
final todayMedicationsProvider =
    StreamProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).watchByMember(memberId);
});

// Активності — для резолву назви/типу/кроків по activityId з ActivityLog.
// Навмисно ВСІ активні активності родини, а не watchByMember(memberId): для
// ротаційної рутини (>1 виконавець) ActivityLog.memberId — це той, чия
// сьогодні черга (assigneeForDate), а не Activity.memberId (той, хто рутину
// створив) — тож коли черга дійшла до локального залежного профілю, його
// власний watchByMember НІКОЛИ не містив би цю рутину, і картка на
// Сьогодні показувала б заглушку "Активність" замість реальної назви й
// кнопок (чекліст/зміна черги) — саме так і виглядав баг.
final todayActivitiesProvider =
    StreamProvider.family<List<Activity>, int>((ref, memberId) {
  return ref.watch(activitiesRepositoryProvider).watchAll();
});

// Id рутин без фіксованого часу — див. ActivitiesRepository.
// watchNoFixedTimeActivityIds. Такі ActivityLog виводяться в окрему секцію
// "будь-коли сьогодні" замість пропущено/зараз/незабаром.
final todayNoFixedTimeActivityIdsProvider =
    StreamProvider.family<Set<int>, int>((ref, memberId) {
  return ref
      .watch(activitiesRepositoryProvider)
      .watchNoFixedTimeActivityIds(memberId);
});

// Завтра: прийоми
final tomorrowIntakesProvider =
    FutureProvider.family<List<Intake>, int>((ref, memberId) async {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  await ref.read(intakeGeneratorProvider).generateForDay(tomorrow);
  return ref.read(intakesRepositoryProvider).getByMemberAndDate(memberId, tomorrow);
});

// Завтра: логи активностей
final tomorrowActivityLogsProvider =
    FutureProvider.family<List<ActivityLog>, int>((ref, memberId) async {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  await ref.read(activityLogGeneratorProvider).generateForDay(tomorrow);
  return ref.read(activitiesRepositoryProvider).getLogsByMemberAndDate(memberId, tomorrow);
});

// Завтра: нагадування (включно з daily/weekly/yearly повторами, активними
// саме завтра — не лише тими, чий якір scheduledAt буквально завтра)
final tomorrowAppointmentsProvider =
    FutureProvider.family<List<Reminder>, int>((ref, memberId) async {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return ref
      .read(remindersRepositoryProvider)
      .watchActiveOnDate(memberId, tomorrow)
      .first;
});

// Нагадування на сьогодні (включно з daily/weekly/yearly повторами)
final todayAppointmentsProvider =
    StreamProvider.family<List<Reminder>, int>((ref, memberId) {
  return ref
      .watch(remindersRepositoryProvider)
      .watchActiveOnDate(memberId, DateTime.now());
});

// Per-occurrence логи повторюваних нагадувань на сьогодні (для реальних
// кнопок Виконати/Пропустити/Перенести замість інфо-чипа — repeatType !=
// 'none' лише, 'none' і далі керується напряму через Reminders.status).
final todayReminderLogsProvider =
    StreamProvider.family<List<ReminderLog>, int>((ref, memberId) {
  return ref
      .watch(remindersRepositoryProvider)
      .watchLogsByMemberAndDate(memberId, DateTime.now());
});
