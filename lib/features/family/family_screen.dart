import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/services/attachment_cleanup_service.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';
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
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../plans/elly_denied_screen.dart';
import '../plans/plans_screen.dart';
import '../today/providers/today_providers.dart';
import 'family_group_invite_screen.dart';
import 'family_group_join_screen.dart';
import 'shared_family_data_screen.dart';

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
    // Власник рахується як локальний профіль — той самий слот, що і раніше
    // займав "maxMembers" на Free-плані. "Автономний" тепер завжди означає
    // незалежний FamilyPeer (Members більше не мають ролі 'member'), тому
    // ліміт рахується за кількістю пірів.
    final localCount = members.length;
    // Лише пірі, яких запросив Я (invitedMe == false), витрачають мій ліміт
    // слотів — вхідні запрошення (мене хтось запросив до своєї сім'ї) не
    // повинні його займати.
    final peersCount = (ref.watch(_familyPeersProvider).valueOrNull ?? [])
        .where((p) => !p.invitedMe)
        .length;
    final localLimitReached =
        limits.maxLocalMembers != 0 && localCount >= limits.maxLocalMembers;
    if (localLimitReached) unawaited(MarketingTopicsService.markHitLocalLimit());
    final autonomousLimitReached = limits.maxAutonomousMembers == 0
        ? true
        : peersCount >= limits.maxAutonomousMembers;
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
        ref.invalidate(allMembersProvider);
        ref.invalidate(_familyPeersProvider);
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
              ...others.map((m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.md),
                    child: _MemberCard(member: m, ownerId: owner.id),
                  )),
              if (!blocked) const _AddMemberTile(),
              const SizedBox(height: AppDimensions.xl),
              if (others.isNotEmpty) _CareSummaryCard(count: others.length),
              const SizedBox(height: AppDimensions.xl),
              _FamilyGroupSection(ownerFamilyId: owner.familyId),
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
  const _MemberCard({required this.member, required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = member.role == 'owner';
    // Лише owner/dependent лишаються локальними Members-рядками — власник
    // веде dependent-профілі напряму, тож перегляд тут завжди дозволений,
    // жодних permission-гейтів не потрібно (на відміну від незалежних
    // FamilyPeers, з ними видимість — окреме питання, див. _PeerCard).
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

    final hasMissed = missedIntakes.isNotEmpty;

    String medNameFor(int medicationId) {
      for (final m in meds) {
        if (m.id == medicationId) return m.name;
      }
      return context.l10n.defaultMedName;
    }

    String timeStr(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    Widget statusLine;
    if (isOwner) {
      statusLine = Text(
        total == 0
            ? context.l10n.noMedsTodayLabel
            : (taken == total
                ? context.l10n.allDoneTodayLabel
                : context.l10n.takenOfTotalIntakesLabel(taken, total)),
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      );
    } else if (hasMissed) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_rounded, size: 12, color: AppColors.danger),
        const SizedBox(width: 3),
        Text(context.l10n.missedRemindersLabel(missedIntakes.length),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
      ]);
    } else if (total > 0 && taken == total) {
      statusLine = Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF22C55E)),
        const SizedBox(width: 3),
        Text(context.l10n.allDoneTodayLabel,
            style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF22C55E))),
      ]);
    } else if (nextIntake != null) {
      statusLine = Text(
        context.l10n.nextIntakeLabel(medNameFor(nextIntake.medicationId), timeStr(nextIntake.scheduledAt)),
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      );
    } else {
      statusLine = Text(context.l10n.noMedsTodayLabel,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted));
    }

    final showMissedCard = !isOwner && hasMissed;
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
    // "Автономний" тепер завжди означає незалежний FamilyPeer, а не
    // локальний Member-рядок — тому ліміт плану рахується за кількістю
    // пірів, а не за роллю цього профілю (він завжди dependent/owner тут).
    final peersCount = (ref.watch(_familyPeersProvider).valueOrNull ?? [])
        .where((p) => !p.invitedMe)
        .length;
    final autonomousLimitReached = plan.limits.maxAutonomousMembers == 0
        ? true
        : peersCount >= plan.limits.maxAutonomousMembers;
    final pendingConversion = ref.watch(_pendingConversionProvider(member.id)).valueOrNull ?? false;

    final rows = <_SheetAction>[
      if (autonomousLimitReached)
        _SheetAction(
          icon: Icons.workspace_premium_rounded,
          label: context.l10n.inviteAction,
          subtitle: context.l10n.autonomousProfilesPlusOnly,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlansScreen()));
          },
        )
      else
        _SheetAction(
          icon: Icons.person_add_alt_1_rounded,
          label: pendingConversion ? context.l10n.awaitingJoinLabel : context.l10n.inviteToAppLabel,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FamilyGroupInviteScreen(forDependent: member),
              ),
            );
          },
        ),
      _SheetAction(
        icon: Icons.today_rounded,
        label: context.l10n.viewAsLabel(member.name),
        onTap: () {
          ref.read(activeMemberIdProvider.notifier).state = member.id;
          ref.read(requestedTabIndexProvider.notifier).state = 0;
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
      await FamilySyncService(db).deleteMemberEverywhere(member.id);
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
    final badgeText = badge ?? context.l10n.familyLabel;
    final titleText = title ?? context.l10n.profileLimitReachedTitle;
    final subtitleText = subtitle ?? context.l10n.profileLimitReachedSubtitle;
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
                        Text(badgeText,
                            style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(titleText,
                      style: AppTextStyles.labelLg.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 190,
                    child: Text(subtitleText,
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

// ── Family group (peers) ─────────────────────────────────────────────────────
// Єдиний шлях стати автономним — або приєднатись сюди зі своїм акаунтом
// самостійно, або через "Запросити в застосунок" на картці локального
// профілю (перетворення "Локальний → Автономний" з переносом історії, див.
// FamilyGroupService.createConversionInvite). Обмін лише візитівкою
// (ім'я/аватар), без жодних медичних даних. Видимість між учасниками —
// окреме налаштування (Фаза 3/4), тут лише сам факт членства.

class _FamilyGroupSection extends ConsumerWidget {
  final String? ownerFamilyId;
  const _FamilyGroupSection({required this.ownerFamilyId});

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
    await FamilyPeerSyncService(ref.read(databaseProvider)).leaveGroup(familyId);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.leftGroupSnackbar(groupLabel))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peersAsync = ref.watch(_familyPeersProvider);
    final peers = peersAsync.valueOrNull ?? [];
    final plan = ref.watch(planProvider);
    // Слоти рахуються лише за тими, кого запросив Я (invitedMe==false) —
    // вхідні запрошення до чужих груп ліміт не займають.
    final invitedByMeCount = peers.where((p) => !p.invitedMe).length;
    final autonomousLimitReached = plan.limits.maxAutonomousMembers == 0
        ? true
        : invitedByMeCount >= plan.limits.maxAutonomousMembers;

    // Мультисемейність: один пристрій може одночасно вести власну сім'ю і
    // бути гостем у довільній кількості чужих — кожна familyId стає своєю
    // візуальною секцією з окремою кнопкою "Покинути".
    final groups = <String, List<FamilyPeer>>{};
    for (final p in peers) {
      groups.putIfAbsent(p.familyId, () => []).add(p);
    }
    final ownGroup = ownerFamilyId != null ? groups.remove(ownerFamilyId) : null;
    final orderedEntries = [
      if (ownGroup != null) MapEntry(ownerFamilyId!, ownGroup),
      ...groups.entries,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.familyGroupSectionLabel),
        const SizedBox(height: AppDimensions.md),
        for (final entry in orderedEntries) ...[
          _FamilyGroupSubsection(
            familyId: entry.key,
            peers: entry.value,
            isOwnFamily: entry.key == ownerFamilyId,
            // Лічильник слотів і корона — лише для "моєї" секції (я
            // платящий саме тут); у чужій сім'ї я гість, це не моя квота.
            slotsLabel: entry.key == ownerFamilyId
                ? context.l10n.slotsUsedLabel(invitedByMeCount, plan.limits.maxAutonomousMembers)
                : null,
            showPayerBadge: entry.key == ownerFamilyId && plan == AppPlan.family,
            onLeave: (label) =>
                _confirmLeaveGroup(context, ref, entry.key, label),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        Row(
          children: [
            Expanded(
              child: _GroupActionTile(
                icon: Icons.qr_code_2_rounded,
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
                icon: Icons.group_add_rounded,
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

/// Одна секція — одна сімейна група (одна `familyId`). Або "моя" (я плачу і
/// запрошую) — тоді без підпису-приналежності, або "чужа" (мене туди
/// запросили) — тоді підпис "Сім'я {ім'я того, хто запросив}".
class _FamilyGroupSubsection extends StatelessWidget {
  final String familyId;
  final List<FamilyPeer> peers;
  final bool isOwnFamily;
  final String? slotsLabel;
  final bool showPayerBadge;
  final void Function(String label) onLeave;
  const _FamilyGroupSubsection({
    required this.familyId,
    required this.peers,
    required this.isOwnFamily,
    this.slotsLabel,
    this.showPayerBadge = false,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final inviter = peers.where((p) => p.invitedMe).firstOrNull;
    final label = isOwnFamily
        ? context.l10n.myFamilyLabel
        : context.l10n.peerFamilyLabel(inviter?.name ?? peers.first.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: Row(
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
        ),
        ...peers.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: _PeerCard(peer: p),
            )),
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

final _familyPeersProvider = StreamProvider<List<FamilyPeer>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchAll();
});

/// true, якщо для цього локального профілю вже створено (і ще не
/// підтверджено) запрошення "Локальний → Автономний" — щойно приєднання
/// підтвердиться, FamilyGroupService.refreshPeers() видалить сам профіль,
/// тож рядок тут природно зникне разом з ним.
final _pendingConversionProvider = StreamProvider.family<bool, int>((ref, memberId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.pendingGroupInvites)..where((t) => t.convertingMemberId.equals(memberId)))
      .watch()
      .map((rows) => rows.isNotEmpty);
});

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
/// бачу, сюди й не потрапляють у SharedEntities взагалі). Дизайн-піру
/// завжди ділиться лише СВОЇМ ВЛАСНИМ профілем (не своїми dependent'ами —
/// UI видачі грантів це не дозволяє), тож personUuid піра й subjectPersonUuid
/// тут завжди збігаються.
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

Future<void> _sendPeerReminder(BuildContext context, WidgetRef ref, FamilyPeer peer, _MissedItem item) async {
  final l10n = context.l10n;
  final timeStr =
      '${item.scheduledAt.hour.toString().padLeft(2, '0')}:${item.scheduledAt.minute.toString().padLeft(2, '0')}';
  final title = _missedItemTitle(context, item);
  final body = switch (item.entityType) {
    'intake' => l10n.reminderTakeMedBody(
        title, item.detail != null ? ' — ${item.detail}' : '', timeStr),
    'activity_log' => l10n.reminderDoActivityBody(title, timeStr),
    'doctor_appointment' => l10n.reminderDoctorVisitBody(
        title, item.detail != null && item.detail!.isNotEmpty ? ' (${item.detail})' : ''),
    'wellbeing' => l10n.reminderWellbeingBody,
    _ => l10n.reminderGenericBody,
  };
  final messenger = ScaffoldMessenger.of(context);
  try {
    await FamilyPeerSyncService(ref.read(databaseProvider)).sendRemoteReminder(
      channelId: peer.channelId,
      title: l10n.reminderPushTitle,
      body: body,
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.reminderSentSnackbar(peer.name))));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.sendFailedError('$e'))));
  }
}

class _PeerCard extends ConsumerWidget {
  final FamilyPeer peer;
  const _PeerCard({required this.peer});

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removePeerConfirmTitle(peer.name)),
        content: Text(
          context.l10n.removePeerConfirmBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.removeAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FamilyPeerSyncService(ref.read(databaseProvider)).removePeer(peer.personUuid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missed = ref.watch(_peerMissedProvider(peer.personUuid)).valueOrNull ?? const [];
    final firstMissed = missed.isNotEmpty ? missed.first : null;

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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SharedFamilyDataScreen(peerChannelId: peer.channelId, peerName: peer.name),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AvatarImage(index: peer.avatarIndex, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(peer.name, style: AppTextStyles.labelLg),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.independentAccountLabel,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    onTap: () => _confirmRemove(context, ref),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (firstMissed != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
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
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _sendPeerReminder(context, ref, peer, firstMissed),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.l10n.remindAction,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GroupActionTile({required this.icon, required this.label, required this.onTap});

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
            Icon(icon, color: AppColors.primary, size: 24),
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
                          border: InputBorder.none,
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
