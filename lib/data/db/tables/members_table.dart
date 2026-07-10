import 'package:drift/drift.dart';

class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get avatarIndex => integer().withDefault(const Constant(0))();
  TextColumn get role => text().withDefault(const Constant('dependent'))();
  // owner / dependent — "автономний" більше не є роллю Members: незалежні
  // учасники живуть виключно як FamilyPeers (див. FamilyGroupService,
  // "Локальний → Автономний" конверсія переносить дані й видаляє цей рядок).
  IntColumn get fontSize => integer().withDefault(const Constant(2))();
  // 1=small 2=normal 3=large 4=xlarge
  TextColumn get accessType => text().nullable()();
  // link / code / none — тільки для dependent
  TextColumn get accessCode => text().nullable()();
  TextColumn get telegramChatId => text().nullable()();
  TextColumn get notificationChannels =>
      text().withDefault(const Constant('["push"]'))();
  // json: ["push","telegram","sms"]
  TextColumn get contact => text().nullable()();
  // telegram username або телефон, введені під час додавання (до підключення бота)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get personUuid => text().nullable().unique()();
  // Стабільний крос-пристроєвий ідентифікатор ЛЮДИНИ — генерується один
  // раз при створенні профілю і ніколи не змінюється. Локальний
  // autoincrement id має значення лише на цьому пристрої (два різні
  // пристрої незалежно нумерують свої рядки), тому для міжпристроєвих
  // зв'язків (сімейна група, family-sync, видимість) використовується
  // саме це поле, а не id.
  TextColumn get familyId => text().nullable()();
  // Ідентифікатор сімейної групи — спільний для всіх "головних"
  // (незалежних, зі своїм акаунтом) учасників однієї сім'ї. Null, поки
  // профіль не приєднаний до жодної групи, і завжди null для
  // dependent-профілів (ними керує власник, у групі вони окремо не
  // числяться — прив'язка йде через власника).
}
