import 'package:drift/drift.dart';
import 'members_table.dart';

class LabResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get specialty => text()();
  // напрямок лікаря, якому релевантний аналіз — той самий довідник, що й
  // DoctorAppointments.doctorType (lib/core/utils/doctor_specialties.dart),
  // потрібен для об'єднаної історії "все по кардіологу" на медкартці
  TextColumn get testName => text().nullable()();
  // "Загальний аналіз крові" тощо — довільний текст, самі значення аналізів
  // навмисно не структуруємо (надто різні одиниці й референсні діапазони
  // між типами аналізів для MVP)
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  // ЗАСТАРІЛЕ — одиночне вкладення, замінене на documentPaths (список).
  // Лишається в схемі лише заради даних, збережених до міграції 13; новий
  // код це поле більше не читає й не пише.
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"] — фото та PDF-документи аналізу, той самий
  // підхід, що й фото ліків (PhotoService + FileEncryptionService)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync
}
