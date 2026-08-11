import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/family_server_sync_service.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../family/peer_view_providers.dart';
import '../today/providers/today_providers.dart' show allMembersProvider;

/// Крок 11: хто саме може бути "суб'єктом" видимості — ЛИШЕ власний
/// профіль пристрою (role == 'owner'). Локальні dependent-профілі
/// принципово не можуть бути суб'єктом — `FamilyServerSyncService.
/// _pushToChannel()` більше не пушить їхні дані нікуди незалежно від
/// гранту, тож окремий екран налаштування для них не мав би сенсу
/// (перемикачі існували б, але ні на що не впливали б).
///
/// [focusViewerPersonUuid] — опційно, коли екран відкрито з конкретної
/// картки піра (family_screen.dart) — ставить цю картку першою і підсвічує
/// рамкою, замість повноцінного скролу до довільної позиції.
class FamilyVisibilityScreen extends ConsumerWidget {
  final String? focusViewerPersonUuid;
  const FamilyVisibilityScreen({super.key, this.focusViewerPersonUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);
    final viewers = List<PeerSubject>.from(ref.watch(allFamilyPeersProvider));
    if (focusViewerPersonUuid != null) {
      final idx = viewers.indexWhere((v) => v.personUuid == focusViewerPersonUuid);
      if (idx > 0) {
        final focused = viewers.removeAt(idx);
        viewers.insert(0, focused);
      }
    }

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
                  Text(context.l10n.familyVisibilityLabel, style: AppTextStyles.h2),
                ],
              ),
            ),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('$e')),
                data: (members) {
                  final owner = members.where((m) => m.role == 'owner').firstOrNull;
                  if (owner?.personUuid == null) {
                    return Center(child: Text(context.l10n.profileNotFound));
                  }
                  final subjectUuid = owner!.personUuid!;

                  if (viewers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.screenPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/illustrations/elly22.png', height: 160),
                            const SizedBox(height: AppDimensions.lg),
                            Text(
                              context.l10n.familyVisibilityEmptyBody,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
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
                        context.l10n.familyVisibilityIntro,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      for (final viewer in viewers) ...[
                        _ViewerCard(
                          subjectPersonUuid: subjectUuid,
                          viewer: viewer,
                          highlighted: viewer.personUuid == focusViewerPersonUuid,
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

class _ViewerCard extends ConsumerStatefulWidget {
  final String subjectPersonUuid;
  final PeerSubject viewer;
  final bool highlighted;
  const _ViewerCard({required this.subjectPersonUuid, required this.viewer, this.highlighted = false});

  @override
  ConsumerState<_ViewerCard> createState() => _ViewerCardState();
}

class _ViewerCardState extends ConsumerState<_ViewerCard> {
  bool _loading = true;
  bool _denied = false;
  final Map<FamilyPermission, bool> _values = {};
  final Map<FamilySection, Map<bool, bool>> _sectionValues = {};
  // _sectionValues[section][edit] — edit:false = перегляд, edit:true = редагування.

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    for (final p in FamilyPermission.values) {
      _values[p] = await FamilyVisibilityService.isAllowed(db, widget.subjectPersonUuid, widget.viewer.personUuid, p);
    }
    for (final s in FamilySection.values) {
      _sectionValues[s] = {
        false: await FamilyVisibilityService.isSectionAllowed(
            db, widget.subjectPersonUuid, widget.viewer.personUuid, s, edit: false),
        true: await FamilyVisibilityService.isSectionAllowed(
            db, widget.subjectPersonUuid, widget.viewer.personUuid, s, edit: true),
      };
    }
    if (mounted) setState(() => _loading = false);
  }

  void _pushSoon() {
    // Без цього зміна долетить до піра лише на наступному пасивному
    // тригері (resume/FCM) — новий грант лежав би непереданим до тих пір.
    // syncAll() сам обгортає кожен крок у try/catch — тут окрема обгортка
    // не потрібна.
    unawaited(FamilyServerSyncService(ref.read(databaseProvider)).syncAll());
  }

  Future<void> _toggle(FamilyPermission p, bool value) async {
    setState(() => _values[p] = value);
    try {
      await FamilyVisibilityService.setAllowed(
        ref.read(databaseProvider),
        subjectPersonUuid: widget.subjectPersonUuid,
        viewerPersonUuid: widget.viewer.personUuid,
        permission: p,
        value: value,
      );
    } on FamilyGrantDeniedException {
      if (mounted) setState(() => _denied = true);
      return;
    }
    _pushSoon();
  }

  Future<void> _toggleSection(FamilySection section, bool edit, bool value) async {
    setState(() => _sectionValues[section]![edit] = value);
    try {
      await FamilyVisibilityService.setSectionAllowed(
        ref.read(databaseProvider),
        subjectPersonUuid: widget.subjectPersonUuid,
        viewerPersonUuid: widget.viewer.personUuid,
        section: section,
        edit: edit,
        value: value,
      );
      _pushSoon();
    } on FamilyGrantDeniedException {
      if (mounted) setState(() => _denied = true);
    }
  }

  // "Розклад" і "Медкартка" об'єднані в UI в один розділ "Завдання та
  // нагадування" (успадковано з архівної поведінки 07.08) — далі й на
  // пристрої суб'єкта, і в усіх екранах перегляду вони й далі два окремі
  // FamilySection (schedule/medcard, різні типи сутностей у _pushToChannel).
  Future<void> _toggleTasksSection(bool edit, bool value) async {
    setState(() {
      _sectionValues[FamilySection.schedule]![edit] = value;
      _sectionValues[FamilySection.medcard]![edit] = value;
    });
    try {
      final db = ref.read(databaseProvider);
      await FamilyVisibilityService.setSectionAllowed(
        db,
        subjectPersonUuid: widget.subjectPersonUuid,
        viewerPersonUuid: widget.viewer.personUuid,
        section: FamilySection.schedule,
        edit: edit,
        value: value,
      );
      await FamilyVisibilityService.setSectionAllowed(
        db,
        subjectPersonUuid: widget.subjectPersonUuid,
        viewerPersonUuid: widget.viewer.personUuid,
        section: FamilySection.medcard,
        edit: edit,
        value: value,
      );
      _pushSoon();
    } on FamilyGrantDeniedException {
      if (mounted) setState(() => _denied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: widget.highlighted ? AppColors.primary : AppColors.border, width: widget.highlighted ? 2 : 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarImage(index: widget.viewer.avatarIndex, size: 36),
              const SizedBox(width: AppDimensions.sm),
              Expanded(child: Text(widget.viewer.name, style: AppTextStyles.labelLg)),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppDimensions.md),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
            )
          else ...[
            const SizedBox(height: AppDimensions.sm),
            _PermissionRow(
              label: context.l10n.viewerNotifyPermissionLabel,
              value: _values[FamilyPermission.notify]!,
              onChanged: (v) => _toggle(FamilyPermission.notify, v),
            ),
            _PermissionRow(
              label: context.l10n.viewerViewPermissionLabel,
              value: _values[FamilyPermission.view]!,
              onChanged: (v) => _toggle(FamilyPermission.view, v),
            ),
            if (_values[FamilyPermission.view] == true) ...[
              const SizedBox(height: AppDimensions.sm),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.sm),
              Text(
                context.l10n.familySectionsIntro,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppDimensions.xs),
              _SectionPermissionRow(
                label: context.l10n.familySectionTasksLabel,
                viewValue: _sectionValues[FamilySection.schedule]![false]! ||
                    _sectionValues[FamilySection.medcard]![false]!,
                editValue: _sectionValues[FamilySection.schedule]![true]! ||
                    _sectionValues[FamilySection.medcard]![true]!,
                onViewChanged: (v) => _toggleTasksSection(false, v),
                onEditChanged: (v) => _toggleTasksSection(true, v),
              ),
              _SectionPermissionRow(
                label: context.l10n.familySectionShelvesLabel,
                viewValue: _sectionValues[FamilySection.shelves]![false]!,
                editValue: _sectionValues[FamilySection.shelves]![true]!,
                onViewChanged: (v) => _toggleSection(FamilySection.shelves, false, v),
                onEditChanged: (v) => _toggleSection(FamilySection.shelves, true, v),
              ),
            ],
            if (_denied) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.permissionDeniedNotYoursBody,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
              ),
            ],
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
  const _PermissionRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
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

/// Один розділ (Завдання та нагадування / Полички) — окремо перегляд і
/// редагування, замість одного спільного перемикача на всю людину.
class _SectionPermissionRow extends StatelessWidget {
  final String label;
  final bool viewValue;
  final bool editValue;
  final ValueChanged<bool> onViewChanged;
  final ValueChanged<bool> onEditChanged;
  const _SectionPermissionRow({
    required this.label,
    required this.viewValue,
    required this.editValue,
    required this.onViewChanged,
    required this.onEditChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.familySectionViewColumnLabel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              Switch(
                value: viewValue,
                onChanged: onViewChanged,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.familySectionEditColumnLabel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              Switch(
                // Редагування без перегляду не має сенсу — якщо перегляду
                // нема, вимикаємо й ховаємо можливість увімкнути редагування.
                value: viewValue && editValue,
                onChanged: viewValue ? onEditChanged : null,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
