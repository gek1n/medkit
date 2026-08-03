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
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<int> countByMember(int memberId) async {
    final rows = await (_db.select(_db.medcardSections)
          ..where((t) => t.memberId.equals(memberId)))
        .get();
    return rows.length;
  }

  Future<MedcardSection?> getById(int id) =>
      (_db.select(_db.medcardSections)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  // Нові розділи йдуть у кінець списку "Ваші розділи" — sortOrder не
  // передається явним викликачем, тож рахуємо його тут за поточною
  // кількістю розділів профілю.
  Future<int> insert(MedcardSectionsCompanion section) async {
    var toInsert = section;
    if (!section.sortOrder.present) {
      final count = await countByMember(section.memberId.value);
      toInsert = toInsert.copyWith(sortOrder: Value(count));
    }
    return _db.into(_db.medcardSections).insert(toInsert);
  }

  // Викликати з нового порядку id-шників після драг-н-дропу в UI (усі
  // розділи, крім автостворених нотаток — ті завжди пінуються першими
  // окремо, див. med_card_screen.dart).
  Future<void> reorder(List<int> orderedSectionIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedSectionIds.length; i++) {
        await (_db.update(_db.medcardSections)
              ..where((t) => t.id.equals(orderedSectionIds[i])))
            .write(MedcardSectionsCompanion(sortOrder: Value(i)));
      }
    });
  }

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

  // Нотатка без явно обраного Простору падає сюди — рівно один автостворений
  // розділ на профіль (лениво, при першій потребі), а не блокує створення.
  // [defaultName] локалізується викликачем (тут нема доступу до l10n).
  Future<int> getOrCreateDefaultNotesSection(
    int memberId,
    String defaultName,
  ) async {
    final existing = await (_db.select(_db.medcardSections)
          ..where((t) =>
              t.memberId.equals(memberId) & t.isDefaultNotes.equals(true)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db.into(_db.medcardSections).insert(
          MedcardSectionsCompanion.insert(
            memberId: memberId,
            name: defaultName,
            iconKey: const Value('document'),
            isDefaultNotes: const Value(true),
          ),
        );
  }
}

final medcardSectionsRepositoryProvider =
    Provider<MedcardSectionsRepository>((ref) {
  return MedcardSectionsRepository(ref.watch(databaseProvider));
});
