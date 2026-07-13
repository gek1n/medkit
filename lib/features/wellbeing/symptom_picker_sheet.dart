import 'package:flutter/material.dart';
import '../../core/services/symptom_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Список ~50 поширених симптомів + власні (збережені раніше через
/// SymptomLibraryService) з пошуком та можливістю додати нове — на заміну
/// колишньому Wrap із 8 чипів. Повертає оновлений набір ключів через
/// Navigator.pop, або null якщо закрито без підтвердження.
class SymptomPickerSheet extends StatefulWidget {
  final Set<String> initialSelected;
  const SymptomPickerSheet({super.key, required this.initialSelected});

  @override
  State<SymptomPickerSheet> createState() => _SymptomPickerSheetState();
}

class _SymptomPickerSheetState extends State<SymptomPickerSheet> {
  late final Set<String> _selected = {...widget.initialSelected};
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<String> _customKeys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custom = await SymptomLibraryService.getCustom();
    // Раніше додані custom_-симптоми, яких ще нема у збереженому списку
    // (створені до появи персистентності), теж показуємо — інакше вибрані
    // раніше зникнуть із переліку.
    final legacySelected = _selected
        .where((s) => s.startsWith('custom_'))
        .map((s) => s.substring(7))
        .where((label) => !custom.contains(label));
    if (mounted) {
      setState(() {
        _customKeys = [...custom, ...legacySelected];
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCustom(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    await SymptomLibraryService.addCustom(trimmed);
    setState(() {
      if (!_customKeys.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
        _customKeys.add(trimmed);
      }
      _selected.add('custom_$trimmed');
      _searchCtrl.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final commonFiltered = SymptomLibraryService.common
        .where((s) => q.isEmpty || s.$2.toLowerCase().contains(q))
        .toList();
    final customFiltered = _customKeys
        .where((c) => q.isEmpty || c.toLowerCase().contains(q))
        .toList();
    final exactMatchExists = q.isNotEmpty &&
        (commonFiltered.any((s) => s.$2.toLowerCase() == q) ||
            customFiltered.any((c) => c.toLowerCase() == q));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 0),
                child: Row(
                  children: [
                    Expanded(child: Text('Симптоми', style: AppTextStyles.h3)),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('Готово'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Пошук або нова назва…',
                      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.screenPadding, vertical: 4),
                        children: [
                          if (q.isNotEmpty && !exactMatchExists)
                            _AddCustomRow(query: _searchCtrl.text.trim(), onTap: () => _addCustom(_searchCtrl.text)),
                          for (final c in customFiltered)
                            _SymptomRow(
                              label: c,
                              selected: _selected.contains('custom_$c'),
                              onTap: () => setState(() {
                                final key = 'custom_$c';
                                if (_selected.contains(key)) {
                                  _selected.remove(key);
                                } else {
                                  _selected.add(key);
                                }
                              }),
                            ),
                          for (final s in commonFiltered)
                            _SymptomRow(
                              label: s.$2,
                              selected: _selected.contains(s.$1),
                              onTap: () => setState(() {
                                if (_selected.contains(s.$1)) {
                                  _selected.remove(s.$1);
                                } else {
                                  _selected.add(s.$1);
                                }
                              }),
                            ),
                          if (commonFiltered.isEmpty && customFiltered.isEmpty && q.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Список порожній', style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SymptomRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.border,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: selected ? AppColors.textMain : AppColors.textSub,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomRow extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  const _AddCustomRow({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.add_circle_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Додати «$query»',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
