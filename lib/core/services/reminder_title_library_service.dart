import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Історія назв, які користувач вводив у полі нагадування (колишній
/// "Напрямок лікаря") — та сама ідея, що й [LabTestLibraryService], але без
/// попередньо заданого списку: тут немає фіксованого словника, лише вільний
/// текст, який пропонується наступного разу.
class ReminderTitleLibraryService {
  static const _key = 'reminder_title_history';

  static Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> add(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAll();
    existing.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    existing.insert(0, trimmed);
    await prefs.setString(_key, jsonEncode(existing.take(50).toList()));
  }
}
