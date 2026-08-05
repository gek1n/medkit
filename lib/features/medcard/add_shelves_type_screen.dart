import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/space_picker.dart';
import '../plans/elly_denied_screen.dart';
import 'add_medcard_entry_screen.dart';
import 'add_medcard_section_screen.dart';

/// "+" на екрані Поличок — той самий пікер-паттерн, що й openAddTaskScreen
/// на Сьогодні/Розкладі, лише з 2 пунктами замість 5: Нотатка (той самий
/// флоу, що й з Розкладу) і Поличка (той самий флоу, що й кнопка "Додати
/// поличку" нижче на екрані).
void openAddShelvesTypeScreen(BuildContext context, {required int memberId}) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddShelvesTypeScreen(memberId: memberId)),
  );
}

enum _ShelvesAddType { note, shelf }

class AddShelvesTypeScreen extends ConsumerWidget {
  final int memberId;
  const AddShelvesTypeScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openType(_ShelvesAddType type) async {
      if (type == _ShelvesAddType.note) {
        // Той самий флоу, що й пункт "Нотатка" у пікері Розкладу: спершу
        // Простір (з можливістю створити новий чи лишити автостворені
        // "Нотатки"), лише потім сама форма запису.
        var sectionId = await showSpacePicker(context, memberId: memberId, current: null);
        if (sectionId == null || !context.mounted) return;
        if (sectionId == noSpaceSelectedSentinel) {
          sectionId = await ref
              .read(medcardSectionsRepositoryProvider)
              .getOrCreateDefaultNotesSection(memberId, context.l10n.defaultNotesSectionName);
          if (!context.mounted) return;
        }
        final section = await ref.read(medcardSectionsRepositoryProvider).getById(sectionId);
        if (section == null || !context.mounted) return;
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => AddMedcardEntryScreen(section: section)),
        );
        if (saved == true && context.mounted) Navigator.pop(context, true);
        return;
      }

      // _ShelvesAddType.shelf — той самий ліміт-чек, що й кнопка "Додати
      // поличку" на med_card_screen.dart.
      final limits = ref.read(planProvider).limits;
      if (limits.maxMedcardSections != 0) {
        final count =
            await ref.read(medcardSectionsRepositoryProvider).countByMember(memberId);
        if (!context.mounted) return;
        if (count >= limits.maxMedcardSections) {
          Navigator.push(
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
      }
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => AddMedcardSectionScreen(memberId: memberId)),
      );
      if (saved == true && context.mounted) Navigator.pop(context, true);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(context.l10n.addTypeSheetTitle, style: AppTextStyles.h3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                context.l10n.addTypeSheetSubtitle,
                style: AppTextStyles.bodySm,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _ShelvesTypeCard(
                    iconAsset: 'task_note',
                    title: context.l10n.noteCategoryTitle,
                    sub: context.l10n.noteCategorySub,
                    onTap: () => openType(_ShelvesAddType.note),
                  ),
                  const SizedBox(height: 10),
                  _ShelvesTypeCard(
                    iconAsset: 'folder',
                    title: context.l10n.shelfTypeTitle,
                    sub: context.l10n.shelfTypeSub,
                    onTap: () => openType(_ShelvesAddType.shelf),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelvesTypeCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _ShelvesTypeCard({
    required this.iconAsset,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: AssetIcon(iconAsset, size: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(sub, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
