import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../data/models/med_intake.dart';
import '../../../shared/widgets/mk_card.dart';

class TodayMedCard extends StatelessWidget {
  final MedIntake intake;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  const TodayMedCard({
    super.key,
    required this.intake,
    required this.onTake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPending = intake.isPending;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: MkCard(
        color: intake.isTaken
            ? AppColors.successLight
            : intake.isSkipped
                ? AppColors.dangerLight
                : AppColors.surface,
        borderColor: intake.isTaken
            ? AppColors.success.withValues(alpha: 0.3)
            : intake.isSkipped
                ? AppColors.danger.withValues(alpha: 0.2)
                : AppColors.border,
        child: Row(
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
                child: Text(intake.medicationEmoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intake.medicationName,
                    style: AppTextStyles.labelMd,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${intake.medicationDose} · ${MKDateUtils.formatTime(intake.scheduledAt)}',
                    style: AppTextStyles.bodyMd,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              const SizedBox(width: AppDimensions.sm),
              _ActionButton(
                label: l10n.intakeSkip,
                color: AppColors.danger,
                bgColor: AppColors.dangerLight,
                onTap: onSkip,
              ),
              const SizedBox(width: AppDimensions.sm),
              _ActionButton(
                label: l10n.intakeTake,
                color: AppColors.success,
                bgColor: AppColors.successLight,
                onTap: onTake,
              ),
            ] else
              _StatusBadge(intake: intake, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(label,
            style:
                AppTextStyles.labelSm.copyWith(color: color)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MedIntake intake;
  final AppLocalizations l10n;

  const _StatusBadge({required this.intake, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isTaken = intake.isTaken;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isTaken ? Icons.check_circle : Icons.cancel,
          color: isTaken ? AppColors.success : AppColors.danger,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          isTaken ? l10n.intakeTaken : l10n.intakeSkipped,
          style: AppTextStyles.bodySm.copyWith(
            color: isTaken ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }
}
