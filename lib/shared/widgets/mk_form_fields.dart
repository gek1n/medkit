import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import 'mk_back_button.dart';

/// Спільні віджети для екранів "додати/редагувати запис" (візит, аналіз,
/// алергія, хронічне захворювання, щеплення, операція) — щоб усі форми
/// медкартки виглядали однаково, а не кожна вигадувала свій варіант поля.

/// Підпис поля — UPPERCASE, дрібний, приглушений.
class MkFieldLabel extends StatelessWidget {
  final String label;
  const MkFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: AppTextStyles.labelSm);
}

/// Текстове поле в рамці — з контролером, звичайне або readOnly (тоді тап
/// відкриває власний пікер замість клавіатури).
class MkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final TextInputType? keyboardType;

  const MkTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          suffixIcon: readOnly
              ? const Icon(Icons.expand_more_rounded, color: AppColors.textMuted)
              : null,
        ),
        style: AppTextStyles.bodyMd,
      ),
    );
  }
}

/// Поле-кнопка без контролера — показує довільний текст ([value]), тап
/// відкриває пікер (дата, довідник тощо). [filled] керує кольором тексту:
/// приглушений, поки значення не обрано.
class MkTapField extends StatelessWidget {
  final String value;
  final bool filled;
  final VoidCallback onTap;

  const MkTapField({
    super.key,
    required this.value,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMd
                    .copyWith(color: filled ? AppColors.textMain : AppColors.textMuted),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Заголовок екрана форми: назад + назва (+ опційно текстова дія праворуч
/// або кнопка видалення для режиму редагування).
class MkFormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final String? trailingLabel;
  final VoidCallback? onTrailing;
  final VoidCallback? onDelete;

  const MkFormHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailingLabel,
    this.onTrailing,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.h3)),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailing,
              child: Text(
                trailingLabel!,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Рядок "мітка — значення" для екрана перегляду (не редагування) запису
/// медкартки — той самий шрифт/відступи по всій медкартці.
class MkDetailRow extends StatelessWidget {
  final String label;
  final Widget value;
  const MkDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MkFieldLabel(label),
          const SizedBox(height: 6),
          value,
        ],
      ),
    );
  }
}

/// Основна кнопка "Зберегти" форми — той самий стиль по всій медкартці.
class MkSaveButton extends StatelessWidget {
  final bool isSaving;
  final String label;
  final String savingLabel;
  final VoidCallback? onPressed;

  const MkSaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
    this.label = 'Зберегти',
    this.savingLabel = 'Зберігаємо...',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          isSaving ? savingLabel : label,
          style: AppTextStyles.labelLg.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
