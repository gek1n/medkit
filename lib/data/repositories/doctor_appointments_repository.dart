import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class DoctorAppointmentsRepository {
  final AppDatabase _db;
  DoctorAppointmentsRepository(this._db);

  Stream<List<DoctorAppointment>> watchUpcoming(int memberId) {
    final now = DateTime.now();
    return (_db.select(_db.doctorAppointments)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Future<int> insert(DoctorAppointmentsCompanion appointment) =>
      _db.into(_db.doctorAppointments).insert(appointment);

  Future<bool> update(DoctorAppointmentsCompanion appointment) =>
      _db.update(_db.doctorAppointments).replace(appointment);

  Future<int> delete(int id) =>
      (_db.delete(_db.doctorAppointments)..where((t) => t.id.equals(id))).go();
}

final doctorAppointmentsRepositoryProvider =
    Provider<DoctorAppointmentsRepository>((ref) {
  return DoctorAppointmentsRepository(ref.watch(databaseProvider));
});
