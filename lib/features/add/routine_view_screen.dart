import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/plan_access.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_header_action_button.dart';
import '../../shared/widgets/peer_attachment_chip.dart';
import '../../shared/widgets/photo_gallery_viewer.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
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
///
/// Крок 4.3.5 плану: [peer] непорожній — рутина береться не з локальної
/// бази (id синтетичний), а з перекладача кешу піра; кнопки редагування/
/// видалення ховаються. "Чия черга"/стрік — не показуються для піра:
/// ActivityAssignees (пул ротації) взагалі ще не входить у синхронізацію
/// пірів, а стрік рахується з ЛОКАЛЬНИХ ActivityLogs, тож обидва були б
/// або порожні, або оманливо неправильні — задокументований пробіл.
class RoutineViewScreen extends ConsumerWidget {
  final int activityId;
  final PeerSubject? peer;
  const RoutineViewScreen({super.key, required this.activityId, this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (peer != null) {
      final activity = ref
          .watch(peerActivitiesProvider(peer!.personUuid))
          .where((a) => a.id == activityId)
          .firstOrNull;
      if (activity == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
        return const Scaffold(backgroundColor: AppColors.bg, body: SizedBox.shrink());
      }
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: _ViewBody(activity: activity, peer: peer)),
      );
    }

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
  final PeerSubject? peer;
  const _ViewBody({required this.activity, this.peer});

  List<String> get _steps {
    try {
      final list = jsonDecode(activity.stepsJson ?? '[]') as List;
      return list.map((s) => (s as Map)['title'] as String).toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> get _tags {
    try {
      return List<String>.from(jsonDecode(activity.tags) as List);
    } catch (_) {
      return const [];
    }
  }

  List<String> get _photos {
    try {
      return List<String>.from(jsonDecode(activity.documentPaths) as List);
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
    // НЕ викликаємо Navigator.pop тут — щойно softDelete позначить рутину
    // isActive=false, watchById(id) реактивно віддасть null, і сам екран
    // вище (data: (activity) => if (activity == null) ...) закриється
    // через addPostFrameCallback. Виклик pop і тут, і там — подвійний pop
    // на одному навігаторі (чорний екран, що "лікується" лише
    // перезапуском — саме так і виглядав баг).
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
    final tags = _tags;
    final photos = _photos;
    final hasLocation =
        activity.location != null && activity.location!.trim().isNotEmpty;
    // Крок 4.4.4 плану: якщо суб'єкт дозволив редагування Розкладу саме
    // цьому глядачеві — олівець лишається доступним і для рутини піра,
    // лише замість прямого запису шле record_proposal (Крок 4.4.1).
    final grants = peer == null ? null : ref.watch(activePeerGrantsProvider);
    final canEditPeer = grants != null && grants.viewScheduleGranted && grants.editScheduleGranted;

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
                    if (peer == null)
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
                      )
                    else if (canEditPeer)
                      MkEditIconButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddActivityScreen(
                              existing: activity,
                              hideTypePicker: true,
                              compactMode: true,
                              onDraftCreated: (draft) => submitActivityProposal(
                                ref,
                                peer!,
                                draft,
                                existingSyncUuid: activity.syncUuid,
                                existingUpdatedAt: activity.updatedAt,
                                syntheticSectionId: activity.sectionId,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (peer == null)
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
                      child: MedcardIcon(activity.iconKey, size: 22),
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
                if (peer == null && activity.repeatType != 'weeklyGoal') ...[
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
                if (peer == null)
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
                                  text: context.l10n
                                      .routineWhoseTurnLabel(turnName),
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
                if (hasLocation) ...[
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(activity.location!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSub)),
                      ),
                    ],
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusFull),
                              ),
                              child: Text(t,
                                  style: AppTextStyles.labelSm.copyWith(
                                      color: color, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(context.l10n.reminderPhotoLabel.toUpperCase(),
                      style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  if (peer != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: photos
                          .map((path) => PeerAttachmentChip(
                              channelId: peer!.channelId, photoPath: path))
                          .toList(),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => showPhotoGalleryViewer(
                            context, imagePaths: photos, initialIndex: i),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          child: FutureBuilder<Uint8List>(
                            future: PhotoService.decryptedBytes(photos[i]),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return Container(color: AppColors.surface);
                              }
                              return Image.memory(snap.data!, fit: BoxFit.cover);
                            },
                          ),
                        ),
                      ),
                    ),
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
