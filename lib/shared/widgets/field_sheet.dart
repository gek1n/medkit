import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Компактний "чіп" для необов'язкового поля форми — у стилі Todoist: поки
/// значення не задане, показує лише іконку+назву приглушеним кольором; коли
/// задане — підсвічується і показує саме значення замість назви поля.
class FieldChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final Color? swatchColor;
  // Коли true — текст чіпа завжди показує [label] (не [value]); саме
  // [value] лише вмикає підсвічений стиль "заповнено" (напр. колір/тумблер,
  // де сенс несе колір/іконка, а не текстове значення).
  final bool forceLabel;

  const FieldChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.swatchColor,
    this.forceLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = value != null && value!.trim().isNotEmpty;
    final text = (isSet && !forceLabel) ? value! : label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSet ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSet ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatchColor != null)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: swatchColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              Icon(icon,
                  size: 15,
                  color: isSet ? AppColors.primary : AppColors.textSub),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.labelMd.copyWith(
                color: isSet ? AppColors.primary : AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Обгортає довільний віджет поля (теги, колір, документи тощо) у нижню
/// шторку з заголовком і кнопкою "Готово" — дозволяє показувати вже наявні
/// inline-віджети форм як контент, відкритий по тапу на [FieldChip].
Future<void> showFieldSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
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
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                elevation: 0,
              ),
              child: Text(
                ctx.l10n.applyAction,
                style: AppTextStyles.labelLg.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
