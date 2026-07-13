import 'package:shared_preferences/shared_preferences.dart';

import 'backup_settings_service.dart';
import 'notification_service.dart';

/// Одноразове нагадування "увімкніть резервну копію" — той самий підхід, що
/// й [ReviewPromptService]: фіксуємо дату встановлення, і якщо за [_delay]
/// користувач лишається в режимі BackupMode.local, шлемо один локальний
/// пуш і більше ніколи не повторюємо. Доповнює постійний банер у Профілі
/// (той видно завжди, поки бекап вимкнено; це — разовий поштовх для тих,
/// хто банер просто не помітив).
class BackupReminderService {
  static const _installDateKey = 'backup_reminder_install_date';
  static const _shownKey = 'backup_reminder_shown';
  static const _delay = Duration(days: 3);

  /// Викликати один раз на найпершому старті застосунку — безпечно
  /// викликати щоразу, пише лише коли ключа ще нема.
  static Future<void> recordInstallIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_installDateKey) == null) {
      await prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Викликати на тих самих resume/cold-start тригерах, що й
  /// ReviewPromptService.maybeShow().
  static Future<void> maybeRemind() async {
    try {
      if (await BackupSettingsService.currentMode() != BackupMode.local) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_shownKey) ?? false) return;

      final raw = prefs.getString(_installDateKey);
      if (raw == null) return;
      final installedAt = DateTime.tryParse(raw);
      if (installedAt == null) return;
      if (DateTime.now().difference(installedAt) < _delay) return;

      // Позначаємо ДО показу — одноразове нагадування, повторний тригер
      // сенсу нема навіть якщо сама відправка з якоїсь причини впаде.
      await prefs.setBool(_shownKey, true);
      await NotificationService.showBackupReminder();
    } catch (_) {
      // Не критично — банер у Профілі лишається основним каналом нагадування.
    }
  }
}
