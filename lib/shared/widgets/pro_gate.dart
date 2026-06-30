import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Виджет-замок для Pro-фич. Оборачивает child и при [locked]=true
/// показывает размытый оверлей с предложением апгрейда.
class ProGate extends StatelessWidget {
  final Widget child;
  final bool locked;
  final String? title;
  final String? body;
  final VoidCallback? onUpgrade;

  const ProGate({
    super.key,
    required this.child,
    required this.locked,
    this.title,
    this.body,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    return Stack(
      children: [
        IgnorePointer(
          child: Opacity(opacity: 0.35, child: child),
        ),
        Positioned.fill(
          child: _ProOverlay(
            title: title ?? context.l10n.proTitle,
            body: body ?? context.l10n.proLockedHint,
            onUpgrade: onUpgrade,
          ),
        ),
      ],
    );
  }
}

class _ProOverlay extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onUpgrade;

  const _ProOverlay({
    required this.title,
    required this.body,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.proGold, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppDimensions.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.proGoldLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(title,
              style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.sm),
          Text(body,
              style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.xl),
          FilledButton(
            onPressed: onUpgrade ?? () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.proGold,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Text(l10n.proUpgradeButton,
                style: AppTextStyles.labelLg
                    .copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Маленький бейдж PRO для иконок и строк меню
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.proGold,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        context.l10n.proBadge,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
