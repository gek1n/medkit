import 'package:drift/drift.dart';
import 'medications_table.dart';

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();
  TextColumn get timeOfDay => text()();
  // "08:00"
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
