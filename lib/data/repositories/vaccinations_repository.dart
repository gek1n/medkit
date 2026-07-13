import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class VaccinationsRepository {
  final AppDatabase _db;
  VaccinationsRepository(this._db);

  Stream<List<Vaccination>> watchByMember(int memberId) {
    return (_db.select(_db.vaccinations)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.givenAt)]))
        .watch();
  }

  Future<int> insert(VaccinationsCompanion vaccination) =>
      _db.into(_db.vaccinations).insert(vaccination);

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(VaccinationsCompanion vaccination) async {
    final rows = await (_db.update(_db.vaccinations)
          ..where((t) => t.id.equals(vaccination.id.value)))
        .write(vaccination);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.vaccinations)..where((t) => t.id.equals(id))).go();
}

final vaccinationsRepositoryProvider = Provider<VaccinationsRepository>((ref) {
  return VaccinationsRepository(ref.watch(databaseProvider));
});
