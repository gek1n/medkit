import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/notification_service.dart';

class RemindersRepository {
  final AppDatabase _db;
  final Ref _ref;
  RemindersRepository(this._db, this._ref);

  Stream<List<Reminder>> watchAll() =>
      (_db.select(_db.reminders)
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .watch();

  Stream<Reminder?> watchById(int id) =>
      (_db.select(_db.reminders)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<Reminder>> watchByMember(int memberId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  // Для Простору — нагадування, прив'язані до конкретного розділу.
  Stream<List<Reminder>> watchBySection(int sectionId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  // Для Розкладу — на відміну від watchByMember (використовує й Архів, де
  // потрібна повна історія включно з виконаними/скасованими), тут лише
  // "живі" нагадування. Для daily/weekly/monthly/yearly status завжди
  // лишається 'pending' (нема стану "сьогоднішнього" виконання — див.
  // watchActiveOnDate), тож повторювані нагадування це не ховає, доки серія
  // не видалена цілком.
  Stream<List<Reminder>> watchActiveByMember(int memberId) {
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.memberId.equals(memberId) & t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchUpcoming(int memberId) {
    final now = DateTime.now();
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchByDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  // Час(и) спрацювання КОНКРЕТНОГО нагадування у вказаний день, або
  // порожній список, якщо воно неактивне цього дня — єдине джерело правди
  // для watchActiveOnDate (показ на Сьогодні/Розкладі) і
  // ReminderLogGenerator (per-occurrence лог виконання), щоб їхня логіка
  // не розходилась.
  Future<List<DateTime>> occurrencesOnDate(Reminder r, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final anchorDay =
        DateTime(r.scheduledAt.year, r.scheduledAt.month, r.scheduledAt.day);
    switch (r.repeatType) {
      case 'daily':
        if (anchorDay.isAfter(dayStart)) return const [];
        final slots = await getSlotsForReminder(r.id);
        if (slots.isEmpty) return [dayStart];
        return slots.map((s) => _atTimeOfDay(dayStart, s.timeOfDay)).toList();
      case 'weekly':
        if (anchorDay.isAfter(dayStart)) return const [];
        var days = <int>{};
        try {
          final cfg = jsonDecode(r.repeatConfig) as Map<String, dynamic>;
          days = Set<int>.from(cfg['days'] as List);
        } catch (_) {}
        if (!days.contains(date.weekday)) return const [];
        final slots = await getSlotsForReminder(r.id);
        if (slots.isEmpty) return [dayStart];
        return slots.map((s) => _atTimeOfDay(dayStart, s.timeOfDay)).toList();
      case 'yearly':
        if (r.scheduledAt.month != date.month || r.scheduledAt.day != date.day) {
          return const [];
        }
        return [
          DateTime(date.year, date.month, date.day, r.scheduledAt.hour,
              r.scheduledAt.minute)
        ];
      case 'monthly':
        // scheduledAt.month завжди зафіксовано на січні (форма зберігає
        // якір саме так — див. AddAppointmentScreen), тож тут важливий
        // лише .day; для коротших місяців (напр. 31 у лютому) день
        // клемпиться до останнього дня місяця — так само, як і в
        // NotificationService.scheduleMonthlyReminder.
        final daysInTargetMonth = DateTime(date.year, date.month + 1, 0).day;
        final targetDay = r.scheduledAt.day > daysInTargetMonth
            ? daysInTargetMonth
            : r.scheduledAt.day;
        if (date.day != targetDay) return const [];
        return [
          DateTime(date.year, date.month, date.day, r.scheduledAt.hour,
              r.scheduledAt.minute)
        ];
      default:
        return anchorDay == dayStart ? [r.scheduledAt] : const [];
    }
  }

  // Нагадування, що фактично "спрацьовують" у вказаний день — на відміну
  // від watchByDate (буквальний збіг дати), тут враховуються daily/weekly/
  // monthly/yearly повтори (occurrencesOnDate). Мультислотові daily/weekly
  // розгортаються в окремий Reminder-об'єкт (copyWith) на кожен час —
  // scheduledAt кожної копії підмінюється на реальний час ЦЬОГО дня, щоб
  // існуючий UI (сортування/класифікація за scheduledAt) працював без змін.
  Stream<List<Reminder>> watchActiveOnDate(int memberId, DateTime date) {
    return watchByMember(memberId).asyncMap((reminders) async {
      final result = <Reminder>[];
      for (final r in reminders) {
        final occurrences = await occurrencesOnDate(r, date);
        for (final at in occurrences) {
          result.add(r.copyWith(scheduledAt: at));
        }
      }
      result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return result;
    });
  }

  DateTime _atTimeOfDay(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  // Планує сповіщення для вже вставленого нагадування (реальний id/memberId
  // обов'язкові) — спільна логіка для форми створення й фіналізації
  // онбординг-чернеток (де сповіщення відкладені до появи реального
  // профілю), щоб не дублювати цей switch у двох місцях.
  Future<void> scheduleNotificationsForReminder(
    Reminder reminder, {
    List<String> slotTimes = const [],
  }) async {
    final settings = _ref.read(notificationSettingsProvider);
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(reminder.memberId)))
        .getSingleOrNull();
    final memberName = member?.name ?? '';
    final scheduledAt = reminder.scheduledAt;

    List<(int, int)> adjustedSlots() {
      final adjusted = <(int, int)>[];
      for (final s in slotTimes) {
        final parts = s.split(':');
        final now = DateTime.now();
        final raw = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final at = settings.adjust(raw, memberId: reminder.memberId);
        if (at != null) adjusted.add((at.hour, at.minute));
      }
      return adjusted;
    }

    switch (reminder.repeatType) {
      case 'none':
        final rawReminderAt =
            scheduledAt.subtract(Duration(minutes: reminder.remindBeforeMin));
        final remindAt = settings.adjust(rawReminderAt, memberId: reminder.memberId);
        if (remindAt != null) {
          await NotificationService.scheduleAppointmentReminder(
            appointmentId: reminder.id,
            memberName: memberName,
            doctorType: reminder.doctorType,
            location: reminder.location,
            scheduledAt: remindAt,
            remindBeforeMin: 0,
            vibrationEnabled: settings.vibrationEnabled,
            repeatMinutes: settings.repeatMinutes,
          );
        }
        break;
      case 'yearly':
        {
          final rawReminderAt = scheduledAt
              .subtract(Duration(minutes: reminder.remindBeforeMin));
          final remindAt =
              settings.adjust(rawReminderAt, memberId: reminder.memberId);
          if (remindAt != null) {
            await NotificationService.scheduleYearlyReminder(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              location: reminder.location,
              date: remindAt,
              remindBeforeMin: 0,
              vibrationEnabled: settings.vibrationEnabled,
            );
          }
        }
        break;
      case 'monthly':
        {
          final rawReminderAt = scheduledAt
              .subtract(Duration(minutes: reminder.remindBeforeMin));
          final remindAt =
              settings.adjust(rawReminderAt, memberId: reminder.memberId);
          if (remindAt != null) {
            await NotificationService.scheduleMonthlyReminder(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              location: reminder.location,
              dayOfMonth: remindAt.day,
              hour: remindAt.hour,
              minute: remindAt.minute,
              vibrationEnabled: settings.vibrationEnabled,
            );
          }
        }
        break;
      case 'daily':
        {
          final adjusted = adjustedSlots();
          if (adjusted.isNotEmpty) {
            await NotificationService.scheduleDailyReminderSlots(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              slots: adjusted,
              vibrationEnabled: settings.vibrationEnabled,
            );
          }
        }
        break;
      case 'weekly':
        {
          var weekdays = <int>[];
          try {
            final cfg =
                jsonDecode(reminder.repeatConfig) as Map<String, dynamic>;
            weekdays = List<int>.from(cfg['days'] as List);
          } catch (_) {}
          final adjusted = adjustedSlots();
          if (adjusted.isNotEmpty) {
            await NotificationService.scheduleWeeklyReminderSlots(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              weekdays: weekdays,
              slots: adjusted,
              vibrationEnabled: settings.vibrationEnabled,
            );
          }
        }
        break;
    }
  }

  Future<int> insert(RemindersCompanion appointment) =>
      _db.into(_db.reminders).insert(appointment);

  Future<List<ReminderSlot>> getSlotsForReminder(int reminderId) =>
      (_db.select(_db.reminderSlots)
            ..where((t) => t.reminderId.equals(reminderId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> replaceSlots(
    int reminderId,
    List<ReminderSlotsCompanion> slots,
  ) async {
    await (_db.delete(_db.reminderSlots)
          ..where((t) => t.reminderId.equals(reminderId)))
        .go();
    for (final s in slots) {
      await _db.into(_db.reminderSlots).insert(s);
    }
  }

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(RemindersCompanion appointment) async {
    final rows = await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(appointment.id.value)))
        .write(appointment);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  Future<void> markAttended(int id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      status: const Value('attended'),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);
  }

  Future<void> markSkipped(int id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      status: const Value('skipped'),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);
  }

  Future<void> reschedule(int id, DateTime newTime) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      scheduledAt: Value(newTime),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);

    final appt = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (appt == null) return;
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(appt.memberId)))
        .getSingleOrNull();

    final settings = _ref.read(notificationSettingsProvider);
    final rawReminderAt =
        newTime.subtract(Duration(minutes: appt.remindBeforeMin));
    final remindAt = settings.adjust(rawReminderAt, memberId: appt.memberId);
    if (remindAt != null) {
      await NotificationService.scheduleAppointmentReminder(
        appointmentId: id,
        memberName: member?.name ?? '',
        doctorType: appt.doctorType,
        location: appt.location,
        scheduledAt: remindAt,
        remindBeforeMin: 0,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
  }

  // ── ReminderLogs: per-occurrence виконання для daily/weekly/monthly/
  // yearly (репетувані serії) — окремо від Reminders.status, який має сенс
  // лише для repeatType=='none'. Не чіпає саме сповіщення (воно нативно-
  // повторюване, планується один раз при збереженні) — лише позначає
  // "зроблено/пропущено сьогодні" для відображення на Сьогодні.

  Stream<List<ReminderLog>> watchLogsByMemberAndDate(
    int memberId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.reminderLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Future<void> markLogDone(int logId) => (_db.update(_db.reminderLogs)
        ..where((t) => t.id.equals(logId)))
      .write(ReminderLogsCompanion(
        status: const Value('done'),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> markLogSkipped(int logId) => (_db.update(_db.reminderLogs)
        ..where((t) => t.id.equals(logId)))
      .write(ReminderLogsCompanion(
        status: const Value('skipped'),
        updatedAt: Value(DateTime.now()),
      ));

  // Лише переносить відображення на Сьогодні (сам натив-повторюваний алярм
  // ОС не можна перепланувати для "тільки цього випадку" — див. коментар
  // над ReminderLogs) — тому snoozedUntil суто локальний UI-стан.
  Future<void> snoozeLog(int logId, DateTime until) =>
      (_db.update(_db.reminderLogs)..where((t) => t.id.equals(logId))).write(
        ReminderLogsCompanion(
          snoozedUntil: Value(until),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

final remindersRepositoryProvider =
    Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.watch(databaseProvider), ref);
});
