import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/members_repository.dart';
import '../../../data/repositories/intakes_repository.dart';
import '../../../data/repositories/activities_repository.dart';
import '../../../data/repositories/wellbeing_repository.dart';
import '../../../core/services/intake_generator.dart';

// Поточний власник (перший запуск — null)
final currentMemberProvider = StreamProvider<Member?>((ref) {
  return ref.watch(membersRepositoryProvider).watchAll().map(
        (members) => members.isEmpty
            ? null
            : members.firstWhere(
                (m) => m.role == 'owner',
                orElse: () => members.first,
              ),
      );
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
