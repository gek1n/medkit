import 'package:drift/drift.dart';
import 'members_table.dart';

class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  TextColumn get type =>
      text().withDefault(const Constant('walk'))();
  // walk/workout/yoga/cycling/custom
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get durationMin => integer().withDefault(const Constant(30))();
  TextColumn get repeatDays =>
      text().withDefault(const Constant('[1,2,3,4,5]'))();
  // json: [1-7] де 1=Пн
  IntColumn get reminderBeforeMin =>
      integer().withDefault(const Constant(10))();
  TextColumn get youtubeUrl => text().nullable()();
  // посилання на відео тренування/клип — прев'ю показується у картці "Зараз"
  TextColumn get color => text().nullable()();
  // hex "#RRGGBB" — кастомний колір картки, null = дефолтний колір типу
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();
  // стабільний ідентифікатор для family_sync (пейринг автономного профілю)
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
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  // pending/done/skipped
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable()();
}
