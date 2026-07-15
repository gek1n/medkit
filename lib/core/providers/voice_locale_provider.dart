import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Мова розпізнавання голосу (speech_to_text) — НЕЗАЛЕЖНА від мови
/// інтерфейсу застосунку (свого повноцінного вибору мови UI ще нема,
/// інтерфейс лишається українською). Раніше `localeId` у voice_screen.dart
/// був захардкоджений на 'uk_UA', тож диктування будь-якою іншою мовою
/// (напр. російською) розпізнавач просто не розумів — це налаштування дає
/// користувачу явно обрати мову диктування.
class VoiceLocale {
  final String id; // BCP-47/ICU локаль, як очікує speech_to_text
  final String label;
  const VoiceLocale(this.id, this.label);
}

const voiceLocales = [
  VoiceLocale('uk_UA', 'Українська'),
  VoiceLocale('ru_RU', 'Русский'),
  VoiceLocale('en_US', 'English'),
];

const _defaultLocaleId = 'uk_UA';

class VoiceLocaleNotifier extends StateNotifier<String> {
  VoiceLocaleNotifier() : super(_defaultLocaleId) {
    _load();
  }

  static const _key = 'voice_locale_id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) state = saved;
  }

  Future<void> set(String localeId) async {
    state = localeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, localeId);
  }
}

final voiceLocaleProvider =
    StateNotifierProvider<VoiceLocaleNotifier, String>(
        (ref) => VoiceLocaleNotifier());
