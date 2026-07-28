import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../features/plans/plans_screen.dart';

/// Градієнтний банер-запрошення перейти на платний план — спільний стиль
/// для всіх лімітів тарифу (профілі сім'ї, рутинні справи, розділи
/// Простору). Оригінально це був приватний _FamilyUpgradeBanner у
/// family_screen.dart, винесений сюди для повторного використання.
class PlanUpgradeBanner extends StatelessWidget {
  final IconData badgeIcon;
  final String badge;
  final String title;
  final String subtitle;
  final String illustrationAsset;
  final double illustrationHeight;

  const PlanUpgradeBanner({
    super.key,
    required this.badgeIcon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    this.illustrationHeight = 92,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlansScreen()),
      ),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C9A6A), Color(0xFF3B7A56)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: 0,
              child: Image.asset(illustrationAsset,
                  height: illustrationHeight, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(badge,
                            style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(title,
                      style: AppTextStyles.labelLg.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 190,
                    child: Text(subtitle,
                        style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.85))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
