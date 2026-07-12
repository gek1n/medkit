import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import 'family_peer_sync_service.dart';
import 'subscription_service.dart';

/// Грейс-період і розпад ВЛАСНОЇ сім'ї при неоплаті (docs/multifamily_billing_plan.md,
/// розділ 4, пункти 1-2). Окремий файл від [SubscriptionService] навмисно —
/// щоб уникнути циклічного імпорту (`FamilyPeerSyncService` вже імпортує
/// `SubscriptionService` для `payerPlanActive`).
///
/// Викликається з `main.dart` (`_ShellState._billingSyncIfNeeded`) одразу
/// після кожного `SubscriptionService.refreshFromServer()` — на
/// resume/cold-start, той самий тригер, що й family-синк.
class BillingLifecycleService {
  static const _graceStartedAtKey = 'billing_grace_started_at';

  /// Наша власна обіцянка користувачу, незалежно від того, який грейс-період
  /// (якщо взагалі якийсь) дають самі Apple/Google на своєму боці.
  ///
  /// ⚠️ ТИМЧАСОВО 2 хвилини замість 5 днів — для тестування повного флоу
  /// (поп-ап → очікування → авторозрив) на реальних пристроях, не чекаючи
  /// реальні 5 днів. Стан підписки для тесту міняється напряму в БД
  /// (`subscriptions.status`) через phpMyAdmin — окремого debug-UI не
  /// потрібно, `/subscription/status` і так читає прямо з таблиці (DEPLOY.md,
  /// крок 13.0). Повернути на `Duration(days: 5)` перед реальним запуском.
  static const gracePeriod = Duration(minutes: 2);

  /// Викликати одразу після [SubscriptionService.refreshFromServer].
  static Future<GraceCheckResult> checkGraceAndMaybeDisband(AppDatabase db) async {
    final cached = await SubscriptionService.cachedRawStatus();
    final prefs = await SharedPreferences.getInstance();

    if (cached.status == 'active' || cached.status == 'none') {
      // Оплата йде нормально (чи взагалі немає підписки, нема що грейсити) —
      // прибираємо будь-який попередній відлік.
      await prefs.remove(_graceStartedAtKey);
      return GraceCheckResult.none;
    }

    // 'grace' | 'expired' | 'cancelled' — почали (чи продовжуємо) відлік.
    final startedRaw = prefs.getString(_graceStartedAtKey);
    if (startedRaw == null) {
      await prefs.setString(_graceStartedAtKey, DateTime.now().toIso8601String());
      return GraceCheckResult.graceStarted;
    }

    final startedAt = DateTime.tryParse(startedRaw);
    if (startedAt == null || DateTime.now().difference(startedAt) < gracePeriod) {
      return GraceCheckResult.graceOngoing;
    }

    // Грейс вичерпано — розриваємо ВЛАСНУ сім'ю (я платящий для неї). Ніколи
    // не видаляємо локальні дані — leaveGroup лише чистить FamilyPeers/
    // SharedEntities-кеш, "в борг" заведені профілі просто заморожуються
    // (view+delete можна, create/edit — ні) через уже існуючий
    // isMemberBlockedByPlan/EllyDeniedScreen, щойно ефективний план впаде.
    final owner =
        await (db.select(db.members)..where((t) => t.role.equals('owner'))).getSingleOrNull();
    final ownerFamilyId = owner?.familyId;
    if (ownerFamilyId != null) {
      await FamilyPeerSyncService(db).leaveGroup(ownerFamilyId);
    }
    await prefs.remove(_graceStartedAtKey);
    return GraceCheckResult.disbanded;
  }

  /// Скільки часу лишилось до автоматичного розпаду — для тексту поп-апу
  /// (`GraceCheckResult.graceStarted`/`graceOngoing`). `Duration.zero`, якщо
  /// відлік ще не починався (не мало б викликатись у цьому випадку).
  /// Duration, а не int-днів — навмисно, щоб коректно показувати як реальні
  /// 5 днів, так і тимчасовий тестовий gracePeriod у хвилинах.
  static Future<Duration> timeLeftInGrace() async {
    final prefs = await SharedPreferences.getInstance();
    final startedRaw = prefs.getString(_graceStartedAtKey);
    final startedAt = startedRaw != null ? DateTime.tryParse(startedRaw) : null;
    if (startedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(startedAt);
    final left = gracePeriod - elapsed;
    return left.isNegative ? Duration.zero : left;
  }
}

/// - [none] — активна підписка чи взагалі немає підписки, нічого робити не треба.
/// - [graceStarted] — щойно вперше побачили неактивний статус, показати
///   поп-ап "залишилось 5 днів".
/// - [graceOngoing] — грейс триває, показати "залишилось N днів" далі.
/// - [disbanded] — грейс вичерпано, власна сім'я щойно розірвана, показати
///   модалку "що змінилось і чому".
enum GraceCheckResult { none, graceStarted, graceOngoing, disbanded }
