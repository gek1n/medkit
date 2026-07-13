import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class SurgeriesRepository {
  final AppDatabase _db;
  SurgeriesRepository(this._db);

  Stream<List<Surgery>> watchByMember(int memberId) {
    return (_db.select(_db.surgeries)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]))
        .watch();
  }

  Future<int> insert(SurgeriesCompanion surgery) =>
      _db.into(_db.surgeries).insert(surgery);

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(SurgeriesCompanion surgery) async {
    final rows = await (_db.update(_db.surgeries)
          ..where((t) => t.id.equals(surgery.id.value)))
        .write(surgery);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.surgeries)..where((t) => t.id.equals(id))).go();
}

final surgeriesRepositoryProvider = Provider<SurgeriesRepository>((ref) {
  return SurgeriesRepository(ref.watch(databaseProvider));
});
