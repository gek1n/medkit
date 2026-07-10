import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import '../backup/backup_screen.dart';
import '../export/export_data_screen.dart';
import '../help/help_faq_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../notifications/notifications_screen.dart';
import '../plans/plans_screen.dart';
import '../sync/sync_settings_screen.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/members_repository.dart';
import '../../shared/widgets/mk_button.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../today/providers/today_providers.dart';
import '../wellbeing/wellbeing_history_screen.dart';
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
        body: Center(child: Text('Помилка: $e')),
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
                    child: Text('Профіль', style: AppTextStyles.h2),
                  ),
                  _HeroSection(member: member, plan: plan),
                  const SizedBox(height: AppDimensions.lg),
                  if (!plan.isPaid) _UpgradeBanner(),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader("Здоров'я та вправи",
                      icon: Icons.favorite_rounded, color: AppColors.primary),
                  _HealthSection(memberId: member.id),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Налаштування додатку',
                      icon: Icons.tune_rounded, color: AppColors.accent),
                  _AppSettingsSection(
                    isLocalProfile: member.role == 'dependent',
                    canEditFontSize: canEditFontSize,
                    fontSizeIndex: fontSizeIndex,
                    onFontSizeChanged: onFontSizeChanged,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Акаунт',
                      icon: Icons.person_rounded, color: AppColors.warning),
                  _AccountSection(memberId: member.id),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Інше',
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
                        const SizedBox(height: 2),
                        Text(
                          'sgek1n@gmail.com',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSub),
                        ),
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
      AppPlan.free => (Icons.star_outline_rounded, 'Безкоштовний план',
          AppColors.textSub),
      AppPlan.plus => (Icons.favorite_rounded, 'Elly Plus', AppColors.primary),
      AppPlan.family => (Icons.diversity_3_rounded, 'Elly Family', AppColors.accent),
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
                          Text('Сімʼя',
                              style: AppTextStyles.bodySm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Підключіть Сім\'я',
                        style: AppTextStyles.labelLg.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 190,
                      child: Text('Турбуйтесь про всю родину',
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
          icon: Icons.history_rounded,
          label: 'Історія самопочуття',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WellbeingHistoryScreen(memberId: memberId),
            ),
          ),
        ),
        _RowItem(
          icon: Icons.self_improvement_rounded,
          label: 'Антистрес-вправи',
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

class _AppSettingsSection extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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
                    child: Text('Розмір шрифту',
                        style: AppTextStyles.bodyMd),
                  ),
                  Row(
                    children: List.generate(4, (i) {
                      final sizes = [12.0, 14.0, 16.0, 18.0];
                      final labels = ['Аа', 'Аа', 'Аа', 'Аа'];
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
            label: 'Сповіщення',
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
          label: 'Мова',
          color: AppColors.accent,
          trailing: Text('Українська',
              style:
                  AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Вибір мови буде доступний після перекладів')),
          ),
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
          label: 'Тарифи',
          color: AppColors.warning,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(plan.displayName,
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
          label: 'Видимість для сім\'ї',
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
          icon: Icons.sync_rounded,
          label: 'Синхронізація',
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.backup_rounded,
          label: 'Резервна копія',
          color: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.privacy_tip_rounded,
          label: 'Конфіденційність',
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
          label: 'Оцінити застосунок',
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
          label: 'Допомога та FAQ',
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Політика конфіденційності',
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.ios_share_rounded,
          label: 'Експорт даних',
          color: AppColors.info,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExportDataScreen()),
          ),
        ),
      ],
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
        child: const Text('Вийти з акаунту'),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Вийти з акаунту?'),
        content: const Text(
            'Усі дані будуть видалені з цього пристрою. Цю дію неможливо скасувати.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Вийти'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
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
            Text('Редагувати профіль', style: AppTextStyles.h3),
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
                  hintText: "Ваше ім'я",
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
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: avatarCount,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  final selected = _avatarIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _avatarIndex = i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryLight
                            : AppColors.bgPage,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: AvatarImage(index: i, size: 52),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.lg),
              child: MkButton(label: 'Зберегти', onTap: _save),
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
