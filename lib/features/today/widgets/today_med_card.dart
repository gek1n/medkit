import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/med_form_icons.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/intakes_repository.dart';
import '../../../data/repositories/medications_repository.dart';
import '../../../shared/widgets/mk_card.dart';

class TodayMedCard extends StatelessWidget {
  final Intake intake;
  final WidgetRef ref;

  const TodayMedCard({super.key, required this.intake, required this.ref});

  @override
  Widget build(BuildContext context) {
    // Читаємо назву ліків з репозиторію
    final medAsync = ref.watch(
      _medicationProvider(intake.medicationId),
    );

    return medAsync.when(
      loading: () => const SizedBox(height: 72),
      error: (_, _) => const SizedBox.shrink(),
      data: (med) {
        if (med == null) return const SizedBox.shrink();
        return _MedCardContent(intake: intake, med: med, ref: ref);
      },
    );
  }
}

final _medicationProvider =
    FutureProvider.family<Medication?, int>((ref, id) {
  return ref.watch(medicationsRepositoryProvider).getById(id);
});

class _MedCardContent extends StatelessWidget {
  final Intake intake;
  final Medication med;
  final WidgetRef ref;

  const _MedCardContent(
      {required this.intake, required this.med, required this.ref});

  bool get isTaken => intake.status == 'taken';
  bool get isSkipped => intake.status == 'skipped';
  bool get isDone => isTaken || isSkipped;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color bg = AppColors.surface;
    if (isTaken) {
      borderColor = AppColors.success;
      bg = AppColors.successLight;
    }
    if (isSkipped) {
      borderColor = AppColors.border;
      bg = AppColors.bgPage;
    }

    return MkCard(
      color: bg,
      borderColor: borderColor,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDone ? Colors.transparent : AppColors.primaryLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              border:
                  isDone ? Border.all(color: AppColors.borderLight) : null,
            ),
            child: Center(
              child: Icon(
                medFormIcon(med.form),
                size: 22,
                color: isDone ? AppColors.textMuted : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: AppTextStyles.labelLg.copyWith(
                    color: isSkipped
                        ? AppColors.textMuted
                        : AppColors.textMain,
                    decoration: isSkipped
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${med.doseAmount.toStringAsFixed(med.doseAmount == med.doseAmount.roundToDouble() ? 0 : 1)} ${med.doseUnit}',
                      style: AppTextStyles.bodySm,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MKDateUtils.formatTime(intake.scheduledAt),
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isDone) ...[
            const SizedBox(width: AppDimensions.sm),
            _ActionButton(
              label: '✓',
              color: AppColors.success,
              bg: AppColors.successLight,
              onTap: () => ref
                  .read(intakesRepositoryProvider)
                  .markTaken(intake.id),
            ),
            const SizedBox(width: AppDimensions.xs),
            _ActionButton(
              label: '✕',
              color: AppColors.textMuted,
              bg: AppColors.bgPage,
              onTap: () => ref
                  .read(intakesRepositoryProvider)
                  .markSkipped(intake.id),
            ),
          ] else ...[
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xs),
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.bgPage,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                isTaken ? '✓' : '✕',
                style: AppTextStyles.labelMd.copyWith(
                    color: isTaken
                        ? AppColors.success
                        : AppColors.textMuted),
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
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label,
              style: AppTextStyles.labelMd.copyWith(color: color)),
        ),
      ),
    );
  }
}
