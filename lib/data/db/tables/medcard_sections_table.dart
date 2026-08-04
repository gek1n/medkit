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
  // Автостворений розділ для нотаток без явно обраного Простору — рівно
  // один на профіль, лазиво створюється при першому такому виборі (див.
  // MedcardSectionsRepository.getOrCreateDefaultNotesSection). Пінується
  // вгорі списку "Ваші розділи" на med_card_screen.dart.
  BoolColumn get isDefaultNotes => boolean().withDefault(const Constant(false))();
  // Порядок показу серед "Ваші розділи" — керується драг-н-дропом
  // (MedcardSectionsRepository.reorder). isDefaultNotes завжди рендериться
  // першим окремо від цього поля, тож для нього значення не має сенсу.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
