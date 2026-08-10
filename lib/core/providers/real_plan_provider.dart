import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/subscription_service.dart';
import 'plan_provider.dart';

/// Реальний ефективний план — готовий, але СВІДОМО ще НЕ активний
/// (docs/multifamily_billing_plan.md, розділ 6, "Рішення: реальна покупка
/// відкладена"). Поточний джерело істини для UI — bare `planProvider`
/// (`StateProvider`, декоративний перемикач у `PlansScreen`). Фінальне
/// переключення — окрема задача пізніше: замінити всі `ref.watch(planProvider)`
/// на цей провайдер (чи перевести planProvider на цю ж реалізацію) одним
/// кроком, коли підключиться справжня покупка.
///
/// Крок 10 (10.08, карантин функціоналу сім'ї): раніше тут ще додавалось
/// "подароване сім'єю" розширення плану (max власного тарифу й Family, якщо
/// хоч один інвайтер з активною підпискою) — залежність від FamilyPeers,
/// якого більше немає в білді. Тепер це просто прямий проксі на власний
/// куплений план: той, хто реально платить, і далі бачить свій статус без
/// змін; ефекту "подарунку від сім'ї" більше немає, бо немає самої сімейної
/// групи, яка б його роздавала (архів: archive/family_subsystem/).
final realPlanProvider = FutureProvider<AppPlan>((ref) => ref.watch(ownPlanProvider.future));

/// Мій ВЛАСНИЙ куплений план.
final ownPlanProvider = FutureProvider<AppPlan>((ref) => SubscriptionService.cachedPlan());
