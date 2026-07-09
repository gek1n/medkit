import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../today/providers/today_providers.dart';

/// Налаштування, кому з членів сім'ї видно завдання/медкартку/розклад
/// цього профілю, хто може його редагувати і кому надсилати сповіщення.
/// ⚠️ Тут лише зберігається вибір користувача — фактичне застосування
/// цих обмежень в інших екранах (фільтрація сповіщень, блокування
/// редагування/перегляду) ще не підключене, це окрема задача.
class FamilyVisibilityScreen extends ConsumerWidget {
  final int subjectMemberId;
  const FamilyVisibilityScreen({super.key, required this.subjectMemberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.md,
                AppDimensions.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Text('Видимість для сім\'ї', style: AppTextStyles.h2),
                ],
              ),
            ),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('$e')),
                data: (members) {
                  final viewers =
                      members.where((m) => m.id != subjectMemberId).toList();
                  if (viewers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                            AppDimensions.screenPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/illustrations/elly22.png',
                                height: 160),
                            const SizedBox(height: AppDimensions.lg),
                            Text(
                              'Якщо у вашій родині зʼявляться інші учасники, '
                              'тут можна буде керувати рівнями доступу до '
                              'вашого облікового запису',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.lg,
                      AppDimensions.screenPadding,
                      AppDimensions.xl,
                    ),
                    children: [
                      Text(
                        'Що бачать і можуть робити інші члени сім\'ї з вашим профілем',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      for (final viewer in viewers) ...[
                        _ViewerCard(
                          subjectId: subjectMemberId,
                          viewer: viewer,
                        ),
                        const SizedBox(height: AppDimensions.md),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerCard extends StatefulWidget {
  final int subjectId;
  final Member viewer;
  const _ViewerCard({required this.subjectId, required this.viewer});

  @override
  State<_ViewerCard> createState() => _ViewerCardState();
}

class _ViewerCardState extends State<_ViewerCard> {
  bool _loading = true;
  final Map<FamilyPermission, bool> _values = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final p in FamilyPermission.values) {
      _values[p] = await FamilyVisibilityService.isAllowed(
          widget.subjectId, widget.viewer.id, p);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(FamilyPermission p, bool value) async {
    setState(() => _values[p] = value);
    await FamilyVisibilityService.setAllowed(
        widget.subjectId, widget.viewer.id, p, value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarImage(index: widget.viewer.avatarIndex, size: 36),
              const SizedBox(width: AppDimensions.sm),
              Text(widget.viewer.name, style: AppTextStyles.labelLg),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppDimensions.md),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))),
            )
          else ...[
            const SizedBox(height: AppDimensions.sm),
            _PermissionRow(
              label: 'Отримує сповіщення',
              value: _values[FamilyPermission.notify]!,
              onChanged: (v) => _toggle(FamilyPermission.notify, v),
            ),
            _PermissionRow(
              label: 'Може редагувати профіль',
              value: _values[FamilyPermission.edit]!,
              onChanged: (v) => _toggle(FamilyPermission.edit, v),
            ),
            _PermissionRow(
              label: 'Бачить завдання, медкартку й розклад',
              value: _values[FamilyPermission.view]!,
              onChanged: (v) => _toggle(FamilyPermission.view, v),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PermissionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMd),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}
