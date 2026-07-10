import 'package:drift/drift.dart';
import 'members_table.dart';

class Allergies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get allergen => text()();
  // "Пеніцилін", "Горіхи", "Пилок амброзії"...
  TextColumn get reaction => text().nullable()();
  // "висип", "набряк Квінке"...
  TextColumn get severity => text().withDefault(const Constant('mild'))();
  // mild/moderate/severe — для попередження при додаванні ліків з цією
  // алергією варто виділяти severe окремо
  TextColumn get notes => text().nullable()();
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"] — фото/PDF підтвердження алергії (напр. висновок
  // алерголога), той самий підхід, що й в аналізах/візитах
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync
}
