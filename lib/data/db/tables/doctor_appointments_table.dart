import 'package:drift/drift.dart';
import 'members_table.dart';

class DoctorAppointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get doctorType => text()();
  // "Кардіолог", "Терапевт"...
  TextColumn get location => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get remindBeforeMin =>
      integer().withDefault(const Constant(60))();
  TextColumn get notes => text().nullable()();
  TextColumn get pdfPath => text().nullable()();
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  // pending/attended/skipped — на відміну від Intake/ActivityLog, з'явилось
  // пізніше, тому за замовчуванням 'pending', а не окрема таблиця логів
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
}
