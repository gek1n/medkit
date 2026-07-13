import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class ChronicConditionsRepository {
  final AppDatabase _db;
  ChronicConditionsRepository(this._db);

  Stream<List<ChronicCondition>> watchByMember(int memberId) {
    return (_db.select(_db.chronicConditions)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> insert(ChronicConditionsCompanion condition) =>
      _db.into(_db.chronicConditions).insert(condition);

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(ChronicConditionsCompanion condition) async {
    final rows = await (_db.update(_db.chronicConditions)
          ..where((t) => t.id.equals(condition.id.value)))
        .write(condition);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.chronicConditions)..where((t) => t.id.equals(id))).go();
}

final chronicConditionsRepositoryProvider =
    Provider<ChronicConditionsRepository>((ref) {
  return ChronicConditionsRepository(ref.watch(databaseProvider));
});
