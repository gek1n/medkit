import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/task_color.dart';

/// Локальний стан — та сама причина, що й у TagsField/DocumentsSection:
/// коли цей пікер показаний всередині showFieldSheet, setState батьківського
/// екрана не перебудовує вже відкриту шторку (окремий route в Overlay), тож
/// без власного стану обране коло не підсвічувалось би одразу.
class TaskColorPicker extends StatefulWidget {
  final String? selectedHex;
  final ValueChanged<String> onChanged;

  const TaskColorPicker(
      {super.key, required this.selectedHex, required this.onChanged});

  @override
  State<TaskColorPicker> createState() => _TaskColorPickerState();
}

class _TaskColorPickerState extends State<TaskColorPicker> {
  late String? _selectedHex;

  @override
  void initState() {
    super.initState();
    _selectedHex = widget.selectedHex;
  }

  @override
  void didUpdateWidget(covariant TaskColorPicker old) {
    super.didUpdateWidget(old);
    if (old.selectedHex != widget.selectedHex) {
      _selectedHex = widget.selectedHex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.taskColorPickerLabel, style: AppTextStyles.labelSm),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: taskColorPalette.map((hex) {
            final sel = _selectedHex != null &&
                _selectedHex!.toUpperCase() == hex.toUpperCase();
            return GestureDetector(
              onTap: () {
                setState(() => _selectedHex = hex);
                widget.onChanged(hex);
              },
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
