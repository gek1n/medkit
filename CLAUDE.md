# MedKit — Claude Code Context

## Проект
Flutter-додаток для управління ліками сім'ї. Фіолетова палітра (#7048C4). Підтримка декількох мов (uk, en — і більше в майбутньому).

## Заборони (КРИТИЧНО)
- НІКОЛИ не згадувати російські сайти/сервіси/рублі
- Аптеки тільки українські: Liki24.com, Tabletki.ua, Doc.ua, Helsi.me
- Ціни тільки в $ або грн

## Структура
```
lib/
  core/theme/       # AppColors, AppTextStyles, AppDimensions, AppTheme
  core/utils/       # date_utils.dart, l10n_ext.dart
  data/models/      # Medication, MedIntake, FamilyMember
  features/today/   # TodayScreen + widgets
  features/...      # інші екрани (meds, family, profile)
  shared/widgets/   # MkCard, MkButton, SectionLabel, AppBottomNav
  l10n/             # app_uk.arb, app_en.arb (шаблон — uk)
  main.dart         # MedKitApp + _Shell (5 вкладок)
docs/               # MedKit_Brief.html, MedKit_Screens.html
```

## Кольори (AppColors)
- primary: #7048C4 — основний фіолетовий
- accent: #F4855A — теплий акцент
- bg: #FAF8FF, surface: #FFFFFF
- success/warning/danger зі світлими варіантами

## i18n
- Всі рядки UI — тільки через `context.l10n.ключ`
- Нові ключі додавати в обидва ARB файли одночасно
- `flutter gen-l10n` запускається автоматично при `flutter run`

## Команди
```bash
flutter pub get          # після зміни pubspec.yaml
flutter run              # запуск (iOS: потрібен Mac з Xcode)
flutter analyze          # перевірка помилок
flutter test             # тести
```

## Важливо
- `withOpacity()` — ЗАСТАРІЛИЙ, використовувати `.withValues(alpha: x)`
- Розробка на Mac (Xcode + iPhone)
- API ключі (GPT-4o, Claude) — ТІЛЬКИ на сервері, ніколи в app

## Privacy-first переробка (з 2026-07-05) — АКТУАЛЬНИЙ СТАН

Повний план: `C:\Users\user\Desktop\MedKit_Privacy_Rework_Spec.html` (8 фаз).
Стара ідея повного серверного синку (акаунти/JWT/families/members на сервері)
**скасована** — сервер тепер навмисно «сліпий», без акаунтів взагалі.

**Готово:**
- ✅ Фаза 0 — SQLCipher-шифрування локальної Drift-БД + біометричний lock-екран
  застосунку (`lib/core/services/db_encryption_service.dart`,
  `lib/core/services/app_lock_service.dart`). Перевірено на пристрої: заголовок
  файлу БД — випадкові байти, не `SQLite format 3`.
  ⚠️ Два неочевидних фікси, які довелось знайти: (1) `sqlite3_open.open.overrideFor`
  треба викликати і в головному ізоляті (`main.dart`), і в фоновому
  (`isolateSetup` у `NativeDatabase.createInBackground`, `app_database.dart`) —
  інакше SQLCipher мовчки не вантажиться; (2) `local_auth`'s `authenticate()`
  кидає `PlatformException` (NotEnrolled/PasscodeNotSet/NotAvailable), якщо на
  пристрої взагалі нема біометрії/PIN — це нормальний випадок, а не помилка,
  інакше юзер без екрану блокування назавжди застрягне.
- 🔧 Фаза 1 — тонкий анонімний relay-бекенд, окремий проект
  `C:\Users\user\Desktop\medkit-backend\` (PHP 8.4, без Composer/акаунтів).
  Таблиці: pairing_blobs, relay_channels, relay_retry_queue, rate_limits —
  жодних email/імен/сімей/ліків на сервері. **Задеплоєно на api.elly-medkit.com.
  Пройдено через 3 знайдені й виправлені баги:**
  1. ✅ **TLS-сертифікат був самопідписаний** (тимчасовий, cPanel видає такий
     одразу при створенні піддомену, до AutoSSL) — тепер замінений на
     нормальний, `curl` без `-k` проходить.
  2. ✅ **Кожен ендпоінт віддавав голий 500** — причина була подвійна: (а)
     збірка залежностей виконувалась поза try/catch у `public/index.php`
     (виправлено), і (б) **справжня першопричина**, яку знайшов користувач:
     локальна папка з приватним кодом називалась `private/`, а на хостингу
     мала бути `medkit_private/` (за інструкцією в DEPLOY.md) — `require_once`
     шукав бутстрап не за тим шляхом. **Щоб це не повторилось, локальну
     папку перейменовано на `medkit_private/`** — тепер вона 1:1 збігається
     з тим, що заливається на хостинг, ніяких ручних перейменувань при
     деплої більше не треба.
  3. ✅ **Таймзон-баг у пейрингу** — `expires_at` рахувався в PHP по UTC, а
     порівнювався в SQL через `NOW()` (час сесії MySQL, не обов'язково UTC)
     → щойно створений код одразу виглядав "простроченим". Виправлено в
     `PairingController.php` — порівняння тепер іде з PHP-часом
     (`gmdate()`), не з `NOW()` MySQL. Той самий фікс застосовано в
     `cron/cleanup.php`. **Ще не залито на хостинг** — залишається
     перезалити `medkit_private/src/Modules/Relay/PairingController.php`.
  Інструкція — `medkit-backend/DEPLOY.md`.
- ✅ Фаза 2 — згода на голос (називає Anthropic) + прибрано вільний текст
  симптомів з хмарного шляху голосу (`lib/core/services/ai_consent_service.dart`,
  `lib/features/voice/voice_screen.dart`, `lib/core/services/nlu_service.dart`).
- ✅ Шифрування фото ліків — AES-256-GCM, окремий ключ від БД
  (`lib/core/services/file_encryption_service.dart`, оновлено `photo_service.dart`
  + 3 місця показу фото на `Image.memory`). Перевірено: файл на диску — не JPEG.

**В процесі / далі:**
- ✅ `lib/core/services/pairing_crypto_service.dart` — баг знайдено і
  виправлено: `Sha256()` з `cryptography` 2.9.0 не має `hashSync` напряму
  (тільки через `.toSync().hashSync(...)`, або асинхронний `await
  Sha256().hash(...)`). Виправлено на `.toSync().hashSync(...)`, `flutter
  analyze` чистий, доданий round-trip тест
  `test/pairing_crypto_service_test.dart` (encrypt→decrypt, decrypt з невірним
  кодом кидає виняток, codeHash детермінований) — всі 3 проходять.
- ✅ UI пейрингу — `lib/features/pairing/pairing_invite_screen.dart` (генерує
  код + QR через `qr_flutter`, шифрує envelope `{v, channelId, name}`) і
  `pairing_join_screen.dart` (`mobile_scanner` для QR + ручне поле для
  коду). Пакети `qr_flutter`/`mobile_scanner` додані в pubspec.yaml, дозвіл
  на камеру вже був (з image_picker). Старий хардкод-інвайт "MK-2025" і
  `_InviteSheet` в `family_screen.dart` видалені й замінені двома реальними
  екранами ("Запросити" / "У мене є код").
  ⚠️ Свідоме спрощення: QR кодує сам pairing-код (не окремий P2P-канал без
  сервера, як буквально написано у спек-документі) — простіший варіант,
  перевикористовує готовий crypto-шар, уникає ризикованого дизайну "весь
  payload у одному QR".
- ✅ **(2026-07-06) Пейринг/relay — фінальна архітектура: власна MySQL +
  Firebase лише заради FCM.** Був короткий експеримент з повною міграцією на
  Firestore (див. `medkit_privacy_rework.md` — вся історія рішення й чому
  відкотили), але користувач слушно зауважив: власний сервер не має
  пооперационного білінгу й денних квот, на відміну від Firestore Spark
  (~50К читань/20К записів на день, спільно для ВСІХ користувачів проєкту,
  не на сім'ю) — тому повернулись до MySQL для даних, Firebase лишився
  тільки для push (FCM безкоштовний і без лімітів на будь-якому плані).
  - `pairing_api_client.dart`/`relay_api_client.dart` — відновлені (HTTP до
    власного бекенду), `relay_api_client.dart` доповнений методом `fetchState()`.
  - Бекенд: `PairingController.php` відновлений (з уже застосованим
    UTC/gmdate-фіксом часового поясу). `RelayController.php`: `register()` —
    як раніше; `send()` тепер ще й **перезаписує** рядок у новій таблиці
    `channel_state` (один рядок на канал, не зростаюча черга — свідомо,
    щоб пристрій, що пропустив push, міг забрати актуальний стан через
    новий `state()`/`POST /relay/state`, без окремого механізму повторів).
    `relay_retry_queue` більше не використовується (код, що туди писав,
    прибраний з `RelayController` і з `cron/cleanup.php`).
  - `migrations/002_channel_state.sql` — нова таблиця `channel_state`.
  - `Firebase/FirestoreService.php` і `firestore.rules` видалені —
    сервер більше не читає/пише Firestore взагалі.
  - Клієнт: `push_token_service.dart` — маленький хелпер отримання
    FCM-токена (запит дозволу на iOS + `getToken()`), використовується
    обома екранами пейрингу замість видаленого `firebase_auth_service.dart`.
    `pubspec.yaml`: прибрані `cloud_firestore`/`firebase_auth`, лишились
    `firebase_core`+`firebase_messaging` (тільки заради FCM).
  - Android Gradle: `com.google.gms.google-services` плагін лишився,
    підключений **умовно** (`if (file("google-services.json").exists())`)
    — це рішення (уникнути build-помилки до додавання файлу) не залежало
    від Firestore-vs-MySQL, лишилось як є.
  - `flutter analyze`/`flutter test` чисті.
  ⚠️ **Знайдений і виправлений під час обговорення нюанс** (навіть у
  Firestore-варіанті, поки не відкотили): якби Firestore-колекція
  `channels/{id}/updates` росла необмежено (`.add()` без ліміту/чищення),
  кожне перепідключення live-listener'а перечитувало б всю історію заново —
  дизайн "один рядок стану, що перезаписується" (тепер у MySQL
  `channel_state`) уникає цього класу проблем взагалі, незалежно від backend'у.
  ⚠️ **Що лишається зробити руками (не можна з коду):**
  - Firebase Console: додати Android/iOS застосунки (package/bundle ID —
    `com.medkit.medkit`) → покласти `google-services.json` в `android/app/`,
    `GoogleService-Info.plist` в `ios/Runner/` (в Xcode, з увімкненим target
    membership); Service account JSON → `medkit_private/firebase-service-account.json`
  - Xcode: capability **Background Modes → Remote notifications** (інакше
    data-only push не розбудить закритий застосунок на iOS)
  - Перезалити на хостинг: `medkit_private/src/Modules/Relay/PairingController.php`
    (відновлений), `RelayController.php` (оновлений), `public/index.php`,
    `cron/cleanup.php`, і виконати `migrations/002_channel_state.sql`
  - **Не вирішено (окрема задача, не "налаштування Firebase/бекенду")**: яка
    саме схема даних у `encrypted_payload` (повний знімок розкладу? diff-подія?)
    і де в коді (`medications_repository.dart` та інші CRUD) викликати
    `RelayApiClient.send()` — транспорт готовий повністю, лишилось вирішити
    "що саме доставляти щоразу при зміні".
  Живого тестування ще не було з реальним Firebase-проєктом (артефакти поки
  не покладені на місце), але сам пейринг/relay-флоу через MySQL вже
  перевірявся раніше в цій сесії (curl) і працював.
- ✅ `/voice/parse` — бекенд-ендпоінт написаний: `medkit-backend/medkit_private/src/Ai/ClaudeService.php`
  (сирий cURL до Anthropic Messages API, без SDK) +
  `.../Modules/Voice/VoiceController.php` (system-промпт витягує
  action/drugName/doseAmount/... з транскрипту, відповідь Claude **завжди**
  проганяється через білий список перед поверненням клієнту — action,
  scheduleTimes, foodRelation обмежені enum'ами, рядки обрізані). Rate-limit
  30/год на IP. Підключено в `index.php` (`POST /voice/parse`), потребує
  `ANTHROPIC_API_KEY` у `.env` (додано в шаблон + `DEPLOY.md`, крок 6 у тесті
  флоу). Нічого не логується/не зберігається — stateless, як і решта Фази 2.
  Ще не перевірено наживо (бекенд поки що взагалі віддає 500 на всі
  ендпоінти, див. нижче).
- ✅ Google Drive/iCloud бекап — `lib/core/services/backup_crypto_service.dart`
  (пакує db+file ключі шифрування в один blob, захищений паролем бекапу,
  той самий Argon2id+AES-GCM підхід що і в пейрингу), `backup_service.dart`
  (zip з `medkit.db` + `med_photos/` через пакет `archive`, оркеструє
  create/restore), `google_drive_backup_service.dart` (сирі REST-виклики до
  Drive API v3, `appDataFolder` — прихована службова папка, не займає квоту
  "My Drive"), `icloud_backup_service.dart` (пакет `icloud_storage`). UI —
  `lib/features/backup/backup_screen.dart`, підключений з профілю
  ("Резервна копія" в `_OtherSection`). Ціль обирається автоматично за
  платформою (iOS → iCloud, Android → Google Drive). `flutter analyze`
  чистий.
  ⚠️ **Обидва канали потребують нативного налаштування, яке не можна
  зробити з коду:** Google Sign-In — OAuth client + SHA-1 (Android) в Google
  Cloud Console; iCloud — увімкнене iCloud capability в Xcode
  (Signing & Capabilities) з containerId `iCloud.com.medkit.medkit` (можна
  змінити в `icloud_backup_service.dart`), потребує Apple Developer акаунт.
  Без цього обидва впадуть з помилкою входу/контейнера — це очікувано, не
  баг. Ще не тестувалось наживо.
- ✅ Privacy Policy / Terms of Service — 4 HTML-документи в `docs/`
  (`MedKit_Privacy_Policy_UK.html`, `_EN.html`, `MedKit_Terms_UK.html`,
  `_EN.html`), у тому ж візуальному стилі, що й `MedKit_Brief.html`. Зміст
  точно відповідає реальній архітектурі (немає акаунтів, локальне
  шифрування, що саме бачить сервер при пейрингу/relay/voice, Anthropic
  названий явно для голосу, OpenAI — як "заплановано" для сканування
  рецептів, якого ще нема). Контакти — плейсхолдери
  `privacy@`/`support@elly-medkit.com`, тарифи Free/Турбота/Сімʼя з
  `plan_provider.dart`.
  ⚠️ **Це чернетка, не остаточний юридичний документ.** Написано технічно
  точно, але перед публікацією в App Store/Google Play вимагає перевірки
  юристом — особливо через дані про здоров'я (чутлива категорія) і
  можливу наявність дитячих (залежних) профілів. Контактні email-адреси
  теж плейсхолдери, потребують підтвердження, що такі скриньки реально
  існують.
- ✅ Recipe-скан (сканування рецепта/упаковки, через Claude, не OpenAI —
  рішення змінено в цій сесії) — повністю реалізовано:
  - Бекенд: `ClaudeService.php` розширений методом `completeWithImages()`
    (vision), новий `Ai/DrugReferenceService.php` (спільна довідкова
    інформація — їжа/побічні ефекти за назвою, використовується і сканом, і
    голосом, щоб не дублювати промпт), `Modules/Drug/DrugInfoController.php`
    (`POST /drug/info`), `Modules/Scan/PrescriptionScanController.php`
    (`POST /scan/prescription`, 1-5 фото за раз). Окрема сильніша модель для
    vision — `ANTHROPIC_VISION_MODEL` (за замовчуванням claude-sonnet-5) vs
    `ANTHROPIC_MODEL` (haiku) для тексту. Усі три ендпоінти підключені в
    `index.php`, DEPLOY.md оновлено (тест-кроки 7-8).
  - Клієнт: `drug_info_service.dart`, `prescription_scan_service.dart`,
    екран `lib/features/scan/prescription_scan_screen.dart` (згода з
    kind='scan' називає Anthropic → камера/галерея, кілька фото →
    редагований список розпізнаних ліків з позначкою "довідково, не
    гарантовано, звірте з інструкцією").
  - **Два входи, як просив користувач:** (1) `add_medication_screen.dart` —
    вже готова, раніше неробоча кнопка `_ScanCta` тепер веде на скан; 1
    розпізнаний препарат — префілить поточну форму, декілька — зберігаються
    одразу через `medicationsRepositoryProvider`. (2) `onboarding_screen.dart`
    — кнопка скану на кроці "Ліки" тепер робоча; оскільки owner-профіль
    ще не створений на цьому кроці (створюється тільки в `_finish()`),
    розпізнані ліки складаються в `_scannedMedDrafts` і зберігаються після
    створення `ownerId`, за тим самим патерном, що і `_familyDrafts`.
  - **Голосовий ввід теж збагачений**: після розпізнавання `add_med`/
    `mark_taken` з `drugName`, `voice_screen.dart` окремим запитом тягне
    `DrugInfoService.lookup()` і показує ту саму картку "їжа + побічні
    ефекти + застереження" в результаті — без блокування основного флоу
    (якщо запит впаде, просто нічого не показується).
  - Оновлено Privacy Policy (UK+EN) — секція AI-функцій тепер описує скан
    як реалізовану фічу через Anthropic (було: "заплановано, OpenAI").
  - `flutter analyze` по всьому проєкту чистий (лише старі, не повʼязані
    попередження), `flutter test` проходить.
  - Не перевірено наживо — потребує реального деплою нових файлів
    (`ClaudeService.php`, `DrugReferenceService.php`, обидва нові
    контролери) на хостинг, ще не залито.
- Медкартка як реальна фіча — досі не існує в коді взагалі, тільки заглушка.
- ✅ **(2026-07-07) Опційна зашифрована серверна синхронізація — Фаза 1
  (текстові дані, без фото, без Google/Apple Sign-In)** — див. план у
  `medkit_privacy_rework.md` для повного контексту рішення (GDPR + надійне
  відновлення сім'ї на новому телефоні + бажання лишити локальний-only
  режим теж доступним).
  - Схема: усі 11 таблиць (`Members`, `Medications`, `Schedules`, `Intakes`,
    `Symptoms`, `WellbeingLogs`, `WellbeingSchedules`, `Activities`,
    `ActivitySlots`, `ActivityLogs`, `DoctorAppointments`) отримали
    `updatedAt`, schemaVersion 4→5 (`lib/data/db/app_database.dart`).
  - Бекенд: `migrations/003_sync.sql` (`accounts`, `encrypted_entities` —
    один рядок на сутність, не один blob, `encrypted_photos` — для Фази 2).
    `Modules/Sync/AccountController.php` (create/login/delete —
    recovery-key-режим; auth_provider google/apple в схемі вже є, але код
    поки приймає лише 'none', Google/Apple Sign-In — Фаза 3),
    `Modules/Sync/SyncController.php` (push/pull, до 500 сутностей за
    запит). Підключено в `index.php`, DEPLOY.md оновлено (крок 10).
  - Клієнт: `sync_crypto_service.dart` (AES-256-GCM на кожен рядок, той
    самий підхід що і `file_encryption_service.dart`), `account_service.dart`
    (recovery key — 24 символи, той самий обмежений алфавіт що й у
    пейрингу, HMAC-SHA256 для розділення "хеш для сервера" від "ключ
    шифрування" з одного секрету — Argon2id тут не потрібен, recovery key
    вже високоентропійний, на відміну від людського пароля),
    `account_api_client.dart`, `sync_api_client.dart`, `sync_service.dart`
    (push/pull по `updatedAt`, generic helper через Drift `TableInfo` для
    запитів + явний switch на 11 типів для `fromJson`/`insertOnConflictUpdate`
    при pull). Обидва крипто-шляхи (HMAC у `account_service.dart`,
    AES-GCM у `sync_crypto_service.dart`) підтверджені офлайн-тестами
    (`test/account_service_test.dart`, `test/sync_crypto_service_test.dart`)
    одразу, а не "здається, працює" — за прикладом бага з `pairing_crypto_service.dart`
    раніше в цій же сесії.
  - UI: `lib/features/sync/sync_settings_screen.dart` (3 режими: локально/
    хмара без акаунта/хмара з акаунтом-заглушка), підключено з профілю
    ("Синхронізація та акаунт", окремо від "Резервної копії" — це різні речі,
    Drive/iCloud лишається як є). Хук синхронізації — `WidgetsBindingObserver`
    у `_ShellState` (`lib/main.dart`), тихо тягне push+pull на
    `AppLifecycleState.resumed`, якщо режим не `local`.
  ⚠️ **Свідоме обмеження цієї фази** (задокументоване прямо в
  `sync_service.dart`): `local_id` — локальний Drift autoincrement, НЕ
  глобально унікальний між пристроями. Безпечно для "відновити свої ж дані
  після переустановки" (один акаунт активний на одному пристрої за раз), АЛЕ
  не розраховане на одночасну синхронізацію одного акаунта з двох живих
  пристроїв — це окрема задача (потрібні глобально унікальні ідентифікатори
  рядків), і не плутати з пейрингом (`PairingApiClient`/`RelayApiClient`),
  який лишається окремим механізмом саме для обміну між РІЗНИМИ людьми.
  `flutter analyze`/`flutter test` чисті. Не перевірено наживо (бекенд-файли
  ще не залиті на хостинг, `migrations/003_sync.sql` не виконана на живій БД).
- ✅ **(2026-07-07) Фаза 2 синхронізації — фото.** `PhotoService.pickAndSave()`/
  `delete()` тепер записують у нову чергу `photo_sync_queue.dart`
  (SharedPreferences: два набори — "чекає заливки"/"чекає видалення"), яку
  `SyncService.pushChanges()` вичитує і чистить після успішної відправки —
  окремо від `updatedAt`-логіки сутностей, бо самі файли дати зміни не
  мають. Фото льються **як є**, вже зашифровані `file_encryption_service.dart`
  на диску — сервер (і `SyncController::upsertPhoto()`) ніякого додаткового
  шифрування не робить, просто зберігає байти в `encrypted_photos`.
  `SyncController.php`: `push()`/`pull()` тепер приймають/повертають і
  `entities`, і `photos` (обидва поля опційні — можна пушити тільки фото без
  жодної зміненої сутності). М'яке видалення тим самим прапорцем `deleted`,
  що і в сутностях. `pull()` записує отримані фото прямо на диск за
  `photo_id` (= відносний шлях `med_photos/{uuid}.ext`), не через
  `SyncCryptoService` (той — лише для JSON-сутностей, фото і так шифровані
  окремим механізмом). DEPLOY.md — кроки 10.5-10.6 з тестами фото.
  `flutter analyze`/`flutter test` чисті. Не перевірено наживо (та сама
  причина — бекенд-файли не залиті).
- ✅ **(2026-07-07) Фаза 3 синхронізації — Google/Apple Sign-In.** Бекенд:
  `Auth/JwtVerifier.php` (NEW) — верифікація RS256 Google/Apple ID-токенів
  без жодних бібліотек: тягне JWKS по HTTP, конвертує JWK у PEM вручну
  (сирий DER/ASN.1 — `derInteger`/`derSequence`/`derLength`), перевіряє
  підпис через `openssl_verify()`, звіряє `iss`/`aud`/`exp`. ⚠️ Це
  security-критичний код, написаний "наосліп" — в цьому середовищі немає
  PHP CLI, тож жодного рядка з `JwtVerifier.php` жодного разу не було
  реально виконано; перед продакшеном обов'язково прогнати з реальними
  токенами Google/Apple. `AccountController` тепер приймає
  `googleClientId`/`appleServiceId` і отримав `loginOAuth()` (вхід за вже
  верифікованим OAuth-`sub`, без recovery key) та опційні
  `authProvider`/`authToken` в `create()` (перевіряються і прив'язуються
  поряд з recovery-key-хешем, коли передані). Нові env-змінні
  `GOOGLE_CLIENT_ID`/`APPLE_SERVICE_ID` (поки заглушки в `.env`) і
  `DEPLOY.md` крок 11 — інструкція реєстрації в Google Cloud Console /
  Apple Developer.
  Клієнт: `account_service.dart` — `_googleIdToken()`/`_appleIdentityToken()`
  через `google_sign_in`/`sign_in_with_apple` (без email/fullName scopes —
  персональні дані нам не потрібні), `enableAccountSync()` (створює акаунт,
  прив'язаний і до OAuth, і до recovery key — токен НІКОЛИ не бере участі
  в KDF ключа шифрування, лише ідентифікація), `findAccountViaOAuth()` +
  `attachRecoveryKey()` (двокроковий вхід на новому пристрої: спершу
  знайти account_id через Google/Apple, потім раз ввести recovery key,
  щоб вивести ключ шифрування локально). `sync_settings_screen.dart` —
  кнопка "Відновити через Google/Apple" + діалог вибору провайдера.
  ⚠️ Незавершені ручні кроки (не код, налаштування платформи):
  (1) `_googleServerClientId` в `account_service.dart:43` — заглушка
  `YOUR_WEB_CLIENT_ID...`, треба реальний Web Client ID з Google Cloud
  Console (те саме значення — в `GOOGLE_CLIENT_ID` на бекенді);
  (2) Xcode: увімкнути capability "Sign In with Apple" для Runner;
  (3) Apple Sign-In повністю працює лише на iOS/macOS "з коробки" — для
  Android Apple вимагає окремий web-based flow (`webAuthenticationOptions`
  з Services ID + hosted redirect URI), який тут НЕ налаштований, тобто
  на Android кнопка "Apple" поки не запрацює.
  `flutter analyze`/`flutter test` чисті (той самий `widget_test.dart`
  falsy-fail, що й раніше, не пов'язаний з цією роботою).
- ✅ **(2026-07-07) family_sync — бідирекційна синхронізація одного профілю
  сім'ї між ДВОМА пристроями.** Окрема від account-sync (Фази 1-3) фіча: там
  ОДИН акаунт відновлює СВОЇ Ж дані на новому телефоні; тут ДВОЄ РІЗНИХ людей
  (напр. син і тато) одночасно редагують дані ОДНОГО профілю після пейрингу.
  Раніше пейринг лише встановлював QR/код-обмін ідентичністю і channelId,
  нічого фактично не синхронізуючи (`/relay/send`/`/relay/state` були мертвим
  кодом) — ця робота довела інфраструктуру до кінця.
  **Знайдений по дорозі баг, виправлений заодно:** жоден метод
  update/mark/soft-delete в жодному репозиторії (`intakes_repository.dart`,
  `medications_repository.dart`, `symptoms_repository.dart`) не оновлював
  `updatedAt` — лише `insert` (через `withDefault`). Це означало, що вже
  робочий account-sync **не підхоплював жодних правок існуючих рядків**
  (напр. "відмітив прийнятим"), тільки нові вставки. Виправлено додаванням
  `updatedAt: Value(DateTime.now())` у кожен мутуючий метод — це чинить і
  account-sync, і є передумовою для family_sync.
  **Обмін ключем при пейрингу:** envelope `PairingCryptoService` розширено
  з `{v:1, channelId, name}` до `{v:2, channelId, name, syncKey}` —
  `syncKey` (32 випадкових байти) генерується інвайтером і йде всередині
  вже зашифрованого envelope, без окремого handshake. `pairing_invite_screen.dart`
  тепер прив'язаний до конкретного `memberId` (кнопка переїхала з загальної
  секції на карточку члена сім'ї — "Підключити телефон"/"🔗 Підключено" в
  `family_screen.dart`), і одразу зберігає прив'язку member↔channel (нова
  таблиця `SharedChannels`, schema v5→v6) + ключ (`SharedChannelKeyStorage`,
  secure storage). `pairing_join_screen.dart` після розшифровки envelope
  (якщо є `syncKey`) показує вибір "До якого профілю прив'язати?" (авто, якщо
  профіль один).
  **`syncUuid`** (nullable, unique) доданий на `Medications`/`Schedules`/
  `Intakes`/`Symptoms` — на відміну від account-sync (де `local_id`
  безпечний, бо активний лише один пристрій одночасно), тут обидва пристрої
  живі одночасно, тож локальний autoincrement id не годиться як спільний
  ідентифікатор. Призначається лениво при першому push, дочірні сутності
  несуть `medicationSyncUuid`/`scheduleSyncUuid` замість сирих FK.
  Бекенд: нові таблиці `family_sync_entities`/`family_sync_photos`
  (`migrations/004_family_sync.sql`), `Modules/Relay/FamilySyncController.php`
  (копія структури `SyncController`, але область видимості — `channel_id`
  capability-токен, не `account_id`; ідентифікатор рядка — `entity_uuid`, не
  `local_id`). Роути `/family-sync/push`/`/family-sync/pull`, `DEPLOY.md`
  крок 12.
  Клієнт: `family_sync_delete_queue.dart` (tombstone-черга — потрібна лише
  для `Schedules.replaceAll()`/`delete()`, єдиного місця з реальним hard
  delete серед цих 4 таблиць; заодно тombstone і для каскадно видалених
  `Intakes`), `family_sync_api_client.dart`, `family_sync_service.dart`
  (push/pull-оркестрація: лениве призначення `syncUuid`, резолв
  батько↔дитина через uuid, фото — діфом поточних `photoPaths` проти вже
  відправлених для каналу, без окремої черги мутацій). Тригери: після кожної
  релевантної мутації в репозиторіях (`unawaited` виклик
  `FamilySyncService.syncChannelForMember`), при `didChangeAppLifecycleState`
  resume (поряд з account-sync), і новий `FirebaseMessaging.onMessage`
  listener в `main.dart` (раніше жоден FCM-обробник вхідних повідомлень
  ніде не був підключений).
  ⚠️ **Свідомі обмеження v1:** один канал на member (другий одночасний
  caregiver — майбутня задача, нове запрошення заміняє прив'язку); конфлікти
  — last-write-wins по `updatedAt` (як і в account-sync); фото звіряються
  раз на синк-раунд (не миттєво при зміні) — прийнятно, бо фото на member
  зазвичай одиниці; рідкісний теоретичний edge-case одночасного першого
  push з двох пристроїв одразу міг би загубити ще не розв'язану
  `medicationSyncUuid`-залежність без ретраю — не виправлено, задокументовано.
  `flutter analyze`/`flutter test` чисті — 13 проходять (9 попередніх + 4
  нових для `family_sync_delete_queue_test.dart`), той самий falsy-fail
  `widget_test.dart`. Не тестовано наживо (бекенд-файли не залиті,
  `migrations/004_family_sync.sql` не виконана на живій БД, немає двох
  реальних пристроїв у цьому середовищі для наскрізного тесту).
  ⚠️ Наступна фаза (за планом): Фаза 4 account-sync — `/sync/export`-based
  GDPR-експорт (локальна кнопка "Експортувати мої дані" — з БД, що і так
  розшифрована в пам'яті — окрема, простіша частина GDPR, ще не зроблена, це
  не те саме, що серверний `/sync/export`, якого поки що навіть немає як
  ендпоінта).

Детальний лог рішень — пам'ять проекту (memory), файл
`medkit_privacy_rework.md`.

## Що робити далі (станом на 2026-07-07)

**1. Розгорнути вже написане (без цього нічого мережеве не запрацює):**
- Залити змінені/нові файли `medkit-backend/` на хостинг (востаннє заливалось
  до Фази 3/family_sync — `JwtVerifier.php`, `AccountController.php`,
  `FamilySyncController.php` і т.д. ще не на живому сервері).
- Виконати на живій БД міграції `002_channel_state.sql`, `003_sync.sql`,
  `004_family_sync.sql` (перевірено: `001_init.sql` точно там, решта — під
  питанням).
- Заповнити в `.env`: `GOOGLE_CLIENT_ID`, `APPLE_SERVICE_ID` (зараз
  заглушки).

**2. Налаштування платформ (не код, вручну через консолі):**
- Firebase Console: зареєструвати Android/iOS застосунки →
  `google-services.json`/`GoogleService-Info.plist`.
- Google Cloud Console: отримати реальний Web Client ID → вставити в
  `account_service.dart:43` (зараз `YOUR_WEB_CLIENT_ID...`) і в той самий
  `GOOGLE_CLIENT_ID` на бекенді.
- Xcode: увімкнути capability "Sign In with Apple" + "Background Modes →
  Remote notifications".

**3. Незакриті фічі:**
- Фаза 4 account-sync: `/sync/export` (серверний GDPR-експорт) + локальна
  кнопка "Експортувати мої дані".
- Apple Sign-In на Android поки не працює (потрібен окремий web-based flow
  із Services ID + redirect URI) — зараз працює лише iOS/macOS.

**4. Не терміново, але тримати в голові:**
- Privacy Policy/ToS — чернетка, потрібна перевірка юристом перед
  публікацією в стори.
- `test/widget_test.dart` — старий нерелевантний тест (немає
  `ProviderScope`), свідомо не займались.
