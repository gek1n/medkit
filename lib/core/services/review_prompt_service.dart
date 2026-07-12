import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/plan_provider.dart';

/// Автоматичний запит "Оцінити застосунок" — окремо від ручної кнопки в
/// Профілі (яка лишається як є). Apple/Google самі жорстко обмежують, як
/// часто діалог РЕАЛЬНО показується (iOS — не більше ~3 разів на рік,
/// незалежно від кількості викликів requestReview()) і не дають зворотного
/// зв'язку, чи показався він і що відповів користувач — тому логіка нижче
/// лише РІШАЄ, коли ЗАПИТАТИ систему, а не гарантує реальний показ.
///
/// Три тригери, кожен через тиждень після своєї події: встановлення,
/// покупка Plus, покупка Family. За один виклик [maybeShow] спрацьовує
/// щонайбільше один — щоб не закидати запитами в одну сесію.
class ReviewPromptService {
  static const _installDateKey = 'review_install_date';
  static const _plusPurchaseDateKey = 'review_plus_purchase_date';
  static const _familyPurchaseDateKey = 'review_family_purchase_date';

  static const _shownForInstallKey = 'review_shown_install';
  static const _shownForPlusKey = 'review_shown_plus';
  static const _shownForFamilyKey = 'review_shown_family';

  static const _delay = Duration(days: 7);

  /// Викликати ОДИН РАЗ на найпершому старті застосунку (main.dart) —
  /// фіксує install_date, якщо його ще немає. Безпечно викликати щоразу:
  /// пише лише коли ключа ще нема.
  static Future<void> recordInstallIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_installDateKey) == null) {
      await prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Викликати одразу після успішної покупки Plus/Family (PlansScreen).
  /// Перезаписує дату щоразу навмисно — якщо людина купує повторно після
  /// розриву/паузи, тиждень рахується з НОВОЇ покупки, а не з першої, і
  /// відповідний тригер стає доступним знову (новий привід запитати).
  static Future<void> recordPurchase(AppPlan plan) async {
    if (plan == AppPlan.free) return;
    final prefs = await SharedPreferences.getInstance();
    final isFamily = plan == AppPlan.family;
    await prefs.setString(
      isFamily ? _familyPurchaseDateKey : _plusPurchaseDateKey,
      DateTime.now().toIso8601String(),
    );
    await prefs.remove(isFamily ? _shownForFamilyKey : _shownForPlusKey);
  }

  /// Викликати на тих самих тригерах, що й інші sync-хуки (resume/cold-start
  /// у main.dart).
  static Future<void> maybeShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      bool due(String dateKey, String shownKey) {
        if (prefs.getBool(shownKey) ?? false) return false;
        final raw = prefs.getString(dateKey);
        if (raw == null) return false;
        final date = DateTime.tryParse(raw);
        if (date == null) return false;
        return now.difference(date) >= _delay;
      }

      String? toMark;
      if (due(_installDateKey, _shownForInstallKey)) {
        toMark = _shownForInstallKey;
      } else if (due(_plusPurchaseDateKey, _shownForPlusKey)) {
        toMark = _shownForPlusKey;
      } else if (due(_familyPurchaseDateKey, _shownForFamilyKey)) {
        toMark = _shownForFamilyKey;
      }
      if (toMark == null) return;

      // Позначаємо ДО виклику — навіть якщо ОС вирішить не показувати
      // діалог (свій ліміт вичерпано), повторно смикати цей самий тригер
      // сенсу нема, він одноразовий.
      await prefs.setBool(toMark, true);

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Не критично — спробуємо на наступному тригері (для install він уже
      // не спрацює повторно, зате purchase-тригери можуть, якщо саме там
      // впав виклик).
    }
  }
}
