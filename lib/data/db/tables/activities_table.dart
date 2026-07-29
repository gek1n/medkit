import 'package:drift/drift.dart';
import 'medcard_sections_table.dart';
import 'members_table.dart';

class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get sectionId => integer()
      .nullable()
      .references(MedcardSections, #id, onDelete: KeyAction.setNull)();
  // Необов'язковий Простір — див. коментар у medications_table.dart.
  TextColumn get type =>
      text().withDefault(const Constant('walk'))();
  // walk/workout/yoga/cycling/custom — легасі-значення від старого повного
  // редактора (сітка типів + YouTube), більше не заповнюються з UI, лише
  // читаються для вже існуючих записів. Нові рядки завжди 'routine'.
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get durationMin => integer().withDefault(const Constant(30))();
  TextColumn get repeatDays =>
      text().withDefault(const Constant('[1,2,3,4,5]'))();
  // json: [1-7] де 1=Пн — використовується лише коли repeatType=='weekly'
  IntColumn get reminderBeforeMin =>
      integer().withDefault(const Constant(10))();
  TextColumn get youtubeUrl => text().nullable()();
  // легасі, більше не редагується з UI — лишається лише для читання старих записів
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();
  // стабільний ідентифікатор для family_sync (пейринг автономного профілю)

  // ── Рутинні справи v2 (ADHD-механіки + сімейна ротація) ──────────────────
  TextColumn get repeatType =>
      text().withDefault(const Constant('weekly'))();
  // daily/weekly/monthly/everyNDays/weeklyGoal — weekly (з repeatDays) є
  // дефолтом для сумісності зі старими рядками (де repeatDays вже задано).
  IntColumn get repeatDayOfMonth => integer().nullable()();
  // 1-31, для repeatType=='monthly'
  IntColumn get repeatIntervalDays => integer().nullable()();
  // N, для repeatType=='everyNDays' ("раз на N днів" від rotationAnchorDate)
  IntColumn get weeklyGoalCount => integer().nullable()();
  // N, для repeatType=='weeklyGoal' ("N разів на тиждень, будь-які дні") —
  // логи для цього режиму НЕ генеруються заздалегідь (див.
  // ActivityLogGenerator), а створюються "на льоту" при відмітці виконання.
  DateTimeColumn get rotationAnchorDate => dateTime().nullable()();
  // точка відліку для обчислення occurrence-індексу (ротація/everyNDays) —
  // задається один раз при створенні (= createdAt), не змінюється при
  // редагуванні, інакше збився б розрахунок "чия черга сьогодні".
  TextColumn get rotationMode =>
      text().withDefault(const Constant('fixed'))();
  // fixed (один виконавець, як і раніше) / perOccurrence / weekly / monthly —
  // каденція ротації пулу з ActivityAssignees, задається при створенні.
  TextColumn get stepsJson => text().nullable()();
  // json: [{"title": "..."}] — шаблон підкроків (чек-лист), вільний порядок
  // виконання. null/[] — звичайна рутина без розбивки (одна дія = один тогл).

  // ── Поля, вирівняні з формою Нагадування (той самий порядок у UI) ────────
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))();
  TextColumn get location => text().nullable()();
  TextColumn get iconKey => text().withDefault(const Constant('task_routine'))();
  // ключ для MedcardIcon — пара до color, як і в Reminders.
}

class ActivityAssignees extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId =>
      integer().references(Activities, #id, onDelete: KeyAction.cascade)();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // Пул ротації для rotationMode != 'fixed'. Порожньо або 1 рядок —
  // фіксований виконавець (Activities.memberId), як і в попередній версії.
}

class ActivitySlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId =>
      integer().references(Activities, #id, onDelete: KeyAction.cascade)();
  TextColumn get timeOfDay => text()();
  // "08:30"
  IntColumn get durationMin => integer().withDefault(const Constant(30))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();
}

class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get activityId =>
      integer().references(Activities, #id, onDelete: KeyAction.cascade)();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  // "Чия черга" на цей конкретний день — обчислюється при генерації за
  // формулою ротації, або перезаписується вручну (обмін/пропуск черги).
  // НЕ обов'язково той, хто фактично відмітив виконання — див. completedByMemberId.
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  // pending/done/partial/skipped — partial: частина підкроків виконана
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();

  IntColumn get completedByMemberId => integer()
      .nullable()
      .references(Members, #id, onDelete: KeyAction.setNull)();
  // Хто фактично натиснув "виконано" — може відрізнятись від memberId
  // (черга), оскільки відмітити може будь-який член сім'ї.
  TextColumn get completedStepsJson => text().nullable()();
  // json: [indices] підкроків Activities.stepsJson, відмічених саме цього дня.
}
