import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_env.dart';

/// Легкий лог подій/помилок застосунку, який пишеться у файл на диску —
/// щоб користувач міг переглянути й поділитись ним (через share sheet)
/// без кабелю/Mac/Xcode, коли щось піде не так.
///
/// Навмисно НЕ логуємо вміст медичних даних (назви ліків, симптоми,
/// текст нотаток) — лише назви подій/типів, щоб лог було безпечно
/// пересилати. Джерело правди — файл на диску (виживає між запусками,
/// зокрема після краху), `_buffer` лише кеш для швидкого доступу.
///
/// ⚠️ Повністю no-op у продакшн-збірці (`!AppEnv.isTestBuild`) — жодного
/// запису на диск, жодного `debugPrint`, `readAll()`/`exportFile()`
/// повертають порожньо. Заголовки нагадувань містять реальні імена людей
/// ("Кохана · Час прийняти ліки"), тож локальний лог-файл, доступний через
/// UI (`DebugLogScreen`), прийнятний лише для тестових збірок команди, не
/// для реальних користувачів у сторі.
class AppLogger {
  AppLogger._();

  static const _maxFileBytes = 512 * 1024;
  static const _trimToBytes = 256 * 1024;

  static final List<String> _buffer = [];
  static const _maxBufferLines = 500;

  static File? _logFile;

  // Черга, що серіалізує записи у файл — БЕЗ цього кожен виклик log()
  // запускав _appendToFile() незалежно, без очікування завершення
  // попереднього виклику. При кількох log() поспіль (саме такий шаблон у
  // ensureEncryptedDatabase — 5 спроб за секунди) паралельні незавершені
  // writeAsString(..., mode: FileMode.append) до ОДНОГО файлу можуть
  // перекривати одна одну — реальний, підтверджений наслідок: у зібраних
  // під час цього розслідування логах регулярно бракувало проміжних рядків
  // "key resolved from...", хоча сам код їх точно писав. Тепер кожен
  // виклик приєднується до кінця ланцюжка попереднього — гарантовано по
  // одному, у правильному хронологічному порядку.
  static Future<void> _writeQueue = Future.value();

  static Future<File> _file() async {
    final existing = _logFile;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_log.txt'));
    _logFile = file;
    return file;
  }

  static void log(String message, {String level = 'info'}) {
    if (!AppEnv.isTestBuild) return;
    final line = '${DateTime.now().toIso8601String()} [$level] $message';
    debugPrint('📝 $line');
    _buffer.add(line);
    if (_buffer.length > _maxBufferLines) _buffer.removeAt(0);
    _writeQueue = _writeQueue.then((_) => _appendToFile(line));
  }

  static void logError(String context, Object error, [StackTrace? stack]) {
    final details = stack == null ? '$error' : '$error\n$stack';
    log('$context: $details', level: 'error');
  }

  static const _lastAppStartKey = 'app_logger_last_app_start_millis';

  /// Логує "app_start" РАЗОМ із тим, скільки минуло часу з попереднього
  /// такого запуску (новий холодний процес — не resume з фону) — без цього
  /// з самого тексту логу неможливо відрізнити "щойно оновили застосунок"
  /// від "не відкривали кілька годин/днів", доводилось щоразу перепитувати
  /// користувача й співставляти вручну. Час зберігається в SharedPreferences
  /// (переживає між запусками), не в `_buffer`.
  static Future<void> logAppStart() async {
    if (!AppEnv.isTestBuild) return;
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_lastAppStartKey);
    final now = DateTime.now();
    if (lastMillis == null) {
      log('app_start (перший відомий запуск на цьому пристрої)');
    } else {
      final gap = now.difference(DateTime.fromMillisecondsSinceEpoch(lastMillis));
      log('app_start (${_formatGap(gap)} з попереднього запуску)');
    }
    await prefs.setInt(_lastAppStartKey, now.millisecondsSinceEpoch);
  }

  static String _formatGap(Duration d) {
    if (d.inDays > 0) return '${d.inDays}д ${d.inHours % 24}г';
    if (d.inHours > 0) return '${d.inHours}г ${d.inMinutes % 60}хв';
    if (d.inMinutes > 0) return '${d.inMinutes}хв ${d.inSeconds % 60}с';
    return '${d.inSeconds}с';
  }

  static Future<void> _appendToFile(String line) async {
    try {
      final file = await _file();
      await file.writeAsString('$line\n', mode: FileMode.append, flush: false);
      final len = await file.length();
      if (len > _maxFileBytes) {
        final content = await file.readAsString();
        final trimmed = content.length > _trimToBytes
            ? content.substring(content.length - _trimToBytes)
            : content;
        await file.writeAsString(trimmed, mode: FileMode.write);
      }
    } catch (_) {
      // Лог не має права зламати застосунок.
    }
  }

  static Future<String> readAll() async {
    if (!AppEnv.isTestBuild) return '';
    try {
      // Чекаємо на завершення всіх ще незаписаних рядків у черзі — інакше
      // "Переглянути журнал" одразу після події міг би показати текст без
      // щойно записаних останніх рядків.
      await _writeQueue;
      final file = await _file();
      if (!await file.exists()) return _buffer.join('\n');
      return await file.readAsString();
    } catch (_) {
      return _buffer.join('\n');
    }
  }

  static Future<File> exportFile() async {
    await _writeQueue;
    return _file();
  }

  static Future<void> clear() async {
    _buffer.clear();
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
