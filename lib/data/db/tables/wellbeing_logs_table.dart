import 'package:drift/drift.dart';
import 'members_table.dart';

class WellbeingLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get mood => integer()();
  // 1-5: 😢😕😐🙂😄
  TextColumn get symptomsJson =>
      text().withDefault(const Constant('[]'))();
  // ЗАСТАРІЛЕ — контрольований словник симптомів, замінений на вільні теги
  // (tagsJson). Лишається в схемі лише заради даних, збережених до міграції
  // 28; нові записи сюди більше не пишуться.
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  // json: ["втома","стрес"] — довільні мітки, які користувач вводить сам;
  // окрема історія від тегів завдань (SharedTagsLibraryService)
  TextColumn get comment => text().nullable()();
  TextColumn get voiceNotePath => text().nullable()();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  // true — користувач натиснув "Пропустити", реальних даних немає;
  // виключається з аналітики/історії, але враховується як "оброблено" в
  // перевірці today_screen.dart, щоб слот не висів вічно активним
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();
  // стабільний ідентифікатор для family_sync (пейринг автономного профілю)
}
