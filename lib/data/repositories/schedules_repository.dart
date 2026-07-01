import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class SchedulesRepository {
  final AppDatabase _db;
  SchedulesRepository(this._db);

  Future<List<Schedule>> getByMedication(int medicationId) =>
      (_db.select(_db.schedules)
            ..where((t) => t.medicationId.equals(medicationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<Schedule>> watchByMedication(int medicationId) =>
      (_db.select(_db.schedules)
            ..where((t) => t.medicationId.equals(medicationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insert(SchedulesCompanion schedule) =>
      _db.into(_db.schedules).insert(schedule);

  Future<void> replaceAll(int medicationId, List<SchedulesCompanion> schedules) async {
    await (_db.delete(_db.schedules)
          ..where((t) => t.medicationId.equals(medicationId)))
        .go();
    for (final s in schedules) {
      await _db.into(_db.schedules).insert(s);
    }
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.schedules)..where((t) => t.id.equals(id))).go();
}

final schedulesRepositoryProvider = Provider<SchedulesRepository>((ref) {
  return SchedulesRepository(ref.watch(databaseProvider));
});
