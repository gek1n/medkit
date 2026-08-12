import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/activity_log_generator.dart';
import '../../core/services/family_server_sync_service.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/services/intake_generator.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/reminders_repository.dart';
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
  final Map<FamilySection, Map<String, bool>> _sectionValues = {};
  // _sectionValues[section]['create'|'view'|'edit'].

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
        'create': await FamilyVisibilityService.isCreateAllowed(
            db, widget.subjectPersonUuid, widget.viewer.personUuid, s),
        'view': await FamilyVisibilityService.isSectionAllowed(
            db, widget.subjectPersonUuid, widget.viewer.personUuid, s, edit: false),
        'edit': await FamilyVisibilityService.isSectionAllowed(
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
    unawaited(FamilyServerSyncService(ref.read(databaseProvider), intakeGenerator: ref.read(intakeGeneratorProvider), activityLogGenerator: ref.read(activityLogGeneratorProvider), remindersRepository: ref.read(remindersRepositoryProvider)).syncAll());
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

  Future<void> _setSectionAction(AppDatabase db, FamilySection section, String action, bool value) {
    if (action == 'create') {
      return FamilyVisibilityService.setCreateAllowed(
        db,
        subjectPersonUuid: widget.subjectPersonUuid,
        viewerPersonUuid: widget.viewer.personUuid,
        section: section,
        value: value,
      );
    }
    return FamilyVisibilityService.setSectionAllowed(
      db,
      subjectPersonUuid: widget.subjectPersonUuid,
      viewerPersonUuid: widget.viewer.personUuid,
      section: section,
      edit: action == 'edit',
      value: value,
    );
  }

  Future<void> _toggleSection(FamilySection section, String action, bool value) async {
    setState(() => _sectionValues[section]![action] = value);
    try {
      await _setSectionAction(ref.read(databaseProvider), section, action, value);
      _pushSoon();
    } on FamilyGrantDeniedException {
      if (mounted) setState(() => _denied = true);
    }
  }

  // "Розклад" і "Медкартка" об'єднані в UI в один розділ "Завдання та
  // нагадування" (успадковано з архівної поведінки 07.08) — далі й на
  // пристрої суб'єкта, і в усіх екранах перегляду вони й далі два окремі
  // FamilySection (schedule/medcard, різні типи сутностей у _pushToChannel).
  Future<void> _toggleTasksSection(String action, bool value) async {
    setState(() {
      _sectionValues[FamilySection.schedule]![action] = value;
      _sectionValues[FamilySection.medcard]![action] = value;
    });
    try {
      final db = ref.read(databaseProvider);
      await _setSectionAction(db, FamilySection.schedule, action, value);
      await _setSectionAction(db, FamilySection.medcard, action, value);
      // #323: "Отримує сповіщення" залежить від Перегляду завдань — коли
      // Перегляд вимикають, сповіщення примусово гасяться разом з ним.
      if (action == 'view' && !value && _values[FamilyPermission.notify] == true) {
        await _toggle(FamilyPermission.notify, false);
      }
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
            // #323: без майстер-перемикача "Бачить..." — розділи одразу
            // видно, кожен зі своїми трьома незалежними правами. Отримує
            // сповіщення — між двома розділами, залежить лише від Перегляду
            // завдань (не від Поличок).
            _SectionPermissionRow(
              label: context.l10n.familySectionTasksLabel,
              createValue: _sectionValues[FamilySection.schedule]!['create']! ||
                  _sectionValues[FamilySection.medcard]!['create']!,
              viewValue: _sectionValues[FamilySection.schedule]!['view']! ||
                  _sectionValues[FamilySection.medcard]!['view']!,
              editValue: _sectionValues[FamilySection.schedule]!['edit']! ||
                  _sectionValues[FamilySection.medcard]!['edit']!,
              onCreateChanged: (v) => _toggleTasksSection('create', v),
              onViewChanged: (v) => _toggleTasksSection('view', v),
              onEditChanged: (v) => _toggleTasksSection('edit', v),
            ),
            const SizedBox(height: AppDimensions.sm),
            _NotifyRow(
              value: _values[FamilyPermission.notify]!,
              enabled: _sectionValues[FamilySection.schedule]!['view']! ||
                  _sectionValues[FamilySection.medcard]!['view']!,
              onChanged: (v) => _toggle(FamilyPermission.notify, v),
            ),
            const SizedBox(height: AppDimensions.sm),
            _SectionPermissionRow(
              label: context.l10n.familySectionShelvesLabel,
              createValue: _sectionValues[FamilySection.shelves]!['create']!,
              viewValue: _sectionValues[FamilySection.shelves]!['view']!,
              editValue: _sectionValues[FamilySection.shelves]!['edit']!,
              onCreateChanged: (v) => _toggleSection(FamilySection.shelves, 'create', v),
              onViewChanged: (v) => _toggleSection(FamilySection.shelves, 'view', v),
              onEditChanged: (v) => _toggleSection(FamilySection.shelves, 'edit', v),
            ),
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

/// "Отримує сповіщення" — між двома секційними рядками. Незалежний від
/// Поличок, залежить лише від Перегляду завдань ([enabled]): без нього
/// перемикач вимкнено й візуально приглушено, а сам грант примусово
/// вимикається в [_ViewerCardState._toggleTasksSection].
class _NotifyRow extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _NotifyRow({required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Той самий трьохколонковий каркас, що й _SectionPermissionRow (заголовок
    // зверху, перемикач під першою колонкою) — раніше перемикач висів справа
    // окремим Row, що випадково збігалося по X з колонкою "Редагування" і
    // виглядало як частина сусіднього розділу.
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.viewerNotifyPermissionLabel, style: AppTextStyles.labelMd),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Switch(
                    value: enabled && value,
                    onChanged: enabled ? onChanged : null,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                  ),
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Один розділ (Завдання та нагадування / Полички) — три незалежні права:
/// створення, перегляд, редагування (#323). Створення не залежить від
/// перегляду (можна штовхати нові записи, не бачачи чужих наявних);
/// редагування, як і раніше, вимагає ввімкненого перегляду.
class _SectionPermissionRow extends StatelessWidget {
  final String label;
  final bool createValue;
  final bool viewValue;
  final bool editValue;
  final ValueChanged<bool> onCreateChanged;
  final ValueChanged<bool> onViewChanged;
  final ValueChanged<bool> onEditChanged;
  const _SectionPermissionRow({
    required this.label,
    required this.createValue,
    required this.viewValue,
    required this.editValue,
    required this.onCreateChanged,
    required this.onViewChanged,
    required this.onEditChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _ToggleColumn(
                label: context.l10n.familySectionCreateColumnLabel,
                value: createValue,
                onChanged: onCreateChanged,
              ),
            ),
            Expanded(
              child: _ToggleColumn(
                label: context.l10n.familySectionViewColumnLabel,
                value: viewValue,
                onChanged: onViewChanged,
              ),
            ),
            Expanded(
              child: _ToggleColumn(
                label: context.l10n.familySectionEditColumnLabel,
                // Редагування без перегляду не має сенсу — якщо перегляду
                // нема, вимикаємо й ховаємо можливість увімкнути редагування.
                value: viewValue && editValue,
                onChanged: viewValue ? onEditChanged : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToggleColumn extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _ToggleColumn({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primaryLight,
        ),
      ],
    );
  }
}
