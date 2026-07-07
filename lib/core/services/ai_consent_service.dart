import 'package:shared_preferences/shared_preferences.dart';

/// Явна згода користувача перед першим використанням хмарної AI-функції.
/// Зберігається тільки локально (timestamp), сервер про це нічого не знає.
class AiConsentService {
  static const _prefix = 'ai_consent_';

  static Future<bool> hasConsent(String kind) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$kind') != null;
  }

  static Future<void> recordConsent(String kind) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$kind', DateTime.now().toIso8601String());
  }
}
