import 'package:drift/drift.dart';

/// Учасник сімейної групи, який НЕ керується цим пристроєм — у нього
/// власний акаунт і власний пристрій (на відміну від `Members` із
/// role=dependent/member, чиї дані веде власник). Це легкий локальний кеш
/// "хто в групі" (ім'я, аватар, канал для обміну карткою учасника) —
/// самі медичні дані сюди не потрапляють, це питання видимості (Фаза 3/4).
class FamilyPeers extends Table {
  TextColumn get personUuid => text()();
  TextColumn get familyId => text()();
  TextColumn get name => text()();
  IntColumn get avatarIndex => integer().withDefault(const Constant(0))();
  TextColumn get channelId => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  // Фаза 4 — курсор для інкрементального push/pull даних (не картки)
  // через FamilySyncApiClient, той самий підхід, що й SharedChannels.

  BoolColumn get notifyGranted => boolean().withDefault(const Constant(false))();
  BoolColumn get viewGranted => boolean().withDefault(const Constant(false))();
  BoolColumn get editGranted => boolean().withDefault(const Constant(false))();
  // Що САМ цей пір (його головний профіль) дозволив МЕНІ — не моє рішення,
  // а те, що він мені повідомив через grants_summary при синку. FamilyGrants
  // живе лише на пристрої субʼєкта, тому без цього обміну я б не мав жодного
  // способу дізнатись, що мені взагалі дозволено.

  @override
  Set<Column> get primaryKey => {personUuid};
}

/// Профіль, чиї дані МЕНІ поділив пір (сам пір або його dependent) — не
/// плутати з `Members`: свідомо ОКРЕМА таблиця, щоб отримані "чужі" дані
/// ніколи не потрапили в перемикач профілів, ліміти плану чи today-дешборд,
/// які розраховані лише на профілі, якими керує цей пристрій.
class SharedSubjects extends Table {
  TextColumn get personUuid => text()();
  TextColumn get peerChannelId => text()();
  TextColumn get name => text()();
  IntColumn get avatarIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {personUuid};
}

/// Дані, поділені зі мною через сімейну групу — свідомо нетипізоване
/// (dataJson як є, тільки для читання/показу), щоб не дублювати всю схему
/// Medications/Allergies/etc. заради того, що ніколи не редагується тут.
class SharedEntities extends Table {
  TextColumn get subjectPersonUuid => text()();
  TextColumn get entityType => text()();
  TextColumn get uuid => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {uuid};
}

/// Канал запрошення до сімейної групи, який я сам створив як інвайтер, і
/// ще чекаю на відповідь від того, хто відсканує код — щойно приходить
/// картка учасника через цей канал, рядок перетворюється на [FamilyPeers]
/// і видаляється звідси.
class PendingGroupInvites extends Table {
  TextColumn get channelId => text()();
  TextColumn get familyId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get convertingMemberId => integer().nullable()();
  // Заповнено лише для запрошень "Локальний → Автономний" (перетворення
  // існуючого профілю, а не звичайне запрошення нового учасника групи) —
  // саме за цим полем refreshPeers() дізнається, що після приєднання
  // потрібно прибрати локальний Member і відв'язати одноразовий канал
  // передачі історії.

  @override
  Set<Column> get primaryKey => {channelId};
}
