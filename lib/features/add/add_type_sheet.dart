import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/today/providers/today_providers.dart';
import '../appointments/add_appointment_screen.dart';
import '../medications/add_medication_screen.dart';
import '../wellbeing/wellbeing_check_screen.dart';
import 'add_activity_screen.dart';

void showAddTypeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTypeSheet(),
  );
}

class _AddTypeSheet extends ConsumerWidget {
  const _AddTypeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final memberId = memberAsync.valueOrNull?.id;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Що хочете додати?', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Оберіть тип — форма підлаштується',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: 20),

          _TypeCard(
            color: AppColors.primaryLight,
            borderColor: AppColors.primary,
            iconBg: AppColors.primaryLighter,
            icon: '💊',
            title: 'Лікарство',
            sub: 'Розклад, дозування, AI-скан рецепта',
            checked: true,
            onTap: () {
              Navigator.pop(context);
              if (memberId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddMedicationScreen(memberId: memberId)),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          _TypeCard(
            color: const Color(0xFFF0FDF4),
            borderColor: AppColors.border,
            iconBg: const Color(0xFFDCFCE7),
            icon: '🚶',
            title: 'Активність',
            sub: 'Прогулянка, зарядка, вправи, ЛФК',
            onTap: () {
              Navigator.pop(context);
              if (memberId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddActivityScreen(memberId: memberId)),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          _TypeCard(
            color: const Color(0xFFF5F3FF),
            borderColor: AppColors.border,
            iconBg: const Color(0xFFEDE9FE),
            icon: '💜',
            title: 'Самопочуття',
            sub: 'Зробити зріз — настрій, симптоми, коментар',
            onTap: () {
              Navigator.pop(context);
              if (memberId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          WellbeingCheckScreen(memberId: memberId)),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          _TypeCard(
            color: const Color(0xFFF0FDFA),
            borderColor: AppColors.border,
            iconBg: const Color(0xFFCCFBF1),
            icon: '🩺',
            title: 'Запис до лікаря',
            sub: 'Обрати спеціаліста, час та отримати нагадування',
            onTap: () {
              Navigator.pop(context);
              if (memberId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddAppointmentScreen(memberId: memberId)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color iconBg;
  final String icon;
  final String title;
  final String sub;
  final bool checked;
  final VoidCallback onTap;

  const _TypeCard({
    required this.color,
    required this.borderColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.sub,
    this.checked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: checked ? 2 : 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: checked ? AppColors.primary : AppColors.border,
                    width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
