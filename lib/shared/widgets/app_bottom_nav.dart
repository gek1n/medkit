import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.wb_sunny_rounded, label: l10n.navToday, index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.calendar_month_rounded, label: l10n.navMeds, index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.medical_information_rounded, label: l10n.navMedCard, index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.people_alt_rounded, label: l10n.navFamily, index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_rounded, label: l10n.navProfile, index: 4, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isActive ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }
}
