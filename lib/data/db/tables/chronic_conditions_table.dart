import 'package:drift/drift.dart';
import 'members_table.dart';

/// ЗАСТАРІЛЕ — фактична таблиця дропається для всіх користувачів у
/// AppDatabase-міграції 30 (і одразу після createAll на нових пристроях).
/// Клас лишається в схемі лише тому, що історичні кроки onUpgrade
/// (from < 11, 12, 14) звертаються до generated-гетера `chronicConditions`
/// — без нього вони не скомпілюються. Ніде в продуктовому коді більше не
/// використовується.
class ChronicConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // назва діагнозу
  TextColumn get specialty => text().nullable()();
  // релевантний напрямок лікаря — той самий довідник, що й
  // DoctorAppointments.doctorType / LabResults.specialty
  DateTimeColumn get diagnosedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"] — фото/PDF підтвердження діагнозу, той самий
  // підхід, що й в аналізах/візитах
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync
}
