import 'package:drift/drift.dart';
import 'members_table.dart';

class Vaccinations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get givenAt => dateTime()();
  DateTimeColumn get nextDoseAt => dateTime().nullable()();
  // дата наступної ревакцинації — null, якщо разова/невідомо
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync
}
