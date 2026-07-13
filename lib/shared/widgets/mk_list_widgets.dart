import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'mk_back_button.dart';

/// Заголовок екрана-списку медкартки: назад + назва. Кнопка додавання — це
/// плаваюча кнопка внизу справа (як на Сьогодні), не в заголовку.
class MkListHeader extends StatelessWidget {
  final String title;

  const MkListHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.h3)),
        ],
      ),
    );
  }
}

/// Плаваюча кнопка "+" внизу справа — той самий стиль, що й на Сьогодні,
/// для всіх списків медкартки.
class MkAddFab extends StatelessWidget {
  final VoidCallback onPressed;
  const MkAddFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }
}

/// Порожній стан списку медкартки — та сама ілюстрація й тон по всій
/// медкартці ("Ще нічого не додано"), лише підказка змінюється.
class MkEmptyState extends StatelessWidget {
  final String hint;

  const MkEmptyState({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/illustrations/elly-docs.png', height: 140),
            const SizedBox(height: 16),
            Text('Ще нічого не додано', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
