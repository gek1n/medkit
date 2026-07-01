import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class SymptomsRepository {
  final AppDatabase _db;
  SymptomsRepository(this._db);

  Stream<List<Symptom>> watchByMedication(int medicationId) =>
      (_db.select(_db.symptoms)
            ..where((t) => t.medicationId.equals(medicationId)))
          .watch();

  Future<List<Symptom>> getTrackedByMember(int memberId) async {
    // Симптоми що відстежуються — з усіх активних ліків члена сім'ї
    final query = _db.select(_db.symptoms).join([
      innerJoin(
        _db.medications,
        _db.medications.id.equalsExp(_db.symptoms.medicationId),
      ),
    ])
      ..where(_db.medications.memberId.equals(memberId) &
          _db.medications.isActive.equals(true) &
          _db.symptoms.isTracked.equals(true));
    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.symptoms)).toList();
  }

  Future<int> insert(SymptomsCompanion symptom) =>
      _db.into(_db.symptoms).insert(symptom);

  Future<void> insertAll(List<SymptomsCompanion> symptoms) async {
    for (final s in symptoms) {
      await _db.into(_db.symptoms).insertOnConflictUpdate(s);
    }
  }

  Future<void> setTracked(int id, bool tracked) async {
    await (_db.update(_db.symptoms)..where((t) => t.id.equals(id)))
        .write(SymptomsCompanion(isTracked: Value(tracked)));
  }
}

final symptomsRepositoryProvider = Provider<SymptomsRepository>((ref) {
  return SymptomsRepository(ref.watch(databaseProvider));
});
