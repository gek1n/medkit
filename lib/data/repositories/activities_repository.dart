import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/notification_service.dart';

class ActivitiesRepository {
  final AppDatabase _db;
  final Ref _ref;
  ActivitiesRepository(this._db, this._ref);

  void _triggerFamilySync(int memberId) {
    unawaited(FamilySyncService(_db).syncChannelForMember(memberId));
    unawaited(FamilyPeerSyncService(_db).syncAllPeers());
  }

  Stream<List<Activity>> watchByMember(int memberId) =>
      (_db.select(_db.activities)
            ..where((t) =>
                t.memberId.equals(memberId) & t.isActive.equals(true)))
          .watch();

  Stream<List<Activity>> watchAll() =>
      (_db.select(_db.activities)..where((t) => t.isActive.equals(true)))
          .watch();

  // Всі активні рутини з реальною ротацією (пул > 1) — для загального
  // сімейного огляду "чия сьогодні черга" без перемикання профілів.
  Stream<List<Activity>> watchAllRotating() {
    return (_db.select(_db.activities)
          ..where((t) =>
              t.isActive.equals(true) & t.rotationMode.equals('fixed').not()))
        .watch();
  }

  // Для Простору — рутини, прив'язані до конкретного розділу.
  Stream<List<Activity>> watchBySection(int sectionId) =>
      (_db.select(_db.activities)
            ..where((t) =>
                t.sectionId.equals(sectionId) & t.isActive.equals(true)))
          .watch();

  // isActive.equals(true) — інакше після softDelete (isActive=false)
  // RoutineViewScreen продовжував би показувати щойно "видалену" рутину
  // замість того, щоб закритись (єдиний споживач цього методу).
  Stream<Activity?> watchById(int id) =>
      (_db.select(_db.activities)
            ..where((t) => t.id.equals(id) & t.isActive.equals(true)))
          .watchSingleOrNull();

  Future<int> countByMember(int memberId) async {
    final rows = await (_db.select(_db.activities)
          ..where((t) =>
              t.memberId.equals(memberId) & t.isActive.equals(true)))
        .get();
    return rows.length;
  }

  Future<List<ActivitySlot>> getSlotsForActivity(int activityId) =>
      (_db.select(_db.activitySlots)
            ..where((t) => t.activityId.equals(activityId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  // Рутини "без фіксованого часу" (ActivitySlots порожній — див. коментар в
  // ActivityLogGenerator) — id активностей члена сім'ї, чиї ActivityLogs слід
  // показувати поза звичайним бакетингом пропущено/зараз/незабаром (див.
  // today_screen.dart _AnytimeRoutinesSection).
  Stream<Set<int>> watchNoFixedTimeActivityIds(int memberId) {
    return (_db.select(_db.activities)
          ..where(
              (t) => t.memberId.equals(memberId) & t.isActive.equals(true)))
        .watch()
        .asyncMap((acts) async {
      final result = <int>{};
      for (final a in acts) {
        final slots = await getSlotsForActivity(a.id);
        if (slots.isEmpty) result.add(a.id);
      }
      return result;
    });
  }

  Future<List<ActivityLog>> getLogsByMemberAndDate(
    int memberId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.activityLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end)))
        .get();
  }

  Stream<List<ActivityLog>> watchLogsByMemberAndDate(
    int memberId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.activityLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end)))
        .watch();
  }

  Future<int> insertActivity(ActivitiesCompanion activity) async {
    final id = await _db.into(_db.activities).insert(activity);
    if (activity.memberId.present) _triggerFamilySync(activity.memberId.value);
    return id;
  }

  Future<void> insertSlots(List<ActivitySlotsCompanion> slots) async {
    for (final s in slots) {
      await _db.into(_db.activitySlots).insert(s);
    }
  }

  Future<void> replaceSlots(
    int activityId,
    List<ActivitySlotsCompanion> slots,
  ) async {
    await (_db.delete(_db.activitySlots)
          ..where((t) => t.activityId.equals(activityId)))
        .go();
    await insertSlots(slots);
  }

  // [actingMemberId] — хто фактично натиснув "виконано"; може відрізнятись
  // від log.memberId (чия черга) — відмітити може будь-який член сім'ї.
  Future<void> markLogDone(int id, {int? actingMemberId}) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id))).write(
      ActivityLogsCompanion(
        status: const Value('done'),
        completedByMemberId: Value(actingMemberId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await NotificationService.cancelActivityReminder(id);
    await _triggerFamilySyncForLog(id);
  }

  Future<void> markLogSkipped(int id) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id)))
        .write(ActivityLogsCompanion(status: const Value('skipped'), updatedAt: Value(DateTime.now())));
    await NotificationService.cancelActivityReminder(id);
    await _triggerFamilySyncForLog(id);
  }

  // Тогл одного підкроку чек-листа для конкретного дня — статус логу
  // перераховується автоматично: жодного підкроку -> pending, частина ->
  // partial, усі -> done (ADHD-дружній "м'який" прогрес, без окремого
  // обов'язкового натискання "готово" після останнього підкроку).
  Future<void> toggleLogStep(
    int logId,
    int stepIndex,
    int totalSteps, {
    required int actingMemberId,
  }) async {
    final log = await (_db.select(_db.activityLogs)
          ..where((t) => t.id.equals(logId)))
        .getSingleOrNull();
    if (log == null) return;
    var completed = <int>{};
    try {
      completed =
          Set<int>.from(jsonDecode(log.completedStepsJson ?? '[]') as List);
    } catch (_) {}
    if (completed.contains(stepIndex)) {
      completed.remove(stepIndex);
    } else {
      completed.add(stepIndex);
    }
    final status = completed.isEmpty
        ? 'pending'
        : (completed.length >= totalSteps ? 'done' : 'partial');
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(logId)))
        .write(
      ActivityLogsCompanion(
        completedStepsJson: Value(jsonEncode(completed.toList()..sort())),
        status: Value(status),
        completedByMemberId: Value(actingMemberId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (status == 'done') {
      await NotificationService.cancelActivityReminder(logId);
    }
    await _triggerFamilySyncForLog(logId);
  }

  // ── Ротація виконавців ────────────────────────────────────────────────

  Stream<List<ActivityAssignee>> watchAssignees(int activityId) {
    return (_db.select(_db.activityAssignees)
          ..where((t) => t.activityId.equals(activityId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<List<ActivityAssignee>> getAssignees(int activityId) =>
      (_db.select(_db.activityAssignees)
            ..where((t) => t.activityId.equals(activityId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> replaceAssignees(int activityId, List<int> memberIds) async {
    await (_db.delete(_db.activityAssignees)
          ..where((t) => t.activityId.equals(activityId)))
        .go();
    for (var i = 0; i < memberIds.length; i++) {
      await _db.into(_db.activityAssignees).insert(
            ActivityAssigneesCompanion.insert(
              activityId: activityId,
              memberId: memberIds[i],
              sortOrder: Value(i),
            ),
          );
    }
  }

  // Чи спрацьовує рутина в цей календарний день (без урахування часу доби —
  // ним опікуються ActivitySlots окремо). weeklyGoal свідомо повертає
  // false — для нього логи не генеруються заздалегідь, див.
  // ActivityLogGenerator/todayProviders.
  Future<bool> occursOnDate(Activity a, DateTime date) async {
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

  // Порядковий номер сьогоднішнього спрацювання від rotationAnchorDate
  // (0-based) — основа для формули ротації. Для кадансу weekly/monthly
  // рахуємо календарні тижні/місяці від якоря (не кількість спрацювань),
  // щоб "черга" трималась цілий тиждень/місяць незалежно від того, скільки
  // разів на тиждень рутина спрацьовує.
  Future<int> _occurrenceIndex(Activity a, DateTime date) async {
    final anchor = a.rotationAnchorDate ?? a.createdAt;
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final day = DateTime(date.year, date.month, date.day);
    switch (a.rotationMode) {
      case 'weekly':
        return (day.difference(anchorDay).inDays) ~/ 7;
      case 'monthly':
        return (day.year - anchorDay.year) * 12 + (day.month - anchorDay.month);
      case 'perOccurrence':
      default:
        var count = -1;
        var cursor = anchorDay;
        while (!cursor.isAfter(day)) {
          if (await occursOnDate(a, cursor)) count++;
          cursor = cursor.add(const Duration(days: 1));
        }
        return count < 0 ? 0 : count;
    }
  }

  // Хто виконує рутину в конкретний день — з урахуванням ротації. Порожній
  // пул чи rotationMode=='fixed' -> завжди Activities.memberId (як і в
  // попередній версії, без ротації).
  Future<int> assigneeForDate(Activity a, DateTime date) async {
    final pool = await getAssignees(a.id);
    if (pool.isEmpty || a.rotationMode == 'fixed' || pool.length == 1) {
      return pool.isEmpty ? a.memberId : pool.first.memberId;
    }
    final occIndex = await _occurrenceIndex(a, date);
    final idx = occIndex % pool.length;
    return pool[idx < 0 ? idx + pool.length : idx].memberId;
  }

  // Обмін черги на конкретного члена сім'ї для одного вже згенерованого
  // логу — формула ротації для МАЙБУТНІХ днів не зачіпається (вона
  // рахується наново при кожній генерації, не зберігається).
  Future<void> reassignLog(int logId, int newMemberId) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(logId)))
        .write(ActivityLogsCompanion(
      memberId: Value(newMemberId),
      updatedAt: Value(DateTime.now()),
    ));
    await _triggerFamilySyncForLog(logId);
  }

  // Пропустити чергу — передати наступному по колу пулу без вибору
  // конкретної людини (на відміну від reassignLog).
  Future<void> skipTurn(int logId) async {
    final log = await (_db.select(_db.activityLogs)
          ..where((t) => t.id.equals(logId)))
        .getSingleOrNull();
    if (log == null) return;
    final pool = await getAssignees(log.activityId);
    if (pool.length < 2) return;
    final currentIdx = pool.indexWhere((m) => m.memberId == log.memberId);
    final nextIdx = currentIdx < 0 ? 0 : (currentIdx + 1) % pool.length;
    await reassignLog(logId, pool[nextIdx].memberId);
  }

  // ── weeklyGoal: "N разів на тиждень, будь-які дні" ─────────────────────
  // На відміну від календарних режимів, логи тут НЕ генеруються заздалегідь
  // (occursOnDate завжди false для weeklyGoal) — кожна відмітка створює
  // власний лог "на льоту" з поточним часом.

  Stream<List<Activity>> watchWeeklyGoalsByMember(int memberId) {
    return (_db.select(_db.activities)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.isActive.equals(true) &
              t.repeatType.equals('weeklyGoal')))
        .watch();
  }

  static DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Stream<int> watchWeeklyGoalDoneCount(int activityId, {DateTime? now}) {
    final start = _weekStart(now ?? DateTime.now());
    final end = start.add(const Duration(days: 7));
    final query = _db.select(_db.activityLogs)
      ..where((t) =>
          t.activityId.equals(activityId) &
          t.status.equals('done') &
          t.scheduledAt.isBiggerOrEqualValue(start) &
          t.scheduledAt.isSmallerThanValue(end));
    return query.watch().map((rows) => rows.length);
  }

  Future<void> markWeeklyGoalDone(
    Activity activity, {
    required int actingMemberId,
  }) async {
    final memberId = await assigneeForDate(activity, DateTime.now());
    final logId = await _db.into(_db.activityLogs).insert(
          ActivityLogsCompanion.insert(
            activityId: activity.id,
            memberId: memberId,
            scheduledAt: DateTime.now(),
            status: const Value('done'),
            completedByMemberId: Value(actingMemberId),
          ),
        );
    if (logId > 0) _triggerFamilySync(memberId);
  }

  Future<void> _triggerFamilySyncForLog(int id) async {
    final log = await (_db.select(_db.activityLogs)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (log != null) _triggerFamilySync(log.memberId);
  }

  Future<void> snoozeLog(int id, DateTime newScheduledAt) async {
    await (_db.update(_db.activityLogs)..where((t) => t.id.equals(id)))
        .write(ActivityLogsCompanion(scheduledAt: Value(newScheduledAt), updatedAt: Value(DateTime.now())));
    await NotificationService.cancelActivityReminder(id);

    final log = await (_db.select(_db.activityLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (log == null) return;
    final activity = await (_db.select(_db.activities)
          ..where((t) => t.id.equals(log.activityId)))
        .getSingleOrNull();
    if (activity == null) return;
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(log.memberId)))
        .getSingleOrNull();

    final settings = _ref.read(notificationSettingsProvider);
    final remindAt = settings.adjust(newScheduledAt, memberId: log.memberId);
    if (remindAt != null) {
      await NotificationService.scheduleActivityReminder(
        logId: id,
        memberName: member?.name ?? '',
        activityName: activity.name,
        scheduledAt: remindAt,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
    _triggerFamilySync(log.memberId);
  }

  Future<List<ActivityLog>> getLogsByMemberAndDateRange(
    int memberId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.activityLogs)
            ..where((t) =>
                t.memberId.equals(memberId) &
                t.scheduledAt.isBiggerOrEqualValue(from) &
                t.scheduledAt.isSmallerThanValue(to)))
          .get();

  // Кількість підряд виконаних (status=='done') минулих/поточних входжень,
  // рахуючи від найновішого — той самий "streak", що й у habit-tracker
  // застосунках, мотиваційний показник "чому це рутина, а не просто
  // нагадування". Майбутні (ще не настали) логи пропускаються — вони не
  // мають статусу ще, тож не повинні ні продовжувати, ні обривати серію.
  // Перший-же минулий лог не зі статусом 'done' (пропущено/частково) обриває
  // підрахунок.
  Future<int> computeStreakDays(int activityId) async {
    final now = DateTime.now();
    final logs = await (_db.select(_db.activityLogs)
          ..where((t) => t.activityId.equals(activityId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .get();
    var streak = 0;
    for (final log in logs) {
      if (log.scheduledAt.isAfter(now)) continue;
      if (log.status == 'done') {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> insertLog(ActivityLogsCompanion log) async {
    final id = await _db.into(_db.activityLogs).insert(log);
    if (log.memberId.present) _triggerFamilySync(log.memberId.value);
    return id;
  }

  Future<void> updateActivity(ActivitiesCompanion activity) async {
    // Той самий фікс дублювання, що й у MedicationsRepository.update(): час
    // слотів міг змінитись, тож старі ще не виконані activityLog-рядки на
    // сьогодні/майбутнє відповідають СТАРОМУ розкладу і мають бути прибрані
    // до перегенерації — інакше ActivityLogGenerator додасть поруч ще один
    // лог під новий час, і користувач отримає два нагадування.
    if (activity.id.present) await _cancelFutureStaleLogs(activity.id.value);
    await (_db.update(_db.activities)..where((t) => t.id.equals(activity.id.value)))
        .write(activity);
    final row = await (_db.select(_db.activities)..where((t) => t.id.equals(activity.id.value)))
        .getSingleOrNull();
    if (row != null) _triggerFamilySync(row.memberId);
  }

  Future<void> _cancelFutureStaleLogs(int activityId) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final stale = await (_db.select(_db.activityLogs)
          ..where((t) =>
              t.activityId.equals(activityId) &
              t.status.equals('pending') &
              t.scheduledAt.isBiggerOrEqualValue(cutoff)))
        .get();
    if (stale.isEmpty) return;
    for (final log in stale) {
      await NotificationService.cancelActivityReminder(log.id);
    }
    await (_db.delete(_db.activityLogs)
          ..where((t) => t.id.isIn(stale.map((e) => e.id))))
        .go();
  }

  Future<int> softDelete(int id) async {
    final pending = await (_db.select(_db.activityLogs)
          ..where((t) => t.activityId.equals(id) & t.status.equals('pending')))
        .get();
    for (final log in pending) {
      await NotificationService.cancelActivityReminder(log.id);
    }

    final activity = await (_db.select(_db.activities)..where((t) => t.id.equals(id))).getSingleOrNull();
    final result = await (_db.update(_db.activities)..where((t) => t.id.equals(id)))
        .write(const ActivitiesCompanion(isActive: Value(false)));
    if (activity != null) _triggerFamilySync(activity.memberId);
    return result;
  }
}

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(ref.watch(databaseProvider), ref);
});
