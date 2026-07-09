import 'package:shared_preferences/shared_preferences.dart';

/// Явна згода з Політикою конфіденційності — обов'язковий крок онбордингу
/// (в будь-якому з трьох флоу: створення акаунта, підключення до сім'ї,
/// відновлення). На відміну від [AiConsentService] (згода на конкретну
/// хмарну функцію, можна відкликати без наслідків для решти застосунку),
/// ця згода — умова використання застосунку взагалі, тому екран не дає
/// відкрити дашборд без неї.
///
/// Версія зберігається окремо від дати — якщо документ суттєво зміниться,
/// досить підняти [currentVersion], і `hasAccepted` знову поверне false,
/// поки користувач не погодиться заново.
class PrivacyConsentService {
  static const currentVersion = '1.0';

  static const _versionKey = 'privacy_policy_consent_version';
  static const _dateKey = 'privacy_policy_consent_date';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_versionKey) == currentVersion;
  }

  static Future<void> recordAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, currentVersion);
    await prefs.setString(_dateKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> acceptedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dateKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<String?> acceptedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_versionKey);
  }
}
