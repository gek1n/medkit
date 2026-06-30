import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../data/models/med_intake.dart';

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

    Color cardBg;
    Color cardBorder;
    Color iconBg;
    Color timeDot;

    if (intake.isTaken) {
      cardBg = const Color(0xFFF0FDF4);
      cardBorder = const Color(0xFFD1FAE5);
      iconBg = const Color(0xFFDCFCE7);
      timeDot = const Color(0xFFFCD34D);
    } else if (intake.isSkipped) {
      cardBg = const Color(0xFFFFF5F5);
      cardBorder = const Color(0xFFFEE2E2);
      iconBg = const Color(0xFFFEF3C7);
      timeDot = const Color(0xFFFCD34D);
    } else {
      cardBg = AppColors.bg;
      cardBorder = AppColors.border;
      iconBg = AppColors.primaryMid;
      timeDot = const Color(0xFFC4B5FD);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Center(
              child: Text(intake.medicationEmoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          // Info
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
                  intake.medicationDose,
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSub),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: timeDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      MKDateUtils.formatTime(intake.scheduledAt),
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          // Action / Status
          if (intake.isPending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  label: l10n.intakeSkip,
                  color: AppColors.danger,
                  bg: const Color(0xFFFEF2F2),
                  onTap: onSkip,
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  label: l10n.intakeTake,
                  color: AppColors.primary,
                  bg: AppColors.primaryLight,
                  onTap: onTake,
                ),
              ],
            )
          else
            _StatusBadge(intake: intake, l10n: l10n),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: color),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isTaken ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        isTaken ? l10n.intakeTaken : l10n.intakeSkipped,
        style: AppTextStyles.labelSm.copyWith(
          color: isTaken
              ? const Color(0xFF065F46)
              : const Color(0xFF991B1B),
        ),
      ),
    );
  }
}
