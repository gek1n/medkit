import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class MedicationsRepository {
  final AppDatabase _db;
  MedicationsRepository(this._db);

  Stream<List<Medication>> watchByMember(int memberId) =>
      (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<Medication>> getByMember(int memberId) =>
      (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId) & t.isActive.equals(true)))
          .get();

  Future<Medication?> getById(int id) =>
      (_db.select(_db.medications)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<Medication?> watchById(int id) =>
      (_db.select(_db.medications)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Future<int> insert(MedicationsCompanion med) =>
      _db.into(_db.medications).insert(med);

  Future<bool> update(MedicationsCompanion med) =>
      _db.update(_db.medications).replace(med);

  Future<void> decrementRemaining(int id) async {
    final med = await getById(id);
    if (med == null || med.remainingCount <= 0) return;
    await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      remainingCount: Value(med.remainingCount - 1),
    ));
  }

  Future<void> refill(int id, int count) async {
    await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      remainingCount: Value(count),
      totalCount: Value(count),
    ));
  }

  Future<int> softDelete(int id) =>
      (_db.update(_db.medications)..where((t) => t.id.equals(id)))
          .write(const MedicationsCompanion(isActive: Value(false)));
}

final medicationsRepositoryProvider = Provider<MedicationsRepository>((ref) {
  return MedicationsRepository(ref.watch(databaseProvider));
});
