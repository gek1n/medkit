import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../today/providers/today_providers.dart';
import 'allergies_screen.dart';
import 'chronic_conditions_screen.dart';
import 'lab_results_screen.dart';
import 'specialty_history_screen.dart';
import 'surgeries_screen.dart';
import 'vaccinations_screen.dart';

/// (subjectPersonUuid, viewerPersonUuid) — чи дозволив subject власнику
/// пристрою бачити свою медкартку. Той самий патерн, що й
/// `_viewAllowedProvider` на `family_screen.dart`, тут — власна копія, бо
/// провайдер там приватний.
final _medCardViewAllowedProvider = FutureProvider.family<bool, (String, String)>((
  ref,
  ids,
) {
  return FamilyVisibilityService.isAllowed(
    ref.watch(databaseProvider),
    ids.$1,
    ids.$2,
    FamilyPermission.view,
  );
});

class MedCardScreen extends ConsumerWidget {
  const MedCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final membersAsync = ref.watch(allMembersProvider);
    final activeId = ref.watch(activeMemberIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Помилка: $e')),
          data: (member) {
            if (member == null) return const SizedBox.shrink();
            final members = membersAsync.valueOrNull ?? [];
            Member? owner;
            for (final m in members) {
              if (m.role == 'owner') {
                owner = m;
                break;
              }
            }
            final showBanner = shouldShowSwitchBanner(activeId, member.role);
            if (owner == null || owner.id == member.id) {
              return _MedCardBody(
                memberId: member.id,
                memberName: member.name,
                showSwitchBanner: showBanner,
              );
            }
            if (member.personUuid == null || owner.personUuid == null) {
              return const _AccessRestricted();
            }
            final allowedAsync = ref.watch(
              _medCardViewAllowedProvider((member.personUuid!, owner.personUuid!)),
            );
            return allowedAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Помилка: $e')),
              data: (allowed) => allowed
                  ? _MedCardBody(
                      memberId: member.id,
                      memberName: member.name,
                      showSwitchBanner: showBanner,
                    )
                  : const _AccessRestricted(),
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
  const _MedCardBody({
    required this.memberId,
    required this.memberName,
    required this.showSwitchBanner,
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
          child: Text('Медкартка', style: AppTextStyles.h2),
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
                icon: Icons.history_rounded,
                iconColor: AppColors.primary,
                title: 'Історія за напрямком',
                subtitle: 'Візити й аналізи одного лікаря — все в одному місці',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpecialtyHistoryScreen(memberId: memberId),
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

class _AccessRestricted extends StatelessWidget {
  const _AccessRestricted();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Медкартка прихована',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Цей профіль обмежив перегляд своєї медкартки в налаштуваннях приватності',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
