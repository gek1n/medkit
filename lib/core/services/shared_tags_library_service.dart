import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Історія тегів, спільна для нагадувань і нотаток (записів поличок) — щоб
/// один і той самий тег можна було шукати серед обох типів. Самопочуття
/// має власний окремий набір ([WellbeingTagLibraryService]) — теги настрою
/// навмисно не змішуються із завданнями.
///
/// [getAll] також підмішує значення зі старих роздільних ключів
/// (`reminder_tags_history`/`medcard_entry_tags_history`), щоб теги, введені
/// до об'єднання, не зникли зі списку вибору.
class SharedTagsLibraryService {
  static const _key = 'shared_tags_history';
  static const _legacyKeys = [
    'reminder_tags_history',
    'medcard_entry_tags_history',
  ];

  static Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final merged = <String>[];
    void mergeIn(String? raw) {
      if (raw == null) return;
      try {
        for (final v in (jsonDecode(raw) as List).cast<String>()) {
          if (!merged.any((e) => e.toLowerCase() == v.toLowerCase())) {
            merged.add(v);
          }
        }
      } catch (_) {}
    }

    mergeIn(prefs.getString(_key));
    for (final legacyKey in _legacyKeys) {
      mergeIn(prefs.getString(legacyKey));
    }
    return merged;
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
