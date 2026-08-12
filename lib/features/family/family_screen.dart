import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/family_status_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/providers/real_plan_provider.dart';
import '../../core/services/activity_log_generator.dart';
import '../../core/services/attachment_cleanup_service.dart';
import '../../core/services/family_api_client.dart';
import '../../core/services/family_group_service.dart';
import '../../core/services/family_join_popup_service.dart';
import '../../core/services/family_server_sync_service.dart';
import '../../core/services/intake_generator.dart';
import '../../core/services/marketing_topics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/plan_upgrade_banner.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../plans/elly_denied_screen.dart';
import '../profile/family_visibility_screen.dart';
import '../today/providers/today_providers.dart';
import 'family_duties_screen.dart';
import 'family_group_invite_screen.dart';
import 'family_group_join_screen.dart';
import 'family_join_popup.dart';
import 'peer_view_providers.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _memberMedsProvider = StreamProvider.family<List<Medication>, int>(
  (ref, memberId) =>
      ref.watch(medicationsRepositoryProvider).watchByMember(memberId),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: membersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) => _FamilyBody(members: members),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _FamilyBody extends ConsumerWidget {
  final List<Member> members;
  const _FamilyBody({required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    final limits = plan.limits;
    // Реальний, НЕ "подарований" сім'єю план — можливість запросити когось
    // у свою окрему сім'ю прирівнюється до статусу адміністратора і має
    // спиратись лише на власну покупку (адміністратором може бути лише
    // той, хто платить).
    final ownPlan = ref.watch(ownPlanProvider).valueOrNull ?? AppPlan.free;
    final localCount = members.length;
    // Скільки автономних учасників запросив Я (у сім'ях, де я
    // адміністратор) — саме це витрачає мій ліміт слотів; вхідні
    // запрошення (мене хтось запросив до своєї сім'ї) не повинні його
    // займати.
    final familyStatus = ref.watch(familyStatusProvider).valueOrNull;
    final myAccountId = ref.watch(myAccountIdProvider).valueOrNull;
    final peersCount = (familyStatus?.families ?? const <FamilyEntry>[])
        .where((f) => f.role == 'admin')
        .expand((f) => f.members)
        .where((m) => m.accountId != myAccountId)
        .length;
    final localLimitReached =
        limits.maxLocalMembers != 0 && localCount >= limits.maxLocalMembers;
    if (localLimitReached) unawaited(MarketingTopicsService.markHitLocalLimit());
    final autonomousLimitReached = ownPlan.limits.maxAutonomousMembers == 0
        ? true
        : peersCount >= ownPlan.limits.maxAutonomousMembers;
    final familyAvailable = !localLimitReached || !autonomousLimitReached;
    final activeId = ref.watch(activeMemberIdProvider);
    Member? activeMember;
    if (activeId != null) {
      for (final m in members) {
        if (m.id == activeId) {
          activeMember = m;
          break;
        }
      }
    }

    final owner = members.firstWhere((m) => m.role == 'owner',
        orElse: () => members.first);
    final others = members.where((m) => m.id != owner.id).toList();
    final blocked = localLimitReached && autonomousLimitReached;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        try {
          await FamilyServerSyncService(ref.read(databaseProvider), intakeGenerator: ref.read(intakeGeneratorProvider), activityLogGenerator: ref.read(activityLogGeneratorProvider), remindersRepository: ref.read(remindersRepositoryProvider)).syncAll();
        } catch (_) {
          // Тиха невдача — те саме, що і billing/backup синк-тригери.
        }
        ref.invalidate(allMembersProvider);
        ref.invalidate(familyStatusProvider);
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (activeMember != null && activeMember.role != 'owner')
          SliverToBoxAdapter(
            child: SwitchProfileBanner(name: activeMember.name),
          ),
        SliverToBoxAdapter(
          child: _FamilyHeader(
              count: members.length, canAdd: familyAvailable),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppDimensions.lg),
              _MemberCard(member: owner, ownerId: owner.id),
              const SizedBox(height: AppDimensions.md),
              if (blocked)
                const _FamilyUpgradeBanner()
              else if (plan == AppPlan.plus)
                _FamilyUpgradeBanner(
                  badge: context.l10n.familyLabel,
                  title: context.l10n.localProfilesTitle,
                  subtitle: context.l10n.familyUpgradeSubtitle,
                ),
              if (blocked || plan == AppPlan.plus)
                const SizedBox(height: AppDimensions.md),
              if (others.isNotEmpty)
                _FamilyAccordionSection(
                  header: Text(
                    context.l10n.localUsersSectionLabel.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
                  ),
                  child: _DraggableMembers(others: others, ownerId: owner.id),
                ),
              if (!blocked) const _AddMemberTile(),
              const SizedBox(height: AppDimensions.xl),
              if (others.isNotEmpty) _CareSummaryCard(count: others.length),
              const SizedBox(height: AppDimensions.md),
              _FamilyDutiesTile(),
              const SizedBox(height: AppDimensions.xl),
              const _FamilyGroupSection(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FamilyHeader extends StatelessWidget {
  final int count;
  final bool canAdd;
  const _FamilyHeader({required this.count, required this.canAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            AppDimensions.lg,
            AppDimensions.screenPadding,
            AppDimensions.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.familyLabel, style: AppTextStyles.h2),
                    Text(
                      context.l10n.familyMembersCountLabel(count),
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              if (canAdd)
                GestureDetector(
                  onTap: () => _openAddMemberScreen(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                          color: AppColors.primaryLighter, width: 1.5),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────

class _MemberCard extends ConsumerWidget {
  final Member member;
  final int ownerId;
  final Widget? dragHandle;
  const _MemberCard({required this.member, required this.ownerId, this.dragHandle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = member.role == 'owner';
    // Лише owner/dependent лишаються локальними Members-рядками — власник
    // веде dependent-профілі напряму, тож перегляд тут завжди дозволений,
    // жодних permission-гейтів не потрібно (на відміну від незалежних
    // учасників сімейної групи — див. _PeerCard).
    final progress = ref.watch(familyMemberTodayProgressProvider(member.id));
    final medsAsync = ref.watch(_memberMedsProvider(member.id));
    final activitiesAsync = ref.watch(todayActivitiesProvider(member.id));
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));
    final activityLogsAsync = ref.watch(todayActivityLogsProvider(member.id));
    final noFixedTimeIdsAsync =
        ref.watch(todayNoFixedTimeActivityIdsProvider(member.id));
    final remindersAsync = ref.watch(todayAppointmentsProvider(member.id));
    final reminderLogsAsync = ref.watch(todayReminderLogsProvider(member.id));
    final wbScheduleAsync =
        ref.watch(todayWellbeingScheduleProvider(member.id));
    final wbLogsAsync = ref.watch(todayWellbeingLogsProvider(member.id));

    final meds = medsAsync.valueOrNull ?? [];
    final activities = activitiesAsync.valueOrNull ?? [];
    final intakes = intakesAsync.valueOrNull ?? [];
    final activityLogs = activityLogsAsync.valueOrNull ?? [];
    final noFixedTimeIds = noFixedTimeIdsAsync.valueOrNull ?? <int>{};
    // watchActiveOnDate дає окрему копію Reminder (той самий id) на кожен
    // слот мультислотового daily/weekly — дедуп за id обов'язковий, інакше
    // .where(reminderId==r.id) нижче знайде ті самі ReminderLogs по кілька
    // разів і додасть дублікати в missedItems.
    final reminders = {
      for (final r in remindersAsync.valueOrNull ?? <Reminder>[]) r.id: r,
    }.values.toList();
    final reminderLogs = reminderLogsAsync.valueOrNull ?? [];
    final wbSchedule = wbScheduleAsync.valueOrNull;
    final wbLogs = wbLogsAsync.valueOrNull ?? [];

    final taken = progress.done;
    final total = progress.total;
    final hasMissed = progress.missed > 0;

    String medNameFor(int medicationId) {
      for (final m in meds) {
        if (m.id == medicationId) return m.name;
      }
      return context.l10n.defaultMedName;
    }

    String activityNameFor(int activityId) {
      for (final a in activities) {
        if (a.id == activityId) return a.name;
      }
      return context.l10n.defaultActivityName;
    }

    String timeStr(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // Пропущені елементи БУДЬ-ЯКОГО типу (ліки/нагадування/рутини) — те саме
    // 15-хвилинне вікно, що й у familyMemberTodayProgressProvider вище, лише
    // тут ще й резолвиться назва для картки-деталі нижче.
    final now = DateTime.now();
    final activeWindowStart = now.subtract(const Duration(minutes: 15));
    DateTime effectiveDue(Intake i) =>
        i.status == 'snoozed' && i.snoozedUntil != null
            ? i.snoozedUntil!
            : i.scheduledAt;
    final missedItems = <_MissedItem>[];
    for (final i in intakes) {
      final due = effectiveDue(i);
      if ((i.status == 'pending' || i.status == 'snoozed') &&
          due.isBefore(activeWindowStart)) {
        missedItems.add(_MissedItem(
          entityType: 'intake',
          uuid: 'intake_${i.id}',
          title: medNameFor(i.medicationId),
          scheduledAt: due,
        ));
      }
    }
    for (final l in activityLogs) {
      if ((l.status == 'pending' || l.status == 'partial') &&
          !noFixedTimeIds.contains(l.activityId) &&
          l.scheduledAt.isBefore(activeWindowStart)) {
        missedItems.add(_MissedItem(
          entityType: 'activity_log',
          uuid: 'activity_${l.id}',
          title: activityNameFor(l.activityId),
          scheduledAt: l.scheduledAt,
        ));
      }
    }
    for (final r in reminders) {
      if (r.repeatType == 'none') {
        if (r.status == 'pending' && r.scheduledAt.isBefore(activeWindowStart)) {
          missedItems.add(_MissedItem(
            entityType: 'doctor_appointment',
            uuid: 'reminder_${r.id}',
            title: r.doctorType,
            scheduledAt: r.scheduledAt,
          ));
        }
        continue;
      }
      for (final log in reminderLogs.where((l) => l.reminderId == r.id)) {
        final scheduledAt = log.snoozedUntil ?? log.scheduledAt;
        if (log.status == 'pending' && scheduledAt.isBefore(activeWindowStart)) {
          missedItems.add(_MissedItem(
            entityType: 'doctor_appointment',
            uuid: 'reminderLog_${log.id}',
            title: r.doctorType,
            scheduledAt: scheduledAt,
          ));
        }
      }
    }
    // Пропущені зрізи самопочуття — той самий розрахунок слотів, що й у
    // familyMemberTodayProgressProvider вище: без цієї гілки progress.missed
    // міг рахувати пропущений зріз самопочуття (hasMissed=true), а
    // missedItems тут лишався порожнім — і missedItems.first нижче падав з
    // Bad state: No element.
    if (wbSchedule != null && wbSchedule.isActive) {
      List<String> times;
      try {
        times = List<String>.from(jsonDecode(wbSchedule.times) as List);
      } catch (_) {
        times = const [];
      }
      final today = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      final slots = times.map((t) {
        final p = t.split(':');
        return DateTime(
            today.year, today.month, today.day, int.parse(p[0]), int.parse(p[1]));
      }).toList()
        ..sort();
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final windowEnd = i + 1 < slots.length ? slots[i + 1] : endOfDay;
        final hasLog = wbLogs.any((l) =>
            l.loggedAt.isAfter(slot.subtract(const Duration(minutes: 30))) &&
            l.loggedAt.isBefore(windowEnd));
        if (hasLog || slot.isAfter(now)) continue;
        if (slot.isBefore(activeWindowStart)) {
          missedItems.add(_MissedItem(
            entityType: 'wellbeing',
            uuid: 'wellbeing_${member.id}_$i',
            title: null,
            scheduledAt: slot,
          ));
        }
      }
    }
    missedItems.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    Widget statusLine;
    if (isOwner) {
      statusLine = Text(
        total == 0
            ? context.l10n.noMedsTodayLabel
            : (taken == total
                ? context.l10n.allDoneTodayLabel
                : context.l10n.tasksProgressLabel(taken, total)),
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      );
    } else if (hasMissed) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_rounded, size: 12, color: AppColors.danger),
        const SizedBox(width: 3),
        Text(context.l10n.missedRemindersLabel(missedItems.length),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
      ]);
    } else if (total > 0 && taken == total) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF22C55E)),
        const SizedBox(width: 3),
        Text(context.l10n.allDoneTodayLabel,
            style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF22C55E))),
      ]);
    } else if (total > 0) {
      statusLine = Text(
        context.l10n.tasksProgressLabel(taken, total),
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      );
    } else {
      statusLine = Text(context.l10n.noMedsTodayLabel,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted));
    }

    final showMissedCard = !isOwner && hasMissed;
    final firstMissed = hasMissed ? missedItems.first : null;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMissedCard) Container(width: 4, color: AppColors.danger),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isOwner
                        ? null
                        : () => _showMemberActionsSheet(
                            context, ref, member, ownerId),
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        if (dragHandle != null) ...[
                          dragHandle!,
                          const SizedBox(width: 4),
                        ],
                        AvatarImage(index: member.avatarIndex, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(member.name,
                                        style: AppTextStyles.labelLg,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                        isOwner ? context.l10n.meLabel : context.l10n.localLabel,
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              statusLine,
                            ],
                          ),
                        ),
                        if (!isOwner) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted, size: 22),
                        ],
                      ],
                    ),
                    ),
                  ),
                  if (showMissedCard && firstMissed != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    switch (firstMissed.entityType) {
                                      'intake' => Icons.medication_rounded,
                                      'activity_log' => Icons.checklist_rounded,
                                      _ => Icons.notifications_rounded,
                                    },
                                    size: 18,
                                    color: AppColors.danger),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_missedItemTitle(context, firstMissed),
                                          style: AppTextStyles.labelMd),
                                      Text(
                                          context.l10n.notTakenSuffixLabel(timeStr(firstMissed.scheduledAt)),
                                          style: AppTextStyles.bodySm
                                              .copyWith(color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// ── Локальні члени: драг-н-дроп ──────────────────────────────────────────────
// Той самий патерн, що й _DraggableSections у med_card_screen.dart —
// власник НІКОЛИ не входить сюди (завжди перший, поза списком, окремо
// рендериться в _FamilyBody). Порядок, встановлений тут, автоматично
// підхоплюють усі інші перемикачі "хто зараз активний" (Сьогодні,
// MemberSwitcherPill на Розкладі/Медкартці) — вони читають той самий
// allMembersProvider/MembersRepository.watchAll(), відсортований за
// sortOrder.
class _DraggableMembers extends ConsumerStatefulWidget {
  final List<Member> others;
  final int ownerId;
  const _DraggableMembers({required this.others, required this.ownerId});

  @override
  ConsumerState<_DraggableMembers> createState() => _DraggableMembersState();
}

class _DraggableMembersState extends ConsumerState<_DraggableMembers> {
  late List<Member> _local;
  // Поки триває збереження нового порядку — не підміняти _local вхідними
  // widget.others (той самий компроміс, що й _DraggableSectionsState).
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _local = widget.others;
  }

  @override
  void didUpdateWidget(covariant _DraggableMembers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reordering) _local = widget.others;
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    setState(() {
      _reordering = true;
      final item = _local.removeAt(oldIndex);
      _local.insert(newIndex, item);
    });
    await ref.read(membersRepositoryProvider).reorder(_local.map((m) => m.id).toList());
    if (mounted) setState(() => _reordering = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_local.isEmpty) return const SizedBox.shrink();
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _local.length,
      onReorderItem: _handleReorder,
      // Дефолтний proxy (Material з непрозорим canvasColor-фоном, без
      // заокруглень) малює прямокутний "ореол" навколо заокругленої картки
      // під час перетягування — прибираємо його, лишаючи лише власне
      // оформлення _MemberCard.
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: child,
      ),
      itemBuilder: (context, index) {
        final m = _local[index];
        return Padding(
          key: ValueKey(m.id),
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: _MemberCard(
            member: m,
            ownerId: widget.ownerId,
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
            ),
          ),
        );
      },
    );
  }
}

void _showMemberActionsSheet(
    BuildContext context, WidgetRef ref, Member member, int ownerId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (_) => _MemberActionsSheet(member: member, ownerId: ownerId),
  );
}

class _MemberActionsSheet extends ConsumerWidget {
  final Member member;
  final int ownerId;
  const _MemberActionsSheet({required this.member, required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <_SheetAction>[
      _SheetAction(
        icon: Icons.today_rounded,
        label: context.l10n.viewAsLabel(member.name),
        onTap: () {
          ref.read(activePeerProvider.notifier).state = null;
          ref.read(activeMemberIdProvider.notifier).state = member.id;
          ref.read(requestedTabIndexProvider.notifier).state = 2; // Сьогодні
          Navigator.pop(context);
        },
      ),
      _SheetAction(
        icon: Icons.delete_forever_rounded,
        label: context.l10n.deleteForeverAction,
        color: AppColors.danger,
        onTap: () => _confirmDelete(context, ref),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding, AppDimensions.lg, AppDimensions.screenPadding, AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(member.name, style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    rows[i],
                    if (i < rows.length - 1)
                      const Divider(height: 1, color: AppColors.borderLight),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/illustrations/elly-thinking-2.png', height: 120),
            const SizedBox(height: AppDimensions.md),
            Text(context.l10n.areYouSureTitle,
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              context.l10n.deleteMemberConfirmBody(member.name),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.deleteForeverAction),
          ),
        ],
      ),
    );
    if (ok == true) {
      final db = ref.read(databaseProvider);
      // Зібрати й видалити прикріплені файли ДО каскадного видалення рядків
      // — інакше зашифровані документи лишаться в med_photos/ назавжди.
      await AttachmentCleanupService.deleteAllForMember(db, member.id);
      await ref.read(membersRepositoryProvider).delete(member.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Center(child: Icon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodyMd.copyWith(
                          color: color == AppColors.danger ? color : null)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CareSummaryCard extends StatelessWidget {
  final int count;
  const _CareSummaryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Image.asset('assets/illustrations/elly-hospital.png', height: 64),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              context.l10n.careSummaryLabel(count),
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Family duties tile ──────────────────────────────────────────────────────

class _FamilyDutiesTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FamilyDutiesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const AssetIcon('home', size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(context.l10n.routineAllRoutinesScreenTitle,
                  style: AppTextStyles.labelLg),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Add member tile ───────────────────────────────────────────────────────────

class _AddMemberTile extends StatelessWidget {
  const _AddMemberTile();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddMemberScreen(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.addFamilyMemberLabel,
                    style:
                        AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(context.l10n.addMemberHint,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Показується замість "Додати члена сімʼї", коли ліміт профілів поточного
// плану вже вичерпано — той самий градієнтний стиль, що й AI-банер сканування
// рецепта в add_medication_screen.dart, з ілюстрацією родини.
class _FamilyUpgradeBanner extends StatelessWidget {
  final String? badge;
  final String? title;
  final String? subtitle;
  const _FamilyUpgradeBanner({this.badge, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return PlanUpgradeBanner(
      badgeIcon: Icons.family_restroom_rounded,
      badge: badge ?? context.l10n.familyLabel,
      title: title ?? context.l10n.profileLimitReachedTitle,
      subtitle: subtitle ?? context.l10n.profileLimitReachedSubtitle,
      illustrationAsset: 'assets/illustrations/family.png',
    );
  }
}

// ── Family group (peers) ─────────────────────────────────────────────────────
// Крок 11: єдиний шлях стати автономним — приєднатись сюди зі своїм
// акаунтом самостійно (запросити/приєднатись через QR/6-значний код).
// Перетворення "Локальний → Автономний" лишається заблокованим (Крок 1.2).
// Дані про сім'ї/учасників/канали читаються з кешованого `/family/status`
// ([familyStatusProvider]) — не з локальної Drift-таблиці, як раніше.

class _FamilyGroupSection extends ConsumerWidget {
  const _FamilyGroupSection();

  Future<void> _confirmLeaveGroup(
      BuildContext context, WidgetRef ref, String familyId, String groupLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.leaveGroupConfirmTitle(groupLabel)),
        content: Text(
          context.l10n.leaveGroupConfirmBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.leaveAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FamilyGroupService(ref.read(databaseProvider)).leaveGroup(familyId);
    try {
      await FamilyServerSyncService(ref.read(databaseProvider), intakeGenerator: ref.read(intakeGeneratorProvider), activityLogGenerator: ref.read(activityLogGeneratorProvider), remindersRepository: ref.read(remindersRepositoryProvider)).syncAll();
    } catch (_) {
      // Тиха невдача — статус все одно підхопиться наступним тригером.
    }
    ref.invalidate(familyStatusProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.leftGroupSnackbar(groupLabel))));
    }
  }

  // Кожне оновлення familyStatusProvider — перевіряємо, чи серед активних
  // учасників МОЄЇ сім'ї (де я адміністратор) є хтось, кого ще не бачив
  // (дедуп — FamilyJoinPopupService, персонально по personUuid, тож
  // повторний виклик після показу нічого не робить). "mark ДО show" —
  // навіть швидкий повторний вхід одразу після показу не дублює поп-ап.
  Future<void> _maybeShowJoinPopups(BuildContext context, List<FamilyMemberEntry> newMembers) async {
    for (final m in newMembers) {
      if (!context.mounted) return;
      // #313: family_screen.dart лишається mounted (просто не в топі
      // навігації), поки зверху відкритий інший екран (напр. Видимість,
      // куди веде сама кнопка "Так" цього поп-апу) — familyStatusProvider
      // може оновитись саме в цей час (напр. фоновий syncAll на екрані
      // видимості) і викликати цей слухач ЗНОВУ, поки перший поп-ап уже
      // показаний і закритий. Без цієї перевірки showDialog все одно
      // намагається відкритись на неактивному маршруті — і "виринає",
      // щойно користувач повертається назад, виглядаючи як дубль.
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (!await FamilyJoinPopupService.shouldShowForOwner(m.personUuid)) continue;
      await FamilyJoinPopupService.markShownForOwner(m.personUuid);
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
      await showFamilyJoinPopup(context, peerName: m.name, asInvitee: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(familyStatusProvider).valueOrNull;
    final families = status?.families ?? const <FamilyEntry>[];
    final myAccountId = ref.watch(myAccountIdProvider).valueOrNull;

    ref.listen<AsyncValue<FamilyStatusResult?>>(familyStatusProvider, (previous, next) {
      final s = next.valueOrNull;
      final myId = ref.read(myAccountIdProvider).valueOrNull;
      if (s == null || myId == null) return;
      final myFamily = s.families.where((f) => f.role == 'admin').firstOrNull;
      if (myFamily == null) return;
      final others = myFamily.members.where((m) => m.accountId != myId && m.status == 'active').toList();
      unawaited(_maybeShowJoinPopups(context, others));
    });

    final ownPlan = ref.watch(ownPlanProvider).valueOrNull ?? AppPlan.free;
    // Слоти рахуються лише за учасниками сімей, де я адміністратор —
    // вхідні запрошення до чужих груп ліміт не займають.
    final invitedByMeCount = families
        .where((f) => f.role == 'admin')
        .expand((f) => f.members)
        .where((m) => m.accountId != myAccountId)
        .length;
    final autonomousLimitReached = ownPlan.limits.maxAutonomousMembers == 0
        ? true
        : invitedByMeCount >= ownPlan.limits.maxAutonomousMembers;

    // "Моя" сім'я (де я адміністратор) — першою, решта — порядком з сервера.
    final ordered = [...families]
      ..sort((a, b) => a.role == 'admin' ? -1 : (b.role == 'admin' ? 1 : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.familyGroupSectionLabel),
        const SizedBox(height: AppDimensions.md),
        for (final family in ordered) ...[
          _FamilyGroupSubsection(
            family: family,
            myAccountId: myAccountId,
            slotsLabel: family.role == 'admin'
                ? context.l10n.slotsUsedLabel(invitedByMeCount, ownPlan.limits.maxAutonomousMembers)
                : null,
            showPayerBadge: family.role == 'admin' ? ownPlan == AppPlan.family : family.plan.active,
            onLeave: (label) => _confirmLeaveGroup(context, ref, family.familyId, label),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        Row(
          children: [
            Expanded(
              child: _GroupActionTile(
                assetIcon: 'qr-code',
                label: context.l10n.inviteToFamilyTitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => autonomousLimitReached
                        ? EllyDeniedScreen(
                            title: context.l10n.autonomousLimitReachedTitle,
                            subtitle: context.l10n.autonomousLimitReachedSubtitle,
                          )
                        : const FamilyGroupInviteScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _GroupActionTile(
                assetIcon: 'family',
                label: context.l10n.joinAction,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FamilyGroupJoinScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Одна секція — одна сімейна група (одна `familyId`). "Моя" (я
/// адміністратор і запрошую) — без підпису-приналежності; "чужа" (мене
/// туди запросили) — з підписом "Сім'я {ім'я одного з учасників}" (сервер
/// не повертає явно "хто саме мене запросив", лише список активних
/// учасників — тому як представник групи береться перший інший учасник,
/// той самий фолбек, що був і в архівній версії).
class _FamilyGroupSubsection extends StatelessWidget {
  final FamilyEntry family;
  final String? myAccountId;
  final String? slotsLabel;
  final bool showPayerBadge;
  final void Function(String label) onLeave;
  const _FamilyGroupSubsection({
    required this.family,
    required this.myAccountId,
    this.slotsLabel,
    this.showPayerBadge = false,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final others = family.members.where((m) => m.accountId != myAccountId).toList();
    final isOwnFamily = family.role == 'admin';
    final label = isOwnFamily
        ? context.l10n.myFamilyLabel
        : context.l10n.peerFamilyLabel(others.isNotEmpty ? others.first.name : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FamilyAccordionSection(
          header: Row(
            children: [
              Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.textSub)),
              if (showPayerBadge) ...[
                const SizedBox(width: 6),
                const Icon(Icons.workspace_premium_rounded, size: 15, color: AppColors.primary),
              ],
              if (slotsLabel != null) ...[
                const Spacer(),
                Text(slotsLabel!,
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          child: others.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    ...others.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                          child: _PeerCard(family: family, member: m, isAdmin: isOwnFamily),
                        )),
                  ],
                ),
        ),
        // Адміністратор власної сім'ї не може її покинути (лише видаляти
        // учасників через _PeerCard) — щоб не "осиротити" сім'ю, для якої
        // owner_account_id більше не вказує на активного учасника.

        if (!isOwnFamily)
          Center(
            child: TextButton(
              onPressed: () => onLeave(label),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(context.l10n.leaveAction),
            ),
          ),
      ],
    );
  }
}

class _PeerCard extends ConsumerWidget {
  final FamilyEntry family;
  final FamilyMemberEntry member;
  // Хрестик (виключити з сім'ї для всіх) видно лише в "моїй" групі — я там
  // адміністратор/платящий; у чужій сім'ї я гість, і не маю права
  // виключати інших її учасників (лишається тільки "Покинути" — вихід
  // виключно за себе).
  final bool isAdmin;
  const _PeerCard({required this.family, required this.member, required this.isAdmin});

  String? _channelId() => family.channels
      .where((c) => c.counterpartAccountId == member.accountId)
      .map((c) => c.channelId)
      .firstOrNull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(_peerMissedProvider(member.personUuid)).valueOrNull ?? const [];
    final firstMissed = missed.isNotEmpty ? missed.first : null;
    final channelId = _channelId();

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: channelId == null
                ? null
                : () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => _PeerActionsSheet(
                        family: family,
                        member: member,
                        channelId: channelId,
                        isAdmin: isAdmin,
                      ),
                    ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AvatarImage(index: member.avatarIndex, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: AppTextStyles.labelLg),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.independentAccountLabel,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (firstMissed != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_rounded, size: 18, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_missedItemTitle(context, firstMissed), style: AppTextStyles.labelMd),
                              Text(
                                missed.length > 1
                                    ? context.l10n.missedCountLabel(missed.length)
                                    : context.l10n.missedLabel,
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Крок 11 (#225-суміжне): _peerMissedProvider уже фільтрує
                    // за грантом view (дані, яких я не бачу, сюди не
                    // потрапляють) — тож якщо картка взагалі показує
                    // пропущене, у мене вже є право його побачити, окрема
                    // перевірка гранту тут не потрібна.
                    if (channelId != null) ...[
                      const SizedBox(height: 10),
                      _RemindButton(
                        channelId: channelId,
                        counterpartPublicKeyHex: member.publicKeyHex,
                        peerName: member.name,
                        item: firstMissed,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Крок 11 (#225-суміжне): "🔔 Нагадати" про пропущене — вже готова
/// інфраструктура (`FamilyServerSyncService.sendRemoteReminder`, FCM-nudge,
/// `_handleRemoteReminder`/`showRemoteReminder` на боці отримувача) просто
/// не була підключена до жодної кнопки. Окремий StatefulWidget (а не
/// перетворення всього _PeerCard на Stateful) — щоб "стоппер" на подвійний
/// тап жив локально, поки перше надсилання ще в польоті.
class _RemindButton extends ConsumerStatefulWidget {
  final String channelId;
  final String counterpartPublicKeyHex;
  final String peerName;
  final _MissedItem item;
  const _RemindButton({
    required this.channelId,
    required this.counterpartPublicKeyHex,
    required this.peerName,
    required this.item,
  });

  @override
  ConsumerState<_RemindButton> createState() => _RemindButtonState();
}

class _RemindButtonState extends ConsumerState<_RemindButton> {
  bool _sending = false;

  Future<void> _remind() async {
    if (_sending) return;
    setState(() => _sending = true);
    final l10n = context.l10n;
    final item = widget.item;
    final timeStr =
        '${item.scheduledAt.hour.toString().padLeft(2, '0')}:${item.scheduledAt.minute.toString().padLeft(2, '0')}';
    final title = _missedItemTitle(context, item);
    final body = switch (item.entityType) {
      'intake' => l10n.reminderTakeMedBody(title, item.detail != null ? ' — ${item.detail}' : '', timeStr),
      'activity_log' => l10n.reminderDoActivityBody(title, timeStr),
      'doctor_appointment' =>
        l10n.reminderDoctorVisitBody(title, item.detail != null && item.detail!.isNotEmpty ? ' (${item.detail})' : ''),
      'wellbeing' => l10n.reminderWellbeingBody,
      _ => l10n.reminderGenericBody,
    };
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FamilyServerSyncService(ref.read(databaseProvider), intakeGenerator: ref.read(intakeGeneratorProvider), activityLogGenerator: ref.read(activityLogGeneratorProvider), remindersRepository: ref.read(remindersRepositoryProvider)).sendRemoteReminder(
        channelId: widget.channelId,
        counterpartPublicKeyHex: widget.counterpartPublicKeyHex,
        title: l10n.reminderPushTitle,
        body: body,
      );
      // Підтвердження, що надсилання пройшло на сервер — не гарантія, що
      // сповіщення вже показалось на екрані піра (залежить від того, чи
      // його застосунок зараз здатний прийняти push, поза нашим контролем).
      messenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.reminderSentSnackbar(widget.peerName))),
          ],
        ),
        backgroundColor: AppColors.primary,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.sendFailedError('$e'))),
          ],
        ),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _sending ? null : _remind,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: _sending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _sending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                context.l10n.remindAction,
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
      ),
    );
  }
}

class _PeerActionsSheet extends ConsumerWidget {
  final FamilyEntry family;
  final FamilyMemberEntry member;
  final String channelId;
  // Виключити з сім'ї видно лише в "моїй" групі — я там адміністратор/
  // платящий; у чужій сім'ї я гість, і не маю права виключати інших її
  // учасників (можу лише сам покинути ЇЇ, не свою).
  final bool isAdmin;
  const _PeerActionsSheet({
    required this.family,
    required this.member,
    required this.channelId,
    required this.isAdmin,
  });

  Future<void> _confirmExclude(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removePeerConfirmTitle(member.name)),
        content: Text(context.l10n.removePeerConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.excludeFromFamilyAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FamilyGroupService(ref.read(databaseProvider)).kick(family.familyId, member.accountId);
    try {
      await FamilyServerSyncService(ref.read(databaseProvider), intakeGenerator: ref.read(intakeGeneratorProvider), activityLogGenerator: ref.read(activityLogGeneratorProvider), remindersRepository: ref.read(remindersRepositoryProvider)).syncAll();
    } catch (_) {
      // Тиха невдача.
    }
    ref.invalidate(familyStatusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <_SheetAction>[
      _SheetAction(
        icon: Icons.today_rounded,
        label: context.l10n.viewAsLabel(member.name),
        onTap: () {
          ref.read(activeMemberIdProvider.notifier).state = null;
          ref.read(activePeerProvider.notifier).state = PeerSubject(
            personUuid: member.personUuid,
            channelId: channelId,
            accountId: member.accountId,
            publicKeyHex: member.publicKeyHex,
            name: member.name,
            avatarIndex: member.avatarIndex,
          );
          ref.read(requestedTabIndexProvider.notifier).state = 2; // Сьогодні
          Navigator.pop(context);
        },
      ),
      _SheetAction(
        icon: Icons.visibility_rounded,
        label: context.l10n.familyVisibilityLabel,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyVisibilityScreen(focusViewerPersonUuid: member.personUuid),
            ),
          );
        },
      ),
      if (isAdmin)
        _SheetAction(
          icon: Icons.person_remove_rounded,
          label: context.l10n.excludeFromFamilyAction,
          color: AppColors.danger,
          onTap: () => _confirmExclude(context, ref),
        ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding, AppDimensions.lg, AppDimensions.screenPadding, AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(member.name, style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    rows[i],
                    if (i < rows.length - 1) const Divider(height: 1, color: AppColors.borderLight),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupActionTile extends StatelessWidget {
  final String assetIcon;
  final String label;
  final VoidCallback onTap;
  const _GroupActionTile({required this.assetIcon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            AssetIcon(assetIcon, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add member screen ─────────────────────────────────────────────────────────

void _openAddMemberScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _AddMemberScreen()),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.labelSm);
}

/// Акордеон для списків членів сім'ї — заголовок у тому самому стилі, що
/// й "Ранок"/"День"/"Ніч" на Сьогодні (uppercase labelSm), зі стрілкою
/// розкриття справа скраю. За замовчуванням розкрито.
class _FamilyAccordionSection extends StatefulWidget {
  final Widget header;
  final Widget child;
  const _FamilyAccordionSection({required this.header, required this.child});

  @override
  State<_FamilyAccordionSection> createState() => _FamilyAccordionSectionState();
}

class _FamilyAccordionSectionState extends State<_FamilyAccordionSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
            child: Row(
              children: [
                Expanded(child: widget.header),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) widget.child,
      ],
    );
  }
}

// Розділ пікера аватарів на діапазон [start, end) — той самий вигляд плиток,
// що й раніше, лише параметризований, щоб малювати і людські аватари, і
// секцію "Домашні улюбленці" одним і тим самим кодом.
class _AvatarGrid extends StatelessWidget {
  final int start;
  final int end;
  final int selectedIndex;
  final void Function(int) onChanged;
  const _AvatarGrid({
    required this.start,
    required this.end,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: end - start,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final index = start + i;
        final sel = index == selectedIndex;
        return GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: sel ? AppColors.primaryLight : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? AppColors.success : AppColors.border,
                width: sel ? 2 : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: AvatarImage(index: index, size: 49),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarSectionDivider extends StatelessWidget {
  final String label;
  const _AvatarSectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _AddMemberBackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _AddMemberBackHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Text(title, style: AppTextStyles.h3),
        ],
      ),
    );
  }
}


class _AddMemberScreen extends ConsumerStatefulWidget {
  const _AddMemberScreen();

  @override
  ConsumerState<_AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<_AddMemberScreen> {
  final _nameCtrl = TextEditingController();
  int _avatarIndex = 0;
  bool _saving = false;
  bool _consentChecked = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (!_consentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.confirmGuardianConsentSnackbar)),
      );
      return;
    }

    setState(() => _saving = true);
    await ref.read(membersRepositoryProvider).insert(
          MembersCompanion.insert(
            name: name,
            avatarIndex: Value(_avatarIndex),
            role: const Value('dependent'),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AddMemberBackHeader(
                title: context.l10n.addFamilyMemberLabel,
                onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(context.l10n.nameFieldLabel),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: context.l10n.memberNameHint,
                          hintStyle: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textMuted),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    _SectionLabel(context.l10n.avatarFieldLabel),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AvatarGrid(
                              start: 0,
                              end: avatarCount,
                              selectedIndex: _avatarIndex,
                              onChanged: (i) =>
                                  setState(() => _avatarIndex = i),
                            ),
                            const SizedBox(height: AppDimensions.md),
                            _AvatarSectionDivider(
                              label: context.l10n.petAvatarsSectionLabel,
                            ),
                            const SizedBox(height: AppDimensions.md),
                            _AvatarGrid(
                              start: avatarCount,
                              end: totalAvatarCount,
                              selectedIndex: _avatarIndex,
                              onChanged: (i) =>
                                  setState(() => _avatarIndex = i),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    GestureDetector(
                      onTap: () => setState(() => _consentChecked = !_consentChecked),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _consentChecked ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _consentChecked ? AppColors.primary : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: _consentChecked
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.guardianConsentCheckbox,
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          _saving ? context.l10n.savingLabel : context.l10n.addAction,
                          style:
                              AppTextStyles.labelLg.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissedItem {
  final String entityType; // intake / activity_log / doctor_appointment / wellbeing
  final String uuid;
  final String? title;
  final String? detail;
  final DateTime scheduledAt;
  const _MissedItem({
    required this.entityType,
    required this.uuid,
    required this.title,
    this.detail,
    required this.scheduledAt,
  });
}

/// Заголовок пропущеного пункту — назва сутності, якщо вона відома
/// (medicationSyncUuid/activitySyncUuid не завжди резолвиться, якщо самі
/// ліки/активність ще не долетіли через SharedEntities), інакше типова
/// заглушка за типом сутності. Резолвиться тут, а не в провайдері вище,
/// бо провайдер не має BuildContext для локалізації.
String _missedItemTitle(BuildContext context, _MissedItem item) {
  final title = item.title;
  if (title != null && title.isNotEmpty) return title;
  return switch (item.entityType) {
    'intake' => context.l10n.defaultMedName,
    'activity_log' => context.l10n.defaultActivityName,
    'doctor_appointment' => context.l10n.doctorFallbackLabel,
    _ => context.l10n.wellbeingTitle,
  };
}

/// Пропущене (доза/активність/прийом лікаря/самопочуття) для профілю, яким
/// керує пір [personUuid] — рахується лише за грантом view (дані, яких я не
/// бачу, сюди й не потрапляють у SharedEntities взагалі).
final _peerMissedProvider = StreamProvider.family<List<_MissedItem>, String>((ref, personUuid) {
  return ref.watch(familyPeersRepositoryProvider).watchSharedEntities(personUuid).map((entities) {
    Map<String, dynamic>? decode(SharedEntity e) {
      try {
        return jsonDecode(e.dataJson) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    String? nameFor(String entityType, String? uuid) {
      if (uuid == null) return null;
      for (final e in entities) {
        if (e.entityType == entityType && e.uuid == uuid) return decode(e)?['name'] as String?;
      }
      return null;
    }

    final now = DateTime.now();
    final items = <_MissedItem>[];
    var hasWellbeingLogToday = false;
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final e in entities) {
      if (e.entityType == 'wellbeing_log') {
        final loggedAt = DateTime.tryParse(decode(e)?['loggedAt'] as String? ?? '');
        if (loggedAt != null && !loggedAt.isBefore(todayStart)) hasWellbeingLogToday = true;
      }
    }

    for (final e in entities) {
      final json = decode(e);
      if (json == null) continue;
      final status = json['status'] as String?;
      if (status != null && status != 'pending') continue;

      switch (e.entityType) {
        case 'intake':
          final scheduledAt = DateTime.tryParse(json['scheduledAt'] as String? ?? '');
          if (scheduledAt == null || scheduledAt.isAfter(now)) continue;
          final medName = nameFor('medication', json['medicationSyncUuid'] as String?);
          final doseAmount = json['doseAmount'];
          final dose = doseAmount != null ? '$doseAmount ${json['doseUnit'] ?? ''}'.trim() : null;
          items.add(_MissedItem(
              entityType: 'intake', uuid: e.uuid, title: medName, detail: dose, scheduledAt: scheduledAt));
        case 'activity_log':
          final scheduledAt = DateTime.tryParse(json['scheduledAt'] as String? ?? '');
          if (scheduledAt == null || scheduledAt.isAfter(now)) continue;
          final activityName = nameFor('activity', json['activitySyncUuid'] as String?);
          items.add(_MissedItem(
              entityType: 'activity_log', uuid: e.uuid, title: activityName, scheduledAt: scheduledAt));
        case 'doctor_appointment':
          final scheduledAt = DateTime.tryParse(json['scheduledAt'] as String? ?? '');
          if (scheduledAt == null || scheduledAt.isAfter(now)) continue;
          items.add(_MissedItem(
            entityType: 'doctor_appointment',
            uuid: e.uuid,
            title: json['doctorType'] as String?,
            detail: json['location'] as String?,
            scheduledAt: scheduledAt,
          ));
        // Для ПОВТОРЮВАНИХ нагадувань (daily/weekly/monthly/yearly) статус
        // "виконано/пропущено" живе НЕ в самому doctor_appointment
        // (Reminders.status має сенс лише для repeatType=='none'), а в
        // окремих reminder_log — кожен день/слот окремим записом.
        case 'reminder_log':
          final scheduledAt = DateTime.tryParse(json['scheduledAt'] as String? ?? '');
          if (scheduledAt == null || scheduledAt.isAfter(now)) continue;
          final reminderUuid = json['reminderSyncUuid'] as String?;
          // ⚠️ НЕ nameFor() — той читає поле 'name' (медикаменти/активності),
          // а doctor_appointment зберігає заголовок у 'doctorType'.
          String? reminderTitle;
          for (final re in entities) {
            if (re.entityType == 'doctor_appointment' && re.uuid == reminderUuid) {
              reminderTitle = decode(re)?['doctorType'] as String?;
              break;
            }
          }
          items.add(_MissedItem(
            entityType: 'doctor_appointment',
            uuid: e.uuid,
            title: reminderTitle,
            scheduledAt: scheduledAt,
          ));
      }
    }

    if (!hasWellbeingLogToday) {
      for (final e in entities) {
        if (e.entityType != 'wellbeing_schedule') continue;
        final json = decode(e);
        List<String> times;
        try {
          times = List<String>.from(json?['times'] as List);
        } catch (_) {
          continue;
        }
        final day = DateTime(now.year, now.month, now.day);
        for (final t in times) {
          final parts = t.split(':');
          final slot = DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
          if (slot.isBefore(now)) {
            items.add(_MissedItem(entityType: 'wellbeing', uuid: e.uuid, title: null, scheduledAt: slot));
            break;
          }
        }
      }
    }

    items.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return items;
  });
});
