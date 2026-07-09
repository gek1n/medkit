import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'mk_back_button.dart';

// Єдина шапка "назад + заголовок" для екранів, які не використовують
// Scaffold.appBar (щоб не смішувати два різних стилі заголовка в одному
// застосунку — Material AppBar центрує leading інакше, ніж наш Row).
class MkScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const MkScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: onBack ?? () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.h3)),
          ?trailing,
        ],
      ),
    );
  }
}
