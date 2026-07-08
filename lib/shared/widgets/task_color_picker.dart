import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/task_color.dart';

class TaskColorPicker extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<String> onChanged;

  const TaskColorPicker(
      {super.key, required this.selectedHex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ЦВІТ КАРТОЧКИ', style: AppTextStyles.labelSm),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: taskColorPalette.map((hex) {
            final sel = selectedHex != null &&
                selectedHex!.toUpperCase() == hex.toUpperCase();
            return GestureDetector(
              onTap: () => onChanged(hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorFromHex(hex),
                  shape: BoxShape.circle,
                  border: sel
                      ? Border.all(color: Colors.black, width: 2.5)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
