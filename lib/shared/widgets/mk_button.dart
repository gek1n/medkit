import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

class MkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isFullWidth;
  final Widget? icon;
  final bool isLoading;

  const MkButton({
    super.key,
    required this.label,
    this.onTap,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  const MkButton.secondary({
    super.key,
    required this.label,
    this.onTap,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  }) : isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                label,
                style: AppTextStyles.labelLg.copyWith(
                  color: isPrimary ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    );
    final minSize =
        isFullWidth ? const Size(double.infinity, 52) : const Size(0, 48);

    if (isPrimary) {
      return FilledButton(
        onPressed: isLoading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryMid,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: shape,
          minimumSize: minSize,
        ),
        child: content,
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primaryMid, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: shape,
        minimumSize: minSize,
      ),
      child: content,
    );
  }
}
