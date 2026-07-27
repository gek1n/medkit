import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Історія всіх тегів, які користувач колись вводив у нагадуваннях —
/// пропонується як список для вибору (мультивибір) наступного разу, той
/// самий підхід, що й [ReminderTitleLibraryService].
class ReminderTagsLibraryService {
  static const _key = 'reminder_tags_history';

  static Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> addAll(Iterable<String> values) async {
    final trimmed = values.map((v) => v.trim()).where((v) => v.isNotEmpty);
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAll();
    for (final v in trimmed) {
      if (!existing.any((e) => e.toLowerCase() == v.toLowerCase())) {
        existing.add(v);
      }
    }
    await prefs.setString(_key, jsonEncode(existing));
  }
}
