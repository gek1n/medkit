import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/notification_service.dart';

// Нижче цього залишку прийомів медикамент вважається таким, що закінчується
const int lowStockThreshold = 3;

// Нижче цього відсотка флакон/тюбик вважається таким, що закінчується
const int lowStockPercentThreshold = 15;

// Форми, для яких залишок відстежується у % (одна відкрита ємність),
// а не підрахунком дискретних одиниць (таблеток, ампул тощо).
const Set<String> percentTrackedForms = {'syrup', 'drops', 'cream', 'inhaler'};

bool isPercentTrackedForm(String form) => percentTrackedForms.contains(form);

class MedicationsRepository {
  final AppDatabase _db;
  final Ref _ref;
  MedicationsRepository(this._db, this._ref);

  Stream<List<Medication>> watchByMember(int memberId) =>
      (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<Medication>> getByMember(int memberId) =>
      (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId) & t.isActive.equals(true)))
          .get();

  /// Усі ліки члена сім'ї — і активні, і зупинені (isActive=false лишається
  /// в БД через [softDelete], не видаляється фізично) — для архіву.
  Stream<List<Medication>> watchAllByMember(int memberId) =>
      (_db.select(_db.medications)
            ..where((t) => t.memberId.equals(memberId))
            ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
          .watch();

  Future<Medication?> getById(int id) =>
      (_db.select(_db.medications)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<Medication?> watchById(int id) =>
      (_db.select(_db.medications)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Future<int> insert(MedicationsCompanion med) async {
    final id = await _db.into(_db.medications).insert(med);
    if (med.memberId.present) _triggerFamilySync(med.memberId.value);
    return id;
  }

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // партіальні виклики (не лише повне збереження форми) інакше падали б,
  // як це вже сталось із MembersRepository/LabResultsRepository.
  Future<bool> update(MedicationsCompanion med) async {
    final rows = await (_db.update(_db.medications)
          ..where((t) => t.id.equals(med.id.value)))
        .write(med.copyWith(updatedAt: Value(DateTime.now())));
    if (med.id.present) await _triggerFamilySyncForMedication(med.id.value);
    return rows > 0;
  }

  Future<void> decrementRemaining(int id) async {
    final med = await getById(id);
    if (med == null || med.remainingCount <= 0) return;
    final newRemaining = med.remainingCount - 1;
    await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      remainingCount: Value(newRemaining),
      updatedAt: Value(DateTime.now()),
    ));

    if (med.totalCount > 0 && newRemaining <= lowStockThreshold) {
      final settings = _ref.read(notificationSettingsProvider);
      if (settings.pushEnabled && settings.isMemberEnabled(med.memberId)) {
        await NotificationService.showLowStockAlert(
          medicationId: med.id,
          memberName: await _memberName(med.memberId),
          medName: med.name,
          remaining: newRemaining,
          unit: med.doseUnit,
          vibrationEnabled: settings.vibrationEnabled,
        );
      }
    }
    _triggerFamilySync(med.memberId);
  }

  Future<void> incrementRemaining(int id) async {
    final med = await getById(id);
    if (med == null) return;
    final capped = med.totalCount > 0
        ? (med.remainingCount + 1).clamp(0, med.totalCount)
        : med.remainingCount + 1;
    await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      remainingCount: Value(capped),
      updatedAt: Value(DateTime.now()),
    ));
    _triggerFamilySync(med.memberId);
  }

  Future<void> setStockPercent(int id, int percent) async {
    final med = await getById(id);
    if (med == null) return;
    final clamped = percent.clamp(0, 100);
    await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      stockPercent: Value(clamped),
      updatedAt: Value(DateTime.now()),
    ));

    if (clamped <= lowStockPercentThreshold) {
      final settings = _ref.read(notificationSettingsProvider);
      if (settings.pushEnabled && settings.isMemberEnabled(med.memberId)) {
        await NotificationService.showLowStockAlert(
          medicationId: med.id,
          memberName: await _memberName(med.memberId),
          medName: med.name,
          remaining: clamped,
          unit: '%',
          vibrationEnabled: settings.vibrationEnabled,
        );
      }
    }
    _triggerFamilySync(med.memberId);
  }

  Future<void> openNewContainer(int id) async {
    await (_db.update(_db.medications)..where((t) => t.id.equals(id))).write(
      MedicationsCompanion(
        stockPercent: const Value(100),
        openedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _triggerFamilySyncForMedication(id);
  }

  Future<void> refill(int id, int count) async {
    await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      remainingCount: Value(count),
      totalCount: Value(count),
      updatedAt: Value(DateTime.now()),
    ));
    await _triggerFamilySyncForMedication(id);
  }

  Future<int> softDelete(int id) async {
    // Скасовуємо нагадування для всіх ще не прийнятих/минулих прийомів —
    // інакше сповіщення про зупинені ліки продовжують спрацьовувати.
    final pending = await (_db.select(_db.intakes)
          ..where((t) => t.medicationId.equals(id) & t.status.equals('pending')))
        .get();
    for (final intake in pending) {
      await NotificationService.cancelIntakeReminder(intake.id);
    }
    await NotificationService.cancel(NotificationService.lowStockNotificationId(id));

    final result = await (_db.update(_db.medications)..where((t) => t.id.equals(id)))
        .write(MedicationsCompanion(
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
    await _triggerFamilySyncForMedication(id);
    return result;
  }

  void _triggerFamilySync(int memberId) {
    unawaited(FamilySyncService(_db).syncChannelForMember(memberId));
  }

  Future<String> _memberName(int memberId) async {
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(memberId)))
        .getSingleOrNull();
    return member?.name ?? '';
  }

  Future<void> _triggerFamilySyncForMedication(int medicationId) async {
    final med = await getById(medicationId);
    if (med != null) _triggerFamilySync(med.memberId);
  }
}

final medicationsRepositoryProvider = Provider<MedicationsRepository>((ref) {
  return MedicationsRepository(ref.watch(databaseProvider), ref);
});
