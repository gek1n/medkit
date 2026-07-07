import 'dart:convert';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Бекап у прихований `appDataFolder` користувача на Google Drive — цю папку
/// бачить лише сам застосунок, не сам користувач у звичайному Drive UI, і
/// вона не враховується у квоту "My Drive". Сирі REST-виклики без пакету
/// `googleapis` (той самий підхід, що й для FCM/Claude на бекенді) — тут
/// достатньо трьох ендпоінтів.
///
/// ⚠️ Потребує налаштування в Google Cloud Console (OAuth client + SHA-1 для
/// Android / Bundle ID для iOS) — без цього `signIn()` впаде помилкою
/// "sign_in_failed" / ApiException 10. Це окремий крок, який робиться на
/// стороні розробника (Mac + Xcode + Google Cloud Console), не в коді.
class GoogleDriveBackupService {
  static const _backupFileName = 'medkit_backup.zip';
  static const _keysFileName = 'medkit_backup_keys.bin';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.appdata'],
  );

  Future<String> _accessToken() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Вхід у Google скасовано');
    }
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) {
      throw StateError('Не вдалося отримати токен доступу Google');
    }
    return token;
  }

  Future<void> uploadBackup({required Uint8List zipBytes, required Uint8List keysBlob}) async {
    final token = await _accessToken();
    await _upload(token, _backupFileName, zipBytes, 'application/zip');
    await _upload(token, _keysFileName, keysBlob, 'application/octet-stream');
  }

  Future<({Uint8List zipBytes, Uint8List keysBlob})> downloadBackup() async {
    final token = await _accessToken();
    final backupId = await _findFileId(token, _backupFileName);
    final keysId = await _findFileId(token, _keysFileName);
    if (backupId == null || keysId == null) {
      throw StateError('Резервну копію в Google Drive не знайдено');
    }
    final zipBytes = await _download(token, backupId);
    final keysBlob = await _download(token, keysId);
    return (zipBytes: zipBytes, keysBlob: keysBlob);
  }

  Future<String?> _findFileId(String token, String name) async {
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files').replace(queryParameters: {
      'spaces': 'appDataFolder',
      'q': "name = '$name' and trashed = false",
      'fields': 'files(id)',
    });
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) {
      throw StateError('Drive API помилка (${response.statusCode}): ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final files = json['files'] as List;
    return files.isEmpty ? null : files.first['id'] as String;
  }

  Future<void> _upload(String token, String name, Uint8List bytes, String mimeType) async {
    final existingId = await _findFileId(token, name);
    final metadata = jsonEncode(existingId == null
        ? {'name': name, 'parents': ['appDataFolder']}
        : {'name': name});

    const boundary = 'medkit_backup_boundary';
    final body = <int>[];
    void addPart(String content) => body.addAll(utf8.encode(content));

    addPart('--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$metadata\r\n');
    addPart('--$boundary\r\nContent-Type: $mimeType\r\n\r\n');
    body.addAll(bytes);
    addPart('\r\n--$boundary--');

    final uri = existingId == null
        ? Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart')
        : Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$existingId?uploadType=multipart');

    final response = await (existingId == null
        ? http.post(uri,
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'multipart/related; boundary=$boundary'},
            body: body)
        : http.patch(uri,
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'multipart/related; boundary=$boundary'},
            body: body));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError('Не вдалося завантажити $name на Drive (${response.statusCode}): ${response.body}');
    }
  }

  Future<Uint8List> _download(String token, String fileId) async {
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) {
      throw StateError('Не вдалося завантажити файл із Drive (${response.statusCode})');
    }
    return response.bodyBytes;
  }
}
