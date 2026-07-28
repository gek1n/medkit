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
import '../../features/medcard/add_medcard_section_screen.dart';
import '../../features/plans/elly_denied_screen.dart';
import 'field_sheet.dart';

// Сентинел "явно обрано Без простору" — відрізняється від null (шторку
// просто закрили свайпом/тапом поза нею, без жодного вибору). Для більшості
// викликачів (ліки/активності/нагадування/самопочуття) різниця не важлива —
// SpaceField/SpaceChip мапують обидва в null. Але для нотаток (де sectionId
// не може лишитись порожнім) відмінність критична — див. add_task_screen.dart.
const int noSpaceSelectedSentinel = 0;

/// Пікер Простору — той самий розділ архіву (MedcardSections), тепер
/// використовується не лише для нотаток, а й для будь-якого завдання
/// (ліки/активності/нагадування/самопочуття). Повертає обраний id,
/// [noSpaceSelectedSentinel] (явно "без простору") або null, якщо закрито
/// без вибору.
Future<int?> showSpacePicker(
  BuildContext context, {
  required int memberId,
  required int? current,
}) {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (_) => _SpacePickerSheet(memberId: memberId, current: current),
  );
}

class _SpacePickerSheet extends ConsumerWidget {
  final int memberId;
  final int? current;
  const _SpacePickerSheet({required this.memberId, required this.current});

  Future<void> _createNew(BuildContext context, bool limitReached) async {
    if (limitReached) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EllyDeniedScreen(
            title: context.l10n.medcardSectionsLimitDeniedTitle,
            subtitle: context.l10n.medcardSectionsLimitDeniedSubtitle,
          ),
        ),
      );
      return;
    }
    final newId = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedcardSectionScreen(memberId: memberId),
      ),
    );
    if (newId != null && context.mounted) Navigator.pop(context, newId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(_sectionsProvider(memberId));
    final limits = ref.watch(planProvider).limits;
    final sectionsCount = sectionsAsync.valueOrNull?.length ?? 0;
    final limitReached = limits.maxMedcardSections != 0 &&
        sectionsCount >= limits.maxMedcardSections;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(context.l10n.spacePickerTitle, style: AppTextStyles.h3),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context, noSpaceSelectedSentinel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: current == null ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: current == null ? AppColors.primary : AppColors.border,
                    width: current == null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(context.l10n.noSpaceOption, style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
            ),
            sectionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => Text(context.l10n.errorGeneric('$e')),
              data: (sections) => Column(
                children: sections.map((s) {
                  final selected = s.id == current;
                  final color = colorFromHex(s.color) ?? AppColors.primary;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, s.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            child: MedcardIcon(s.iconKey, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.name, style: AppTextStyles.bodyMd)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _createNew(context, limitReached),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.createNewSpaceAction,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _sectionsProvider = StreamProvider.family<List<MedcardSection>, int>((ref, memberId) {
  return ref.watch(medcardSectionsRepositoryProvider).watchByMember(memberId);
});

/// Компактне поле "Простір" для форм створення — тап відкриває
/// [showSpacePicker], сама форма лише зберігає обраний sectionId.
class SpaceField extends ConsumerWidget {
  final int memberId;
  final int? sectionId;
  final ValueChanged<int?> onChanged;
  const SpaceField({
    super.key,
    required this.memberId,
    required this.sectionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(_sectionsProvider(memberId));
    final current = sectionsAsync.valueOrNull?.where((s) => s.id == sectionId).firstOrNull;

    return GestureDetector(
      onTap: () async {
        final picked = await showSpacePicker(context, memberId: memberId, current: sectionId);
        if (picked == null) return; // закрито без вибору — лишаємо як є
        onChanged(picked == noSpaceSelectedSentinel ? null : picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (current != null) ...[
              MedcardIcon(current.iconKey, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                current?.name ?? context.l10n.noSpaceOption,
                style: AppTextStyles.bodyMd.copyWith(
                  color: current == null ? AppColors.textMuted : AppColors.textMain,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Компактний чіп-варіант [SpaceField] для форм у стилі Todoist.
class SpaceChip extends ConsumerWidget {
  final int memberId;
  final int? sectionId;
  final ValueChanged<int?> onChanged;
  const SpaceChip({
    super.key,
    required this.memberId,
    required this.sectionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(_sectionsProvider(memberId));
    final current = sectionsAsync.valueOrNull?.where((s) => s.id == sectionId).firstOrNull;

    return FieldChip(
      icon: Icons.folder_outlined,
      iconWidget: current != null ? MedcardIcon(current.iconKey, size: 15) : null,
      label: context.l10n.spaceFieldLabel,
      value: current?.name,
      onClear: current == null ? null : () => onChanged(null),
      onTap: () async {
        final picked = await showSpacePicker(context, memberId: memberId, current: sectionId);
        if (picked == null) return;
        onChanged(picked == noSpaceSelectedSentinel ? null : picked);
      },
    );
  }
}
