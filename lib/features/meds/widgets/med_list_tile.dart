import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../data/models/medication.dart';
import '../../../shared/widgets/mk_card.dart';

class MedListTile extends StatelessWidget {
  final Medication med;
  final VoidCallback? onTap;

  const MedListTile({super.key, required this.med, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = med.remainingPercent;
    final barColor = pct > 0.4
        ? AppColors.success
        : pct > 0.15
            ? AppColors.warning
            : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: MkCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Center(
                    child: Text(med.form.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: AppTextStyles.labelMd),
                      const SizedBox(height: 2),
                      Text(med.dose, style: AppTextStyles.bodyMd),
                    ],
                  ),
                ),
                Text(
                  l10n.medsRemaining(med.remainingCount),
                  style: AppTextStyles.bodySm.copyWith(color: barColor),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
