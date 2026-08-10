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

  BoolColumn get viewScheduleGranted => boolean().withDefault(const Constant(false))();
  BoolColumn get editScheduleGranted => boolean().withDefault(const Constant(false))();
  BoolColumn get viewMedcardGranted => boolean().withDefault(const Constant(false))();
  BoolColumn get editMedcardGranted => boolean().withDefault(const Constant(false))();
  // Крок 4.1 плану: те саме view/editGranted вище, але по кожному розділу
  // окремо (Розклад / Медкартка) — старі поля лишаються як "загальний"
  // дозвіл (чи бачу цю людину взагалі), нові уточнюють, ЩО САМЕ в межах
  // цього видно/можна редагувати. Той самий принцип "я не вирішую сам за
  // себе, лише читаю те, що суб'єкт сповістив через grants_summary".

  BoolColumn get viewShelvesGranted => boolean().withDefault(const Constant(false))();
  BoolColumn get editShelvesGranted => boolean().withDefault(const Constant(false))();
  // Крок 4.3.4 плану: Полички як окремий розділ, той самий принцип, що й
  // Розклад/Медкартка вище — додано, коли самі Полички вже синхронізуються
  // (Крок 5.1), окремо від Медкартки (візити/самопочуття), бо в Поличках
  // часто вільні особисті нотатки, які людина може захотіти лишити
  // приватними, навіть ділячись медичною історією.

  BoolColumn get invitedMe => boolean().withDefault(const Constant(false))();
  // true — це ВІН мене запросив (я скановував його код, або конверсія
  // "Локальний → Автономний" на його боці); false — це Я його запросив, або
  // звʼязок зʼявився через автопредставлення (Фаза 5). Рахувати слоти плану
  // потрібно лише за false-рядками — вхідні запрошення не мають витрачати
  // мій ліміт. Плюшки Family дарує лише той, у кого invitedMe==true.

  BoolColumn get payerPlanActive => boolean().withDefault(const Constant(false))();
  // Те саме, що notify/view/editGranted — прилітає через grants_summary,
  // ЙОГО повідомлення про ЙОГО власний білінг (Фаза 6, per-peer: він включає
  // це поле лише для пірів, яких сам запросив у свою оплачувану Family).
  // Мій ефективний план рахується як max(власний кеш, family якщо є хоч
  // один рядок invitedMe==true && payerPlanActive==true) — завжди
  // динамічно, ніколи не кешується статичним булевим прапорцем.

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // Порядок відображення серед автономних пірів у перемикачах — той самий
  // принцип, що й Members.sortOrder, керується драг-н-дропом на екрані
  // Сім'я. Піри завжди рендеряться ОКРЕМИМ блоком ПІСЛЯ локальних членів
  // (MemberSwitcherPill/FamilyStatusStrip), тож колізії з їхнім sortOrder
  // немає — власне поле, власний 0-based простір значень.

  BoolColumn get introductionSent => boolean().withDefault(const Constant(false))();
  // Реальний баг у продакшені (04.08): моя картка-відповідь у acceptInvite()
  // надсилалась РІВНО ОДИН раз, у момент прийняття запрошення — якщо
  // push-токен ще не був готовий (типово на iOS, поки дозвіл не надано),
  // картка НІКОЛИ не йшла повторно, і інвайтер назавжди лишався без жодного
  // сліду, що запрошення прийняли (сам pending-інвайт у нього тим часом
  // стирався по TTL, теж мовчки). DEFAULT false (не true!) — свідомо, щоб
  // САМЕ ЦІ вже наявні (потенційно зіпсовані заздалегідь, ще до цього
  // фіксу) рядки теж підхопили повторну спробу після міграції, а не
  // лишились "начебто відправленими" назавжди. Повторна відправка для вже
  // здорової пари — не шкодить: relay-стан каналу однаково перезаписується
  // тим самим вмістом, і ніхто вже не читає той канал після встановлення
  // зв'язку (retryPendingIntroductions фільтрує лише invitedMe==true,
  // тобто торкається виключно "мене хтось запросив", де саме такий
  // повторний надсил і потрібен). false — картку ще треба (повторно)
  // надіслати при кожному sync-раунді, доки не вийде;
  // true (дефолт, і явно для НОВИХ рядків, де я сам когось запросив,
  // invitedMe=false — там немає що надсилати) — усе гаразд, ретраїти
  // нема потреби. DEFAULT true — щоб для вже наявних (старих) рядків
  // при міграції нічого зайвого не ретраїлось.

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

/// "Візитівка" людини, яку я ЗНАЮ (бачу в списку "Видимість для сім'ї"), але
/// з якою ще НЕМАЄ справжнього зашифрованого каналу — навмисно окремо від
/// [FamilyPeers] (там лише реально встановлені канали). Заповнюється через
/// автопредставлення: коли хтось приєднується до сімейної групи, платящий
/// розсилає візитівки (ім'я/аватар/personUuid, БЕЗ доступу до даних) всім
/// існуючим учасникам цієї ж групи і навпаки. Канал створюється лениво —
/// лише коли субʼєкт явно вмикає видимість для когось із цього списку (тоді
/// й рядок тут видаляється, замінений на справжній [FamilyPeers]).
class KnownFamilyMembers extends Table {
  TextColumn get personUuid => text()();
  TextColumn get familyId => text()();
  TextColumn get name => text()();
  IntColumn get avatarIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {personUuid};
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
