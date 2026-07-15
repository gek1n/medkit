import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Розділи застосунку, де можлива партнерська (affiliate) кнопка "Купити".
/// Зараз реально використовується лише [medications] — doctors/nutra лишені
/// тут як заплановані на майбутнє, щоб формат конфігу нижче не довелось
/// міняти, коли вони з'являться.
enum AffiliateSection { medications, doctors, nutra }

/// Конфіг партнерських посилань: країна → розділ → одне спільне посилання
/// (не на конкретний товар/сторінку — на головну партнера, той самий підхід
/// для всіх ліків у розділі). Кнопка "Купити" показується лише там, де для
/// поточної країни користувача явно прописане посилання — немає запису =
/// кнопки нема, без жодного дефолтного/глобального фолбека.
///
/// Навмисно НЕ компільований у застосунок як `const` — суть конфігу саме в
/// тому, щоб посилання можна було змінити чи додати на сервері
/// (medkit-backend/medkit_private/config/affiliate_links.php) без нового
/// релізу застосунку. Клієнт підтягує JSON з `GET /config/affiliate-links`
/// (див. [warmUp], викликається один раз з main.dart) і кешує його локально
/// через SharedPreferences, щоб посилання лишались доступні офлайн і на
/// випадок тимчасової недоступності сервера.
class AffiliateConfigService {
  static const _url = 'https://api.elly-medkit.com/config/affiliate-links';
  static const _cacheKey = 'affiliate_links_cache_v1';

  static Map<String, Map<String, String>>? _cache;

  /// Бампається щоразу, коли [_cache] оновлюється — [AffiliateBuyButton]
  /// слухає це через [ValueListenableBuilder], щоб з'явитись без
  /// перезаходу на екран, якщо мережевий запит завершився вже ПІСЛЯ
  /// першого рендеру кнопки (типово на холодному старті).
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<void> warmUp() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && _cache == null) {
      _cache = _tryParse(cached) ?? {};
      revision.value++;
    }
    try {
      final response = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final parsed = _tryParse(response.body);
        if (parsed != null) {
          _cache = parsed;
          revision.value++;
          await prefs.setString(_cacheKey, response.body);
        }
      }
    } catch (_) {
      // Немає мережі чи сервер недоступний — лишаємось на кеші (чи на
      // порожньому конфігу, якщо це взагалі перший запуск застосунку).
    }
    if (_cache == null) {
      _cache = {};
      revision.value++;
    }
  }

  static Map<String, Map<String, String>>? _tryParse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((country, sections) => MapEntry(
            country,
            (sections as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String)),
          ));
    } catch (_) {
      return null;
    }
  }

  /// Посилання для розділу в країні користувача. null, якщо конфіг ще не
  /// підвантажився, чи партнерства для цієї країни/розділу нема — обидва
  /// випадки однаково вимикають кнопку "Купити".
  static String? linkFor(AffiliateSection section, {String? countryCodeOverride}) {
    final country = countryCodeOverride ?? _deviceCountryCode();
    if (country == null || _cache == null) return null;
    return _cache![country]?[section.name];
  }

  // Застосунок поки що не має ні вибору мови, ні реального визначення
  // регіону (інтерфейс завжди українською незалежно від пристрою) — тож
  // визначати країну з locale пристрою (Platform.localeName) сенсу нема:
  // будь-який пристрій з нестандартним системним регіоном (типово — англ.
  // локаль на емуляторах за замовчуванням) ховав би кнопку "Купити" навіть
  // при правильно налаштованому конфізі. Поки єдиний ринок — Україна,
  // просто дефолтимось на 'UA'; коли з'явиться реальний вибір
  // мови/регіону в застосунку — підмінити цей метод на визначення з нього
  // (НЕ з Platform.localeName, який завжди відображає пристрій, а не
  // вибір користувача в застосунку).
  static String? _deviceCountryCode() => 'UA';
}
