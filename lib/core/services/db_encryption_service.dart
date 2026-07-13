import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Керує ключем шифрування локальної БД (SQLCipher) і перешифруванням
/// наявної незашифрованої БД (для пристроїв, де вона вже існувала до
/// впровадження шифрування).
class DbEncryptionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'db_encryption_key';

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

    final key = await _getOrCreateKey();

    // Виконується на кожному запуску (не одноразово через прапорець у
    // SharedPreferences) — _rekeyIfPlaintext сам по собі безпечний і
    // ідемпотентний: якщо файл вже зашифрований цим ключем, спроба
    // прочитати його без PRAGMA key просто впаде і мовчки проковтнеться.
    // Прапорець-гейт раніше "згорав" ще до появи незашифрованого файлу
    // (напр. якщо БД на пристрої з'являлась пізніше за перший запуск) і
    // назавжди блокував перешифрування — саме це й спричиняло
    // "file is not a database" при відкритті через Drift з ключем.
    await _rekeyIfPlaintext(dbFile, key);

    return key;
  }

  /// Raw-key у форматі SQLCipher: x'64 hex-символи' (32 байти, без PBKDF2 —
  /// ми вже генеруємо криптографічно випадкове значення самі).
  static Future<String> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return _generateAndStoreKey();
  }

  static Future<String> _generateAndStoreKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final key = "x'$hex'";

    await _secureStorage.write(key: _keyStorageKey, value: key);
    return key;
  }

  /// Видаляє файл БД разом із ключем шифрування — єдиний вихід із стану
  /// "PRAGMA key встановлено, але файл усе одно нечитабельний" (SqliteException
  /// code 26, "file is not a database"): це означає, що збережений ключ
  /// фізично не той, яким зашифровано файл (типово — залишок Keychain від
  /// попередньої інсталяції), а без правильного ключа розшифрувати дані
  /// криптографічно неможливо в принципі. Викликається лише явно, з
  /// підтвердженням користувача.
  static Future<void> resetCorruptedDatabase(File dbFile) async {
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    await _secureStorage.delete(key: _keyStorageKey);
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
}
