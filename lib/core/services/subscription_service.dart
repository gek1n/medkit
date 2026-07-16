import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_env.dart';
import '../providers/plan_provider.dart';
import 'account_service.dart';
import 'subscription_api_client.dart';

/// Реальний білінг Plus/Family (StoreKit 2 / Play Billing через
/// `in_app_purchase`) + верифікація на сервері. Написано повністю (розділ 6
/// docs/multifamily_billing_plan.md), але СВІДОМО ще не викликається з
/// `PlansScreen` — кнопки там лишаються декоративним перемикачем
/// `planProvider.notifier`, поки користувач не протестує решту фіч і не
/// попросить фінальне переключення (одна маленька задача: замінити onSelect
/// на [buy] тут + активувати [realPlanProvider] замість bare StateProvider).
class SubscriptionService {
  static const _statusCacheKey = 'subscription_status_cache_v1';
  static const _api = SubscriptionApiClient();
  static final _account = AccountService();

  // TODO: замінити на реальні product ID з App Store Connect/Google Play
  // Console (адмінська частина, користувач заповнює сам пізніше) — той самий
  // паттерн-заглушка, що й AccountService._googleServerClientId.
  static const _productIds = {
    (AppPlan.plus, false): 'plus_monthly',
    (AppPlan.plus, true): 'plus_yearly',
    (AppPlan.family, false): 'family_monthly',
    (AppPlan.family, true): 'family_yearly',
  };

  // Те саме значення, що й BILLING_TEST_SECRET у .env бекенду (DEPLOY.md,
  // крок 13.0). Навмисно НЕ хардкодиться в джерельному коді (потрапило б у
  // зібраний APK/IPA й у git-історію) — передається через --dart-define при
  // збірці/запуску, той самий флаг для debug-run і для реального білда
  // (включно з TestFlight — прапорець баковиться в бінарник під час
  // архівації, а не вводиться користувачем у рантаймі):
  //   flutter run --dart-define=BILLING_TEST_SECRET=...
  //   flutter build ipa --release --dart-define=BILLING_TEST_SECRET=...
  //   flutter build apk --release --dart-define=BILLING_TEST_SECRET=...
  // Порожній рядок за замовчуванням — verifyTest/cancelTest без нього
  // впадуть з помилкою сервера (тестовий режим і так лише для локального
  // тестування, ніколи не потрапляє в реальний реліз у сторах).
  static const _testSecret = String.fromEnvironment('BILLING_TEST_SECRET');

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Реальні відформатовані ціни (з символом валюти, локалізовані самим
  /// стором під регіон акаунта користувача) для платних тарифів — ключ той
  /// самий, що й [_productIds]. Порожня мапа, якщо стор недоступний чи
  /// продукти ще не створені в App Store Connect/Google Play Console —
  /// [PlansScreen] тоді лишає попередньо захардкожені орієнтовні ціни.
  /// Безпечно викликати і в тестовій, і в продакшн-збірці: це лише
  /// read-only запит каталогу, без жодної покупки.
  static Future<Map<(AppPlan, bool), String>> queryPrices() async {
    try {
      if (!await InAppPurchase.instance.isAvailable()) return {};
      final response = await InAppPurchase.instance.queryProductDetails(
        _productIds.values.toSet(),
      );
      final byId = {for (final p in response.productDetails) p.id: p.price};
      return {
        for (final entry in _productIds.entries)
          if (byId[entry.value] != null) entry.key: byId[entry.value]!,
      };
    } catch (_) {
      return {};
    }
  }

  // ── Кеш статусу (SharedPreferences) — читає realPlanProvider ────────────

  static Future<void> _persistStatus(SubscriptionStatusResult status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusCacheKey, jsonEncode({
      'status': status.status,
      'product_id': status.productId,
      'expires_at': status.expiresAt?.toIso8601String(),
    }));
  }

  /// "Сирий" кешований статус БЕЗ мережевого виклику — 'active' | 'grace' |
  /// 'expired' | 'cancelled' | 'none' (кешу ще нема чи синк вимкнено).
  /// Публічний окремо від [cachedPlan] заради [BillingLifecycleService] —
  /// їй потрібно розрізняти 'active' від 'grace' (це вже "план активний" для
  /// [cachedPlan], але різні речі для грейс-таймера).
  static Future<CachedSubscriptionStatus> cachedRawStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusCacheKey);
    if (raw == null) return const CachedSubscriptionStatus(status: 'none');
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const CachedSubscriptionStatus(status: 'none');
    }

    final status = json['status'] as String? ?? 'none';
    final expiresAtRaw = json['expires_at'] as String?;
    final expiresAt = expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;
    // 'active' з простроченим expiresAt (кеш не оновлювався якийсь час) —
    // трактуємо як 'expired', щоб не довіряти застарілому "активний" вічно.
    final effectiveStatus =
        (status == 'active' && expiresAt != null && expiresAt.isBefore(DateTime.now()))
            ? 'expired'
            : status;

    return CachedSubscriptionStatus(
      status: effectiveStatus,
      productId: json['product_id'] as String?,
      expiresAt: expiresAt,
    );
  }

  /// Кешований план БЕЗ мережевого виклику — читає останній відомий
  /// [refreshFromServer]/[verifyAndPersist] результат. `free`, якщо синк
  /// вимкнено (SyncMode.local) чи кешу ще нема.
  static Future<AppPlan> cachedPlan() async {
    final cached = await cachedRawStatus();
    if (cached.status != 'active' && cached.status != 'grace') return AppPlan.free;
    return _planForProductId(cached.productId);
  }

  static AppPlan _planForProductId(String? productId) {
    if (productId == null) return AppPlan.free;
    if (productId.startsWith('family')) return AppPlan.family;
    if (productId.startsWith('plus')) return AppPlan.plus;
    return AppPlan.free;
  }

  /// Викликати на тих самих тригерах, що й FamilyGroupService.refreshPeers()
  /// (відкриття/resume застосунку) — дешевий lookup, не окремий
  /// polling-цикл. No-op, якщо синк вимкнено (SyncMode.local — нема
  /// account_id, нема що перевіряти на сервері).
  static Future<void> refreshFromServer() async {
    final accountId = await _account.currentAccountId();
    final hash = await _account.currentRecoveryKeyHash();
    if (accountId == null || hash == null) return;

    try {
      final status = await _api.status(accountId: accountId, recoveryKeyHash: hash);
      await _persistStatus(status);
    } catch (_) {
      // Мережа недоступна чи сервер тимчасово не відповідає — кеш лишається
      // попереднім (планProvider не мигне назад на free через тимчасовий збій).
    }
  }

  /// Результат [buy]/[restorePurchases] — [newRecoveryKeyDisplay] заповнений
  /// лише коли покупка сама створила sync-акаунт (пристрій був у
  /// SyncMode.local) — UI-шар має одразу показати екран "збережіть recovery
  /// key" (Рішення з docs/multifamily_billing_plan.md, розділ 4: НІКОЛИ не
  /// тихо, завжди explicit екран).
  static Future<PurchaseOutcome> buy(AppPlan plan, {required bool yearly}) async {
    if (plan == AppPlan.free) {
      throw ArgumentError('Безкоштовний план не купується');
    }
    final productId = _productIds[(plan, yearly)]!;

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      throw StateError('Магазин застосунків недоступний на цьому пристрої');
    }

    final response = await InAppPurchase.instance.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw StateError('Продукт "$productId" не знайдено в App Store/Google Play');
    }

    final purchase = await _buyAndAwait(response.productDetails.first);
    return _verifyPurchase(plan: plan, productId: productId, purchase: purchase);
  }

  /// Єдина точка входу для UI (`PlansScreen`) — сама вирішує, реальна це
  /// покупка через StoreKit/Play Billing чи тестова через сервер, залежно
  /// від збірки. UI-код НЕ повинен сам обирати між [buy]/[buyTest] — весь
  /// вибір тут, в одному місці, щоб продакшн-збірка фізично не могла
  /// випадково піти тестовим шляхом.
  static Future<PurchaseOutcome> purchase(AppPlan plan, {required bool yearly}) {
    return AppEnv.isTestBuild ? buyTest(plan, yearly: yearly) : buy(plan, yearly: yearly);
  }

  /// Єдина точка входу для "піти геть з платного тарифу". Реальні підписки
  /// App Store/Google Play НЕ можна скасувати викликом з застосунку —
  /// Apple/Google це прямо забороняють, скасування завжди йде через рідне
  /// керування підпискою. У тестовій збірці лишається старий шлях
  /// ([cancelTest] — миттєво знімає план на сервері, зручно для тестування
  /// грейс-періоду/розпаду сім'ї). Повертає true, якщо план змінено
  /// локально одразу (тестовий шлях); false, якщо лише відкрито рідне
  /// керування підпискою і користувач має завершити скасування там сам —
  /// UI не повинен нічого міняти локально в цьому випадку, справжній
  /// статус прийде з наступної [refreshStatus] (сервер дізнається про
  /// скасування від Apple/Google через їхній власний механізм сповіщень).
  static Future<bool> cancelOrManageSubscription() async {
    if (AppEnv.isTestBuild) {
      await cancelTest();
      return true;
    }
    final uri = Uri.parse(Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return false;
  }

  /// "Відновити покупки" — для нового пристрою чи переустановки. Play/App
  /// Store самі знають про вже куплені активні підписки цього
  /// Apple ID/Google-акаунта.
  static Future<List<PurchaseOutcome>> restorePurchases() async {
    final completer = Completer<List<PurchaseDetails>>();
    late final StreamSubscription sub;
    sub = InAppPurchase.instance.purchaseStream.listen((purchases) {
      if (purchases.isNotEmpty) {
        completer.complete(purchases);
        sub.cancel();
      }
    }, onError: (Object e) {
      if (!completer.isCompleted) completer.completeError(e);
      sub.cancel();
    });

    await InAppPurchase.instance.restorePurchases();
    final purchases = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        sub.cancel();
        return const [];
      },
    );

    final outcomes = <PurchaseOutcome>[];
    for (final purchase in purchases) {
      if (purchase.status != PurchaseStatus.restored && purchase.status != PurchaseStatus.purchased) {
        continue;
      }
      final plan = _planForProductId(purchase.productID);
      if (plan == AppPlan.free) continue;
      outcomes.add(await _verifyPurchase(plan: plan, productId: purchase.productID, purchase: purchase));
    }
    return outcomes;
  }

  static Future<PurchaseDetails> _buyAndAwait(ProductDetails product) async {
    final completer = Completer<PurchaseDetails>();
    late final StreamSubscription sub;
    sub = InAppPurchase.instance.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (p.productID != product.id) continue;
        if (p.status == PurchaseStatus.error) {
          if (!completer.isCompleted) completer.completeError(p.error ?? StateError('Покупка не вдалась'));
          sub.cancel();
        } else if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
          if (!completer.isCompleted) completer.complete(p);
          sub.cancel();
        }
        // canceled — просто чекаємо далі/completer ніколи не завершиться до
        // таймауту нижче, той самий підхід, що й у SubscriptionService.buy
        // caller (показує "Скасовано" по exception з timeout).
      }
    });

    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );

    return completer.future.timeout(const Duration(minutes: 5), onTimeout: () {
      sub.cancel();
      throw StateError('Покупку скасовано або час очікування вичерпано');
    });
  }

  static Future<PurchaseOutcome> _verifyPurchase({
    required AppPlan plan,
    required String productId,
    required PurchaseDetails purchase,
  }) async {
    // iOS (StoreKit 2 через in_app_purchase_storekit): purchaseID —
    // originalTransactionId, саме те, що приймає App Store Server API.
    // Android (Play Billing): serverVerificationData — purchase token.
    final receipt = Platform.isIOS
        ? (purchase.purchaseID ?? purchase.verificationData.serverVerificationData)
        : purchase.verificationData.serverVerificationData;

    final account = await _ensureAccount();

    final status = await _api.verify(
      accountId: account.accountId,
      recoveryKeyHash: account.recoveryKeyHash,
      platform: _platform,
      productId: productId,
      receipt: receipt,
    );
    await _persistStatus(status);
    await InAppPurchase.instance.completePurchase(purchase);

    return PurchaseOutcome(status: status, newRecoveryKeyDisplay: account.newRecoveryKeyDisplay);
  }

  /// SyncMode.local → покупка Plus/Family автоматично вмикає sync-акаунт
  /// (обидва платні тарифи й сьогодні мають serverSync:true в PlanLimits,
  /// тож без акаунта покупка все одно була б безсенсовна). НІКОЛИ тихо —
  /// [_EnsuredAccount.newRecoveryKeyDisplay] заповнюється, коли акаунт щойно
  /// створено, UI-шар одразу показує екран "збережіть recovery key"
  /// (Рішення, docs/multifamily_billing_plan.md, розділ 4).
  static Future<_EnsuredAccount> _ensureAccount() async {
    String? newRecoveryKeyDisplay;
    var accountId = await _account.currentAccountId();
    var hash = await _account.currentRecoveryKeyHash();
    if (accountId == null || hash == null) {
      newRecoveryKeyDisplay = AccountService.generateRecoveryKey();
      await _account.enableNoAccountSync(newRecoveryKeyDisplay);
      accountId = await _account.currentAccountId();
      hash = await _account.currentRecoveryKeyHash();
    }
    if (accountId == null || hash == null) {
      throw StateError('Не вдалося створити sync-акаунт для підтвердження покупки');
    }
    return _EnsuredAccount(accountId, hash, newRecoveryKeyDisplay);
  }

  // ── Тестовий режим (docs/multifamily_billing_plan.md, "Тестовий режим
  // біллінгу") — реальний сервер+синк, БЕЗ реального походу до Apple/Google
  // і БЕЗ in_app_purchase. Існує лише для тестування мультисемейності на
  // кількох реальних пристроях до налаштування App Store Connect/Google
  // Play Console. Сервер сам вимкне ці ендпоінти (404), якщо
  // BILLING_TEST_MODE/BILLING_TEST_SECRET не налаштовані в його .env.

  static Future<PurchaseOutcome> buyTest(AppPlan plan, {required bool yearly}) async {
    if (plan == AppPlan.free) {
      throw ArgumentError('Безкоштовний план не купується');
    }
    final productId = _productIds[(plan, yearly)]!;
    final account = await _ensureAccount();

    final status = await _api.verifyTest(
      accountId: account.accountId,
      recoveryKeyHash: account.recoveryKeyHash,
      platform: _platform,
      productId: productId,
      testSecret: _testSecret,
    );
    await _persistStatus(status);
    return PurchaseOutcome(status: status, newRecoveryKeyDisplay: account.newRecoveryKeyDisplay);
  }

  /// Тестовий аналог миттєвого розриву (добровільна зміна тарифу ГЕТЬ від
  /// Family) — прибирає підписку на сервері одразу, щоб інші пристрої теж
  /// побачили зміну на своєму наступному resume. No-op, якщо синк вимкнено.
  static Future<void> cancelTest() async {
    final accountId = await _account.currentAccountId();
    final hash = await _account.currentRecoveryKeyHash();
    if (accountId == null || hash == null) return;

    await _api.cancelTest(accountId: accountId, recoveryKeyHash: hash, testSecret: _testSecret);
    await _persistStatus(const SubscriptionStatusResult(status: 'none'));
  }
}

class _EnsuredAccount {
  final String accountId;
  final String recoveryKeyHash;
  final String? newRecoveryKeyDisplay;
  const _EnsuredAccount(this.accountId, this.recoveryKeyHash, this.newRecoveryKeyDisplay);
}

class PurchaseOutcome {
  final SubscriptionStatusResult status;
  final String? newRecoveryKeyDisplay;

  const PurchaseOutcome({required this.status, this.newRecoveryKeyDisplay});
}

/// [status] — 'none' | 'active' | 'grace' | 'expired' | 'cancelled'.
class CachedSubscriptionStatus {
  final String status;
  final String? productId;
  final DateTime? expiresAt;

  const CachedSubscriptionStatus({required this.status, this.productId, this.expiresAt});
}
