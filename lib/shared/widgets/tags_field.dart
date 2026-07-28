import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Поле довільних тегів — чипси вже доданих тегів + інпут з живими
/// підказками з історії (як почнеш вводити — знизу з'являються відповідні
/// раніше вживані теги, тап одразу додає). Кнопка праворуч відкриває повний
/// список для перегляду/мультивибору й додавання абсолютно нового тега.
/// Необов'язкове поле. [loadHistory] визначає джерело історії — різні фічі
/// (нагадування/нотатки, самопочуття) тримають свої окремі, не пов'язані
/// одна з одною історії тегів.
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
  // Локальна копія — а не пряме читання widget.tags — інакше чипси не
  // оновлювались би одразу, коли це поле показане всередині showFieldSheet:
  // той child будується один раз у момент відкриття шторки, а setState
  // батьківського екрана не перебудовує вже відкритий bottom sheet (окремий
  // route в Overlay). Кожна зміна тут одразу викликає власний setState
  // (миттєвий візуальний фідбек) І widget.onChanged (щоб батько теж знав).
  late List<String> _tags;
  final _inputController = TextEditingController();
  List<String> _history = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _tags = [...widget.tags];
    _inputController.addListener(_updateSuggestions);
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant TagsField old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.tags, widget.tags)) {
      _tags = [...widget.tags];
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await widget.loadHistory();
    if (!mounted) return;
    setState(() => _history = h);
    _updateSuggestions();
  }

  void _updateSuggestions() {
    final query = _inputController.text.trim().toLowerCase();
    final used = _tags.map((t) => t.toLowerCase()).toSet();
    setState(() {
      _suggestions = _history
          .where((t) =>
              !used.contains(t.toLowerCase()) &&
              (query.isEmpty || t.toLowerCase().contains(query)))
          .toList();
    });
  }

  void _addTag(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    if (_tags.any((e) => e.toLowerCase() == v.toLowerCase())) return;
    setState(() => _tags = [..._tags, v]);
    widget.onChanged(_tags);
    _updateSuggestions();
  }

  // Кома як роздільник — дозволяє вставити чи ввести декілька тегів разом.
  void _commitTyped() {
    final raw = _inputController.text;
    if (raw.trim().isEmpty) return;
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final p in parts) {
      if (!_tags.any((e) => e.toLowerCase() == p.toLowerCase())) {
        _tags = [..._tags, p];
      }
    }
    _inputController.clear();
    setState(() {});
    widget.onChanged(_tags);
    _updateSuggestions();
  }

  void _remove(String tag) {
    setState(() => _tags = _tags.where((t) => t != tag).toList());
    widget.onChanged(_tags);
    _updateSuggestions();
  }

  Future<void> _openHistoryPicker() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => _TagsHistorySheet(
        history: _history,
        initiallySelected: Set<String>.from(_tags),
      ),
    );
    if (result == null) return;
    setState(() => _tags = result.toList());
    widget.onChanged(_tags);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags
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
        // Живі підказки — почав вводити (або порожній інпут одразу показує
        // невикористані теги з історії) — тап миттєво додає без ретайпінгу.
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions
                .map((t) => GestureDetector(
                      onTap: () {
                        _addTag(t);
                        _inputController.clear();
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgPage,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(t,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.textSub)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
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
  String _query = '';

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
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _query.isEmpty
        ? _allTags
        : _allTags.where((t) => t.toLowerCase().contains(_query.toLowerCase())).toList();
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
                          onChanged: (v) => setState(() => _query = v),
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
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.noTagsYetLabel,
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final t = visible[index];
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
