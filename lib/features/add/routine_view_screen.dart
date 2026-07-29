import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/plan_access.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_header_action_button.dart';
import '../plans/elly_denied_screen.dart';
import '../today/providers/today_providers.dart';
import 'add_activity_screen.dart';

final _activityProvider = StreamProvider.family<Activity?, int>((ref, id) {
  return ref.watch(activitiesRepositoryProvider).watchById(id);
});

final _assigneesProvider =
    StreamProvider.family<List<ActivityAssignee>, int>((ref, id) {
  return ref.watch(activitiesRepositoryProvider).watchAssignees(id);
});

// Кількість активних рутин власника — для перевірки isRoutineOverLimit
// (редагування блокується понад ліміт плану, перегляд лишається доступним).
final _routineCountProvider = StreamProvider.family<int, int>((ref, memberId) {
  return ref
      .watch(activitiesRepositoryProvider)
      .watchByMember(memberId)
      .map((list) => list.length);
});

// Скільки разів підряд рутину виконано — мотиваційний показник, який
// одразу пояснює, навіщо взагалі рахувати виконання рутини (на відміну від
// разового нагадування). Див. ActivitiesRepository.computeStreakDays.
final _streakProvider = FutureProvider.family<int, int>((ref, activityId) {
  return ref.watch(activitiesRepositoryProvider).computeStreakDays(activityId);
});

/// Перегляд рутинної справи — той самий патерн, що й ReminderViewScreen/
/// MedcardEntryViewScreen: показує все заповнене, кнопка "Редагувати" веде
/// на форму. Дії відмітити виконано/пропустити/поміняти чергу лишаються на
/// картках Сьогодні/Розкладу — тут лише перегляд.
class RoutineViewScreen extends ConsumerWidget {
  final int activityId;
  const RoutineViewScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(_activityProvider(activityId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: activityAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text(context.l10n.errorGeneric('$e'))),
          data: (activity) {
            if (activity == null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.pop(context),
              );
              return const SizedBox.shrink();
            }
            return _ViewBody(activity: activity);
          },
        ),
      ),
    );
  }
}

class _ViewBody extends ConsumerWidget {
  final Activity activity;
  const _ViewBody({required this.activity});

  List<String> get _steps {
    try {
      final list = jsonDecode(activity.stepsJson ?? '[]') as List;
      return list.map((s) => (s as Map)['title'] as String).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _dayLabel(BuildContext context, int weekday) {
    final l10n = context.l10n;
    return switch (weekday) {
      1 => l10n.dayMon,
      2 => l10n.dayTue,
      3 => l10n.dayWed,
      4 => l10n.dayThu,
      5 => l10n.dayFri,
      6 => l10n.daySat,
      _ => l10n.daySun,
    };
  }

  String _repeatSummary(BuildContext context) {
    switch (activity.repeatType) {
      case 'daily':
        return context.l10n.reminderRepeatDailyLabel;
      case 'monthly':
        return '${context.l10n.reminderRepeatMonthlyLabel} · '
            '${activity.repeatDayOfMonth ?? ''}';
      case 'everyNDays':
        return context.l10n
            .routineIntervalDaysValueLabel(activity.repeatIntervalDays ?? 1);
      case 'weeklyGoal':
        return context.l10n
            .routineWeeklyGoalValueLabel(activity.weeklyGoalCount ?? 1);
      case 'weekly':
      default:
        var days = <int>{};
        try {
          days = Set<int>.from(jsonDecode(activity.repeatDays) as List);
        } catch (_) {}
        final sorted = days.toList()..sort();
        if (sorted.isEmpty) return context.l10n.noDaysSelectedHint;
        if (sorted.length == 7) return context.l10n.repeatDaily;
        return sorted.map((d) => _dayLabel(context, d)).join(', ');
    }
  }

  String _timeSummary(BuildContext context) {
    if (activity.repeatType == 'weeklyGoal') return '';
    return context.l10n.routineAnyTimeTodayLabel;
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteActivityConfirmTitle),
        content: Text(context.l10n.deleteActivityConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.deleteAction,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(activitiesRepositoryProvider).softDelete(activity.id);
    ref.invalidate(generateTodayActivityLogsProvider);
    ref.invalidate(tomorrowActivityLogsProvider);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorFromHex(activity.color) ?? AppColors.primary;
    final assigneesAsync = ref.watch(_assigneesProvider(activity.id));
    final membersAsync = ref.watch(allMembersProvider);
    final steps = _steps;
    final routineCount =
        ref.watch(_routineCountProvider(activity.memberId)).valueOrNull ?? 0;
    final editBlocked = isRoutineOverLimit(ref, routineCount);
    final streak = ref.watch(_streakProvider(activity.id)).valueOrNull ?? 0;

    return Column(
      children: [
        Container(
          color: AppColors.bg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              MkBackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(activity.name,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    MkEditIconButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => editBlocked
                              ? EllyDeniedScreen(
                                  title: context.l10n.routineTasksLimitDeniedTitle,
                                  subtitle: context
                                      .l10n.routineTasksLimitDeniedSubtitle,
                                )
                              : AddActivityScreen(
                                  memberId: activity.memberId,
                                  existing: activity,
                                  hideTypePicker: true,
                                  compactMode: true,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MkDeleteIconButton(
                onTap: () => _delete(context, ref, activity),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.md,
              AppDimensions.screenPadding,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: const AssetIcon('task_routine', size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_repeatSummary(context),
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textSub)),
                          if (_timeSummary(context).isNotEmpty)
                            Text(_timeSummary(context),
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (activity.repeatType != 'weeklyGoal') ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.local_fire_department_rounded,
                    color: color,
                    text: streak > 0
                        ? context.l10n.routineStreakDaysLabel(streak)
                        : context.l10n.routineNoStreakYetLabel,
                  ),
                ],
                const SizedBox(height: 18),
                assigneesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (assignees) {
                    final members = membersAsync.valueOrNull ?? [];
                    String nameFor(int id) => members
                        .where((m) => m.id == id)
                        .map((m) => m.name)
                        .firstOrNull ??
                        '';
                    if (assignees.length <= 1) {
                      final id = assignees.isNotEmpty
                          ? assignees.first.memberId
                          : activity.memberId;
                      return _InfoRow(
                        icon: Icons.person_outline_rounded,
                        color: color,
                        text: nameFor(id),
                      );
                    }
                    return FutureBuilder<int>(
                      future: ref
                          .read(activitiesRepositoryProvider)
                          .assigneeForDate(activity, DateTime.now()),
                      builder: (context, snap) {
                        final turnName =
                            snap.hasData ? nameFor(snap.data!) : '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              icon: Icons.sync_rounded,
                              color: color,
                              text: context.l10n
                                  .routineRotationSummary(assignees.length),
                            ),
                            if (turnName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _InfoRow(
                                icon: Icons.person_outline_rounded,
                                color: color,
                                text:
                                    context.l10n.routineWhoseTurnLabel(turnName),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(context.l10n.routineStepsLabel.toUpperCase(),
                      style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  ...steps.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.circle_outlined,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s, style: AppTextStyles.bodyMd),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
        ),
      ],
    );
  }
}
