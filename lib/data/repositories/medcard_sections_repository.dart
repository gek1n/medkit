import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class MedcardSectionsRepository {
  final AppDatabase _db;
  MedcardSectionsRepository(this._db);

  Stream<List<MedcardSection>> watchByMember(int memberId) {
    return (_db.select(_db.medcardSections)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<MedcardSection?> getById(int id) =>
      (_db.select(_db.medcardSections)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insert(MedcardSectionsCompanion section) =>
      _db.into(_db.medcardSections).insert(section);

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екран редагування передає лише змінені поля без memberId.
  Future<bool> update(MedcardSectionsCompanion section) async {
    final rows = await (_db.update(_db.medcardSections)
          ..where((t) => t.id.equals(section.id.value)))
        .write(section);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.medcardSections)..where((t) => t.id.equals(id))).go();
}

final medcardSectionsRepositoryProvider =
    Provider<MedcardSectionsRepository>((ref) {
  return MedcardSectionsRepository(ref.watch(databaseProvider));
});
