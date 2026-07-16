import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/notification_settings_provider.dart';
import 'app_logger.dart';
import 'notification_service.dart';

/// Перепланування ВСІХ ще не спрацьованих локальних нагадувань (ліки,
/// активності, лікарі, самопочуття — лише профілі, якими керує цей
/// пристрій, НЕ пір'я, — quiet hours на peer-check ніяк не впливає) під
/// АКТУАЛЬНІ налаштування. Викликається щоразу, коли міняється щось, що
/// впливає на результат `NotificationSettings.adjust()` (тихі години,
/// зсув, чи сам push увімкнено) — [NotificationSettingsNotifier].
///
/// Навіщо: `adjust()` рахується один раз, у момент СТВОРЕННЯ нагадування
/// (генератор ліків/активностей, форма запису до лікаря тощо) — сама зміна
/// налаштувань НІЯК не чіпає вже заплановані `zonedSchedule`. Без цього
/// сервісу "вимкнути сповіщення" зупиняло б лише майбутнє планування, а всі
/// нагадування, заплановані ДО вимкнення, і далі спрацьовували б як було.
class NotificationResyncService {
  final AppDatabase _db;
  final Ref _ref;
  NotificationResyncService(this._db, this._ref);

  Future<void> resyncAll() async {
    try {
      await _resyncIntakes();
      await _resyncActivityLogs();
      await _resyncAppointments();
      await _resyncWellbeing();
    } catch (e, st) {
      AppLogger.logError('NotificationResyncService.resyncAll', e, st);
    }
  }

  Future<void> _resyncIntakes() async {
    final settings = _ref.read(notificationSettingsProvider);
    final pending = await (_db.select(_db.intakes)
          ..where((t) => t.status.equals('pending') | t.status.equals('snoozed')))
        .get();
    for (final intake in pending) {
      await NotificationService.cancelIntakeReminder(intake.id);
      final baseAt = intake.status == 'snoozed' && intake.snoozedUntil != null
          ? intake.snoozedUntil!
          : intake.scheduledAt;
      final remindAt = settings.adjust(baseAt, memberId: intake.memberId);
      if (remindAt == null) continue;
      final med = await (_db.select(_db.medications)
            ..where((t) => t.id.equals(intake.medicationId)))
          .getSingleOrNull();
      if (med == null) continue;
      final member = await (_db.select(_db.members)
            ..where((t) => t.id.equals(intake.memberId)))
          .getSingleOrNull();
      await NotificationService.scheduleIntakeReminder(
        intakeId: intake.id,
        memberName: member?.name ?? '',
        medName: med.name,
        dose: '${med.doseAmount} ${med.doseUnit}',
        scheduledAt: remindAt,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
  }

  Future<void> _resyncActivityLogs() async {
    final settings = _ref.read(notificationSettingsProvider);
    final pending =
        await (_db.select(_db.activityLogs)..where((t) => t.status.equals('pending'))).get();
    for (final log in pending) {
      await NotificationService.cancelActivityReminder(log.id);
      final remindAt = settings.adjust(log.scheduledAt, memberId: log.memberId);
      if (remindAt == null) continue;
      final activity = await (_db.select(_db.activities)
            ..where((t) => t.id.equals(log.activityId)))
          .getSingleOrNull();
      if (activity == null) continue;
      final member = await (_db.select(_db.members)
            ..where((t) => t.id.equals(log.memberId)))
          .getSingleOrNull();
      await NotificationService.scheduleActivityReminder(
        logId: log.id,
        memberName: member?.name ?? '',
        activityName: activity.name,
        scheduledAt: remindAt,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
  }

  Future<void> _resyncAppointments() async {
    final settings = _ref.read(notificationSettingsProvider);
    final pending = await (_db.select(_db.doctorAppointments)
          ..where((t) => t.status.equals('pending')))
        .get();
    for (final appt in pending) {
      await NotificationService.cancelAppointmentReminder(appt.id);
      final rawReminderAt = appt.scheduledAt.subtract(Duration(minutes: appt.remindBeforeMin));
      final remindAt = settings.adjust(rawReminderAt, memberId: appt.memberId);
      if (remindAt == null) continue;
      final member = await (_db.select(_db.members)
            ..where((t) => t.id.equals(appt.memberId)))
          .getSingleOrNull();
      await NotificationService.scheduleAppointmentReminder(
        appointmentId: appt.id,
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

  Future<void> _resyncWellbeing() async {
    final settings = _ref.read(notificationSettingsProvider);
    final schedules =
        await (_db.select(_db.wellbeingSchedules)..where((t) => t.isActive.equals(true))).get();
    for (final sched in schedules) {
      await NotificationService.cancelAllWellbeingForMember(sched.memberId);
      List<String> times;
      try {
        times = List<String>.from(jsonDecode(sched.times) as List);
      } catch (_) {
        continue;
      }
      final member = await (_db.select(_db.members)
            ..where((t) => t.id.equals(sched.memberId)))
          .getSingleOrNull();
      final now = DateTime.now();
      for (var i = 0; i < times.length; i++) {
        final parts = times[i].split(':');
        final raw = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        final at = settings.adjust(raw, memberId: sched.memberId);
        if (at == null) continue;
        await NotificationService.scheduleWellbeingDaily(
          memberId: sched.memberId,
          memberName: member?.name ?? '',
          slotIndex: i,
          hour: at.hour,
          minute: at.minute,
          vibrationEnabled: settings.vibrationEnabled,
        );
      }
    }
  }
}

final notificationResyncServiceProvider = Provider<NotificationResyncService>((ref) {
  return NotificationResyncService(ref.watch(databaseProvider), ref);
});
