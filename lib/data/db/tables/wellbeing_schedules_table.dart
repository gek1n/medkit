import 'package:drift/drift.dart';
import 'medcard_sections_table.dart';
import 'members_table.dart';

class WellbeingSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get sectionId => integer()
      .nullable()
      .references(MedcardSections, #id, onDelete: KeyAction.setNull)();
  // Необов'язковий Простір — див. коментар у medications_table.dart.
  IntColumn get timesPerDay =>
      integer().withDefault(const Constant(2))();
  // 1/2/3
  TextColumn get times =>
      text().withDefault(const Constant('["08:00","20:00"]'))();
  // json: ["08:00","13:00","20:00"]
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();
  // стабільний ідентифікатор для family_sync (пейринг автономного профілю)
}
