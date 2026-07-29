import 'package:drift/drift.dart';
import 'members_table.dart';

/// ЗАСТАРІЛЕ — перейменовано на [Reminders] (reminders_table.dart), сам клас
/// і фізична таблиця перейменовуються для всіх у AppDatabase-міграції 31
/// (`m.renameTable`). Лишається в схемі лише тому, що історичні кроки
/// onUpgrade (from < 9, 12, 13, 20, 27) звертаються до generated-гетера
/// `doctorAppointments` — без нього вони не скомпілюються. Ніде в
/// продуктовому коді більше не використовується.
class DoctorAppointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  // Назва нагадування — вільний текст (з підказками з історії введених
  // значень, див. ReminderTitleLibraryService), а не контрольований
  // словник напрямків лікаря, як раніше. Назва колонки лишилась старою
  // заради міграції — новий код скрізь трактує це поле як довільну назву.
  TextColumn get doctorType => text()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  // json: ["тег1","тег2"] — довільні мітки, які користувач вводить через
  // кому; історія всіх уживаних тегів — SharedTagsLibraryService.
  TextColumn get location => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get remindBeforeMin =>
      integer().withDefault(const Constant(60))();
  TextColumn get notes => text().nullable()();
  TextColumn get pdfPath => text().nullable()();
  // ЗАСТАРІЛЕ — одиночне вкладення, замінене на documentPaths (список).
  // Лишається в схемі лише заради даних, збережених до міграції 13; новий
  // код це поле більше не читає й не пише.
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  // json: ["path1","path2"] — фото/PDF виписок, направлень тощо
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  // pending/attended/skipped — на відміну від Intake/ActivityLog, з'явилось
  // пізніше, тому за замовчуванням 'pending', а не окрема таблиця логів
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync — null, поки рядок
  // ще не синхронізований жодного разу
}
