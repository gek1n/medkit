import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Рядок під заголовком розділу Полички/архіву: пошук зліва (більший) +
/// фільтр тегів з мультивибором справа (менший), з хрестиком скидання,
/// коли обрано хоч один тег. [tagsLoader] викликається щоразу при відкритті
/// шторки вибору — той самий лінивий патерн, що й одиночний
/// _TagFilterChip/_TagFilterSheet, які цей віджет замінює.
class TagSearchFilterBar extends StatefulWidget {
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Future<List<String>> Function() tagsLoader;
  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onTagsChanged;

  const TagSearchFilterBar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    required this.tagsLoader,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  State<TagSearchFilterBar> createState() => _TagSearchFilterBarState();
}

class _TagSearchFilterBarState extends State<TagSearchFilterBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTagPicker() async {
    final tags = await widget.tagsLoader();
    if (!mounted) return;
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MultiTagFilterSheet(
        tags: tags,
        initiallySelected: widget.selectedTags,
      ),
    );
    if (result != null) widget.onTagsChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.selectedTags.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: AppColors.border),
            ),
            // Той самий Container(height: 40, ...), що й у фільтрі тегів
            // нижче, — щоб обидва завжди мали однакову висоту пікселя в
            // піксель. Bare TextField з collapsed-декорацією (без власного
            // border/fill від InputDecorator) замість повноцінного поля —
            // висота рахується самим Container, не InputDecorator.
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    style: AppTextStyles.bodySm,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration.collapsed(
                      hintText: widget.searchHint,
                      hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          flex: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            onTap: _openTagPicker,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: active ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      active
                          ? widget.selectedTags.join(', ')
                          : context.l10n.allTagsFilter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMd.copyWith(
                        color: active ? AppColors.primary : AppColors.textSub,
                      ),
                    ),
                  ),
                  if (active)
                    GestureDetector(
                      onTap: () => widget.onTagsChanged(const {}),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiTagFilterSheet extends StatefulWidget {
  final List<String> tags;
  final Set<String> initiallySelected;
  const _MultiTagFilterSheet({required this.tags, required this.initiallySelected});

  @override
  State<_MultiTagFilterSheet> createState() => _MultiTagFilterSheetState();
}

class _MultiTagFilterSheetState extends State<_MultiTagFilterSheet> {
  late Set<String> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.6,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(context.l10n.reminderTagsPickerTitle, style: AppTextStyles.h3),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selected = {}),
                      child: Text(context.l10n.clearAction),
                    ),
                ],
              ),
            ),
            Expanded(
              child: widget.tags.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.noTagsYetLabel,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: widget.tags.length,
                      itemBuilder: (context, index) {
                        final t = widget.tags[index];
                        final selected = _selected.contains(t);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(t);
                            } else {
                              _selected.remove(t);
                            }
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                          title: Text(t, style: AppTextStyles.bodyLg),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    elevation: 0,
                  ),
                  child: Text(context.l10n.applyAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
