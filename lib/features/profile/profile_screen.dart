import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backup/backup_screen.dart';
import '../notifications/notifications_screen.dart';
import '../plans/plans_screen.dart';
import '../sync/sync_settings_screen.dart';
import '../../core/providers/font_scale_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/med_form_icons.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../medications/medication_detail_screen.dart';
import '../today/providers/today_providers.dart';

// ────────────────────────────── providers ──────────────────────────────

final _profileMedsProvider =
    StreamProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).watchByMember(memberId);
});

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
    final fontSizeIndex = ref.watch(fontSizeIndexProvider);

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
          fontSizeIndex: fontSizeIndex,
          onFontSizeChanged: (i) =>
              ref.read(fontSizeIndexProvider.notifier).setIndex(i),
        );
      },
    );
  }
}

// ────────────────────────────── body ──────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final Member member;
  final int fontSizeIndex;
  final ValueChanged<int> onFontSizeChanged;

  const _ProfileBody({
    required this.member,
    required this.fontSizeIndex,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(_profileMedsProvider(member.id));
    final plan = ref.watch(planProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroSection(member: member, plan: plan),
                  const SizedBox(height: AppDimensions.lg),
                  if (!plan.isPaid) _UpgradeBanner(),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Мої ліки'),
                  medsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppDimensions.lg),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (meds) => meds.isEmpty
                        ? _EmptyMeds()
                        : _MedsList(meds: meds, memberId: member.id),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Вигляд'),
                  _AppearanceSection(
                    fontSizeIndex: fontSizeIndex,
                    onFontSizeChanged: onFontSizeChanged,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Підключення'),
                  _ConnectionsSection(),
                  const SizedBox(height: AppDimensions.xl),
                  _ProfileSectionHeader('Інше'),
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
        AppDimensions.xl,
        AppDimensions.screenPadding,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primaryLighter, width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: AvatarImage(index: member.avatarIndex, size: 82),
                ),
              ),
              GestureDetector(
                onTap: () => _showEditSheet(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.surface, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.edit_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          GestureDetector(
            onTap: () => _showEditSheet(context),
            child: Text(
              member.name,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'sgek1n@gmail.com',
            style:
                AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppDimensions.md),
          _PlanBadge(plan: plan),
          ],
        ),
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
    final (bg, border, textColor) = switch (plan) {
      AppPlan.free => (AppColors.warningLight, AppColors.warning, AppColors.warning),
      AppPlan.care => (AppColors.primaryLight, AppColors.primaryLighter, AppColors.primary),
      AppPlan.family => (const Color(0xFFFFFBEB), const Color(0xFFFDE68A), const Color(0xFF92400E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: border),
      ),
      child: Text(
        plan.badge,
        style: AppTextStyles.bodySm.copyWith(color: textColor),
      ),
    );
  }
}

// ────────────────────────────── upgrade banner ──────────────────────────────

class _UpgradeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlansScreen()),
      ),
      child: Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4C9A6A), Color(0xFF6FBE8C)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          children: [
            const Icon(Icons.family_restroom_rounded,
                color: Colors.white, size: 32),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Підключіть Family',
                    style: AppTextStyles.h3
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Відстежуйте ліки всієї родини',
                    style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '\$4/міс',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary),
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
  const _ProfileSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        0,
        AppDimensions.screenPadding,
        AppDimensions.sm,
      ),
      child: Text(
        title,
        style:
            AppTextStyles.labelMd.copyWith(color: AppColors.textSub),
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

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _RowItem({
    required this.icon,
    required this.label,
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
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
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

// ────────────────────────────── my meds ──────────────────────────────

class _EmptyMeds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'Ліків ще немає',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub),
          ),
        ),
      ),
    );
  }
}

class _MedsList extends ConsumerWidget {
  final List<Medication> meds;
  final int memberId;
  const _MedsList({required this.meds, required this.memberId});

  String _daysLeft(Medication m) {
    if (m.endDate == null) return 'постійно';
    final diff = m.endDate!.difference(DateTime.now()).inDays;
    if (diff < 0) return 'завершено';
    return 'залишилось $diff д';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      children: meds
          .map(
            (m) => _RowItem(
              icon: medFormIcon(m.form),
              label: m.name,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _daysLeft(m),
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSub),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicationDetailScreen(
                    medicationId: m.id,
                    memberId: memberId,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ────────────────────────────── appearance ──────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final int fontSizeIndex;
  final ValueChanged<int> onFontSizeChanged;

  const _AppearanceSection({
    required this.fontSizeIndex,
    required this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(Icons.text_fields_rounded, size: 20, color: AppColors.primary),
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
                    onTap: () => onFontSizeChanged(i),
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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding,
            vertical: 10,
          ),
          child: Row(
            children: [
              const Icon(Icons.dark_mode_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text('Темна тема',
                    style: AppTextStyles.bodyMd),
              ),
              Switch(
                value: false,
                onChanged: (_) {},
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── connections ──────────────────────────────

class _ConnectionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: [
        _RowItem(
          icon: Icons.send_rounded,
          label: 'Telegram-бот',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '✓ Активний',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Скоро...')),
          ),
        ),
        _RowItem(
          icon: Icons.notifications_rounded,
          label: 'Сповіщення',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NotificationsScreen()),
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
          icon: Icons.sync_rounded,
          label: 'Синхронізація та акаунт',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.backup_rounded,
          label: 'Резервна копія',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          ),
        ),
        _RowItem(
          icon: Icons.ios_share_rounded,
          label: 'Експорт даних',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Скоро...')),
          ),
        ),
        _RowItem(
          icon: Icons.help_outline_rounded,
          label: 'Допомога та FAQ',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Скоро...')),
          ),
        ),
        _RowItem(
          icon: Icons.star_rounded,
          label: 'Оцінити застосунок',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Скоро...')),
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
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        top: AppDimensions.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            AppDimensions.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl)),
      ),
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
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('Редагувати профіль', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.xl),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: avatarCount,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppDimensions.md),
              itemBuilder: (_, i) {
                final selected = _avatarIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _avatarIndex = i),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(selected ? 2 : 1),
                      child: AvatarImage(index: i, size: 52),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: "Ім'я",
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: const Text('Зберегти'),
            ),
          ),
        ],
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
