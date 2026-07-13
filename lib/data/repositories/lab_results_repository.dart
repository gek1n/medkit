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

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(LabResultsCompanion result) async {
    final rows = await (_db.update(_db.labResults)
          ..where((t) => t.id.equals(result.id.value)))
        .write(result);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.labResults)..where((t) => t.id.equals(id))).go();
}

final labResultsRepositoryProvider = Provider<LabResultsRepository>((ref) {
  return LabResultsRepository(ref.watch(databaseProvider));
});
