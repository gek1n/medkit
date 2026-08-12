import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../features/family/peer_view_providers.dart';
import '../../features/today/providers/today_providers.dart';

/// #325-доробка (виконує роль і #318, і #319): спільний пікер "Хто виконує"
/// — локальні профілі (власник + залежні) ТА автономні пір'я одразу в
/// одному списку (раніше пір взагалі не показувався — #318). [showModes]
/// вмикає перемикач "Всім одразу"/черга (лише для рутин, де черга взагалі
/// має сенс) — для решти типів завдань (Нагадування/Ліки/Самопочуття/
/// Нотатки) завжди мультивибір без черги: кожен обраний одразу отримує
/// власний незалежний запис.
class AssigneeSelection {
  final Set<int> localMemberIds;
  final Set<String> peerPersonUuids;
  final String mode; // 'all' | 'perOccurrence' | 'weekly' | 'monthly'
  const AssigneeSelection({
    required this.localMemberIds,
    required this.peerPersonUuids,
    required this.mode,
  });

  int get count => localMemberIds.length + peerPersonUuids.length;
}

Future<AssigneeSelection?> showAssigneePicker(
  BuildContext context, {
  required AssigneeSelection initial,
  bool showModes = false,
  bool showPeers = true,
}) {
  return showModalBottomSheet<AssigneeSelection>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AssigneePickerSheet(initial: initial, showModes: showModes, showPeers: showPeers),
  );
}

class _AssigneePickerSheet extends ConsumerStatefulWidget {
  final AssigneeSelection initial;
  final bool showModes;
  final bool showPeers;
  const _AssigneePickerSheet({required this.initial, required this.showModes, this.showPeers = true});

  @override
  ConsumerState<_AssigneePickerSheet> createState() => _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends ConsumerState<_AssigneePickerSheet> {
  late Set<int> _localIds;
  late Set<String> _peerUuids;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _localIds = {...widget.initial.localMemberIds};
    _peerUuids = {...widget.initial.peerPersonUuids};
    _mode = widget.initial.mode;
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(allMembersProvider).valueOrNull ?? const [];
    final peers = ref.watch(allFamilyPeersProvider);
    final totalSelected = _localIds.length + _peerUuids.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding, AppDimensions.lg, AppDimensions.screenPadding, AppDimensions.lg),
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
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(context.l10n.assigneePickerTitle, style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in members)
                  _MemberChip(
                    name: m.name,
                    avatarIndex: m.avatarIndex,
                    selected: _localIds.contains(m.id),
                    onTap: () => setState(() {
                      if (_localIds.contains(m.id)) {
                        _localIds.remove(m.id);
                      } else {
                        _localIds.add(m.id);
                      }
                    }),
                  ),
                if (widget.showPeers)
                  for (final p in peers)
                    _MemberChip(
                      name: p.name,
                      avatarIndex: p.avatarIndex,
                      selected: _peerUuids.contains(p.personUuid),
                      onTap: () => setState(() {
                        if (_peerUuids.contains(p.personUuid)) {
                          _peerUuids.remove(p.personUuid);
                        } else {
                          _peerUuids.add(p.personUuid);
                        }
                      }),
                    ),
              ],
            ),
            if (widget.showModes && totalSelected > 1) ...[
              const SizedBox(height: AppDimensions.lg),
              Text(context.l10n.routineRotationCadenceLabel.toUpperCase(), style: AppTextStyles.labelSm),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('all', context.l10n.assigneeModeAllAtOnce),
                  ('perOccurrence', context.l10n.routineRotationCadencePerOccurrence),
                  ('weekly', context.l10n.routineRotationCadenceWeekly),
                  ('monthly', context.l10n.routineRotationCadenceMonthly),
                ].map((opt) {
                  final sel = _mode == opt.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _mode = opt.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        opt.$2,
                        style: AppTextStyles.labelMd.copyWith(color: sel ? AppColors.primaryDark : AppColors.textSub),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppDimensions.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_localIds.isEmpty && _peerUuids.isEmpty)
                    ? null
                    : () => Navigator.pop(
                          context,
                          AssigneeSelection(
                            localMemberIds: _localIds,
                            peerPersonUuids: _peerUuids,
                            mode: totalSelected > 1 ? _mode : 'all',
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(context.l10n.doneAction, style: AppTextStyles.labelLg.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String name;
  final int avatarIndex;
  final bool selected;
  final VoidCallback onTap;
  const _MemberChip({
    required this.name,
    required this.avatarIndex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarImage(index: avatarIndex, size: 24),
            const SizedBox(width: 8),
            Text(name, style: AppTextStyles.bodySm.copyWith(color: selected ? AppColors.primaryDark : AppColors.textMain)),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Компактний чіп у формі — "Хто виконує: Марина, Тато +2" — тап відкриває
/// [showAssigneePicker].
class AssigneeFieldChip extends ConsumerWidget {
  final AssigneeSelection selection;
  final VoidCallback onTap;
  const AssigneeFieldChip({super.key, required this.selection, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(allMembersProvider).valueOrNull ?? const [];
    final peers = ref.watch(allFamilyPeersProvider);
    final names = <String>[
      for (final id in selection.localMemberIds)
        members.where((m) => m.id == id).map((m) => m.name).firstOrNull ?? '',
      for (final uuid in selection.peerPersonUuids)
        peers.where((p) => p.personUuid == uuid).map((p) => p.name).firstOrNull ?? '',
    ]..removeWhere((n) => n.isEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.textSub),
            const SizedBox(width: 6),
            Text(context.l10n.assigneeFieldLabel, style: AppTextStyles.labelSm),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                names.isEmpty ? context.l10n.assigneeFieldEmptyValue : names.join(', '),
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
