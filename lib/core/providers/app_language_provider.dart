import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Мова застосунку — поки що керує лише мовою розпізнавання голосу
/// (speech_to_text у voice_screen.dart/wellbeing_check_screen.dart/
/// grounding_54321_screen.dart), бо повноцінного перекладу інтерфейсу ще
/// нема. Коли з'являться переклади під різні країни поширення — цей самий
/// вибір стане й мовою UI, тому назва провайдера вже загальна ("мова
/// застосунку"), а не "мова диктування".
class AppLanguage {
  final String id; // BCP-47/ICU локаль, як очікує speech_to_text
  final String label;
  const AppLanguage(this.id, this.label);
}

const appLanguages = [
  AppLanguage('uk_UA', 'Українська'),
  AppLanguage('ru_RU', 'Русский'),
  AppLanguage('en_US', 'English'),
];

const _fallbackLanguageId = 'en_US';

String appLanguageLabel(String id) =>
    appLanguages.firstWhere((l) => l.id == id, orElse: () => appLanguages.first).label;

/// Перший запуск (нема збереженого вибору) — підставляємо мову пристрою,
/// якщо вона є серед підтримуваних, інакше англійську (не українську —
/// та була дефолтом лише як мова розробки, англійська ж дійсно розуміється
/// найширше з усіх, кого немає в списку).
String _detectDeviceLanguageId() {
  final deviceCode = PlatformDispatcher.instance.locale.languageCode;
  for (final l in appLanguages) {
    if (l.id.startsWith('${deviceCode}_')) return l.id;
  }
  return _fallbackLanguageId;
}

class AppLanguageNotifier extends StateNotifier<String> {
  AppLanguageNotifier() : super(_detectDeviceLanguageId()) {
    _load();
  }

  // Ключ навмисно лишився старим ('voice_locale_id', з часів, коли це
  // налаштування стосувалось лише голосового екрана) — щоб вибір мови, який
  // користувачі вже зробили до цього перейменування, не скинувся мовчки.
  static const _key = 'voice_locale_id';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      state = saved;
    } else {
      // Перший запуск — запам'ятовуємо визначену мову пристрою одразу, а не
      // лише тримаємо її в state: інакше _VoiceCommentField/Grounding54321
      // (незалежний loadLanguageId() нижче, читає з SharedPreferences
      // напряму, не з цього state) побачили б інший, ще не збережений вибір.
      await prefs.setString(_key, state);
    }
  }

  Future<void> set(String languageId) async {
    state = languageId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageId);
  }

  /// Незалежний від Riverpod завантажувач — для віджетів без ref (напр.
  /// _VoiceCommentField у wellbeing_check_screen.dart, звичайний
  /// StatefulWidget без ConsumerState).
  static Future<String> loadLanguageId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? _detectDeviceLanguageId();
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, String>(
        (ref) => AppLanguageNotifier());
