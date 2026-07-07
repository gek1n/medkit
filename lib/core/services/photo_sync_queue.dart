import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Черга "які фото ще треба залити/видалити на сервері". `PhotoService`
/// записує сюди при кожному збереженні/видаленні файлу, а `SyncService`
/// вичитує і чистить чергу під час push. Окремо від самих фото-файлів —
/// нам не треба перечитувати med_photos/ щоразу, достатньо знати, що
/// змінилось з минулого разу.
class PhotoSyncQueue {
  static const _pendingUploadKey = 'photo_sync_pending_upload';
  static const _pendingDeleteKey = 'photo_sync_pending_delete';

  static Future<void> markPendingUpload(String relativePath) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = _readSet(prefs, _pendingUploadKey)..add(relativePath);
    final deletes = _readSet(prefs, _pendingDeleteKey)..remove(relativePath);
    await _writeSet(prefs, _pendingUploadKey, uploads);
    await _writeSet(prefs, _pendingDeleteKey, deletes);
  }

  static Future<void> markPendingDelete(String relativePath) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = _readSet(prefs, _pendingUploadKey)..remove(relativePath);
    final deletes = _readSet(prefs, _pendingDeleteKey)..add(relativePath);
    await _writeSet(prefs, _pendingUploadKey, uploads);
    await _writeSet(prefs, _pendingDeleteKey, deletes);
  }

  static Future<Set<String>> pendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    return _readSet(prefs, _pendingUploadKey);
  }

  static Future<Set<String>> pendingDeletes() async {
    final prefs = await SharedPreferences.getInstance();
    return _readSet(prefs, _pendingDeleteKey);
  }

  static Future<void> clearUpload(String relativePath) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = _readSet(prefs, _pendingUploadKey)..remove(relativePath);
    await _writeSet(prefs, _pendingUploadKey, uploads);
  }

  static Future<void> clearDelete(String relativePath) async {
    final prefs = await SharedPreferences.getInstance();
    final deletes = _readSet(prefs, _pendingDeleteKey)..remove(relativePath);
    await _writeSet(prefs, _pendingDeleteKey, deletes);
  }

  static Set<String> _readSet(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return <String>{};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  static Future<void> _writeSet(SharedPreferences prefs, String key, Set<String> value) async {
    await prefs.setString(key, jsonEncode(value.toList()));
  }
}
