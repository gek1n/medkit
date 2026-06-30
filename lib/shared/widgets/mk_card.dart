import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class MkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? borderRadius;

  const MkCard({super.key, required this.child, this.padding, this.color, this.borderColor, this.onTap, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusLg),
        border: Border.all(color: borderColor ?? AppColors.border, width: 1.5),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: content);
    return content;
  }
}
