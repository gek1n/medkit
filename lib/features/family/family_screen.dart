import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/shared_channels_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../pairing/pairing_invite_screen.dart';
import '../pairing/pairing_join_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/family_visibility_screen.dart';
import '../today/providers/today_providers.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _memberMedsProvider = StreamProvider.family<List<Medication>, int>(
  (ref, memberId) =>
      ref.watch(medicationsRepositoryProvider).watchByMember(memberId),
);

final _memberChannelProvider = StreamProvider.family<SharedChannel?, int>(
  (ref, memberId) =>
      ref.watch(sharedChannelsRepositoryProvider).watchForMember(memberId),
);

/// (subjectId, viewerId) — чи дозволив subject перегляд своїх даних viewer'у.
final _viewAllowedProvider =
    FutureProvider.family<bool, (int, int)>((ref, ids) {
  return FamilyVisibilityService.isAllowed(
      ids.$1, ids.$2, FamilyPermission.view);
});

final _viewOrEditAllowedProvider =
    FutureProvider.family<bool, (int, int)>((ref, ids) async {
  final view =
      await FamilyVisibilityService.isAllowed(ids.$1, ids.$2, FamilyPermission.view);
  if (view) return true;
  return FamilyVisibilityService.isAllowed(ids.$1, ids.$2, FamilyPermission.edit);
});

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
    // Власник рахується як локальний профіль — той самий слот, що і раніше
    // займав "maxMembers" на Free-плані.
    final localCount = members.where((m) => m.role != 'member').length;
    final autonomousCount = members.where((m) => m.role == 'member').length;
    final localLimitReached =
        limits.maxLocalMembers != 0 && localCount >= limits.maxLocalMembers;
    final autonomousLimitReached = limits.maxAutonomousMembers == 0
        ? true
        : autonomousCount >= limits.maxAutonomousMembers;
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

    return CustomScrollView(
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
                const _FamilyUpgradeBanner(
                  badge: 'Сімʼя',
                  title: 'Профілі локальні',
                  subtitle:
                      'Щоб сім\'я теж могла керувати — перейдіть на Elly Family',
                ),
              if (blocked || plan == AppPlan.plus)
                const SizedBox(height: AppDimensions.md),
              ...others.map((m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.md),
                    child: _MemberCard(member: m, ownerId: owner.id),
                  )),
              if (!blocked) const _AddMemberTile(),
              const SizedBox(height: AppDimensions.xl),
              if (others.isNotEmpty) _CareSummaryCard(count: others.length),
              const SizedBox(height: AppDimensions.xl),
              const _InviteSection(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
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
                    Text('Сімʼя', style: AppTextStyles.h2),
                    Text(
                      '$count ${_membersLabel(count)}',
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

  String _membersLabel(int n) {
    if (n == 1) return 'член';
    if (n < 5) return 'члени';
    return 'членів';
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────

class _MemberCard extends ConsumerWidget {
  final Member member;
  final int ownerId;
  const _MemberCard({required this.member, required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = member.role == 'owner';
    final isAutonomous = member.role == 'member';
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));
    final medsAsync = ref.watch(_memberMedsProvider(member.id));

    final intakes = intakesAsync.valueOrNull ?? [];
    final meds = medsAsync.valueOrNull ?? [];

    final taken = intakes.where((i) => i.status == 'taken').length;
    final total = intakes.length;
    final missedIntakes = intakes.where((i) => i.status == 'skipped').toList();
    final nextIntake = () {
      final pending = intakes.where((i) => i.status == 'pending').toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return pending.isEmpty ? null : pending.first;
    }();

    // Якщо план більше не підтримує автономні профілі (напр. злетіла
    // підписка Elly Family) — перегляд/редагування таких профілів
    // забороняється, хоч у списку сім'ї вони лишаються видимими.
    final plan = ref.watch(planProvider);
    final restrictedByPlan = isAutonomous && plan.limits.maxAutonomousMembers == 0;

    // Локальні профілі керує сам власник — перегляд завжди дозволений.
    // Автономні — лише якщо самі дозволили (за замовчуванням так) і план
    // це дозволяє.
    final viewAllowedAsync = isOwner || !isAutonomous
        ? const AsyncValue<bool>.data(true)
        : ref.watch(_viewAllowedProvider((member.id, ownerId)));
    final viewAllowed = !restrictedByPlan && (viewAllowedAsync.valueOrNull ?? false);

    final hasMissed = missedIntakes.isNotEmpty;

    String medNameFor(int medicationId) {
      for (final m in meds) {
        if (m.id == medicationId) return m.name;
      }
      return 'Ліки';
    }

    String timeStr(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    Widget statusLine;
    if (isOwner) {
      statusLine = Text(
        total == 0
            ? 'Немає ліків на сьогодні'
            : (taken == total ? 'Усе виконано сьогодні' : '$taken з $total прийомів'),
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      );
    } else if (restrictedByPlan) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text('Потрібен план Elly Family',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
      ]);
    } else if (!viewAllowed) {
      statusLine = const SizedBox.shrink();
    } else if (hasMissed) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_rounded, size: 12, color: AppColors.danger),
        const SizedBox(width: 3),
        Text('Пропущено ${missedIntakes.length} ${_remindersWordUk(missedIntakes.length)}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
      ]);
    } else if (total > 0 && taken == total) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF22C55E)),
        const SizedBox(width: 3),
        Text('Усе виконано сьогодні',
            style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF22C55E))),
      ]);
    } else if (nextIntake != null) {
      statusLine = Text(
        'Наступне: ${medNameFor(nextIntake.medicationId)} о ${timeStr(nextIntake.scheduledAt)}',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      );
    } else {
      statusLine = Text('Немає ліків на сьогодні',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted));
    }

    final showMissedCard = !isOwner && viewAllowed && hasMissed;
    final firstMissed = hasMissed ? missedIntakes.first : null;

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
                                        isOwner
                                            ? 'я'
                                            : (isAutonomous ? 'Автономний' : 'Локальний'),
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
                                const Icon(Icons.medication_rounded,
                                    size: 18, color: AppColors.danger),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(medNameFor(firstMissed.medicationId),
                                          style: AppTextStyles.labelMd),
                                      Text(
                                          '${timeStr(firstMissed.scheduledAt)} · не прийнято',
                                          style: AppTextStyles.bodySm
                                              .copyWith(color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAutonomous) ...[
                            const SizedBox(height: 10),
                            _RemindBtn(
                              label: '🔔 Нагадати',
                              color: Colors.white,
                              bg: AppColors.primary,
                              fullWidth: true,
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Нагадування для ${member.name} відправлено')),
                              ),
                            ),
                          ],
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

String _remindersWordUk(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'нагадування';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'нагадування';
  return 'нагадувань';
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
    final plan = ref.watch(planProvider);
    final isAutonomous = member.role == 'member';
    final channelAsync = ref.watch(_memberChannelProvider(member.id));
    final autonomousCount =
        ref.watch(allMembersProvider).valueOrNull?.where((m) => m.role == 'member').length ?? 0;
    final autonomousLimitReached = plan.limits.maxAutonomousMembers == 0
        ? true
        : autonomousCount >= plan.limits.maxAutonomousMembers;
    // Якщо план більше не підтримує автономні профілі (напр. злетіла
    // підписка Elly Family), переглядати/редагувати їх не можна незалежно
    // від того, що дозволив сам профіль.
    final planAllowsAutonomous = plan.limits.maxAutonomousMembers > 0;
    final canViewAsAsync = isAutonomous
        ? ref.watch(_viewOrEditAllowedProvider((member.id, ownerId)))
        : const AsyncValue<bool>.data(true);
    final canViewAs =
        (!isAutonomous || planAllowsAutonomous) && (canViewAsAsync.valueOrNull ?? false);

    final rows = <_SheetAction>[
      if (!isAutonomous)
        if (autonomousLimitReached)
          _SheetAction(
            icon: Icons.workspace_premium_rounded,
            label: 'Запросити',
            subtitle: 'Автономні профілі — лише на Elly Family',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlansScreen()));
            },
          )
        else
          _SheetAction(
            icon: Icons.person_add_alt_1_rounded,
            label: channelAsync.valueOrNull != null
                ? 'Запрошення надіслано'
                : 'Запросити в застосунок',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PairingInviteScreen(
                    ownerName: member.name,
                    memberId: member.id,
                  ),
                ),
              );
            },
          ),
      // Локальні профілі не мають власного акаунту, яким могли б керувати
      // рівнями доступу — власник і так керує ними напряму.
      if (isAutonomous)
        _SheetAction(
          icon: Icons.visibility_rounded,
          label: 'Рівні доступу',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FamilyVisibilityScreen(subjectMemberId: member.id),
              ),
            );
          },
        ),
      if (!isAutonomous || canViewAs)
        _SheetAction(
          icon: Icons.today_rounded,
          label: 'Переглянути як ${member.name}',
          onTap: () {
            ref.read(activeMemberIdProvider.notifier).state = member.id;
            ref.read(requestedTabIndexProvider.notifier).state = 0;
            Navigator.pop(context);
          },
        ),
      _SheetAction(
        icon: Icons.delete_forever_rounded,
        label: 'Видалити назавжди',
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
            Text('Ви впевнені?',
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Будуть видалені весь розклад та медичні картки, прив\'язані до профілю ${member.name}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Видалити назавжди'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FamilySyncService(ref.read(databaseProvider)).deleteMemberEverywhere(member.id);
      await ref.read(membersRepositoryProvider).delete(member.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.label,
    this.subtitle,
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted)),
                  ],
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
              'Ви піклуєтесь про $count ${_closeOnesWordUk(count)}. '
              'Еллі надішле сповіщення, якщо хтось пропустить прийом.',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _closeOnesWordUk(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'близького';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'близьких';
  return 'близьких';
}

class _RemindBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  final bool fullWidth;
  const _RemindBtn({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        alignment: fullWidth ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMd
              .copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 13),
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
                Text('Додати члена сімʼї',
                    style:
                        AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('Батьки, діти, партнер…',
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
  final String badge;
  final String title;
  final String subtitle;
  const _FamilyUpgradeBanner({
    this.badge = 'Сімʼя',
    this.title = 'Ліміт профілів досягнуто',
    this.subtitle = 'Перейдіть на Elly Plus — необмежена кількість локальних профілів',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlansScreen()),
      ),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C9A6A), Color(0xFF3B7A56)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: 0,
              child: Image.asset('assets/illustrations/family.png',
                  height: 92, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.family_restroom_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(badge,
                            style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(title,
                      style: AppTextStyles.labelLg.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 190,
                    child: Text(subtitle,
                        style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.85))),
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

// ── Invite section ────────────────────────────────────────────────────────────
// Запросити конкретного члена сім'ї можна з його картки (кнопка "Підключити
// телефон" у _MemberCard) — тут лишається лише приєднання за чужим кодом,
// бо до розшифровки коду невідомо, чий це профіль.

class _InviteSection extends StatelessWidget {
  const _InviteSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Приєднатись до сім\'ї'),
        const SizedBox(height: AppDimensions.md),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.of(context).push<PairingResult>(
              MaterialPageRoute(builder: (_) => const PairingJoinScreen()),
            );
            if (result != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Приєднано до "${result.name}"')),
              );
            }
          },
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
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('У мене є код',
                          style: AppTextStyles.labelLg
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text('Приєднатись до іншого пристрою',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
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

class _ProfileTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _ProfileTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: locked
              ? AppColors.bgPage
              : (selected ? AppColors.primaryLight : AppColors.surface),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: selected && !locked ? AppColors.primary : AppColors.border,
            width: selected && !locked ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(locked ? Icons.workspace_premium_rounded : icon,
                size: 20,
                color: locked
                    ? AppColors.warning
                    : (selected ? AppColors.primary : AppColors.textMuted)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelLg.copyWith(
                          color: locked
                              ? AppColors.textMuted
                              : (selected
                                  ? AppColors.primary
                                  : AppColors.textMain))),
                  const SizedBox(height: 3),
                  Text(description,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                  if (locked) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              size: 11, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text('Доступно в Elly Family',
                              style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (locked)
              const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.textMuted)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.circle_rounded,
                        size: 8, color: Colors.white)
                    : null,
              ),
          ],
        ),
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
  String _profileType = 'dependent'; // dependent (Локальний) | member (Автономний)
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (_profileType == 'member') {
      final plan = ref.read(planProvider);
      final members = ref.read(allMembersProvider).valueOrNull ?? [];
      final autonomousCount = members.where((m) => m.role == 'member').length;
      final maxAutonomous = plan.limits.maxAutonomousMembers;
      if (maxAutonomous == 0 || autonomousCount >= maxAutonomous) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(maxAutonomous == 0
                ? 'Автономні профілі доступні з плану Elly Family'
                : 'Досягнуто ліміту автономних профілів ($maxAutonomous)'),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    await ref.read(membersRepositoryProvider).insert(
          MembersCompanion.insert(
            name: name,
            avatarIndex: Value(_avatarIndex),
            role: Value(_profileType),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final autonomousLocked =
        ref.watch(planProvider).limits.maxAutonomousMembers == 0;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _AddMemberBackHeader(
                title: 'Додати члена сімʼї',
                onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('ІМʼЯ'),
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
                          hintText: 'Мама, Тато, Бабуся…',
                          hintStyle: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    const _SectionLabel('АВАТАР'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: GridView.builder(
                        itemCount: avatarCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (_, i) {
                          final sel = i == _avatarIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _avatarIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      sel ? AppColors.success : AppColors.border,
                                  width: sel ? 2 : 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(1.5),
                                child: AvatarImage(index: i, size: 49),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    const _SectionLabel('ТИП ПРОФІЛЮ'),
                    const SizedBox(height: 8),
                    _ProfileTypeCard(
                      icon: Icons.home_rounded,
                      title: 'Локальний',
                      description:
                          'Без власного телефону — записи зберігаються у твоєму акаунті, ти керуєш ліками та розкладом.',
                      selected: _profileType == 'dependent',
                      onTap: () => setState(() => _profileType = 'dependent'),
                    ),
                    const SizedBox(height: 10),
                    _ProfileTypeCard(
                      icon: Icons.link_rounded,
                      title: 'Автономний',
                      description:
                          'Надсилаєш інвайт. Людина сама встановлює застосунок і керує своїм профілем.',
                      selected: _profileType == 'member',
                      locked: autonomousLocked,
                      onTap: autonomousLocked
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PlansScreen()))
                          : () => setState(() => _profileType = 'member'),
                    ),
                    const SizedBox(height: AppDimensions.xl),
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
                          _saving ? 'Зберігаємо...' : 'Додати',
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
