import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';

/// Пікер іконки для довільного розділу архіву — сітка з нейтральних
/// іконок (medcard_icons.dart). Повертає обраний ключ або null, якщо
/// закрито без вибору.
Future<String?> showMedcardIconPicker(BuildContext context, {required String current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (_) => _MedcardIconPickerSheet(current: current),
  );
}

class _MedcardIconPickerSheet extends StatelessWidget {
  final String current;
  const _MedcardIconPickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
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
            Text(context.l10n.chooseIconLabel, style: AppTextStyles.h3),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: medcardIcons.entries.map((e) {
                final selected = e.key == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, e.key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      e.value,
                      color: selected ? AppColors.primary : AppColors.textSub,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
