import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/l10n_ext.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppDimensions.navHeight,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.today_outlined,
                activeIcon: Icons.today,
                label: l10n.navToday,
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.medication_outlined,
                activeIcon: Icons.medication,
                label: l10n.navMeds,
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              // FAB placeholder
              const Expanded(child: SizedBox()),
              _NavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: l10n.navFamily,
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: l10n.navProfile,
                index: 4,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color:
                  isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
