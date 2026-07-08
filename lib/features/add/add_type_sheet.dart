import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/today/providers/today_providers.dart';
import '../appointments/add_appointment_screen.dart';
import '../medications/add_medication_screen.dart';
import '../wellbeing/add_wellbeing_schedule_screen.dart';
import 'add_activity_screen.dart';
import '../voice/voice_screen.dart';

void showAddTypeSheet(BuildContext context, {int? memberId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTypeSheet(memberId: memberId),
  );
}

class _AddTypeSheet extends ConsumerWidget {
  final int? memberId;
  const _AddTypeSheet({this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackMemberAsync = ref.watch(currentMemberProvider);
    final memberId = this.memberId ?? fallbackMemberAsync.valueOrNull?.id;
    final plan = ref.watch(planProvider);

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
            icon: Icons.medication_rounded,
            title: 'Ліки',
            sub: 'Розклад, дозування, AI-скан рецепта',
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
            icon: Icons.directions_walk_rounded,
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
            icon: Icons.favorite_rounded,
            title: 'Самопочуття',
            sub: 'Зробити зріз — настрій, симптоми, коментар',
            onTap: () {
              Navigator.pop(context);
              if (memberId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddWellbeingScheduleScreen(memberId: memberId)),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          _TypeCard(
            icon: Icons.medical_services_rounded,
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
          const SizedBox(height: 14),
          GestureDetector(
            onTap: plan.limits.voiceCommands
                ? () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceScreen()),
                    );
                  }
                : () => _showUpgradeSnack(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: plan.limits.voiceCommands
                    ? AppColors.primaryLight
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: plan.limits.voiceCommands
                      ? AppColors.primaryLighter
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    plan.limits.voiceCommands ? Icons.mic_rounded : Icons.lock_outline_rounded,
                    size: 18,
                    color: plan.limits.voiceCommands
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plan.limits.voiceCommands
                        ? 'Голосова команда'
                        : 'Голосова команда (Турбота+)',
                    style: AppTextStyles.labelMd.copyWith(
                      color: plan.limits.voiceCommands
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showUpgradeSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Голосові команди доступні з плану Турбота'),
      action: SnackBarAction(
        label: 'Плани',
        onPressed: () {},
      ),
    ),
  );
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Icon(icon, size: 26, color: AppColors.primary)),
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
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
