import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/member_switcher_pill.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../appointments/appointments_history_screen.dart';
import '../today/providers/today_providers.dart';
import '../wellbeing/wellbeing_history_screen.dart';
import 'allergies_screen.dart';
import 'chronic_conditions_screen.dart';
import 'lab_results_screen.dart';
import 'medication_archive_screen.dart';
import 'specialty_history_screen.dart';
import 'surgeries_screen.dart';
import 'vaccinations_screen.dart';

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
    // сім'ї — Медкартка теж підхоплює цей вибір (доки користувач сам не
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
          error: (e, _) => Center(child: Text('Помилка: $e')),
          data: (defaultMember) {
            if (defaultMember == null) return const SizedBox.shrink();
            final members = membersAsync.valueOrNull ?? [defaultMember];
            final selected = members.firstWhere(
              (m) => m.id == (_selectedMemberId ?? defaultMember.id),
              orElse: () => defaultMember,
            );
            // ⚠️ FamilyVisibilityService/FamilyGrants навмисно НЕ застосовується
            // тут — currentMemberProvider/allMembersProvider завжди читають
            // лише ЛОКАЛЬНУ таблицю Members (owner + dependent-профілі, якими
            // керує власник цього пристрою напряму); незалежні автономні
            // учасники в цій таблиці ніколи не з'являються (живуть виключно
            // як FamilyPeers, див. members_table.dart). Той гейт вимагав явний
            // грант видимості, якого для dependent-профілю просто нізвідки
            // взятися — тож медкартка будь-якого локального dependent
            // назавжди показувала б "Медкартка прихована".
            final showBanner = shouldShowSwitchBanner(activeId, selected.role);
            return _MedCardBody(
              memberId: selected.id,
              memberName: selected.name,
              showSwitchBanner: showBanner,
              members: members,
              selected: selected,
              onMemberChanged: (id) => setState(() => _selectedMemberId = id),
            );
          },
        ),
      ),
    );
  }
}

class _MedCardBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              Expanded(child: Text('Медкартка', style: AppTextStyles.h2)),
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
              // Головний розділ — виділений окремо стилем картки й
              // відступом, щоб не губився серед решти однакових плиток.
              _MedCardHighlightTile(
                icon: Icons.timeline_rounded,
                title: 'Історія лікування за напрямками',
                subtitle: 'Візити й аналізи одного лікаря — все в одному місці',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialtyHistoryScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              _MedCardTile(
                icon: Icons.biotech_rounded,
                iconColor: AppColors.info,
                title: 'Аналізи',
                subtitle: 'Результати за напрямками',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LabResultsScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.medication_liquid_rounded,
                iconColor: AppColors.primary,
                title: 'Архів ліків',
                subtitle: 'Усі препарати й статус лікування',
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
                iconColor: AppColors.primary,
                title: 'Візити до лікарів',
                subtitle: 'Записи обраного профілю',
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
                iconColor: AppColors.primary,
                title: 'Історія самопочуття',
                subtitle: 'Настрій та симптоми за весь час',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WellbeingHistoryScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.danger,
                title: 'Алергії',
                subtitle: 'Реакції на препарати й речовини',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllergiesScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.danger,
                title: 'Хронічні захворювання',
                subtitle: 'Діагнози, дата встановлення',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChronicConditionsScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.vaccines_rounded,
                iconColor: AppColors.warning,
                title: 'Щеплення',
                subtitle: 'Історія й наступні ревакцинації',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VaccinationsScreen(memberId: memberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.local_hospital_rounded,
                iconColor: AppColors.warning,
                title: 'Операції та госпіталізації',
                subtitle: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurgeriesScreen(memberId: memberId),
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

/// Той самий розділ, що й [_MedCardTile], але виділений кольором/рамкою —
/// для головного, найважливішого пункту медкартки (Історія лікування).
class _MedCardHighlightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MedCardHighlightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelLg.copyWith(color: AppColors.primaryDark)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _MedCardTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MedCardTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(icon, size: 20, color: iconColor),
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
