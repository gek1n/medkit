import 'package:flutter/material.dart';

import '../../core/services/lab_test_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Пошуковий пікер назви аналізу — заміна вільного `TextField`, щоб той
/// самий аналіз завжди мав ту саму назву (можна буде надійно зібрати
/// однакові аналізи в один список у майбутньому). Власні назви
/// зберігаються через [LabTestLibraryService] і пропонуються наступного
/// разу — на відміну від `specialty_picker.dart`, де "Інше" одноразове.
Future<String?> showLabTestPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (_) => _LabTestPickerSheet(current: current),
  );
}

class _LabTestPickerSheet extends StatefulWidget {
  final String? current;
  const _LabTestPickerSheet({required this.current});

  @override
  State<_LabTestPickerSheet> createState() => _LabTestPickerSheetState();
}

class _LabTestPickerSheetState extends State<_LabTestPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  List<String> _customNames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custom = await LabTestLibraryService.getCustom();
    if (mounted) {
      setState(() {
        _customNames = custom;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCustom(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await LabTestLibraryService.addCustom(trimmed);
    if (mounted) Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final commonFiltered =
        LabTestLibraryService.common.where((s) => q.isEmpty || s.toLowerCase().contains(q)).toList();
    final customFiltered = _customNames.where((s) => q.isEmpty || s.toLowerCase().contains(q)).toList();
    final exactMatchExists = q.isNotEmpty &&
        (commonFiltered.any((s) => s.toLowerCase() == q) || customFiltered.any((s) => s.toLowerCase() == q));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
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
                child: Text('Назва аналізу', style: AppTextStyles.h3),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Пошук або нова назва…',
                      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    style: AppTextStyles.bodyMd,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        children: [
                          if (q.isNotEmpty && !exactMatchExists)
                            ListTile(
                              leading: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                              title: Text(
                                'Додати «${_searchController.text.trim()}»',
                                style: AppTextStyles.bodyLg.copyWith(
                                    color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                              onTap: () => _addCustom(_searchController.text),
                            ),
                          for (final s in customFiltered)
                            ListTile(
                              title: Text(s, style: AppTextStyles.bodyLg),
                              trailing: s == widget.current
                                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                                  : null,
                              onTap: () => Navigator.pop(context, s),
                            ),
                          for (final s in commonFiltered)
                            ListTile(
                              title: Text(s, style: AppTextStyles.bodyLg),
                              trailing: s == widget.current
                                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                                  : null,
                              onTap: () => Navigator.pop(context, s),
                            ),
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
