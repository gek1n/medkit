import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_encryption_service.dart';

/// Кеш файлів, отриманих ВІД пірів (сімейна група, Фаза 4) — навмисно
/// окрема директорія від `PhotoService._dir` ("med_photos"), бо
/// `BackupService._buildZip()` хардкодить саме ту теку: якщо покласти чужі
/// файли туди ж, вони мовчки потрапили б у резервну копію цього акаунту.
/// На диску — так само зашифровано ключем цього пристрою
/// ([FileEncryptionService]), як і власні вкладення.
class PeerPhotoService {
  static const _dir = 'shared_peer_photos';
  static const _pendingKey = 'peer_photo_pending_requests';

  static Future<String> _localPathFor(String channelId, String photoPath) async {
    final base = await getApplicationDocumentsDirectory();
    final safeName = photoPath.replaceAll('/', '_').replaceAll('\\', '_');
    return p.join(base.path, _dir, channelId, safeName);
  }

  static Future<bool> exists(String channelId, String photoPath) async {
    final path = await _localPathFor(channelId, photoPath);
    return File(path).exists();
  }

  static Future<Uint8List> decryptedBytes(String channelId, String photoPath) async {
    final path = await _localPathFor(channelId, photoPath);
    final blob = await File(path).readAsBytes();
    return FileEncryptionService.decryptBytes(blob);
  }

  static Future<void> save(String channelId, String photoPath, Uint8List plainBytes) async {
    final path = await _localPathFor(channelId, photoPath);
    final file = File(path);
    await file.parent.create(recursive: true);
    final encrypted = await FileEncryptionService.encryptBytes(plainBytes);
    await file.writeAsBytes(encrypted);
  }

  static bool isPdf(String photoPath) => photoPath.toLowerCase().endsWith('.pdf');

  // ── Стан очікування "запит надіслано, файл ще не прийшов" ──────────────
  // Живе лише в SharedPreferences (не в БД) — суто UI-прапорець, губити його
  // при переустановці не критично, користувач просто запросить ще раз.

  static String _pendingId(String channelId, String photoPath) => '$channelId|$photoPath';

  static Future<void> markRequested(String channelId, String photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_pendingKey) ?? []).toSet();
    set.add(_pendingId(channelId, photoPath));
    await prefs.setStringList(_pendingKey, set.toList());
  }

  static Future<void> clearRequested(String channelId, String photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_pendingKey) ?? []).toSet();
    set.remove(_pendingId(channelId, photoPath));
    await prefs.setStringList(_pendingKey, set.toList());
  }

  static Future<bool> isRequested(String channelId, String photoPath) async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getStringList(_pendingKey) ?? [];
    return set.contains(_pendingId(channelId, photoPath));
  }
}
