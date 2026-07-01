import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class IntakesRepository {
  final AppDatabase _db;
  IntakesRepository(this._db);

  Stream<List<Intake>> watchByMemberAndDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.intakes)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Future<List<Intake>> getByMemberAndDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.intakes)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .get();
  }

  Future<int> insert(IntakesCompanion intake) =>
      _db.into(_db.intakes).insert(intake);

  Future<void> markTaken(int id) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      IntakesCompanion(
        status: const Value('taken'),
        takenAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSkipped(int id) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      const IntakesCompanion(status: Value('skipped')),
    );
  }

  Future<void> markSnoozed(int id, DateTime until) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      IntakesCompanion(
        status: const Value('snoozed'),
        snoozedUntil: Value(until),
      ),
    );
  }

  Future<void> markPending(int id) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      const IntakesCompanion(
        status: Value('pending'),
        takenAt: Value(null),
        snoozedUntil: Value(null),
      ),
    );
  }

  // Генерація прийомів для конкретного дня (викликається при відкритті дня)
  Future<List<Intake>> getByMemberAndDateRange(
    int memberId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.intakes)
            ..where((t) =>
                t.memberId.equals(memberId) &
                t.scheduledAt.isBiggerOrEqualValue(from) &
                t.scheduledAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .get();

  Stream<List<Intake>> watchByMedicationAndDateRange(
    int medicationId,
    int memberId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.intakes)
            ..where((t) =>
                t.medicationId.equals(medicationId) &
                t.memberId.equals(memberId) &
                t.scheduledAt.isBiggerOrEqualValue(from) &
                t.scheduledAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .watch();

  Future<List<Intake>> getByMedicationAndDateRange(
    int medicationId,
    int memberId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.intakes)
            ..where((t) =>
                t.medicationId.equals(medicationId) &
                t.memberId.equals(memberId) &
                t.scheduledAt.isBiggerOrEqualValue(from) &
                t.scheduledAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .get();

  Future<void> generateForDate(
    int memberId,
    int medicationId,
    int scheduleId,
    DateTime scheduledAt,
  ) async {
    final exists = await (_db.select(_db.intakes)
          ..where((t) =>
              t.scheduleId.equals(scheduleId) &
              t.scheduledAt.equals(scheduledAt)))
        .getSingleOrNull();
    if (exists != null) return;
    await _db.into(_db.intakes).insert(IntakesCompanion.insert(
      scheduleId: scheduleId,
      medicationId: medicationId,
      memberId: memberId,
      scheduledAt: scheduledAt,
    ));
  }
}

final intakesRepositoryProvider = Provider<IntakesRepository>((ref) {
  return IntakesRepository(ref.watch(databaseProvider));
});
