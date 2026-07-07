import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/family_sync_service.dart';

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

  Future<int> insert(SymptomsCompanion symptom) async {
    final id = await _db.into(_db.symptoms).insert(symptom);
    if (symptom.medicationId.present) {
      await _triggerFamilySyncForMedication(symptom.medicationId.value);
    }
    return id;
  }

  Future<void> insertAll(List<SymptomsCompanion> symptoms) async {
    for (final s in symptoms) {
      await _db.into(_db.symptoms).insertOnConflictUpdate(s);
      if (s.medicationId.present) {
        await _triggerFamilySyncForMedication(s.medicationId.value);
      }
    }
  }

  Future<void> setTracked(int id, bool tracked) async {
    await (_db.update(_db.symptoms)..where((t) => t.id.equals(id)))
        .write(SymptomsCompanion(
      isTracked: Value(tracked),
      updatedAt: Value(DateTime.now()),
    ));
    final symptom = await (_db.select(_db.symptoms)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (symptom != null) await _triggerFamilySyncForMedication(symptom.medicationId);
  }

  Future<void> _triggerFamilySyncForMedication(int medicationId) async {
    final medication = await (_db.select(_db.medications)..where((t) => t.id.equals(medicationId)))
        .getSingleOrNull();
    if (medication != null) {
      unawaited(FamilySyncService(_db).syncChannelForMember(medication.memberId));
    }
  }
}

final symptomsRepositoryProvider = Provider<SymptomsRepository>((ref) {
  return SymptomsRepository(ref.watch(databaseProvider));
});
