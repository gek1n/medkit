import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Легкий лог подій/помилок застосунку, який пишеться у файл на диску —
/// щоб користувач міг переглянути й поділитись ним (через share sheet)
/// без кабелю/Mac/Xcode, коли щось піде не так.
///
/// Навмисно НЕ логуємо вміст медичних даних (назви ліків, симптоми,
/// текст нотаток) — лише назви подій/типів, щоб лог було безпечно
/// пересилати. Джерело правди — файл на диску (виживає між запусками,
/// зокрема після краху), `_buffer` лише кеш для швидкого доступу.
class AppLogger {
  AppLogger._();

  static const _maxFileBytes = 512 * 1024;
  static const _trimToBytes = 256 * 1024;

  static final List<String> _buffer = [];
  static const _maxBufferLines = 500;

  static File? _logFile;

  static Future<File> _file() async {
    final existing = _logFile;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_log.txt'));
    _logFile = file;
    return file;
  }

  static void log(String message, {String level = 'info'}) {
    final line = '${DateTime.now().toIso8601String()} [$level] $message';
    debugPrint('📝 $line');
    _buffer.add(line);
    if (_buffer.length > _maxBufferLines) _buffer.removeAt(0);
    _appendToFile(line);
  }

  static void logError(String context, Object error, [StackTrace? stack]) {
    final details = stack == null ? '$error' : '$error\n$stack';
    log('$context: $details', level: 'error');
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
    try {
      final file = await _file();
      if (!await file.exists()) return _buffer.join('\n');
      return await file.readAsString();
    } catch (_) {
      return _buffer.join('\n');
    }
  }

  static Future<File> exportFile() => _file();

  static Future<void> clear() async {
    _buffer.clear();
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
