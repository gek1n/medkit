import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Інлайн-блок у стилі EllyDeniedScreen (та сама ілюстрація, менший розмір) —
/// на відміну від нього, тут немає кнопки "План" (справа не в тарифі, а в
/// тому, що конкретна людина сама закрила цей розділ), тому просто інформує
/// й показується разом з рештою екрана, а не замінює його повністю.
class PeerSectionClosedCard extends StatelessWidget {
  final String peerName;
  final String sectionLabel;
  const PeerSectionClosedCard({
    super.key,
    required this.peerName,
    required this.sectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Image.asset('assets/illustrations/elly-denied.png', height: 48),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.familySectionAccessClosedTitle(
                    peerName,
                    sectionLabel,
                  ),
                  style: AppTextStyles.labelMd,
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.familySectionAccessClosedBody,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
