import 'package:drift/drift.dart';
import 'medcard_sections_table.dart';
import 'members_table.dart';

// Записи всередині довільного розділу архіву (MedcardSections) — навмисно
// максимально нейтральна форма (назва, дата, нотатка, теги, локація, фото),
// та сама, що й у нагадуваннях, щоб виглядало як звичайна нотатка, а не
// спеціалізована медична форма.
class MedcardEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sectionId =>
      integer().references(MedcardSections, #id, onDelete: KeyAction.cascade)();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  DateTimeColumn get recordDate => dateTime()();
  // дата самого запису — НЕ пов'язана з датою/часом нагадування
  TextColumn get notes => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  // json: ["тег1","тег2"] — окрема історія від тегів нагадувань,
  // MedcardEntryTagLibraryService
  TextColumn get location => text().nullable()();
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncUuid => text().nullable().unique()();
}
