import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../data/models/family_member.dart';

class FamilyStatusStrip extends StatelessWidget {
  final List<FamilyMember> members;
  final bool showProHint;

  const FamilyStatusStrip({
    super.key,
    required this.members,
    this.showProHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppDimensions.screenPadding),
        children: [
          ...members.map((m) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _FamilyCard(member: m),
              )),
          if (showProHint)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _proHintCard(context),
            ),
        ],
      ),
    );
  }

  Widget _proHintCard(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.proGoldLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.proGold, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              context.l10n.proBadge,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.proGold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.navFamily,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.proGold.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final FamilyMember member;
  const _FamilyCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final pct = member.adherence;

    // Colors matching the mockup
    final Color avatarBg;
    final Color statusColor;
    final String statusText;
    final Color dotColor;

    if (pct >= 1.0) {
      avatarBg = const Color(0xFFDCFCE7);
      dotColor = const Color(0xFF22C55E);
      statusColor = const Color(0xFF22C55E);
      statusText = '✓ прийнято';
    } else if (pct > 0) {
      avatarBg = const Color(0xFFEDE9FE);
      dotColor = const Color(0xFFA78BFA);
      statusColor = AppColors.textMuted;
      statusText = 'незабаром';
    } else {
      avatarBg = const Color(0xFFFEE2E2);
      dotColor = const Color(0xFFEF4444);
      statusColor = const Color(0xFFEF4444);
      statusText = '⚠ пропустив';
    }

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(member.avatar,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            member.name,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
