import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_logger.dart';

/// Кидається, коли файл БД уже існує на диску, але secure storage не
/// повертає ключ навіть після повторних спроб. Текст навмисно містить
/// "file is not a database" — це той самий маркер, за яким
/// `_DatabaseErrorScreen` у main.dart вже розпізнає "ключ не збігається з
/// файлом" і показує деструктивний скидання БД замість автоматичного
/// retry (retry тут безглуздий: без правильного ключа розшифрувати файл
/// криптографічно неможливо).
class DbKeyUnavailableException implements Exception {
  final String message;
  DbKeyUnavailableException(this.message);
  @override
  String toString() => 'DbKeyUnavailableException: $message '
      '(file is not a database, code 26)';
}

/// iOS-специфічний випадок: Keychain-елемент фізично на місці, але зараз
/// недосяжний, бо пристрій не розблоковували з моменту перезавантаження —
/// flutter_secure_storage за замовчуванням пише ключ з accessibility
/// `kSecAttrAccessibleWhenUnlocked` (див. `DbEncryptionService`, ми його не
/// перевизначаємо). Якщо застосунок отримує керування у фоні до першого
/// розблокування (silent push, BGTask), `SecItemCopyMatching` повертає
/// `errSecInteractionNotAllowed` (OSStatus -25308) — це НЕ "ключа нема", а
/// "зачекай на розблокування". На відміну від [DbKeyUnavailableException] —
/// НЕ повинно показувати деструктивний скид бази, лише попросити
/// розблокувати пристрій і повернутись.
class DbTemporarilyLockedException implements Exception {
  @override
  String toString() =>
      'DbTemporarilyLockedException: Keychain недоступний — пристрій '
      'не розблокований (errSecInteractionNotAllowed)';
}

const _errSecInteractionNotAllowed = -25308;

bool _isKeychainLockedError(Object e) =>
    Platform.isIOS &&
    e is PlatformException &&
    e.code == 'Unexpected security result code' &&
    e.details == _errSecInteractionNotAllowed;

/// Керує ключем шифрування локальної БД (SQLCipher) і перешифруванням
/// наявної незашифрованої БД (для пристроїв, де вона вже існувала до
/// впровадження шифрування).
class DbEncryptionService {
  // iOS: явний accessibility-рівень замість дефолту пакета
  // (`KeychainAccessibility.unlocked` — доступний ЛИШЕ поки пристрій прямо
  // зараз розблокований, будь-яке фонове читання під час блокування падає з
  // errSecInteractionNotAllowed). `first_unlock_this_device` лишається
  // доступним одразу після ПЕРШОГО розблокування з моменту перезавантаження
  // й аж до наступного — стандартна рекомендація Apple саме для секретів,
  // потрібних у фоні (UIBackgroundModes: remote-notification у Info.plist).
  // `_this_device` (+ вже наявний дефолт `synchronizable: false`) означає
  // ключ ніколи не "пливе" окремо від файлу БД через iCloud Keychain —
  // прив'язаний виключно до фізичного заліза цього пристрою.
  static final _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _keyStorageKey = 'db_encryption_key';

  // Персистентний (переживає повний перезапуск процесу) лічильник кількості
  // разів поспіль, коли користувач бачив _DatabaseErrorScreen через
  // розсинхрон ключа. На відміну від колишнього in-memory State-поля в
  // main.dart, це не обнуляється при "закрити застосунок і відкрити знову" —
  // а це саме та дія, яку сам екран радить як ГОЛОВНУ пораду. Без цього
  // лічильник ніколи не досягав порогу для показу порятункової дії (скидання
  // БД / відновлення з бекапу) для випадків, що переживають relaunch.
  static const _mismatchStreakKey = 'db_key_mismatch_streak_v1';

  /// Повертає готовий до використання ключ (у форматі SQLCipher raw-key,
  /// напр. "x'AB12...'") і гарантує, що файл БД на диску зашифрований саме
  /// цим ключем (виконує одноразову PRAGMA rekey-міграцію, якщо на пристрої
  /// лишилась стара незашифрована база).
  static Future<String> ensureEncryptedDatabase(File dbFile) async {
    if (!await dbFile.exists()) {
      // Файлу БД немає — це або справжній перший запуск, або
      // перевстановлення після Delete App. iOS НЕ чистить Keychain при
      // видаленні застосунку (на відміну від Documents/бази), тож там
      // цілком міг лишитись ключ від попередньої інсталяції. Довіряти
      // такому ключу небезпечно: файлу, якого нема, фізично не може бути
      // зашифровано старим ключем. Тому для будь-якого нового файлу
      // завжди генеруємо СВІЖИЙ ключ і перезаписуємо Keychain — так ключ
      // і файл гарантовано лишаються парою, і "чужий" ключ зі старої
      // інсталяції більше не може спричинити розсинхрон.
      return _generateAndStoreKey();
    }

    var key = await _getOrCreateKey();

    // Реальний кейс (звіт користувача): оновлення через TestFlight поки
    // застосунок був згорнутий (не вбитий), потім "Відкрити" — Keychain
    // повернув НЕПОРОЖНІЙ, але тимчасово НЕПРАВИЛЬНИЙ ключ (сам read() тут
    // не впав, _getOrCreateKey() не бачить різниці). Наслідок долітав аж до
    // Drift'ового PRAGMA user_version у фоновому ізоляті — "Спробувати ще
    // раз" не допомагав (та ж застигла помилка з providers), а лише повний
    // kill+relaunch чомусь давав Keychain прочитати правильне значення.
    // Перевіряємо тут-і-зараз, ще ДО передачі ключа в Drift: якщо з ним
    // файл не відкривається — кілька спроб перечитати Keychain НАНОВО
    // (не з кешу _getOrCreateKey, а справжній read()), перш ніж здатись і
    // віддати Drift-у те, що є (тоді спрацює вже наявний _isKeyMismatch UI
    // у main.dart, як і раніше).
    // Емпірика з логів (звіти користувачів): цей розсинхрон майже завжди
    // самостійно минає, але НЕ від повторної спроби в тому ж процесі —
    // лише від повного вбивства й перезапуску застосунку (нова спроба
    // Keychain-читання з чистого процесу). Тобто короткий ретрай тут
    // рідко встигає щось "вилікувати" сам по собі — але подовжуємо вікно
    // з 3×300мс (макс. ~1.8с) до 5×500мс (макс. ~7.5с) про всяк випадок,
    // якщо причина — все ж таки повільний Keystore/securityd, а не
    // по-справжньому "чекає на новий процес".
    for (var attempt = 0; attempt < 5 && !_keyOpensDatabase(dbFile, key); attempt++) {
      AppLogger.log(
        'DbEncryptionService: key from secure storage does not open '
        'existing db (attempt ${attempt + 1}/5) — re-reading Keychain '
        'before giving up',
        level: 'warn',
      );
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      key = await _getOrCreateKey();
    }

    // Якщо навіть 5 спроб перечитати Keychain не допомогли — перш ніж
    // здатись і показати користувачу екран помилки, перевіряємо ОДНУ
    // конкретну, вже реально підтверджену причину: осиротілі WAL/SHM-
    // супутники від попередньої генерації бази (напр. після старого,
    // ще не виправленого скидання) — їхній SQLCipher-salt не збігається з
    // поточним головним файлом, тому навіть правильний ключ не відкриває
    // PRAGMA user_version. Прибираємо їх ЛИШЕ тут, коли пара ключ+файл і
    // так уже не відкривається (гірше не станеться — ці дані все одно
    // недосяжні прямо зараз), і одразу перевіряємо, чи це реально
    // допомогло, перш ніж мовчки продовжити. Якщо не допомогло — нічого
    // додатково не втрачено, просто падаємо далі в уже наявний UI
    // помилки, як і раніше.
    if (!_keyOpensDatabase(dbFile, key)) {
      final removedSidecars = await _removeWalSidecarsIfPresent(dbFile);
      if (removedSidecars && _keyOpensDatabase(dbFile, key)) {
        AppLogger.log(
          'DbEncryptionService: removing orphaned WAL/SHM sidecars fixed '
          'the key-mismatch — proceeding silently, no error screen needed',
        );
      } else if (removedSidecars) {
        AppLogger.log(
          'DbEncryptionService: removed WAL/SHM sidecars but db still '
          "doesn't open — not a sidecar issue, falling through to error UI",
          level: 'warn',
        );
      }
    }

    // Виконується на кожному запуску (не одноразово через прапорець у
    // SharedPreferences) — _rekeyIfPlaintext сам по собі безпечний і
    // ідемпотентний: якщо файл вже зашифрований цим ключем, спроба
    // прочитати його без PRAGMA key просто впаде і мовчки проковтнеться.
    // Прапорець-гейт раніше "згорав" ще до появи незашифрованого файлу
    // (напр. якщо БД на пристрої з'являлась пізніше за перший запуск) і
    // назавжди блокував перешифрування — саме це й спричиняло
    // "file is not a database" при відкритті через Drift з ключем.
    await _rekeyIfPlaintext(dbFile, key);

    // Дійшли сюди — ключ або відкрив файл одразу, або відкрив після
    // ре-читання Keychain у циклі вище. У будь-якому разі БД зараз робоча:
    // прибираємо лічильник розсинхронів, якщо він десь накопичився раніше
    // (напр. один минущий збій, який сам минув, не мусить наближати до
    // пропозиції деструктивного скидання наступного разу).
    await clearKeyMismatchStreak();

    return key;
  }

  // Пробне (одноразове, короткочасне) відкриття тим самим шляхом, що й
  // _rekeyIfPlaintext нижче — до того, як Drift відкриє СВОЄ реальне
  // з'єднання у фоновому ізоляті, тож конкуренції за файл тут ще нема.
  // PRAGMA user_version — той самий перший реальний read, на якому падає
  // Drift при розсинхроні ключа (_SqliteVersionDelegate.schemaVersion) —
  // навмисно та сама перевірка, а не щось дешевше на кшталт "файл існує".
  static bool _keyOpensDatabase(File dbFile, String key) {
    try {
      final db = sqlite3.open(dbFile.path);
      try {
        db.execute('PRAGMA key = "$key";');
        db.select('PRAGMA user_version;');
        return true;
      } finally {
        db.dispose();
      }
    } catch (_) {
      return false;
    }
  }

  /// Raw-key у форматі SQLCipher: x'64 hex-символи' (32 байти, без PBKDF2 —
  /// ми вже генеруємо криптографічно випадкове значення самі).
  ///
  /// ВАЖЛИВО: сюди потрапляємо лише коли файл БД на диску вже існує (див.
  /// `ensureEncryptedDatabase`) — а отже правильний ключ ФІЗИЧНО мусить уже
  /// десь лежати в secure storage. Якщо read() тут повертає null/порожньо,
  /// це НЕ "перший запуск" (той випадок обробляється раніше й окремо) — це
  /// втрата доступу до вже наявного ключа: транзієнтний збій Keystore,
  /// або (найімовірніше після оновлення/відновлення пристрою) Android
  /// Auto Backup відновив зашифрований SharedPreferences-файл без
  /// прив'язаного до заліза Keystore-ключа, яким він сам зашифрований —
  /// Keystore-ключі принципово ніколи не потрапляють у бекап.
  ///
  /// Раніше тут мовчки генерувався й ЗБЕРІГАВСЯ новий ключ поверх файлу,
  /// зашифрованого старим — це саме та дія, що гарантовано перетворювала
  /// "тимчасово недоступний ключ" на "файл більше ніколи не відкриється":
  /// щоразу після цього Drift падав з (code 26) "file is not a database",
  /// і єдиним виходом лишалось повне видалення застосунку користувачем
  /// (звідси репорт "не сама ожила — допоміг лише повний перезапуск").
  ///
  /// Тепер: кілька спроб read() із короткою паузою (толеруємо транзієнтний
  /// збій), а якщо ключа й далі нема — явна помилка замість тихого
  /// самопошкодження, щоб користувач побачив той самий керований UX
  /// скидання БД, що вже існує для випадку "ключ не збігається".
  static Future<String> _getOrCreateKey() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      String? existing;
      try {
        existing = await _secureStorage.read(key: _keyStorageKey);
      } catch (e) {
        if (_isKeychainLockedError(e)) {
          if (attempt < 2) {
            await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
            continue;
          }
          AppLogger.log(
            'DbEncryptionService: iOS Keychain locked '
            '(errSecInteractionNotAllowed) after 3 attempts — device not '
            'unlocked since boot, NOT treating as key loss',
            level: 'warn',
          );
          throw DbTemporarilyLockedException();
        }
        rethrow;
      }
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }

    AppLogger.log(
      'DbEncryptionService: secure storage has no key for an existing '
      'database file after 3 attempts — refusing to mint a replacement '
      'key (would silently corrupt the file/key pairing)',
      level: 'error',
    );
    throw DbKeyUnavailableException(
      'Ключ шифрування відсутній у secure storage для наявного файлу БД',
    );
  }

  /// Реальний звіт (iOS, прод-збірка зі стору): видалили застосунок,
  /// встановили заново, пройшли онбординг (файл БД щойно створився і
  /// реально шифрувався НОВИМ ключем — інакше сам онбординг не зберігся б),
  /// закрили — відкрили — "ошибка бд". iOS НЕ чистить Keychain при
  /// видаленні застосунку, тож на пристрої, де MedKit уже стояв раніше, під
  /// тим самим `_keyStorageKey` міг лишитись СТАРИЙ запис.
  ///
  /// Джерело підтверджене прямо в коді плагіна (`FlutterSecureStorage.swift`,
  /// `write()`): коли ключ уже існує, плагін пробує `SecItemUpdate`, а якщо
  /// не знайшла збігу — видаляє старий запис по ВСІХ можливих
  /// accessibility-рівнях і лише тоді додає новий. Але ця "прибиральна"
  /// петля щоразу викликає `delete()` з ОДНИМ ФІКСОВАНИМ значенням
  /// `synchronizable` (тим самим, що передали ми — завжди `false`), і
  /// НІКОЛИ не пробує `synchronizable: true`. А `kSecAttrSynchronizable`,
  /// на відміну від `kSecAttrAccessible`, реально впливає на ідентичність
  /// запису в Keychain (iCloud Keychain-синхронізований і локальний запис
  /// із однаковим account/service УСПІШНО співіснують як ДВА різні записи).
  /// Якщо старий запис (з давнішої інсталяції/версії пакета) виявиться
  /// `synchronizable: true` — жодна ітерація тієї петлі його не знайде,
  /// новий запис (`synchronizable: false`) спокійно додасться ПОРУЧ, і
  /// подальше читання (`read()` спершу шукає БЕЗ фільтра по
  /// synchronizable — тобто знаходить обидва) поверне НЕВИЗНАЧЕНО який із
  /// двох — можливо, щойно записаний, можливо, старий чужий.
  ///
  /// Тому явно прибираємо ОБИДВА можливі стани synchronizable нашою
  /// стороною, перед тим як покладатись на внутрішню логіку `write()` —
  /// безпечно (файлу БД ще нема, старому значенню в будь-якому разі нема
  /// чим відповідати) — а після запису перечитуємо і звіряємо.
  ///
  /// ВАЖЛИВО (свідома відмова від "падати одразу, якщо не збіглось"):
  /// це перший запуск ЩОЙНО встановленого застосунку — сюди потрапляє КОЖЕН
  /// новий користувач, ДО онбордингу. Якщо звірка не збіглась і ми кинемо
  /// виняток тут — замість "фікса рідкісного edge-кейсу" це стає новим
  /// способом заблокувати онбординг НАЗАВЖДИ будь-якому користувачу, у кого
  /// Keychain на мить "загальмував" одразу після інсталяції (типовий
  /// транзієнтний стан securityd, а не помилка) — набагато гірше за
  /// початкову проблему. Тому: кілька спроб (delete+write+read) з паузою, а
  /// якщо й після них не збіглось — ПРОДОВЖУЄМО з останнім згенерованим
  /// ключем (як і робилось до цієї перевірки), лише голосно логуючи —
  /// основний захист від дублікатів-по-synchronizable вище вже мав
  /// спрацювати для реальної причини з продового звіту; ця звірка — лише
  /// canary на випадок ще не відомої причини, не привід зупиняти новачка.
  static Future<String> _generateAndStoreKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final key = "x'$hex'";

    for (var attempt = 0; attempt < 3; attempt++) {
      if (Platform.isIOS) {
        // accessibility: null — щоб цей запит НЕ фільтрував по
        // kSecAttrAccessible (той плагін і сам не вважає значущим для
        // ідентичності запису), єдина змінна тут — synchronizable, саме та,
        // яку внутрішня петля `write()` ніколи не варіює.
        await _secureStorage.delete(
          key: _keyStorageKey,
          iOptions:
              const IOSOptions(accessibility: null, synchronizable: true),
        );
        await _secureStorage.delete(
          key: _keyStorageKey,
          iOptions:
              const IOSOptions(accessibility: null, synchronizable: false),
        );
      } else {
        await _secureStorage.delete(key: _keyStorageKey);
      }
      await _secureStorage.write(key: _keyStorageKey, value: key);

      final verify = await _secureStorage.read(key: _keyStorageKey);
      if (verify == key) {
        // Свіжий ключ для свіжого файлу (перший запуск або щойно після
        // resetCorruptedDatabase) — будь-який попередній лічильник
        // розсинхронів більше не стосується нової пари ключ/файл.
        await clearKeyMismatchStreak();
        return key;
      }

      AppLogger.log(
        'DbEncryptionService: freshly written key does not read back '
        'from secure storage (attempt ${attempt + 1}/3) — retrying',
        level: 'warn',
      );
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }

    AppLogger.log(
      'DbEncryptionService: key still does not read back after 3 attempts '
      '— proceeding with it anyway rather than blocking onboarding '
      '(the duplicate-synchronizable cleanup above already covers the '
      'known cause; this is an unverified fallback for anything else)',
      level: 'error',
    );
    await clearKeyMismatchStreak();
    return key;
  }

  /// Якщо файл — незашифрована SQLite-база (стара версія застосунку),
  /// перешифровує її на місці через PRAGMA rekey. Якщо файл вже зашифрований
  /// цим-таки ключем — нічого не робить.
  ///
  /// Спершу перевіряємо заголовок файлу по байтах (без відкриття
  /// FFI-з'єднання) і відкриваємо реальне sqlite3-з'єднання лише якщо
  /// точно знаємо, що rekey треба. Раніше тут завжди відкривався "пробний"
  /// FFI-хендл до файлу на кожному запуску прямо перед тим, як Drift
  /// відкриває своє реальне з'єднання у фоновому ізоляті — зайвий ризик
  /// гонки за той самий файл без потреби (у 99% запусків файл вже
  /// зашифрований, і пробне з'єднання було чистою тратою).
  static Future<void> _rekeyIfPlaintext(File dbFile, String key) async {
    if (!await _looksLikePlaintextSqlite(dbFile)) return;
    final db = sqlite3.open(dbFile.path);
    try {
      db.execute('PRAGMA rekey = "$key";');
    } catch (_) {
      // Малоймовірно (заголовок уже перевірили побайтово), але про всяк
      // випадок — не блокуємо запуск, Drift далі спробує відкрити з
      // реальним ключем сам.
    } finally {
      db.dispose();
    }
  }

  // SQLite-файл завжди починається з 16-байтового магічного заголовка
  // "SQLite format 3" + null-термінатор. У зашифрованого SQLCipher-файлу
  // цей заголовок сам зашифрований і виглядає як випадкові байти — тож
  // побайтовий збіг тут однозначно означає "це стара незашифрована база".
  // Порівнюємо саме списком байтів (не Dart-рядком) — рядок з null-байтом
  // усередині небезпечно тримати як текстовий літерал у джерельному коді.
  static const List<int> _sqliteMagic = [
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
    0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
  ];

  static Future<bool> _looksLikePlaintextSqlite(File dbFile) async {
    RandomAccessFile? raf;
    try {
      raf = await dbFile.open();
      final header = await raf.read(_sqliteMagic.length);
      if (header.length < _sqliteMagic.length) return false;
      for (var i = 0; i < _sqliteMagic.length; i++) {
        if (header[i] != _sqliteMagic[i]) return false;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  static Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'medkit.db'));
  }

  /// Видаляє файл БД разом із ключем шифрування — запасний вихід зі стану
  /// "ключ встановлено, але файл усе одно нечитабельний" (SqliteException
  /// code 26), коли активного хмарного бекапу немає (інакше пріоритетний
  /// шлях — відновлення з нього, `_DatabaseErrorScreen._restoreFromBackup`).
  /// Без правильного ключа розшифрувати наявний файл криптографічно
  /// неможливо, тож дані справді втрачаються — викликається лише явно, з
  /// підтвердженням користувача.
  ///
  /// КРИТИЧНО видаляти й WAL-супутники (`-wal`/`-shm`/`-journal`), не лише
  /// сам `medkit.db` — Drift/SQLCipher за замовчуванням працює в WAL-режимі.
  /// Якщо лишити стару `-wal` (зашифровану СТАРИМ ключем, з іншим
  /// SQLCipher-salt) на диску, а `_generateAndStoreKey()` далі створить
  /// НОВИЙ файл+ключ поруч із нею — SQLite при наступному відкритті бачить
  /// осиротілу WAL, salt якої не збігається з новим головним файлом, і
  /// падає з тим самим SqliteException(26) "file is not a database". Це
  /// перетворювало саму кнопку "Скинути" на самовідтворювану пастку: вона
  /// ніколи повністю не прибирала стару БД, тож помилка поверталась знову
  /// на наступному запуску, хай скільки разів натискати "Скинути" —
  /// реальний, підтверджений корінь звітів "проблема так і не фіксується".
  static Future<void> resetCorruptedDatabase(File dbFile) async {
    await _deleteSidecarFiles(dbFile, includeMain: true);
    await _secureStorage.delete(key: _keyStorageKey);
  }

  /// Видаляє лише `-wal`/`-shm`/`-journal` (за бажанням і сам головний
  /// файл) — спільна реалізація для [resetCorruptedDatabase] (явне
  /// скидання користувачем) і превентивної тихої перевірки в
  /// [ensureEncryptedDatabase] нижче (коли ключ+файл і так уже не
  /// відкриваються, ще до показу екрана помилки).
  static Future<void> _deleteSidecarFiles(
    File dbFile, {
    required bool includeMain,
  }) async {
    final suffixes = includeMain
        ? ['', '-wal', '-shm', '-journal']
        : ['-wal', '-shm', '-journal'];
    for (final suffix in suffixes) {
      final f = File('${dbFile.path}$suffix');
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  /// Превентивна, ТИХА перевірка — викликається лише коли `_keyOpensDatabase`
  /// вже провалилась навіть після повторних спроб перечитати Keychain (див.
  /// [ensureEncryptedDatabase]), тобто гірше вже не зробимо. Повертає true,
  /// якщо `-wal`/`-shm`/`-journal` реально існували й були видалені —
  /// виклик-сторона сама перевіряє, чи це насправді відкрило файл, перш ніж
  /// вважати це "виправленням", а не просто побічним ефектом.
  static Future<bool> _removeWalSidecarsIfPresent(File dbFile) async {
    var foundAny = false;
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('${dbFile.path}$suffix');
      if (await f.exists()) {
        foundAny = true;
        await f.delete();
      }
    }
    return foundAny;
  }

  /// Викликається з `_DatabaseErrorScreen` щоразу, коли він показується через
  /// розсинхрон ключа (і при першому показі, і при кожному "Спробувати ще
  /// раз") — повертає нове значення лічильника. Персистентність через
  /// SharedPreferences (не in-memory) — саме це дозволяє відрізнити "минуло
  /// вже кілька повних перезапусків, а не минає" від "щойно трапилось".
  static Future<int> recordKeyMismatchOccurrence() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_mismatchStreakKey) ?? 0) + 1;
    await prefs.setInt(_mismatchStreakKey, next);
    return next;
  }

  static Future<void> clearKeyMismatchStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mismatchStreakKey);
  }
}
