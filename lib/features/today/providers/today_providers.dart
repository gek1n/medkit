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

// Статистика сім'ї на сьогодні (memberId -> {taken, total})
final familyTodayStatsProvider =
    FutureProvider<Map<int, ({int taken, int total})>>((ref) async {
  final members = await ref.watch(membersRepositoryProvider).watchAll().first;
  final intakesRepo = ref.watch(intakesRepositoryProvider);
  final result = <int, ({int taken, int total})>{};

  for (final m in members) {
    final intakes = await intakesRepo.getByMemberAndDate(m.id, DateTime.now());
    final taken = intakes.where((i) => i.status == 'taken').length;
    result[m.id] = (taken: taken, total: intakes.length);
  }
  return result;
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

// Активності члена сім'ї (для отримання назв/типів)
final todayActivitiesProvider =
    StreamProvider.family<List<Activity>, int>((ref, memberId) {
  return ref.watch(activitiesRepositoryProvider).watchByMember(memberId);
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
