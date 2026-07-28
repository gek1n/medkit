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

  Stream<List<Reminder>> watchByMember(int memberId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.memberId.equals(memberId))
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

  // Нагадування, що фактично "спрацьовують" у вказаний день — на відміну
  // від watchByDate (буквальний збіг дати), тут враховуються daily/weekly/
  // yearly повтори: scheduledAt для них лише якір (дата створення/перший
  // випадок), а не дата конкретного дня. Мультислотові daily/weekly
  // розгортаються в окремий Reminder-об'єкт (copyWith) на кожен час —
  // scheduledAt кожної копії підмінюється на реальний час ЦЬОГО дня, щоб
  // існуючий UI (сортування/класифікація за scheduledAt) працював без змін.
  Stream<List<Reminder>> watchActiveOnDate(int memberId, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return watchByMember(memberId).asyncMap((reminders) async {
      final result = <Reminder>[];
      for (final r in reminders) {
        final anchorDay =
            DateTime(r.scheduledAt.year, r.scheduledAt.month, r.scheduledAt.day);
        switch (r.repeatType) {
          case 'daily':
            if (anchorDay.isAfter(dayStart)) continue;
            final slots = await getSlotsForReminder(r.id);
            if (slots.isEmpty) {
              result.add(r.copyWith(scheduledAt: dayStart));
            } else {
              for (final s in slots) {
                result.add(r.copyWith(
                    scheduledAt: _atTimeOfDay(dayStart, s.timeOfDay)));
              }
            }
            break;
          case 'weekly':
            if (anchorDay.isAfter(dayStart)) continue;
            var days = <int>{};
            try {
              final cfg = jsonDecode(r.repeatConfig) as Map<String, dynamic>;
              days = Set<int>.from(cfg['days'] as List);
            } catch (_) {}
            if (!days.contains(date.weekday)) continue;
            final slots = await getSlotsForReminder(r.id);
            if (slots.isEmpty) {
              result.add(r.copyWith(scheduledAt: dayStart));
            } else {
              for (final s in slots) {
                result.add(r.copyWith(
                    scheduledAt: _atTimeOfDay(dayStart, s.timeOfDay)));
              }
            }
            break;
          case 'yearly':
            if (r.scheduledAt.month != date.month ||
                r.scheduledAt.day != date.day) {
              continue;
            }
            result.add(r.copyWith(
              scheduledAt: DateTime(date.year, date.month, date.day,
                  r.scheduledAt.hour, r.scheduledAt.minute),
            ));
            break;
          default:
            if (anchorDay == dayStart) result.add(r);
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
}

final remindersRepositoryProvider =
    Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.watch(databaseProvider), ref);
});
