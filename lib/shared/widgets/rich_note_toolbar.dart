import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rich_note_format.dart';

/// Панель форматування — під полем нотатки. Працює напряму з
/// [controller]/[focusNode]: жирний/курсив/підкреслений обгортають
/// виділення (або вставляють порожню пару маркерів під курсором), решта —
/// перемикають префікс поточного рядка.
class RichNoteToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const RichNoteToolbar({super.key, required this.controller, required this.focusNode});

  void _inline(String marker) {
    final r = applyInlineMarker(controller.text, controller.selection, marker);
    controller.value = TextEditingValue(text: r.text, selection: r.selection);
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void _line(String Function(String) transform) {
    final r = applyLineToggle(controller.text, controller.selection, transform);
    controller.value = TextEditingValue(text: r.text, selection: r.selection);
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _ToolbarButton(label: 'B', bold: true, onTap: () => _inline('**')),
          _ToolbarButton(label: 'I', italic: true, onTap: () => _inline('*')),
          _ToolbarButton(label: 'U', underline: true, onTap: () => _inline('__')),
          const _ToolbarSeparator(),
          _ToolbarButton(icon: Icons.check_box_outlined, onTap: () => _line(toggleChecklistLine)),
          _ToolbarButton(icon: Icons.format_list_bulleted_rounded, onTap: () => _line(toggleBulletLine)),
          _ToolbarButton(icon: Icons.format_list_numbered_rounded, onTap: () => _line(toggleNumberedLine)),
          const _ToolbarSeparator(),
          _ToolbarButton(icon: Icons.format_quote_rounded, onTap: () => _line(toggleQuoteLine)),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool bold;
  final bool italic;
  final bool underline;
  final VoidCallback onTap;

  const _ToolbarButton({
    this.label,
    this.icon,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 20, color: AppColors.textSub)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  decoration: underline ? TextDecoration.underline : TextDecoration.none,
                  decorationThickness: 2,
                  color: AppColors.textSub,
                ),
              ),
      ),
    );
  }
}

class _ToolbarSeparator extends StatelessWidget {
  const _ToolbarSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.border,
    );
  }
}
