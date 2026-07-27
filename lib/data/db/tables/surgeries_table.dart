import 'package:drift/drift.dart';
import 'members_table.dart';

/// ЗАСТАРІЛЕ — фактична таблиця дропається для всіх користувачів у
/// AppDatabase-міграції 30 (і одразу після createAll на нових пристроях).
/// Клас лишається в схемі лише тому, що історичні кроки onUpgrade
/// (from < 10, 12, 13) звертаються до generated-гетера `surgeries` — без
/// нього вони не скомпілюються. Ніде в продуктовому коді більше не
/// використовується.
class Surgeries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // назва операції/причина госпіталізації
  DateTimeColumn get performedAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  // ЗАСТАРІЛЕ — одиночне вкладення, замінене на documentPaths (список).
  // Лишається в схемі лише заради даних, збережених до міграції 13; новий
  // код це поле більше не читає й не пише.
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"] — фото/PDF виписок, той самий підхід, що й
  // фото ліків/аналізів (PhotoService + FileEncryptionService)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync
}
