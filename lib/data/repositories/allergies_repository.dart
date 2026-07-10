import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class AllergiesRepository {
  final AppDatabase _db;
  AllergiesRepository(this._db);

  Stream<List<Allergy>> watchByMember(int memberId) {
    return (_db.select(_db.allergies)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> insert(AllergiesCompanion allergy) =>
      _db.into(_db.allergies).insert(allergy);

  Future<bool> update(AllergiesCompanion allergy) =>
      _db.update(_db.allergies).replace(allergy);

  Future<int> delete(int id) =>
      (_db.delete(_db.allergies)..where((t) => t.id.equals(id))).go();
}

final allergiesRepositoryProvider = Provider<AllergiesRepository>((ref) {
  return AllergiesRepository(ref.watch(databaseProvider));
});
