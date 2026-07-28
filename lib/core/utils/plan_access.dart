import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plan_provider.dart';
import '../../features/today/providers/today_providers.dart';

/// true, якщо [memberId] — локальний (dependent) профіль, що виходить за
/// межі ліміту локальних профілів поточного плану (напр. підписка Elly
/// Plus/Family злетіла, а локальні профілі понад Free-ліміт лишились).
/// Такому профілю не можна ні створювати, ні редагувати завдання — але
/// вже заплановані нагадування (сповіщення) не скасовуються і продовжують
/// приходити, оскільки це окремий, незалежний механізм.
bool isMemberBlockedByPlan(WidgetRef ref, int? memberId) {
  if (memberId == null) return false;
  final limits = ref.watch(planProvider).limits;
  if (limits.maxLocalMembers == 0) return false; // необмежено
  final members = ref.watch(allMembersProvider).valueOrNull;
  if (members == null) return false;
  final localCount = members.length;
  if (localCount <= limits.maxLocalMembers) return false;
  for (final m in members) {
    if (m.id == memberId) return m.role == 'dependent';
  }
  return false;
}

/// true, якщо кількість рутинних справ учасника вже перевищує ліміт
/// поточного плану (напр. підписка злетіла, а рутини понад Free-ліміт
/// лишились). Такі справи лишаються активними — позначити виконаним/
/// пропущеним чи видалити все ще можна, редагувати — ні, доки ліміт не
/// звільниться або план не оновиться. [routineCount] — кількість, яку
/// викликач вже має завантаженою (щоб не плодити окремий провайдер).
bool isRoutineOverLimit(WidgetRef ref, int routineCount) {
  final limits = ref.watch(planProvider).limits;
  if (limits.maxRoutineTasks == 0) return false;
  return routineCount > limits.maxRoutineTasks;
}
