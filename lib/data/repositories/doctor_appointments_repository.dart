import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/notification_service.dart';

class DoctorAppointmentsRepository {
  final AppDatabase _db;
  final Ref _ref;
  DoctorAppointmentsRepository(this._db, this._ref);

  Stream<List<DoctorAppointment>> watchAll() =>
      (_db.select(_db.doctorAppointments)
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .watch();

  Stream<List<DoctorAppointment>> watchByMember(int memberId) {
    return (_db.select(_db.doctorAppointments)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<DoctorAppointment>> watchUpcoming(int memberId) {
    final now = DateTime.now();
    return (_db.select(_db.doctorAppointments)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<DoctorAppointment>> watchByDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.doctorAppointments)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Future<int> insert(DoctorAppointmentsCompanion appointment) =>
      _db.into(_db.doctorAppointments).insert(appointment);

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(DoctorAppointmentsCompanion appointment) async {
    final rows = await (_db.update(_db.doctorAppointments)
          ..where((t) => t.id.equals(appointment.id.value)))
        .write(appointment);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.doctorAppointments)..where((t) => t.id.equals(id))).go();

  Future<void> markAttended(int id) async {
    await (_db.update(_db.doctorAppointments)..where((t) => t.id.equals(id)))
        .write(DoctorAppointmentsCompanion(
      status: const Value('attended'),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);
  }

  Future<void> markSkipped(int id) async {
    await (_db.update(_db.doctorAppointments)..where((t) => t.id.equals(id)))
        .write(DoctorAppointmentsCompanion(
      status: const Value('skipped'),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);
  }

  Future<void> reschedule(int id, DateTime newTime) async {
    await (_db.update(_db.doctorAppointments)..where((t) => t.id.equals(id)))
        .write(DoctorAppointmentsCompanion(
      scheduledAt: Value(newTime),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);

    final appt = await (_db.select(_db.doctorAppointments)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (appt == null) return;

    final settings = _ref.read(notificationSettingsProvider);
    final rawReminderAt =
        newTime.subtract(Duration(minutes: appt.remindBeforeMin));
    final remindAt = settings.adjust(rawReminderAt, memberId: appt.memberId);
    if (remindAt != null) {
      await NotificationService.scheduleAppointmentReminder(
        appointmentId: id,
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

final doctorAppointmentsRepositoryProvider =
    Provider<DoctorAppointmentsRepository>((ref) {
  return DoctorAppointmentsRepository(ref.watch(databaseProvider), ref);
});
