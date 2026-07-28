import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../features/today/providers/today_providers.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../appointments/add_appointment_screen.dart';
import '../medications/add_medication_screen.dart';
import '../plans/elly_denied_screen.dart';
import '../wellbeing/add_wellbeing_schedule_screen.dart';
import 'add_activity_screen.dart';

/// Відкриває екран створення завдання одразу (без проміжного меню-шторки):
/// перший елемент екрана — пікер із 6 пунктів, вибір одразу веде до
/// відповідної стандартної форми створення.
void openAddTaskScreen(BuildContext context, {int? memberId}) {
  final container = ProviderScope.containerOf(context);
  final plan = container.read(planProvider);
  final members = container.read(allMembersProvider).valueOrNull ?? [];
  final localCount = members.length;
  final overLocalLimit =
      plan.limits.maxLocalMembers != 0 && localCount > plan.limits.maxLocalMembers;

  // Ліміт локальних профілів обмежує лише створення завдань ДЛЯ цих
  // "зайвих" локальних профілів — власнику завжди можна створювати собі.
  var targetIsLocalDependent = false;
  if (memberId != null) {
    for (final m in members) {
      if (m.id == memberId) {
        targetIsLocalDependent = m.role == 'dependent';
        break;
      }
    }
  }

  if (overLocalLimit && targetIsLocalDependent) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EllyDeniedScreen()));
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddTaskScreen(memberId: memberId)),
  );
}

enum _TaskType { meds, sport, meeting, simple, routine, wellbeing }

class AddTaskScreen extends ConsumerWidget {
  final int? memberId;
  const AddTaskScreen({super.key, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackMemberAsync = ref.watch(currentMemberProvider);
    final resolvedMemberId = memberId ?? fallbackMemberAsync.valueOrNull?.id;

    // push (не pushReplacement) — пікер лишається в стеку, тож кнопка
    // "назад"/свайп на формі повертає саме до вибору типу. Але після
    // успішного збереження форма повертає true, і ми одразу "пропускаємо"
    // пікер, popаючи й його — користувач опиняється одразу на Сьогодні/
    // Розкладі, а не знову на екрані вибору типу.
    Future<void> openType(_TaskType type) async {
      if (resolvedMemberId == null) return;
      final Widget screen = switch (type) {
        _TaskType.meds => AddMedicationScreen(memberId: resolvedMemberId),
        _TaskType.sport => AddActivityScreen(
            memberId: resolvedMemberId,
            hideTypePicker: true,
            forcedType: 'general_sport',
          ),
        _TaskType.meeting => AddAppointmentScreen(memberId: resolvedMemberId),
        _TaskType.simple => AddActivityScreen(
            memberId: resolvedMemberId,
            hideTypePicker: true,
            forcedType: 'simple_task',
            compactMode: true,
          ),
        _TaskType.routine => AddActivityScreen(
            memberId: resolvedMemberId,
            hideTypePicker: true,
            forcedType: 'routine',
            compactMode: true,
          ),
        _TaskType.wellbeing =>
          AddWellbeingScheduleScreen(memberId: resolvedMemberId),
      };
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
      if (saved == true && context.mounted) Navigator.pop(context, true);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(context.l10n.addTypeSheetTitle, style: AppTextStyles.h3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                context.l10n.addTypeSheetSubtitle,
                style: AppTextStyles.bodySm,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _TypeCard(
                    icon: Icons.medication_rounded,
                    title: context.l10n.categoryMeds,
                    sub: context.l10n.addTypeMedsSub,
                    onTap: () => openType(_TaskType.meds),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    icon: Icons.directions_walk_rounded,
                    title: context.l10n.taskTypeSport,
                    sub: context.l10n.taskTypeSportSub,
                    onTap: () => openType(_TaskType.sport),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    icon: Icons.notifications_active_rounded,
                    title: context.l10n.taskTypeMeeting,
                    sub: context.l10n.taskTypeMeetingSub,
                    onTap: () => openType(_TaskType.meeting),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    icon: Icons.checklist_rounded,
                    title: context.l10n.taskTypeSimple,
                    sub: context.l10n.taskTypeSimpleSub,
                    onTap: () => openType(_TaskType.simple),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    icon: Icons.home_repair_service_rounded,
                    title: context.l10n.taskTypeRoutine,
                    sub: context.l10n.taskTypeRoutineSub,
                    onTap: () => openType(_TaskType.routine),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    icon: Icons.favorite_rounded,
                    title: context.l10n.wellbeingTitle,
                    sub: context.l10n.addTypeWellbeingSub,
                    onTap: () => openType(_TaskType.wellbeing),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Icon(icon, size: 26, color: AppColors.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
