import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class LabResultsRepository {
  final AppDatabase _db;
  LabResultsRepository(this._db);

  Stream<List<LabResult>> watchByMember(int memberId) {
    return (_db.select(_db.labResults)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .watch();
  }

  Stream<List<LabResult>> watchBySpecialty(int memberId, String specialty) {
    return (_db.select(_db.labResults)
          ..where((t) =>
              t.memberId.equals(memberId) & t.specialty.equals(specialty))
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .watch();
  }

  Future<int> insert(LabResultsCompanion result) =>
      _db.into(_db.labResults).insert(result);

  Future<bool> update(LabResultsCompanion result) =>
      _db.update(_db.labResults).replace(result);

  Future<int> delete(int id) =>
      (_db.delete(_db.labResults)..where((t) => t.id.equals(id))).go();
}

final labResultsRepositoryProvider = Provider<LabResultsRepository>((ref) {
  return LabResultsRepository(ref.watch(databaseProvider));
});
