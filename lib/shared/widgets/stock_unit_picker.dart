import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Найпоширеніші одиниці виміру залишку — для Інвентарю (раніше форма
/// випуску ліків жорстко визначала одиницю; тепер це окремий вільний вибір,
/// що підходить і для ліків, і для їжі/добавок/побутових витратних речей).
const stockUnitKeys = [
  'piece',
  'g',
  'kg',
  'ml',
  'l',
  'vial',
  'tube',
  'pack',
  'jar',
  'bottle',
  'portion',
  'spoon',
  'glass',
];

Map<String, String> stockUnitLabels(BuildContext context) {
  final l10n = context.l10n;
  return {
    'piece': l10n.medUnitPiece,
    'g': l10n.medUnitGram,
    'kg': l10n.stockUnitKg,
    'ml': l10n.medUnitMl,
    'l': l10n.stockUnitLiter,
    'vial': l10n.medUnitVial,
    'tube': l10n.stockUnitTube,
    'pack': l10n.stockUnitPack,
    'jar': l10n.stockUnitJar,
    'bottle': l10n.stockUnitBottle,
    'portion': l10n.stockUnitPortion,
    'spoon': l10n.stockUnitSpoon,
    'glass': l10n.stockUnitGlass,
  };
}

/// Компактний Wrap-пікер одиниці виміру — без власного контейнера/рамки,
/// призначений для вбудовування всередину вже розгорнутого блоку (напр.
/// шторки "Відстежувати та нагадувати про залишок"), а не як окремий чіп.
class StockUnitChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const StockUnitChips({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final labels = stockUnitLabels(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stockUnitKeys.map((u) {
        final sel = selected == u;
        return GestureDetector(
          onTap: () => onSelect(sel ? null : u),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              labels[u]!,
              style: AppTextStyles.labelMd.copyWith(
                color: sel ? Colors.white : AppColors.textMain,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
