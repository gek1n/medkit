import 'package:drift/drift.dart';
import 'medcard_sections_table.dart';
import 'members_table.dart';

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get sectionId => integer()
      .nullable()
      .references(MedcardSections, #id, onDelete: KeyAction.setNull)();
  // Необов'язковий Простір — див. коментар у medications_table.dart.
  // Назва нагадування — вільний текст (з підказками з історії введених
  // значень, див. ReminderTitleLibraryService), а не контрольований
  // словник напрямків лікаря, як раніше. Назва колонки лишилась старою
  // заради міграції — новий код скрізь трактує це поле як довільну назву.
  TextColumn get doctorType => text()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  // json: ["тег1","тег2"] — довільні мітки, які користувач вводить через
  // кому; історія всіх уживаних тегів (спільна з нотатками) —
  // SharedTagsLibraryService.
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
  TextColumn get iconKey => text().withDefault(const Constant('calendar'))();
  // ключ з нейтрального набору medcard_icons.dart — користувач обирає при
  // додаванні; на екрані Сьогодні все одно завжди показується ілюстрація
  // Elly, а не ця іконка (див. today_screen.dart), тут вона використовується
  // в Розкладі/деталях.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  // pending/attended/skipped — на відміну від Intake/ActivityLog, з'явилось
  // пізніше, тому за замовчуванням 'pending', а не окрема таблиця логів
  TextColumn get repeatType => text().withDefault(const Constant('none'))();
  // none/daily/weekly/yearly — об'єднана форма "Нагадування" (замінила
  // окремі Зустрічі/Спорт/Прості завдання): none — разова подія, дата й час
  // беруться з scheduledAt як є; yearly — теж scheduledAt, але рік
  // ігнорується нативним повтором (matchDateTimeComponents.dateAndTime);
  // daily/weekly — час(и) беруться з дочірньої таблиці RemindersSlots
  // (можливо декілька на день), а для weekly ще й дні тижня з repeatConfig.
  TextColumn get repeatConfig => text().withDefault(const Constant('{}'))();
  // json: weekly -> {"days":[1,2,3]} (1=Пн..7=Нд); none/daily/yearly -> {}
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // глобально унікальний ідентифікатор для family_sync — null, поки рядок
  // ще не синхронізований жодного разу
}

class ReminderSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId =>
      integer().references(Reminders, #id, onDelete: KeyAction.cascade)();
  TextColumn get timeOfDay => text()();
  // "08:30" — застосовується лише коли Reminders.repeatType == daily/weekly
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// Стан ВИКОНАННЯ конкретного випадку повторюваного нагадування (daily/
// weekly/monthly/yearly) — на відміну від Reminders.status (спільний для
// всієї серії, і має сенс лише для repeatType=='none'). Генерується
// ReminderLogGenerator при відкритті Сьогодні, за тим самим принципом, що й
// ActivityLogs/Intakes. Не впливає на саме сповіщення (воно й далі
// нативно-повторюване, планується один раз при збереженні нагадування) —
// це суто внутрішньоблог для позначення "зроблено сьогодні"/"пропущено" й
// коректного відображення кнопок на Сьогодні.
class ReminderLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId =>
      integer().references(Reminders, #id, onDelete: KeyAction.cascade)();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // pending/done/skipped
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncUuid => text().nullable()();
}
