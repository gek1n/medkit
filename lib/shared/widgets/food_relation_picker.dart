import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Єдине джерело правди для міток "Відносно їжі" — раніше форма ручного
/// додавання ліків і екран перегляду сканування рецепта тримали дві окремі
/// копії цього словника, і одна з них загубила варіант 'with' (Під час
/// їжі). Без емоджі-іконок навмисно — весь інший текст у формах medkit не
/// підмальовує собі кольорові піктограми, це виглядало розбіжно з рештою.
Map<String, String> foodRelationLabels(BuildContext context) {
  final l10n = context.l10n;
  return {
    'unspecified': l10n.foodRelationUnspecified,
    'before': l10n.foodOptBefore,
    'after': l10n.foodOptAfter,
    'with': l10n.foodRelationWith,
    'any': l10n.refFoodAnyLabel,
  };
}

/// Пікер у стилі решти довідників застосунку (напр. [showSpecialtyPicker]) —
/// заміна нативного `DropdownButton`, чиє спливаюче меню в вузькій колонці
/// відкривалось невиправдано по центру екрана і виглядало не в стилі бренду.
Future<String?> showFoodRelationPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(sheetContext.l10n.foodRelationPickerTitle, style: AppTextStyles.h3),
          ),
          ...foodRelationLabels(sheetContext).entries.map(
            (e) => ListTile(
              title: Text(e.value, style: AppTextStyles.bodyLg),
              trailing: e.key == current
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, e.key),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
