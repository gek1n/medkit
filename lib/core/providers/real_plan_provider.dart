import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/subscription_service.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import 'plan_provider.dart';

/// Той самий `watchAll()`, що й приватні `_familyPeersProvider` у
/// family_screen.dart/family_visibility_screen.dart — окремий публічний
/// provider тут, щоб [realPlanProvider] міг реактивно перераховуватись при
/// зміні grants_summary (payerPlanActive/invitedMe), а не читати один
/// застиглий знімок.
final _familyPeersStreamProvider = StreamProvider<List<FamilyPeer>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchAll();
});

/// Реальний ефективний план — готовий, але СВІДОМО ще НЕ активний
/// (docs/multifamily_billing_plan.md, розділ 6, "Рішення: реальна покупка
/// відкладена"). Поточний джерело істини для UI — bare `planProvider`
/// (`StateProvider`, декоративний перемикач у `PlansScreen`). Фінальне
/// переключення — окрема задача пізніше: замінити всі `ref.watch(planProvider)`
/// на цей провайдер (чи перевести planProvider на цю ж реалізацію) одним
/// кроком, коли підключиться справжня покупка.
///
/// Формула — max(власний кешований тариф, Family якщо є хоч один
/// подарунок від інвайтера з активною підпискою) — рахується ДИНАМІЧНО
/// щоразу, ніколи не кешується статичним булевим прапорцем: якщо я гість у
/// двох сім'ях і одна з них розпадеться, доступ від другої має лишитись
/// робочим.
final realPlanProvider = FutureProvider<AppPlan>((ref) async {
  // watch (не read) — перераховується, коли приходить свіжий grants_summary
  // від будь-якого піра (payerPlanActive/invitedMe могли змінитись).
  final peers = ref.watch(_familyPeersStreamProvider).valueOrNull ?? const [];
  final own = await SubscriptionService.cachedPlan();

  final hasActiveFamilyGift = peers.any((p) => p.invitedMe && p.payerPlanActive);
  if (hasActiveFamilyGift && own != AppPlan.family) {
    return AppPlan.family;
  }
  return own;
});
