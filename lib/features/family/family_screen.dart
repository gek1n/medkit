import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/plan_provider.dart';
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
import '../pairing/pairing_invite_screen.dart';
import '../pairing/pairing_join_screen.dart';
import '../plans/plans_screen.dart';
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
    final familyAvailable = plan.limits.maxMembers > 1;
    final limitReached = members.length >= plan.limits.maxMembers;

    return CustomScrollView(
      slivers: [
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
              ...members.map((m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.md),
                    child: _MemberCard(member: m),
                  )),
              if (limitReached)
                const _FamilyUpgradeBanner()
              else
                const _AddMemberTile(),
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
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryLighter, width: 1.5),
                    ),
                    child: const Icon(Icons.add_rounded,
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
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));
    final medsAsync = ref.watch(_memberMedsProvider(member.id));
    final channelAsync = ref.watch(_memberChannelProvider(member.id));
    final activeId = ref.watch(activeMemberIdProvider);
    final isActive = activeId == member.id ||
        (activeId == null && member.role == 'owner');

    final intakes = intakesAsync.valueOrNull ?? [];
    final meds = medsAsync.valueOrNull ?? [];

    final taken = intakes.where((i) => i.status == 'taken').length;
    final total = intakes.length;
    final missed =
        intakes.where((i) => i.status == 'skipped').length;

    _MemberStatus status;
    if (total == 0) {
      status = _MemberStatus.idle;
    } else if (missed > 0) {
      status = _MemberStatus.warn;
    } else if (taken == total) {
      status = _MemberStatus.ok;
    } else {
      status = _MemberStatus.idle;
    }

    final ringColor = switch (status) {
      _MemberStatus.ok => const Color(0xFF22C55E),
      _MemberStatus.warn => const Color(0xFFEF4444),
      _MemberStatus.idle => AppColors.border,
    };

    final statusIcon = switch (status) {
      _MemberStatus.ok => Icons.check_circle_rounded,
      _MemberStatus.warn => Icons.error_rounded,
      _MemberStatus.idle => null,
    };

    final statusText = switch (status) {
      _MemberStatus.ok => 'Всі прийнято',
      _MemberStatus.warn => 'Є пропуски',
      _MemberStatus.idle =>
        total > 0 ? '$taken/$total прийнято' : 'Немає ліків на сьогодні',
    };

    final statusColor = switch (status) {
      _MemberStatus.ok => const Color(0xFF22C55E),
      _MemberStatus.warn => const Color(0xFFEF4444),
      _MemberStatus.idle => AppColors.textMuted,
    };

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Member header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Avatar with status ring
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: AvatarImage(index: member.avatarIndex, size: 47),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(member.name, style: AppTextStyles.labelLg),
                          if (member.role == 'owner') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('я',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (statusIcon != null) ...[
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 3),
                          ],
                          Text(statusText,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: statusColor)),
                        ],
                      ),
                      if (total > 0)
                        Text(
                          '$taken з $total прийомів',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Switch profile button
                    if (isActive)
                      _RemindBtn(
                        label: '● Активний',
                        color: AppColors.primary,
                        bg: AppColors.primaryLight,
                        onTap: null,
                      )
                    else
                      _RemindBtn(
                        label: 'Переключитись',
                        color: AppColors.primary,
                        bg: AppColors.primaryLight,
                        onTap: () => ref
                            .read(activeMemberIdProvider.notifier)
                            .state = member.id,
                      ),
                    if (member.role != 'owner') ...[
                      const SizedBox(height: 6),
                      channelAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (channel) => _RemindBtn(
                          label: channel != null ? '🔗 Підключено' : 'Підключити телефон',
                          color: channel != null
                              ? const Color(0xFF22C55E)
                              : AppColors.primary,
                          bg: channel != null
                              ? const Color(0xFFF0FDF4)
                              : AppColors.primaryLight,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PairingInviteScreen(
                                ownerName: member.name,
                                memberId: member.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Remind / OK button
                    if (status == _MemberStatus.warn)
                      _RemindBtn(
                        label: 'Нагадати',
                        color: const Color(0xFFEF4444),
                        bg: const Color(0xFFFEF2F2),
                        onTap: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Нагадування для ${member.name} відправлено')),
                        ),
                      )
                    else if (status == _MemberStatus.ok)
                      _RemindBtn(
                        label: '✓ Добре',
                        color: const Color(0xFF22C55E),
                        bg: const Color(0xFFF0FDF4),
                        onTap: null,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Medication chips ──
          if (meds.isNotEmpty) ...[
            const Divider(color: AppColors.borderLight, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: meds.map((med) {
                  // Find today's intakes for this med
                  final medIntakes = intakes
                      .where((i) => i.medicationId == med.id)
                      .toList();
                  final medTaken =
                      medIntakes.where((i) => i.status == 'taken').length;
                  final medTotal = medIntakes.length;
                  final medMissed =
                      medIntakes.where((i) => i.status == 'skipped').length;

                  Color dotColor = AppColors.textMuted;
                  if (medTotal > 0 && medTaken == medTotal) {
                    dotColor = AppColors.success;
                  } else if (medMissed > 0) {
                    dotColor = AppColors.danger;
                  } else if (medTaken > 0) {
                    dotColor = AppColors.warning;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          med.name,
                          style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain),
                        ),
                        if (medTotal > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$medTaken/$medTotal',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _MemberStatus { ok, warn, idle }

class _RemindBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  const _RemindBtn({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
  const _FamilyUpgradeBanner();

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
                        Text('Сімʼя',
                            style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Ліміт профілів досягнуто',
                      style: AppTextStyles.labelLg.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 190,
                    child: Text('Перейдіть на план «Сімʼя» — до 10 профілів',
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
        SectionLabel('Спільний доступ'),
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
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primary, size: 20),
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
  final VoidCallback onTap;

  const _ProfileTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
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
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelLg.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMain)),
                  const SizedBox(height: 3),
                  Text(description,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                  ? const Icon(Icons.circle_rounded, size: 8, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelBox({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textMain)),
          ],
        ),
      ),
    );
  }
}

class _TelegramHint extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  const _TelegramHint({required this.expanded, required this.onToggle});

  static const _steps = [
    'Відкрийте Telegram і знайдіть @EllyBot',
    'Натисніть «Start» у чаті з ботом',
    'Введіть код, який зʼявиться на екрані профілю',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Як підключити бота (${_steps.length} кроки)',
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_steps.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: AppTextStyles.bodyMd.copyWith(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_steps[i],
                              style: AppTextStyles.bodySm
                                  .copyWith(color: const Color(0xFF166534))),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _FontSizeRow({required this.index, required this.onChanged});

  static const _sizes = [12.0, 14.0, 16.0, 18.0];
  static const _labels = ['Дрібний', 'Звичайний', 'Великий', 'Дуже великий'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final selected = index == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text('Аа',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: _sizes[i],
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMain,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      )),
                  const SizedBox(height: 4),
                  Text(_labels[i],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted)),
                ],
              ),
            ),
          ),
        );
      }),
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
  final _contactCtrl = TextEditingController();
  int _avatarIndex = 0;
  String _profileType = 'dependent'; // dependent (Під опікою) | member (Автономний)
  String _channel = 'push'; // push | telegram | sms
  int _fontSizeIndex = 1; // 0..3 -> DB fontSize 1..4
  bool _hintExpanded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final needsContact = _channel != 'push';
    final contact = _contactCtrl.text.trim();
    await ref.read(membersRepositoryProvider).insert(
          MembersCompanion.insert(
            name: name,
            avatarIndex: Value(_avatarIndex),
            role: Value(_profileType),
            notificationChannels: Value(jsonEncode([_channel])),
            contact: needsContact && contact.isNotEmpty
                ? Value(contact)
                : const Value.absent(),
            fontSize: Value(_fontSizeIndex + 1),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final needsContact = _channel != 'push';
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(avatarCount, (i) {
                          final sel = i == _avatarIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _avatarIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              margin: const EdgeInsets.only(right: 10),
                              width: 52,
                              height: 52,
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
                        }),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    const _SectionLabel('ТИП ПРОФІЛЮ'),
                    const SizedBox(height: 8),
                    _ProfileTypeCard(
                      icon: Icons.favorite_border_rounded,
                      title: 'Під опікою',
                      description:
                          'Ти керуєш ліками та розкладом. Людина отримує лише нагадування.',
                      selected: _profileType == 'dependent',
                      onTap: () => setState(() => _profileType = 'dependent'),
                    ),
                    const SizedBox(height: 10),
                    _ProfileTypeCard(
                      icon: Icons.link_rounded,
                      title: 'Автономний',
                      description:
                          'Надсилаєш інвайт. Людина сама керує своїм профілем, ти бачиш статуси.',
                      selected: _profileType == 'member',
                      onTap: () => setState(() => _profileType = 'member'),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    const _SectionLabel('КАНАЛ СПОВІЩЕНЬ'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ChannelBox(
                            icon: Icons.notifications_outlined,
                            label: 'Push',
                            selected: _channel == 'push',
                            onTap: () => setState(() => _channel = 'push'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChannelBox(
                            icon: Icons.send_outlined,
                            label: 'Telegram',
                            selected: _channel == 'telegram',
                            onTap: () => setState(() => _channel = 'telegram'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChannelBox(
                            icon: Icons.sms_outlined,
                            label: 'SMS',
                            selected: _channel == 'sms',
                            onTap: () => setState(() => _channel = 'sms'),
                          ),
                        ),
                      ],
                    ),

                    if (needsContact) ...[
                      const SizedBox(height: AppDimensions.lg),
                      _SectionLabel(_channel == 'telegram'
                          ? 'TELEGRAM USERNAME АБО ТЕЛЕФОН'
                          : 'НОМЕР ТЕЛЕФОНУ'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _contactCtrl,
                          keyboardType: _channel == 'sms'
                              ? TextInputType.phone
                              : TextInputType.text,
                          decoration: InputDecoration(
                            hintText: _channel == 'telegram'
                                ? '@username або +380 99 123 45 67'
                                : '+380 99 123 45 67',
                            hintStyle: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                          ),
                          style: AppTextStyles.bodyMd,
                        ),
                      ),
                      if (_channel == 'telegram') ...[
                        const SizedBox(height: 10),
                        _TelegramHint(
                          expanded: _hintExpanded,
                          onToggle: () =>
                              setState(() => _hintExpanded = !_hintExpanded),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppDimensions.lg),

                    const _SectionLabel('РОЗМІР ШРИФТУ'),
                    const SizedBox(height: 8),
                    _FontSizeRow(
                      index: _fontSizeIndex,
                      onChanged: (i) => setState(() => _fontSizeIndex = i),
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
