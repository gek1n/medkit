import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../db/creator_info.dart';
import '../../core/providers/database_provider.dart';

class MedcardEntriesRepository {
  final AppDatabase _db;
  MedcardEntriesRepository(this._db);

  Stream<List<MedcardEntry>> watchBySection(int sectionId) {
    return (_db.select(_db.medcardEntries)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordDate)]))
        .watch();
  }

  Stream<MedcardEntry?> watchById(int id) {
    return (_db.select(_db.medcardEntries)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<int> insert(MedcardEntriesCompanion entry) async {
    final creator = await ownCreatorInfo(_db);
    final id = await _db.into(_db.medcardEntries).insert(entry);
    await recordCreator(_db, 'medcard_entry', id, creator);
    return id;
  }

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. sectionId), а
  // екран редагування передає лише змінені поля без sectionId.
  Future<bool> update(MedcardEntriesCompanion entry) async {
    final rows = await (_db.update(_db.medcardEntries)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.medcardEntries)..where((t) => t.id.equals(id))).go();
}

final medcardEntriesRepositoryProvider =
    Provider<MedcardEntriesRepository>((ref) {
  return MedcardEntriesRepository(ref.watch(databaseProvider));
});
