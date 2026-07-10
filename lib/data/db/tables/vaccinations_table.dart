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
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"] — фото/PDF сертифікатів щеплення, той самий
  // підхід, що й в аналізах/візитах
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync
}
