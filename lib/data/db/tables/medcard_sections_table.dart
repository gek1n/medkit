import 'package:drift/drift.dart';
import 'members_table.dart';

// Довільні розділи архіву, які створює сам користувач — заміна колишніх
// фіксованих сутностей медкартки (алергії, хронічні захворювання, щеплення,
// операції, аналізи), щоб застосунок не нав'язував медичну структуру: сам
// розділ — просто назва + іконка + колір, без жодної клінічної семантики.
class MedcardSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get iconKey => text().withDefault(const Constant('folder'))();
  // ключ з фіксованого нейтрального набору іконок, не сам codePoint —
  // безпечніше для tree-shaking шрифту іконок, див. medcard_icons.dart
  TextColumn get color => text().withDefault(const Constant('#4C9A6A'))();
  TextColumn get comment => text().nullable()();
  // короткий підпис під назвою на плитці розділу, до 30 символів
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncUuid => text().nullable().unique()();
  // для family_sync — див. коментар у medications_table.dart
}
