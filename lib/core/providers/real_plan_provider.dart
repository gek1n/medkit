import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/subscription_service.dart';
import 'family_status_provider.dart';
import 'plan_provider.dart';

/// Реальний ефективний план. `main.dart`'s `_Shell.build()` тримає міст
/// (`ref.listen<AsyncValue<AppPlan>>(realPlanProvider, ...)`), який пише
/// щойно обчислене тут значення напряму в bare `planProvider`
/// (`StateProvider`, звідти й далі читає решта застосунку всі ліміти) — тож
/// усе, що повертає цей провайдер, реально й одразу впливає на ліміти, а не
/// лише готується на майбутнє.
///
/// Крок 11 (#308): "подароване сім'єю" розширення плану повертається —
/// якщо я гість (`role == 'member'`) хоч в одній сім'ї, де підписка
/// адміністратора зараз активна (`family.plan.active`, рахується наживо на
/// сервері з підписки, — `FamilyController::status()`), ефективний план
/// підіймається до Family (найширший тариф, тож "max" із власним завжди
/// дає family, коли є хоч один активний дарунок). familyStatusProvider сам
/// перерахується на кожен /family/status (і так триггериться після
/// join/leave/kick, Крок 11.6) — момент виходу з сім'ї чи злету підписки
/// адміністратора автоматично забирає "подарунок" без додаткового коду.
final realPlanProvider = FutureProvider<AppPlan>((ref) async {
  final own = await ref.watch(ownPlanProvider.future);
  final status = await ref.watch(familyStatusProvider.future);
  final giftedByFamily = status?.families
          .any((f) => f.role == 'member' && f.plan.active) ??
      false;
  return giftedByFamily ? AppPlan.family : own;
});

/// Мій ВЛАСНИЙ куплений план.
final ownPlanProvider = FutureProvider<AppPlan>((ref) => SubscriptionService.cachedPlan());
