import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyStorage {
  static const _key = 'anthropic_api_key';

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> write(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
