import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Дата-пікер у фірмових кольорах — для записів медкартки часто потрібна
/// дата в минулому (діагноз, аналіз, щеплення), тому [firstDate] за
/// замовчуванням відкритий далеко назад, а не обмежений сьогоднішнім днем.
Future<DateTime?> showMedcardDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(1950),
    lastDate: lastDate ?? DateTime.now(),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    ),
  );
}
