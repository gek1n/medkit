import 'package:drift/drift.dart';
import 'medications_table.dart';

class Symptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();
  TextColumn get nameKey => text()();
  // ключ для перекладу: "nausea", "rash", "headache"
  TextColumn get frequency =>
      text().withDefault(const Constant('common'))();
  // very_common/common/rare
  BoolColumn get isAllergyRisk =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isTracked =>
      boolean().withDefault(const Constant(false))();
  // чи обрав користувач відстежувати
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // для family_sync — див. коментар у medications_table.dart
}
