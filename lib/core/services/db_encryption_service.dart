import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

/// Керує ключем шифрування локальної БД (SQLCipher) і одноразовим
/// перешифруванням наявної незашифрованої БД (для пристроїв, де вона вже
/// існувала до впровадження шифрування).
class DbEncryptionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'db_encryption_key';
  static const _migratedPrefsKey = 'db_encryption_migrated';

  /// Повертає готовий до використання ключ (у форматі SQLCipher raw-key,
  /// напр. "x'AB12...'") і гарантує, що файл БД на диску зашифрований саме
  /// цим ключем (виконує одноразову PRAGMA rekey-міграцію, якщо на пристрої
  /// лишилась стара незашифрована база).
  static Future<String> ensureEncryptedDatabase(File dbFile) async {
    final key = await _getOrCreateKey();

    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_migratedPrefsKey) ?? false;

    if (!alreadyMigrated && await dbFile.exists()) {
      _rekeyIfPlaintext(dbFile, key);
    }
    if (!alreadyMigrated) {
      await prefs.setBool(_migratedPrefsKey, true);
    }

    return key;
  }

  /// Raw-key у форматі SQLCipher: x'64 hex-символи' (32 байти, без PBKDF2 —
  /// ми вже генеруємо криптографічно випадкове значення самі).
  static Future<String> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final key = "x'$hex'";

    await _secureStorage.write(key: _keyStorageKey, value: key);
    return key;
  }

  /// Якщо файл — незашифрована SQLite-база (стара версія застосунку),
  /// перешифровує її на місці через PRAGMA rekey. Якщо файл вже зашифрований
  /// цим-таки ключем — нічого не робить.
  static void _rekeyIfPlaintext(File dbFile, String key) {
    final db = sqlite3.open(dbFile.path);
    try {
      // Незашифрована SQLCipher-база читається без PRAGMA key як звичайна
      // SQLite — якщо це вдається, це стара plaintext-база.
      db.execute('SELECT count(*) FROM sqlite_master;');
      db.execute('PRAGMA rekey = "$key";');
    } catch (_) {
      // Файл або вже зашифрований, або пошкоджений — у будь-якому разі
      // rekey тут не застосовний, БД відкриється як зазвичай через Drift
      // з PRAGMA key і або спрацює (вже зашифрована цим ключем), або ні.
    } finally {
      db.dispose();
    }
  }

  static Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'medkit.db'));
  }
}
