import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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

const medFormLabels = {
  'tablet': 'Таблетка',
  'capsule': 'Капсула',
  'suppository': 'Свічі',
  'vial': 'Флакон',
  'syrup': 'Сироп',
  'drops': 'Краплі',
  'cream': 'Крем',
  'inhaler': 'Інгалятор',
  'injection': 'Ін\'єкція',
};

String unitForMedForm(String form) => switch (form) {
      'tablet' => 'табл.',
      'capsule' => 'капс.',
      'syrup' => 'мл',
      'drops' => 'крап.',
      'cream' => 'г',
      'inhaler' => 'вдих',
      'injection' => 'мл',
      'suppository' => 'свіча',
      'vial' => 'фл.',
      _ => 'шт.',
    };

class FormChips extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const FormChips({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
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
                      medFormLabels[f]!,
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
