import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/med_form_icons.dart';

/// Спільний список форм випуску ліків — раніше жив приватно лише в
/// `add_medication_screen.dart`, винесено сюди, щоб той самий вибір форми
/// (з тими самими стилями) можна було показати і на екрані перегляду
/// результатів сканування рецепта.
const medFormKeys = [
  'tablet',
  'capsule',
  'suppository',
  'vial',
  'syrup',
  'drops',
  'cream',
  'inhaler',
  'injection',
];

Map<String, String> medFormLabels(BuildContext context) {
  final l10n = context.l10n;
  return {
    'tablet': l10n.medFormTablet,
    'capsule': l10n.medFormCapsule,
    'suppository': l10n.medFormSuppository,
    'vial': l10n.medFormVial,
    'syrup': l10n.medFormSyrup,
    'drops': l10n.medFormDrops,
    'cream': l10n.medFormCream,
    'inhaler': l10n.medFormInhaler,
    'injection': l10n.medFormInjection,
  };
}

String unitForMedForm(BuildContext context, String form) {
  final l10n = context.l10n;
  return switch (form) {
    'tablet' => l10n.medUnitTablet,
    'capsule' => l10n.medUnitCapsule,
    'syrup' => l10n.medUnitMl,
    'drops' => l10n.medUnitDrops,
    'cream' => l10n.medUnitGram,
    'inhaler' => l10n.medUnitInhale,
    'injection' => l10n.medUnitMl,
    'suppository' => l10n.medUnitSuppository,
    'vial' => l10n.medUnitVial,
    _ => l10n.medUnitPiece,
  };
}

class FormChips extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const FormChips({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final labels = medFormLabels(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: medFormKeys
          .map(
            (f) => GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected == f ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected == f ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      medFormIcon(f),
                      size: 16,
                      color: selected == f ? Colors.white : AppColors.textMain,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[f]!,
                      style: AppTextStyles.labelMd.copyWith(
                        color: selected == f ? Colors.white : AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
