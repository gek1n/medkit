import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class MedCardScreen extends StatelessWidget {
  const MedCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_shared_rounded,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                Text('Медкартка', style: AppTextStyles.h2),
                const SizedBox(height: 12),
                Text(
                  'Історія хвороб, виписки лікарів та аналізи\nз\'являться тут незабаром',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
