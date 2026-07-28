import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Єдиний стиль кнопки "редагувати" для всіх екранів перегляду (нотатка,
// нагадування, ліки) — іконка-олівець без тла/пілюлі, одразу біля заголовка
// в тому ж рядку. onTap: null вимикає кнопку (напр. під час завантаження).
class MkEditIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  const MkEditIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textSub),
      ),
    );
  }
}

// Єдиний стиль кнопки "видалити"/"зупинити" для тих самих екранів —
// червона іконка кошика в правому куті рядка заголовка (замість окремої
// кнопки внизу екрана чи в формі редагування).
class MkDeleteIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  const MkDeleteIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Icon(Icons.delete_outline_rounded,
            size: 22, color: AppColors.danger),
      ),
    );
  }
}
