import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackupMode { local, googleDrive, iCloud }

enum BackupFrequency { daily, weekly }

/// Налаштування єдиного розділу "Резервна копія" — обраний режим (лише на
/// пристрої / Google Drive / iCloud), частота автобекапу для хмарних режимів,
/// час останнього бекапу (щоб `_Shell` у main.dart знав, чи пора зробити
/// новий на resume/cold-start) і пароль бекапу, запам'ятований на цьому
/// пристрої — щоб автоматичний бекап за розкладом не питав пароль щоразу.
/// Пароль зберігається лише локально в secure storage: якщо застосунок
/// перевстановлено, його знову треба ввести вручну при відновленні (той
/// самий пароль, який користувач сам придумав при першому вмиканні хмари).
class BackupSettingsService {
  static const _secureStorage = FlutterSecureStorage();
  static const _passphraseKey = 'backup_passphrase';
  static const _modeKey = 'backup_mode_v1';
  static const _frequencyKey = 'backup_frequency_v1';
  static const _lastBackupAtKey = 'backup_last_at_v1';

  static Future<BackupMode> currentMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_modeKey);
    return BackupMode.values.firstWhere((m) => m.name == raw, orElse: () => BackupMode.local);
  }

  static Future<void> setMode(BackupMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  static Future<BackupFrequency> currentFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_frequencyKey);
    return BackupFrequency.values.firstWhere((f) => f.name == raw, orElse: () => BackupFrequency.daily);
  }

  static Future<void> setFrequency(BackupFrequency frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_frequencyKey, frequency.name);
  }

  static Future<DateTime?> lastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastBackupAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> markBackedUpNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupAtKey, DateTime.now().toIso8601String());
  }

  static Future<String?> savedPassphrase() => _secureStorage.read(key: _passphraseKey);

  static Future<void> savePassphrase(String passphrase) =>
      _secureStorage.write(key: _passphraseKey, value: passphrase);

  /// true, якщо режим хмарний і з моменту останнього бекапу минуло більше,
  /// ніж обрана частота (або бекапу ще не було жодного разу).
  static Future<bool> isDue() async {
    final mode = await currentMode();
    if (mode == BackupMode.local) return false;
    final last = await lastBackupAt();
    if (last == null) return true;
    final frequency = await currentFrequency();
    final interval = frequency == BackupFrequency.daily
        ? const Duration(days: 1)
        : const Duration(days: 7);
    return DateTime.now().difference(last) >= interval;
  }
}
