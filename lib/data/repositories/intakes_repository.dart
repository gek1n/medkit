import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/notification_service.dart';
import 'medications_repository.dart';

class IntakesRepository {
  final AppDatabase _db;
  final Ref _ref;
  IntakesRepository(this._db, this._ref);

  // Join з medications і фільтр isActive — інакше прийоми вже зупинених
  // ліків (softDelete лише скасовує нагадування, рядки intakes лишаються)
  // продовжують показуватись у розкладі на сьогодні/завтра.
  Stream<List<Intake>> watchByMemberAndDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = _db.select(_db.intakes).join([
      innerJoin(
        _db.medications,
        _db.medications.id.equalsExp(_db.intakes.medicationId),
      ),
    ])
      ..where(_db.intakes.memberId.equals(memberId) &
          _db.intakes.scheduledAt.isBiggerOrEqualValue(start) &
          _db.intakes.scheduledAt.isSmallerThanValue(end) &
          _db.medications.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(_db.intakes.scheduledAt)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(_db.intakes)).toList());
  }

  Future<List<Intake>> getByMemberAndDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = _db.select(_db.intakes).join([
      innerJoin(
        _db.medications,
        _db.medications.id.equalsExp(_db.intakes.medicationId),
      ),
    ])
      ..where(_db.intakes.memberId.equals(memberId) &
          _db.intakes.scheduledAt.isBiggerOrEqualValue(start) &
          _db.intakes.scheduledAt.isSmallerThanValue(end) &
          _db.medications.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(_db.intakes.scheduledAt)]);
    return query
        .get()
        .then((rows) => rows.map((r) => r.readTable(_db.intakes)).toList());
  }

  Future<int> insert(IntakesCompanion intake) async {
    final id = await _db.into(_db.intakes).insert(intake);
    if (intake.memberId.present) _triggerFamilySync(intake.memberId.value);
    return id;
  }

  Future<void> markTaken(int id) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      IntakesCompanion(
        status: const Value('taken'),
        takenAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await NotificationService.cancelIntakeReminder(id);

    final intake =
        await (_db.select(_db.intakes)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (intake != null) {
      await _ref
          .read(medicationsRepositoryProvider)
          .decrementRemaining(intake.medicationId);
      _triggerFamilySync(intake.memberId);
    }
  }

  Future<void> markSkipped(int id) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      IntakesCompanion(
        status: const Value('skipped'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await NotificationService.cancelIntakeReminder(id);
    await _triggerFamilySyncForIntake(id);
  }

  Future<void> markSnoozed(int id, DateTime until) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      IntakesCompanion(
        status: const Value('snoozed'),
        snoozedUntil: Value(until),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await NotificationService.cancelIntakeReminder(id);

    final intake =
        await (_db.select(_db.intakes)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (intake == null) return;
    final med = await (_db.select(_db.medications)
          ..where((t) => t.id.equals(intake.medicationId)))
        .getSingleOrNull();
    if (med == null) return;

    final settings = _ref.read(notificationSettingsProvider);
    final remindAt = settings.adjust(until, memberId: med.memberId);
    if (remindAt != null) {
      await NotificationService.scheduleIntakeReminder(
        intakeId: id,
        medName: med.name,
        dose: '${med.doseAmount} ${med.doseUnit}',
        scheduledAt: remindAt,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
    _triggerFamilySync(intake.memberId);
  }

  Future<void> markPending(int id) async {
    final before =
        await (_db.select(_db.intakes)..where((t) => t.id.equals(id)))
            .getSingleOrNull();

    await (_db.update(_db.intakes)..where((t) => t.id.equals(id))).write(
      IntakesCompanion(
        status: const Value('pending'),
        takenAt: const Value(null),
        snoozedUntil: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (before?.status == 'taken') {
      await _ref
          .read(medicationsRepositoryProvider)
          .incrementRemaining(before!.medicationId);
    }
    if (before != null) _triggerFamilySync(before.memberId);
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
    _triggerFamilySync(memberId);
  }

  void _triggerFamilySync(int memberId) {
    unawaited(FamilySyncService(_db).syncChannelForMember(memberId));
    // Групові піри (FamilyPeers) синкаються окремим шляхом — без цього
    // виклику "перевірка пропущеного" на їхніх пристроях чекала б
    // наступного періодичного/resume-синку, а не спрацьовувала одразу.
    unawaited(FamilyPeerSyncService(_db).syncAllPeers());
  }

  Future<void> _triggerFamilySyncForIntake(int id) async {
    final intake = await (_db.select(_db.intakes)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (intake != null) _triggerFamilySync(intake.memberId);
  }
}

final intakesRepositoryProvider = Provider<IntakesRepository>((ref) {
  return IntakesRepository(ref.watch(databaseProvider), ref);
});
