import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Черга "видалень, які ще треба повідомити іншій стороні" для family_sync.
/// На відміну від account-sync (де більшість таблиць або взагалі не мають
/// hard delete, або soft-delete через `isActive`/`isTracked`), `Schedules`
/// реально видаляє рядки (`replaceAll`/`delete`) — якщо не запам'ятати це
/// тут ДО видалення, інша сторона ніколи не дізнається, що розклад зник.
class FamilySyncDeleteQueue {
  static const _key = 'family_sync_pending_deletes';

  /// [syncUuid] — той самий ідентифікатор, що йшов у push, коли рядок був
  /// вперше синхронізований; якщо рядок ніколи не синхронізувався (syncUuid
  /// == null), викликати цей метод не потрібно — про нього ніхто не знає.
  static Future<void> enqueue({
    required String channelId,
    required String entityType,
    required String syncUuid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = _readList(prefs)
      ..removeWhere((i) => _matches(i, channelId, entityType, syncUuid))
      ..add({'channelId': channelId, 'entityType': entityType, 'syncUuid': syncUuid});
    await _writeList(prefs, items);
  }

  static Future<List<Map<String, String>>> pendingForChannel(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    return _readList(prefs).where((i) => i['channelId'] == channelId).toList();
  }

  static Future<void> clear({
    required String channelId,
    required String entityType,
    required String syncUuid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = _readList(prefs)
      ..removeWhere((i) => _matches(i, channelId, entityType, syncUuid));
    await _writeList(prefs, items);
  }

  static bool _matches(Map<String, String> item, String channelId, String entityType, String syncUuid) =>
      item['channelId'] == channelId && item['entityType'] == entityType && item['syncUuid'] == syncUuid;

  static List<Map<String, String>> _readList(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
  }

  static Future<void> _writeList(SharedPreferences prefs, List<Map<String, String>> items) async {
    await prefs.setString(_key, jsonEncode(items));
  }
}
