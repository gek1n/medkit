import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/models/family_member.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/pro_gate.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final List<FamilyMember> _members = const [
    FamilyMember(
      id: '1',
      name: 'Я',
      avatar: '🧑',
      role: FamilyMemberRole.owner,
      takenToday: 1,
      totalToday: 3,
    ),
    FamilyMember(
      id: '2',
      name: 'Мама',
      avatar: '👩',
      role: FamilyMemberRole.member,
      takenToday: 3,
      totalToday: 3,
    ),
    FamilyMember(
      id: '3',
      name: 'Тато',
      avatar: '👴',
      role: FamilyMemberRole.dependent,
      takenToday: 1,
      totalToday: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canManage = AppConfig.canAddFamilyMembers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.familyTitle, style: AppTextStyles.h3),
      ),
      body: ProGate(
        locked: !canManage,
        title: l10n.familyProRequired,
        body: l10n.familyProBody,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          children: [
            ..._members.map((m) => _FamilyMemberCard(member: m, l10n: l10n)),
            const SizedBox(height: AppDimensions.lg),
            _AddMemberButton(l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final AppLocalizations l10n;

  const _FamilyMemberCard(
      {required this.member, required this.l10n});

  String _roleLabel(FamilyMemberRole r) => switch (r) {
        FamilyMemberRole.owner => l10n.familyMemberOwner,
        FamilyMemberRole.member => l10n.familyMemberMember,
        FamilyMemberRole.dependent => l10n.familyMemberDependent,
      };

  @override
  Widget build(BuildContext context) {
    final pct = member.adherence;
    final barColor = pct >= 1
        ? AppColors.success
        : pct > 0
            ? AppColors.warning
            : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: MkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppDimensions.avatarMd,
                  height: AppDimensions.avatarMd,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(member.avatar,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: AppTextStyles.labelMd),
                      const SizedBox(height: 2),
                      Text(_roleLabel(member.role),
                          style: AppTextStyles.bodyMd),
                    ],
                  ),
                ),
                Text(
                  l10n.familyMedsToday(
                      member.takenToday, member.totalToday),
                  style: AppTextStyles.labelSm
                      .copyWith(color: barColor),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.borderLight,
                      valueColor:
                          AlwaysStoppedAnimation(barColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Text(
                  '${(pct * 100).round()}%',
                  style: AppTextStyles.labelSm
                      .copyWith(color: barColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  final AppLocalizations l10n;
  const _AddMemberButton({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            Text(l10n.familyAddMember,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
