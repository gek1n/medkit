import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_service.dart';
import '../services/family_api_client.dart';
import '../services/family_server_sync_service.dart';

/// Кешований (SharedPreferences, без мережевого виклику тут) знімок
/// останнього `/family/status` — той самий контракт, що й `realPlanProvider`
/// (`core/providers/real_plan_provider.dart`): `FamilyServerSyncService.
/// syncAll()`/`pushGrantsNow()` оновлюють кеш, `main.dart` після цього
/// викликає `ref.invalidate(familyStatusProvider)`, звідси й "живі" дані в
/// UI без окремого мережевого читання на кожен рендер.
final familyStatusProvider = FutureProvider<FamilyStatusResult?>((ref) {
  return FamilyServerSyncService.cachedStatus();
});

/// Мій власний account_id (той самий, що для Subscription/Sync) — лише
/// читає, якщо вже існує; НЕ створює акаунт (на відміну від
/// `ensureFamilyAccount()`). Потрібен UI-шару (family_screen.dart), щоб
/// відрізнити "себе" серед `FamilyEntry.members` — сам API-клієнт цього не
/// робить (сервер не знає, хто "переглядає" список, лише хто автентифікувався).
final myAccountIdProvider = FutureProvider<String?>((ref) {
  return AccountService().currentAccountId();
});
