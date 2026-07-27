import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Історія тегів самопочуття — окрема від тегів нагадувань
/// ([ReminderTagsLibraryService]): різні контексти, різні набори міток.
class WellbeingTagLibraryService {
  static const _key = 'wellbeing_tags_history';

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
