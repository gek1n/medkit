import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import '../backup/backup_screen.dart';
import '../../core/config/app_env.dart';
import '../../core/services/backup_settings_service.dart';
import 'debug_log_screen.dart';
import '../export/export_data_screen.dart';
import '../help/help_faq_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../notifications/notifications_screen.dart';
import '../plans/plans_screen.dart';
import '../../core/providers/app_language_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/members_repository.dart';
import '../../shared/widgets/mk_button.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../today/providers/today_providers.dart';
import 'anti_stress/anti_stress_picker_screen.dart';
import 'family_visibility_screen.dart';
import 'privacy_screen.dart';

// ────────────────────────────── screen ──────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentMemberProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text(context.l10n.errorGeneric(e.toString()))),
      ),
      data: (member) {
        if (member == null) return const SizedBox.shrink();
        return _ProfileBody(
          member: member,
          onFontSizeChanged: (i) => ref.read(membersRepositoryProvider).update(
                MembersCompanion(id: Value(member.id), fontSize: Value(i + 1)),
              ),
        );
      },
    );
  }
}

// ────────────────────────────── body ──────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final Member member;
  final ValueChanged<int> onFontSizeChanged;

  const _ProfileBody({
    required this.member,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    final fontSizeIndex = member.fontSize - 1;
    final activeId = ref.watch(activeMemberIdProvider);
    final showSwitchBanner = activeId != null && member.role != 'owner';
    // Автономні профілі більше не бувають локальними Members-рядками (див.
    // "Локальний → Автономний" конверсію) — той, хто лишився тут, це
    // owner/dependent, яким власник керує напряму, тож розмір шрифту можна
    // міняти завжди.
    const canEditFontSize = true;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          if (showSwitchBanner)
            SliverToBoxAdapter(child: SwitchProfileBanner(name: member.name)),
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.lg,
                      AppDimensions.screenPadding,
                      AppDimensions.md,
                    ),
                    child: Text(context.l10n.navProfile, style: AppTextStyles.h2),
                  ),
                  _HeroSection(member: member, plan: plan),
                  const SizedBox(height: AppDimensions.lg),
                  const _BackupReminderBanner(),
                  if (!plan.isPaid) _UpgradeBanner(),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader(context.l10n.healthSectionHeader,
                      icon: Icons.favorite_rounded, color: AppColors.primary),
                  _HealthSection(memberId: member.id),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader(context.l10n.appSettingsSectionHeader,
                      icon: Icons.tune_rounded, color: AppColors.accent),
                  _AppSettingsSection(
                    isLocalProfile: member.role == 'dependent',
                    canEditFontSize: canEditFontSize,
                    fontSizeIndex: fontSizeIndex,
                    onFontSizeChanged: onFontSizeChanged,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader(context.l10n.accountSectionHeader,
                      icon: Icons.person_rounded, color: AppColors.warning),
                  _AccountSection(memberId: member.id),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader(context.l10n.otherSectionHeader,
                      icon: Icons.more_horiz_rounded, color: AppColors.info),
                  _OtherSection(),
                  const SizedBox(height: AppDimensions.xl),
                  _LogoutButton(member: member),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── hero ──────────────────────────────

class _HeroSection extends StatelessWidget {
  final Member member;
  final AppPlan plan;
  const _HeroSection({required this.member, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.md,
        AppDimensions.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showEditSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 16,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarImage(index: member.avatarIndex, size: 64),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        _PlanBadge(plan: plan),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Center(
                      child: Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(member: member),
    );
  }
}

// ────────────────────────────── plan badge ──────────────────────────────

class _PlanBadge extends StatelessWidget {
  final AppPlan plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (plan) {
      AppPlan.free => (Icons.star_outline_rounded, context.l10n.planFreeLabel,
          AppColors.textSub),
      AppPlan.plus => (Icons.favorite_rounded, context.l10n.planPlusLabel, AppColors.primary),
      AppPlan.family => (Icons.diversity_3_rounded, context.l10n.planFamilyLabel, AppColors.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySm
                .copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── backup reminder banner ──────────────────────

/// Постійний банер, поки резервна копія вимкнена (BackupMode.local) —
/// доповнює одноразовий push з BackupReminderService для тих, хто банер
/// просто пропустив. Зникає сам, щойно користувач вмикає Google Drive/iCloud.
class _BackupReminderBanner extends ConsumerWidget {
  const _BackupReminderBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(backupModeProvider).valueOrNull;
    if (mode != BackupMode.local) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        0,
        AppDimensions.screenPadding,
        AppDimensions.lg,
      ),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          );
          ref.invalidate(backupModeProvider);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 20, color: Color(0xFF78350F)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.backupDisabledTitle,
                        style: AppTextStyles.labelMd.copyWith(color: const Color(0xFF78350F))),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.backupDisabledBody,
                      style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF78350F)),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────── upgrade banner ──────────────────────────────

class _UpgradeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
      child: GestureDetector(
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
                          Text(context.l10n.familyLabel,
                              style: AppTextStyles.bodySm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(context.l10n.connectFamilyTitle,
                        style: AppTextStyles.labelLg.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 190,
                      child: Text(context.l10n.connectFamilySubtitle,
                          style: AppTextStyles.bodySm.copyWith(
                              color: Colors.white.withValues(alpha: 0.85))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// end _UpgradeBanner

// ────────────────────────────── section header ──────────────────────────────

class _ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _ProfileSectionHeader(this.title,
      {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        0,
        AppDimensions.screenPadding,
        AppDimensions.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(title.toUpperCase(), style: AppTextStyles.labelSm),
        ],
      ),
    );
  }
}

// ────────────────────────────── section card ──────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          children: children
              .map((w) => Column(
                    children: [
                      w,
                      if (children.last != w)
                        const Divider(
                            height: 1,
                            indent: AppDimensions.screenPadding,
                            color: AppColors.borderLight),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ────────────────────────────── row item ──────────────────────────────

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SectionIcon(this.icon, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Center(child: Icon(icon, size: 18, color: color)),
      );
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _RowItem({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            _SectionIcon(icon, color: color),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMd),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── health & reminders ──────────────────────────────

class _HealthSection extends StatelessWidget {
  final int memberId;
  const _HealthSection({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        _RowItem(
          icon: Icons.self_improvement_rounded,
          label: context.l10n.antiStressLabel,
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AntiStressPickerScreen()),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── appearance ──────────────────────────────

class _AppSettingsSection extends ConsumerWidget {
  final bool isLocalProfile;
  final bool canEditFontSize;
  final int fontSizeIndex;
  final ValueChanged<int> onFontSizeChanged;

  const _AppSettingsSection({
    required this.isLocalProfile,
    this.canEditFontSize = true,
    required this.fontSizeIndex,
    required this.onFontSizeChanged,
  });

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(appLanguageProvider);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.languageLabel, style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              context.l10n.voiceLanguageDescription,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: AppDimensions.md),
            ...appLanguages.map((l) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.label, style: AppTextStyles.bodyMd),
                  trailing: l.id == current
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, l.id),
                )),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await ref.read(appLanguageProvider.notifier).set(chosen);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      children: [
        // Локальні профілі не мають власного пристрою/акаунту — розмір
        // шрифту й сповіщення налаштовуються лише для owner/автономних.
        if (!isLocalProfile) ...[
          Opacity(
            opacity: canEditFontSize ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const _SectionIcon(Icons.text_fields_rounded,
                      color: AppColors.accent),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(context.l10n.fontSizeLabel,
                        style: AppTextStyles.bodyMd),
                  ),
                  Row(
                    children: List.generate(4, (i) {
                      final sizes = [12.0, 14.0, 16.0, 18.0];
                      final labels = List.filled(4, context.l10n.fontSizeSampleLabel);
                      final selected = fontSizeIndex == i;
                      return GestureDetector(
                        onTap: canEditFontSize
                            ? () => onFontSizeChanged(i)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryLight
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            labels[i],
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: sizes[i],
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMain,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          _RowItem(
            icon: Icons.notifications_rounded,
            label: context.l10n.notificationsLabel,
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
        _RowItem(
          icon: Icons.language_rounded,
          label: context.l10n.languageLabel,
          color: AppColors.accent,
          trailing: Text(appLanguageLabel(ref.watch(appLanguageProvider)),
              style:
                  AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
          onTap: () => _pickLanguage(context, ref),
        ),
      ],
    );
  }
}

// ────────────────────────────── account ──────────────────────────────

class _AccountSection extends ConsumerWidget {
  final int memberId;
  const _AccountSection({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider);
    return _SectionCard(
      children: [
        _RowItem(
          icon: Icons.workspace_premium_rounded,
          label: context.l10n.plansLabel,
          color: AppColors.warning,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(plan.displayName(context),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlansScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.visibility_rounded,
          label: context.l10n.familyVisibilityLabel,
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FamilyVisibilityScreen(subjectMemberId: memberId),
            ),
          ),
        ),
        _RowItem(
          icon: Icons.backup_rounded,
          label: context.l10n.backupLabel,
          color: AppColors.warning,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            );
            ref.invalidate(backupModeProvider);
          },
        ),
        _RowItem(
          icon: Icons.privacy_tip_rounded,
          label: context.l10n.privacyLabel,
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── other ──────────────────────────────

class _OtherSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        _RowItem(
          icon: Icons.star_rounded,
          label: context.l10n.rateAppLabel,
          color: AppColors.info,
          onTap: () async {
            final inAppReview = InAppReview.instance;
            if (await inAppReview.isAvailable()) {
              inAppReview.requestReview();
            } else {
              inAppReview.openStoreListing();
            }
          },
        ),
        _RowItem(
          icon: Icons.help_outline_rounded,
          label: context.l10n.helpFaqLabel,
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.privacy_tip_outlined,
          label: context.l10n.privacyPolicyLabel,
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.ios_share_rounded,
          label: context.l10n.exportDataLabel,
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExportDataScreen()),
          ),
        ),
        const _HiddenDebugLogTrigger(),
      ],
    );
  }
}

// 7 тапів по цьому рядку відкривають журнал подій — навмисно не винесено
// в окремий видимий пункт меню, щоб не плутати звичайних користувачів.
// У продакшн-збірці (AppEnv.isTestBuild == false) тап взагалі нічого не
// робить — AppLogger і так нічого не пише в проді (див. app_logger.dart),
// тож сам вхід у порожній екран лише плутав би, і краще прибрати повністю.
class _HiddenDebugLogTrigger extends StatefulWidget {
  const _HiddenDebugLogTrigger();

  @override
  State<_HiddenDebugLogTrigger> createState() =>
      _HiddenDebugLogTriggerState();
}

class _HiddenDebugLogTriggerState extends State<_HiddenDebugLogTrigger> {
  int _taps = 0;
  DateTime? _firstTapAt;

  void _onTap() {
    if (!AppEnv.isTestBuild) return;
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!) > const Duration(seconds: 3)) {
      _firstTapAt = now;
      _taps = 1;
      return;
    }
    _taps++;
    if (_taps >= 7) {
      _taps = 0;
      _firstTapAt = null;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DebugLogScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 12,
        ),
        child: Text('Elly', style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
      ),
    );
  }
}

// ────────────────────────────── logout ──────────────────────────────

class _LogoutButton extends ConsumerWidget {
  final Member member;
  const _LogoutButton({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: OutlinedButton(
        onPressed: () => _confirm(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        child: Text(context.l10n.logoutLabel),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logoutConfirmTitle),
        content: Text(context.l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.logoutConfirmAction),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      AppLogger.log('logout_confirmed');
      // Каскадне видалення members у БД не проходить через репозиторії
      // окремих фіч, тож заплановані OS-нагадування (intake/activity/
      // appointment/wellbeing/vaccination) самі по собі не скасовуються —
      // робимо це явно, інакше вони спрацьовують і після виходу з акаунту.
      await NotificationService.cancelAll();
      await ref
          .read(membersRepositoryProvider)
          .deleteAll();
    });
  }
}

// ────────────────────────────── edit profile sheet ──────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final Member member;
  const _EditProfileSheet({required this.member});

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late int _avatarIndex;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _avatarIndex = widget.member.avatarIndex;
    _nameCtrl = TextEditingController(text: widget.member.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.lg),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(context.l10n.editProfileTitle, style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.lg),
            Center(child: AvatarImage(index: _avatarIndex, size: 96)),
            const SizedBox(height: AppDimensions.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: context.l10n.yourNameHint,
                  hintStyle: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                ),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMain),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EditAvatarGrid(
                      start: 0,
                      end: avatarCount,
                      selectedIndex: _avatarIndex,
                      onChanged: (i) => setState(() => _avatarIndex = i),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    _EditAvatarSectionDivider(
                      label: context.l10n.petAvatarsSectionLabel,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    _EditAvatarGrid(
                      start: avatarCount,
                      end: totalAvatarCount,
                      selectedIndex: _avatarIndex,
                      onChanged: (i) => setState(() => _avatarIndex = i),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.lg),
              child: MkButton(label: context.l10n.saveAction, onTap: _save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(membersRepositoryProvider).update(
          MembersCompanion(
            id: Value(widget.member.id),
            name: Value(name),
            avatarIndex: Value(_avatarIndex),
          ),
        );
    if (mounted) Navigator.pop(context);
  }
}

// Розділ пікера аватарів на діапазон [start, end) — той самий вигляд плиток,
// що й раніше в _EditProfileSheet, лише параметризований, щоб малювати і
// людські аватари, і секцію "Домашні улюбленці" одним і тим самим кодом.
class _EditAvatarGrid extends StatelessWidget {
  final int start;
  final int end;
  final int selectedIndex;
  final void Function(int) onChanged;
  const _EditAvatarGrid({
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
        final selected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onChanged(index),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLight : AppColors.bgPage,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AvatarImage(index: index, size: 52),
            ),
          ),
        );
      },
    );
  }
}

class _EditAvatarSectionDivider extends StatelessWidget {
  final String label;
  const _EditAvatarSectionDivider({required this.label});

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
