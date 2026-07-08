import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Єдина кнопка "назад" для всіх екранів — біле тло, скруглений квадрат,
// іконка-дужка (не стрілка). onTap: null вимикає кнопку (напр. під час
// завантаження) — тут навмисно немає фолбеку на Navigator.pop, щоб не
// приховати цю різницю на викликах, де null означає "заблоковано".
class MkBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const MkBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 16, color: AppColors.textMain),
      ),
    );
  }
}
