import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionLabel(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: AppTextStyles.labelMd
                .copyWith(color: AppColors.textSub, letterSpacing: 0.5)),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}
