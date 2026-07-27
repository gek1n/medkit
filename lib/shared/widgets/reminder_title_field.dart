import 'package:flutter/material.dart';

import '../../core/services/reminder_title_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Поле назви нагадування — звичайний текстовий ввід із підказками з історії
/// раніше введених значень (замість контрольованого словника напрямків
/// лікаря). Можна ввести будь-що нове — це не обмежує, а лише пришвидшує.
class ReminderTitleField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const ReminderTitleField({
    super.key,
    required this.controller,
    required this.hint,
  });

  @override
  State<ReminderTitleField> createState() => _ReminderTitleFieldState();
}

class _ReminderTitleFieldState extends State<ReminderTitleField> {
  List<String> _history = [];
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    ReminderTitleLibraryService.getAll().then((v) {
      if (mounted) setState(() => _history = v);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        if (value.text.trim().isEmpty) return _history;
        final q = value.text.toLowerCase();
        return _history.where((s) => s.toLowerCase().contains(q));
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
            style: AppTextStyles.bodyMd,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option, style: AppTextStyles.bodyMd),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
