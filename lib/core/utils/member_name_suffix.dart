import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/today/providers/today_providers.dart';
import 'l10n_ext.dart';

/// " для {імʼя}" для заголовку екрана створення/редагування завдання —
/// показуємо лише коли в сім'ї більше одного профілю, інакше це зайвий шум
/// (і так зрозуміло, для кого завдання, коли профіль єдиний).
String memberNameSuffix(BuildContext context, WidgetRef ref, int memberId) {
  final members = ref.watch(allMembersProvider).valueOrNull;
  if (members == null || members.length < 2) return '';
  for (final m in members) {
    if (m.id == memberId) return context.l10n.forMemberSuffix(m.name);
  }
  return '';
}
