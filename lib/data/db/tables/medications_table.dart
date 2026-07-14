import 'package:drift/drift.dart';
import 'members_table.dart';

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get form => text().withDefault(const Constant('tablet'))();
  // tablet/capsule/syrup/drops/cream/inhaler/injection/other
  RealColumn get doseAmount => real()();
  TextColumn get doseUnit => text().withDefault(const Constant('мг'))();
  TextColumn get foodRelation => text().withDefault(const Constant('any'))();
  // before/after/with/any
  TextColumn get repeatType => text().withDefault(const Constant('daily'))();
  // daily/alternate/weekdays/every_n/cycle
  TextColumn get repeatConfig =>
      text().withDefault(const Constant('{}'))();
  // json: {days:[1,3,5]} / {n:3} / {on:7,off:3}
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  // null = постійний
  IntColumn get totalCount => integer().withDefault(const Constant(0))();
  IntColumn get remainingCount => integer().withDefault(const Constant(0))();
  TextColumn get photoPaths =>
      text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"]
  TextColumn get instructions => text().nullable()();
  TextColumn get phases => text().nullable()();
  // json: [{"times":["08:00"],"durationDays":7}, ...]
  IntColumn get stockPercent => integer().nullable()();
  // 0-100, для рідких форм (сироп/краплі/крем/інгалятор)
  DateTimeColumn get openedAt => dateTime().nullable()();
  // коли відкрито поточний флакон/тюбик
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  // глобально унікальний ідентифікатор для сімейної синхронізації (family_sync) —
  // призначається лише коли член сім'ї прив'язаний до каналу, на відміну від
  // локального autoincrement id, який не унікальний між пристроями
  TextColumn get sideEffects => text().nullable()();
  // json: ["назва побічного ефекту", ...] — довідково від ІІ під час
  // сканування рецепта/упаковки (PrescriptionScanService), null для ліків,
  // доданих вручну або без цієї інформації на фото.
}
