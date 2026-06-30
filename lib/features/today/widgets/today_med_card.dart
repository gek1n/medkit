import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/med_intake.dart';
import '../../../shared/widgets/mk_card.dart';

class TodayMedCard extends StatelessWidget {
  final MedIntake intake;
  final VoidCallback? onTaken;
  final VoidCallback? onSkipped;

  const TodayMedCard({super.key, required this.intake, required this.onTaken, required this.onSkipped});

  @override
  Widget build(BuildContext context) {
    final isTaken = intake.isTaken;
    final isSkipped = intake.isSkipped;
    final isDone = isTaken || isSkipped;

    Color borderColor = AppColors.border;
    Color bg = AppColors.surface;
    if (isTaken) { borderColor = AppColors.success; bg = AppColors.successLight; }
    if (isSkipped) { borderColor = AppColors.border; bg = AppColors.bgPage; }

    return MkCard(
      color: bg,
      borderColor: borderColor,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDone ? Colors.transparent : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: isDone ? Border.all(color: AppColors.borderLight) : null,
            ),
            child: Center(child: Text(intake.medicationEmoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(intake.medicationName,
                  style: AppTextStyles.labelLg.copyWith(
                    color: isSkipped ? AppColors.textMuted : AppColors.textMain,
                    decoration: isSkipped ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(intake.medicationDose, style: AppTextStyles.bodySm),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(MKDateUtils.formatTime(intake.scheduledAt), style: AppTextStyles.bodySm),
                  ],
                ),
              ],
            ),
          ),
          if (!isDone) ...[
            const SizedBox(width: AppDimensions.sm),
            _ActionButton(label: '✓', color: AppColors.success, bg: AppColors.successLight, onTap: onTaken),
            const SizedBox(width: AppDimensions.xs),
            _ActionButton(label: '✕', color: AppColors.textMuted, bg: AppColors.bgPage, onTap: onSkipped),
          ] else ...[
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
              decoration: BoxDecoration(
                color: isTaken ? AppColors.success.withValues(alpha: 0.1) : AppColors.bgPage,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                isTaken ? '✓' : '✕',
                style: AppTextStyles.labelMd.copyWith(color: isTaken ? AppColors.success : AppColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Center(child: Text(label, style: AppTextStyles.labelMd.copyWith(color: color))),
      ),
    );
  }
}
