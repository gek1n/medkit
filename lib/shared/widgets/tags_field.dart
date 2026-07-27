import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Поле довільних тегів — вводяться через кому в текстовому полі, або
/// обираються декілька одразу зі списку раніше вживаних (шторка з
/// чекбоксами). Необов'язкове. [loadHistory] визначає, з якого джерела
/// підтягується історія — різні фічі (нагадування, самопочуття) тримають
/// свої окремі, не пов'язані одна з одною історії тегів.
class TagsField extends StatefulWidget {
  final List<String> tags;
  final void Function(List<String>) onChanged;
  final String hint;
  final Future<List<String>> Function() loadHistory;

  const TagsField({
    super.key,
    required this.tags,
    required this.onChanged,
    required this.hint,
    required this.loadHistory,
  });

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _commitTyped() {
    final raw = _inputController.text;
    if (raw.trim().isEmpty) return;
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final next = [...widget.tags];
    for (final p in parts) {
      if (!next.any((e) => e.toLowerCase() == p.toLowerCase())) next.add(p);
    }
    _inputController.clear();
    widget.onChanged(next);
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  Future<void> _openHistoryPicker() async {
    final history = await widget.loadHistory();
    if (!mounted) return;
    final selected = Set<String>.from(widget.tags);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (ctx) => _TagsHistorySheet(history: history, initiallySelected: selected),
    );
    if (result != null) widget.onChanged(result.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.tags
                .map((t) => Chip(
                      label: Text(t, style: AppTextStyles.bodySm),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide(color: AppColors.primaryLighter),
                      onDeleted: () => _remove(t),
                      deleteIconColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _inputController,
                  onSubmitted: (_) => _commitTyped(),
                  onChanged: (v) {
                    if (v.endsWith(',')) _commitTyped();
                  },
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  style: AppTextStyles.bodyMd,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openHistoryPicker,
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagsHistorySheet extends StatefulWidget {
  final List<String> history;
  final Set<String> initiallySelected;
  const _TagsHistorySheet({required this.history, required this.initiallySelected});

  @override
  State<_TagsHistorySheet> createState() => _TagsHistorySheetState();
}

class _TagsHistorySheetState extends State<_TagsHistorySheet> {
  late Set<String> _selected;
  final _newTagController = TextEditingController();
  late List<String> _allTags;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
    _allTags = [...widget.history];
    for (final t in widget.initiallySelected) {
      if (!_allTags.any((e) => e.toLowerCase() == t.toLowerCase())) _allTags.add(t);
    }
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _addNew() {
    final raw = _newTagController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      if (!_allTags.any((e) => e.toLowerCase() == raw.toLowerCase())) _allTags.add(raw);
      _selected.add(raw);
      _newTagController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(context.l10n.reminderTagsPickerTitle, style: AppTextStyles.h3),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _newTagController,
                          onSubmitted: (_) => _addNew(),
                          decoration: InputDecoration(
                            hintText: context.l10n.addNewTagHint,
                            hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          ),
                          style: AppTextStyles.bodyMd,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addNew,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _allTags.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.noTagsYetLabel,
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _allTags.length,
                        itemBuilder: (context, index) {
                          final t = _allTags[index];
                          final checked = _selected.contains(t);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(t);
                              } else {
                                _selected.remove(t);
                              }
                            }),
                            title: Text(t, style: AppTextStyles.bodyLg),
                            activeColor: AppColors.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.l10n.chooseAction,
                      style: AppTextStyles.labelLg.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
