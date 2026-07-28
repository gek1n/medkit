import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/member_switcher_pill.dart';
import '../../shared/widgets/plan_upgrade_banner.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../appointments/appointments_history_screen.dart';
import '../plans/elly_denied_screen.dart';
import '../today/providers/today_providers.dart';
import '../wellbeing/wellbeing_history_screen.dart';
import 'add_medcard_section_screen.dart';
import 'medcard_section_screen.dart';
import 'medication_archive_screen.dart';

final _medcardSectionsProvider =
    StreamProvider.family<List<MedcardSection>, int>((ref, memberId) {
  return ref.watch(medcardSectionsRepositoryProvider).watchByMember(memberId);
});

class MedCardScreen extends ConsumerStatefulWidget {
  const MedCardScreen({super.key});

  @override
  ConsumerState<MedCardScreen> createState() => _MedCardScreenState();
}

class _MedCardScreenState extends ConsumerState<MedCardScreen> {
  int? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    // Якщо десь у застосунку активовано перегляд "від імені" іншого члена
    // сім'ї — Архів теж підхоплює цей вибір (доки користувач сам не
    // перемкне когось локально через пілюлю), той самий патерн, що й у
    // Розкладі.
    ref.listen<int?>(activeMemberIdProvider, (prev, next) {
      if (next != prev) setState(() => _selectedMemberId = next);
    });
    final activeId = ref.watch(activeMemberIdProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
          data: (defaultMember) {
            if (defaultMember == null) return const SizedBox.shrink();
            final members = membersAsync.valueOrNull ?? [defaultMember];
            final selected = members.firstWhere(
              (m) => m.id == (_selectedMemberId ?? defaultMember.id),
              orElse: () => defaultMember,
            );
            final showBanner = shouldShowSwitchBanner(activeId, selected.role);
            return _MedCardBody(
              memberId: selected.id,
              memberName: selected.name,
              showSwitchBanner: showBanner,
              members: members,
              selected: selected,
              onMemberChanged: (id) {
                setState(() => _selectedMemberId = id);
                // Пишемо і в глобальний activeMemberIdProvider — інакше вибір
                // діє лише на цьому екрані й злітає при переході на інші
                // вкладки (Сьогодні/Розклад). Вибір власного профілю в пікері
                // рівнозначний натисканню "Повернутись".
                ref.read(activeMemberIdProvider.notifier).state =
                    id == defaultMember.id ? null : id;
              },
            );
          },
        ),
      ),
    );
  }
}

class _MedCardBody extends ConsumerWidget {
  final int memberId;
  final String memberName;
  final bool showSwitchBanner;
  final List<Member> members;
  final Member selected;
  final void Function(int) onMemberChanged;
  const _MedCardBody({
    required this.memberId,
    required this.memberName,
    required this.showSwitchBanner,
    required this.members,
    required this.selected,
    required this.onMemberChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(_medcardSectionsProvider(memberId));
    final limits = ref.watch(planProvider).limits;
    final sectionsCount = sectionsAsync.valueOrNull?.length ?? 0;
    final sectionsLimitReached = limits.maxMedcardSections != 0 &&
        sectionsCount >= limits.maxMedcardSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSwitchBanner) SwitchProfileBanner(name: memberName),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            AppDimensions.lg,
            AppDimensions.screenPadding,
            AppDimensions.md,
          ),
          child: Row(
            children: [
              Expanded(child: Text(context.l10n.medCardTitle, style: AppTextStyles.h2)),
              if (members.length > 1)
                MemberSwitcherPill(
                  members: members,
                  selected: selected,
                  onSelect: onMemberChanged,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              0,
              AppDimensions.screenPadding,
              48,
            ),
            children: [
              _MedCardTile(
                icon: Icons.medication_liquid_rounded,
                iconWidget: const AssetIcon('task_meds', size: 22),
                iconColor: AppColors.primary,
                title: context.l10n.medCardArchiveTitle,
                subtitle: context.l10n.medCardArchiveSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicationArchiveScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.event_note_rounded,
                iconWidget: const AssetIcon('task_reminder', size: 22),
                iconColor: AppColors.primary,
                title: context.l10n.medCardAppointmentsTitle,
                subtitle: context.l10n.medCardAppointmentsSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentsHistoryScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.mood_rounded,
                iconWidget: const AssetIcon('task_wellbeing', size: 22),
                iconColor: AppColors.primary,
                title: context.l10n.medCardWellbeingHistoryTitle,
                subtitle: context.l10n.medCardWellbeingHistorySubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WellbeingHistoryScreen(memberId: memberId),
                  ),
                ),
              ),

              // ── Довільні розділи, створені користувачем ──
              sectionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (sections) {
                  if (sections.isEmpty) return const SizedBox.shrink();
                  // Автостворений розділ "Нотатки" (isDefaultNotes) завжди
                  // вгорі — незалежно від того, коли саме його лениво
                  // створили відносно інших розділів (watchByMember сортує
                  // за createdAt).
                  final pinned = [...sections]..sort((a, b) {
                      if (a.isDefaultNotes == b.isDefaultNotes) return 0;
                      return a.isDefaultNotes ? -1 : 1;
                    });
                  return Column(
                    children: [
                      const SizedBox(height: AppDimensions.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.customSectionsHeader,
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      ...pinned.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                            child: _MedCardTile(
                              icon: Icons.folder_rounded,
                              iconWidget: MedcardIcon(s.iconKey, size: 24),
                              iconColor: colorFromHex(s.color) ?? AppColors.primary,
                              title: s.name,
                              subtitle: s.comment,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MedcardSectionScreen(section: s),
                                ),
                              ),
                            ),
                          )),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppDimensions.lg),
              if (limits.maxMedcardSections != 0) ...[
                PlanUpgradeBanner(
                  badgeIcon: Icons.folder_rounded,
                  badge: context.l10n.medcardSectionsLimitBadge,
                  title: context.l10n.medcardSectionsLimitTitle,
                  subtitle: context.l10n.medcardSectionsLimitSubtitle(
                      sectionsCount, limits.maxMedcardSections),
                  illustrationAsset: 'assets/illustrations/elly-docs.png',
                ),
                const SizedBox(height: AppDimensions.md),
              ],
              GestureDetector(
                onTap: () {
                  if (sectionsLimitReached) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EllyDeniedScreen(
                          title: context.l10n.medcardSectionsLimitDeniedTitle,
                          subtitle:
                              context.l10n.medcardSectionsLimitDeniedSubtitle,
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMedcardSectionScreen(memberId: memberId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.addSectionAction,
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedCardTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? iconWidget;

  const _MedCardTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onTap,
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
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: iconWidget ?? Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLg),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!disabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
