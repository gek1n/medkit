import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../providers/plan_provider.dart';
import 'subscription_service.dart';

/// FCM Topics для сегментованих push-розсилок (маркетинг) — НЕ плутати з
/// grants_summary/relay (ті теми — про синхронізацію даних між пірами).
/// Сервер тут узагалі ні до чого — теми і кампанії керуються лише з Firebase
/// Console, наш код відповідає тільки за те, щоб кожен пристрій сам
/// підписався на правильні теми виходячи з локального стану.
///
/// Дві категорії тем:
/// - "Core" (тариф/мова/платформа/онбординг) — повністю перераховуються
///   [syncCoreTopics] на кожному resume/cold-start (той самий тригер, що й
///   [SubscriptionService.refreshFromServer]), із diff проти попереднього
///   набору, щоб не смітити зайвими subscribe/unsubscribe.
/// - "Поведінкові" (hit_*_limit, viewed_plans_no_purchase) — вмикаються й
///   вимикаються точково, з конкретних місць у коді (де саме людина впирається
///   в ліміт чи відкриває екран тарифів), не чіпаються syncCoreTopics.
class MarketingTopicsService {
  static const _coreTopicsKey = 'marketing_core_topics_v1';

  // ── Core-теми — повний перерахунок ───────────────────────────────────

  static Future<void> syncCoreTopics(AppDatabase db) async {
    try {
      final topics = <String>{'all_users', _platformTopic(), _localeTopic()};

      final owner = await MembersRepository(db).getOwner();
      if (owner == null) {
        // Онбординг ще не завершено (немає жодного власного профілю) —
        // тарифні теми тут не мають сенсу.
        topics.add('onboarding_incomplete');
      } else {
        topics.add(await _planTopic());
        if (await _isFamilyGuestWithActiveGift(db)) {
          topics.add('plan_family_guest');
        }
      }

      await _applyCoreDiff(topics);
    } catch (_) {
      // Best-effort — маркетингові теми не повинні ламати запуск застосунку.
    }
  }

  static String _platformTopic() => Platform.isIOS ? 'platform_ios' : 'platform_android';

  /// Мова ПРИСТРОЮ (system locale), а не мова інтерфейсу застосунку — та
  /// сьогодні завжди 'uk' (main.dart: `locale: const Locale('uk')`,
  /// перемикача мови в UI ще немає). Для тексту push-розсилки важливіше
  /// реальне мовне вподобання людини, тому береться саме системна локаль.
  static String _localeTopic() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return code == 'uk' ? 'lang_uk' : 'lang_en';
  }

  static Future<String> _planTopic() async {
    return switch (await SubscriptionService.cachedPlan()) {
      AppPlan.free => 'plan_free',
      AppPlan.plus => 'plan_plus',
      AppPlan.family => 'plan_family_payer',
    };
  }

  /// Гість у ЧУЖІЙ сім'ї з активним подарунком — той самий розрахунок, що й
  /// у realPlanProvider (invitedMe==true && payerPlanActive==true).
  static Future<bool> _isFamilyGuestWithActiveGift(AppDatabase db) async {
    final peers = await FamilyPeersRepository(db).allPeers();
    return peers.any((p) => p.invitedMe && p.payerPlanActive);
  }

  static Future<void> _applyCoreDiff(Set<String> desired) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = (prefs.getStringList(_coreTopicsKey) ?? const []).toSet();

    for (final topic in desired.difference(previous)) {
      await _subscribe(topic);
    }
    for (final topic in previous.difference(desired)) {
      await _unsubscribe(topic);
    }
    await prefs.setStringList(_coreTopicsKey, desired.toList());
  }

  // ── Поведінкові теми — точкові тригери ───────────────────────────────
  // "hit_*_limit" — людина щойно вперлася у безкоштовний ліміт, найгарячіший
  // сигнал готовності купити. "viewed_plans_no_purchase" — відкрила екран
  // тарифів, але не купила (класичний "покинутий кошик"). Обидва прибираються
  // одразу після успішної покупки (PlansScreen._selectPaid).

  static Future<void> markHitScanLimit() => _subscribe('hit_scan_limit');
  static Future<void> markHitVoiceLimit() => _subscribe('hit_voice_limit');
  static Future<void> markHitLocalLimit() => _subscribe('hit_local_limit');
  static Future<void> markViewedPlansNoPurchase() => _subscribe('viewed_plans_no_purchase');

  /// Викликати одразу після успішної покупки — усі "готовий купити" сигнали
  /// втрачають сенс, людина вже купила.
  static Future<void> clearPurchaseIntentTopics() async {
    await _unsubscribe('hit_scan_limit');
    await _unsubscribe('hit_voice_limit');
    await _unsubscribe('hit_local_limit');
    await _unsubscribe('viewed_plans_no_purchase');
  }

  static Future<void> _subscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {
      // Firebase не налаштований на цьому білді — не критично.
    }
  }

  static Future<void> _unsubscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {
      // Не критично.
    }
  }
}
