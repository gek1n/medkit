import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/mk_back_button.dart';
import 'breathing_exercise_screen.dart';
import 'clear_mind_screen.dart';
import 'grounding_54321_screen.dart';

class AntiStressPickerScreen extends StatelessWidget {
  const AntiStressPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.md,
                AppDimensions.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Text('Антистрес-вправи', style: AppTextStyles.h2),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.lg,
                  AppDimensions.screenPadding,
                  AppDimensions.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset('assets/illustrations/elly-care.png',
                          height: 160),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'Обери, що допоможе прямо зараз',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    _ExerciseCard(
                      icon: Icons.air_rounded,
                      color: AppColors.primary,
                      title: 'Дихаймо разом',
                      subtitle:
                          'Повільне дихання за 2 хвилини заспокоює нервову систему',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BreathingExerciseScreen()),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    _ExerciseCard(
                      icon: Icons.visibility_rounded,
                      color: AppColors.info,
                      title: '5-4-3-2-1',
                      subtitle:
                          'Техніка заземлення — повертає увагу в тут-і-зараз',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Grounding54321Screen()),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    _ExerciseCard(
                      icon: Icons.blur_on_rounded,
                      color: AppColors.accent,
                      title: 'Чистий розум',
                      subtitle:
                          'Проведи пальцем по екрану — і туман розвіється',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ClearMindScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Center(child: Icon(icon, size: 24, color: color)),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
