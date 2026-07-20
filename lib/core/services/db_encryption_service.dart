import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medkit_db_key_storage/medkit_db_key_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app_logger.dart';

/// Кидається, коли файл БД уже існує на диску, але жодне сховище (нове чи
/// легасі) не повертає ключ навіть після повторних спроб. Текст навмисно
/// містить "file is not a database" — це той самий маркер, за яким
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
/// недосяжний, бо пристрій не розблоковували з моменту перезавантаження.
/// Наш нативний плагін (medkit_db_key_storage) пише ключ з accessibility
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — доступний одразу
/// після ПЕРШОГО розблокування і аж до наступної перезагрузки, але якщо
/// застосунок отримує керування у фоні ДО того першого розблокування
/// (silent push, BGTask), нативна сторона повертає код `keychain_locked`
/// (SecItemCopyMatching -> errSecInteractionNotAllowed). Це НЕ "ключа нема",
/// а "зачекай на розблокування". На відміну від [DbKeyUnavailableException] —
/// НЕ повинно показувати деструктивний скид бази, лише попросити
/// розблокувати пристрій і повернутись.
class DbTemporarilyLockedException implements Exception {
  @override
  String toString() =>
      'DbTemporarilyLockedException: Keychain недоступний — пристрій '
      'не розблокований (errSecInteractionNotAllowed)';
}

bool _isKeychainLockedError(Object e) =>
    e is PlatformException && e.code == 'keychain_locked';

/// Керує ключем шифрування локальної БД (SQLCipher) і перешифруванням
/// наявної незашифрованої БД (для пристроїв, де вона вже існувала до
/// впровадження шифрування).
///
/// Ключ зберігається через власний нативний плагін `medkit_db_key_storage`
/// (прямі виклики Keychain на iOS / EncryptedSharedPreferences+Keystore на
/// Android, БЕЗ стороннього пакета) — один раз і назавжди фіксований набір
/// атрибутів на кожній платформі, без варіацій accessibility/synchronizable
/// між викликами. Це усуває клас багів, підтверджений у flutter_secure_storage
/// (issues #960, #573, #762 та інші): дублікати записів у Keychain через
/// розсинхрон атрибутів між write-викликами різних версій/збірок застосунку,
/// коли читання потім непередбачувано повертає то свіже, то застаріле
/// значення.
///
/// `_legacySecureStorage` (flutter_secure_storage) лишається ЛИШЕ як
/// одноразове джерело міграції для користувачів, які встановили застосунок
/// ДО цього переходу — див. [_getOrCreateKey]/[_migrateLegacyKey]. Нових
/// записів туди більше ніколи не робимо.
class DbEncryptionService {
  static final _legacySecureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _legacyKeyStorageKey = 'db_encryption_key';

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
      // завжди генеруємо СВІЖИЙ ключ і пишемо лише в нове сховище — так
      // ключ і файл гарантовано лишаються парою.
      return _generateAndStoreKey();
    }

    var key = await _getOrCreateKey();

    // Реальний кейс (звіт користувача): оновлення через TestFlight поки
    // застосунок був згорнутий (не вбитий), потім "Відкрити" — сховище
    // повернуло НЕПОРОЖНІЙ, але тимчасово НЕПРАВИЛЬНИЙ ключ (само читання
    // тут не впало, _getOrCreateKey() не бачить різниці). Наслідок долітав
    // аж до Drift'ового PRAGMA user_version у фоновому ізоляті —
    // "Спробувати ще раз" не допомагав, а лише повний kill+relaunch чомусь
    // давав Keychain прочитати правильне значення. Перевіряємо тут-і-зараз,
    // ще ДО передачі ключа в Drift: якщо з ним файл не відкривається —
    // кілька спроб перечитати сховище НАНОВО, перш ніж здатись і віддати
    // Drift-у те, що є (тоді спрацює вже наявний _isKeyMismatch UI у
    // main.dart, як і раніше).
    for (var attempt = 0; attempt < 5 && !_keyOpensDatabase(dbFile, key); attempt++) {
      AppLogger.log(
        'DbEncryptionService: key from storage does not open existing db '
        '(attempt ${attempt + 1}/5) — re-reading before giving up',
        level: 'warn',
      );
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      key = await _getOrCreateKey();
    }

    // Якщо навіть 5 спроб перечитати сховище не допомогли — перш ніж
    // здатись і показати користувачу екран помилки, перевіряємо ОДНУ
    // конкретну, вже реально підтверджену причину: осиротілі WAL/SHM-
    // супутники від попередньої генерації бази (напр. після старого,
    // ще не виправленого скидання) — їхній SQLCipher-salt не збігається з
    // поточним головним файлом, тому навіть правильний ключ не відкриває
    // PRAGMA user_version. Прибираємо їх ЛИШЕ тут, коли пара ключ+файл і
    // так уже не відкривається (гірше не станеться), і одразу перевіряємо,
    // чи це реально допомогло, перш ніж мовчки продовжити.
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
      } else {
        // Раніше тут не логувалось НІЧОГО, якщо супутників просто не було —
        // саме та інформація, якої найбільше бракувало при розборі реальних
        // звітів: без цього рядка неможливо відрізнити "перевірили, файлів
        // не було" від "перевірку взагалі не викликали". Якщо це видно в
        // логу поруч із key resolved успішно і без WAL/SHM — значить,
        // причина в самому файлі БД (напр. пошкодження після різкого
        // завершення процесу одразу після запису), а не в ключі чи
        // осиротілих супутниках.
        AppLogger.log(
          'DbEncryptionService: key does not open db, no WAL/SHM/journal '
          'sidecars present — likely main file corruption, not a key or '
          'sidecar issue',
          level: 'warn',
        );
      }
    }

    // Виконується на кожному запуску (не одноразово через прапорець у
    // SharedPreferences) — _rekeyIfPlaintext сам по собі безпечний і
    // ідемпотентний: якщо файл вже зашифрований цим ключем, спроба
    // прочитати його без PRAGMA key просто впаде і мовчки проковтнеться.
    await _rekeyIfPlaintext(dbFile, key);

    // Дійшли сюди — ключ або відкрив файл одразу, або відкрив після
    // ре-читання сховища у циклі вище. У будь-якому разі БД зараз робоча:
    // прибираємо лічильник розсинхронів, якщо він десь накопичився раніше.
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
  /// [ensureEncryptedDatabase]) — а отже правильний ключ ФІЗИЧНО мусить уже
  /// десь лежати: або в новому сховищі (звичайний випадок після міграції),
  /// або ще в старому flutter_secure_storage (пристрій, що оновився з версії
  /// ДО цього переходу і ще не мігрував) — [_migrateLegacyKey] нижче.
  static Future<String> _getOrCreateKey() async {
    final fromNewStorage = await _readWithRetry(MedkitDbKeyStorage.read);
    if (fromNewStorage != null) {
      // Логуємо і на успішному шляху, не лише на провалі — щоб з логу
      // одного інциденту було видно, ЯКЕ саме джерело врешті спрацювало
      // (і з якої спроби), а не лише те, що щось не відкрилось. Раніше цей
      // деталь доводилось відновлювати непрямо, за форматом рядків логу.
      AppLogger.log('DbEncryptionService: key resolved from native storage');
      return fromNewStorage;
    }

    // Нове сховище порожнє для вже наявного файлу БД — або пристрій ще не
    // проходив міграцію (перший запуск ЦІЄЇ версії застосунку після
    // оновлення з попередньої, де ключ лежав лише в flutter_secure_storage).
    // Читаємо legacy-джерело з тим самим ретраєм.
    final fromLegacyStorage = await _readWithRetry(
      () => _legacySecureStorage.read(key: _legacyKeyStorageKey),
    );
    if (fromLegacyStorage != null) {
      AppLogger.log(
        'DbEncryptionService: key resolved from legacy flutter_secure_storage '
        '— migrating to native storage',
      );
      await _migrateLegacyKey(fromLegacyStorage);
      return fromLegacyStorage;
    }

    AppLogger.log(
      'DbEncryptionService: no key in new or legacy storage for an '
      'existing database file after retries — refusing to mint a '
      'replacement key (would silently corrupt the file/key pairing)',
      level: 'error',
    );
    throw DbKeyUnavailableException(
      'Ключ шифрування відсутній для наявного файлу БД',
    );
  }

  /// Спільна логіка ретраю для обох джерел (нове сховище / legacy
  /// flutter_secure_storage) — 3 спроби зі зростаючою паузою. Толерує і
  /// транзієнтне "порожньо" (напр. повільний Keystore/securityd одразу
  /// після оновлення застосунку), і `keychain_locked` (пристрій не
  /// розблокований відколи перезавантажився — окрема, некритична ситуація,
  /// [DbTemporarilyLockedException], а не "ключа нема").
  static Future<String?> _readWithRetry(Future<String?> Function() read) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final value = await read();
        if (value != null && value.isNotEmpty) return value;
      } catch (e) {
        if (!_isKeychainLockedError(e)) rethrow;
        if (attempt == 2) {
          AppLogger.log(
            'DbEncryptionService: Keychain locked (device not unlocked '
            'since boot) after 3 attempts — NOT treating as key loss',
            level: 'warn',
          );
          throw DbTemporarilyLockedException();
        }
      }
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
    return null;
  }

  /// Одноразовий перенос ключа зі старого flutter_secure_storage у нове
  /// сховище — трапляється рівно один раз на пристрій, коли нове сховище
  /// вперше бачить порожнечу для вже наявного файлу БД. Записуємо і одразу
  /// перечитуємо назад для перевірки. СТАРЕ значення навмисно НЕ видаляємо —
  /// лишається аварійним запасним варіантом на випадок ще не виявленого
  /// багу в новому сховищі; сам файл БД більше ніколи не читає зі старого
  /// шляху після того, як нове сховище перестало бути порожнім, тож
  /// дублювання нешкідливе.
  static Future<void> _migrateLegacyKey(String key) async {
    try {
      await MedkitDbKeyStorage.write(key);
      final verify = await MedkitDbKeyStorage.read();
      if (verify == key) {
        AppLogger.log(
          'DbEncryptionService: migrated legacy key to native storage',
        );
      } else {
        AppLogger.log(
          'DbEncryptionService: legacy key migration did not verify — '
          'continuing with legacy value, will retry migration next launch',
          level: 'warn',
        );
      }
    } catch (e, st) {
      AppLogger.logError('DbEncryptionService._migrateLegacyKey', e, st);
      // Не критично — виклик-сторона вже отримала legacy-ключ і продовжує
      // з ним; наступний запуск просто спробує перенести знову.
    }
  }

  /// Викликається лише коли файлу БД на диску немає (справжній перший
  /// запуск або перевстановлення після Delete App) — генерує новий ключ і
  /// записує ЛИШЕ в нове сховище. Старе сховище тут навмисно не чіпаємо:
  /// воно існує лише як джерело міграції для вже наявних користувачів у
  /// [_getOrCreateKey], ніколи як ціль нового запису.
  static Future<String> _generateAndStoreKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final key = "x'$hex'";

    await MedkitDbKeyStorage.write(key);

    final verify = await MedkitDbKeyStorage.read();
    if (verify != key) {
      // На відміну від колишньої реалізації на flutter_secure_storage —
      // тут нема відомого механізму, який міг би це спричинити (жодних
      // варіацій атрибутів між write/read, нема з чим плутати). Голосно
      // логуємо і продовжуємо з тим, що згенерували: блокувати онбординг
      // новому користувачу через ще не бачений випадок гірше, ніж
      // толерувати його.
      AppLogger.log(
        'DbEncryptionService: freshly written key does not read back from '
        'native storage — proceeding anyway',
        level: 'error',
      );
    }

    await clearKeyMismatchStreak();
    return key;
  }

  /// Якщо файл — незашифрована SQLite-база (стара версія застосунку),
  /// перешифровує її на місці через PRAGMA rekey. Якщо файл вже зашифрований
  /// цим-таки ключем — нічого не робить.
  ///
  /// Спершу перевіряємо заголовок файлу по байтах (без відкриття
  /// FFI-з'єднання) і відкриваємо реальне sqlite3-з'єднання лише якщо
  /// точно знаємо, що rekey треба.
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

  /// Read-only доступ до поточного ключа для `BackupCryptoService.wrapKeys()`
  /// — БЕЗ побічних ефектів (не тригерить міграцію, не ретраїть): нове
  /// сховище, а якщо там ще порожньо (пристрій ще не мігрував) — legacy.
  /// Якщо порожньо в обох (напр. дуже перший запуск, файла БД ще нема) —
  /// null; бекап просто піде без цього ключа цього разу, наступний
  /// запланований автобекап підхопить його вже після [_generateAndStoreKey].
  static Future<String?> currentKeyForBackup() async {
    final fromNew = await MedkitDbKeyStorage.read();
    if (fromNew != null && fromNew.isNotEmpty) return fromNew;
    final fromLegacy = await _legacySecureStorage.read(key: _legacyKeyStorageKey);
    return (fromLegacy != null && fromLegacy.isNotEmpty) ? fromLegacy : null;
  }

  static Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'medkit.db'));
  }

  /// Видаляє файл БД разом із ключем шифрування (з ОБОХ можливих сховищ —
  /// нового і legacy, на випадок якщо міграція вже відбулась, а стара копія
  /// ще лежить) — запасний вихід зі стану "ключ встановлено, але файл усе
  /// одно нечитабельний" (SqliteException code 26), коли активного
  /// хмарного бекапу немає (інакше пріоритетний шлях — відновлення з нього,
  /// `_DatabaseErrorScreen._restoreFromBackup`). Без правильного ключа
  /// розшифрувати наявний файл криптографічно неможливо, тож дані справді
  /// втрачаються — викликається лише явно, з підтвердженням користувача.
  ///
  /// КРИТИЧНО видаляти й WAL-супутники (`-wal`/`-shm`/`-journal`), не лише
  /// сам `medkit.db` — Drift/SQLCipher за замовчуванням працює в WAL-режимі.
  /// Якщо лишити стару `-wal` (зашифровану СТАРИМ ключем, з іншим
  /// SQLCipher-salt) на диску, а `_generateAndStoreKey()` далі створить
  /// НОВИЙ файл+ключ поруч із нею — SQLite при наступному відкритті бачить
  /// осиротілу WAL, salt якої не збігається з новим головним файлом, і
  /// падає з тим самим SqliteException(26) "file is not a database".
  static Future<void> resetCorruptedDatabase(File dbFile) async {
    await _deleteSidecarFiles(dbFile, includeMain: true);
    await MedkitDbKeyStorage.delete();
    await _legacySecureStorage.delete(key: _legacyKeyStorageKey);
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
  /// вже провалилась навіть після повторних спроб перечитати сховище (див.
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
