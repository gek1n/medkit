import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/doctor_specialties.dart';

/// Пошуковий пікер напрямку лікаря — заміна вільного `TextField`, щоб
/// значення завжди приходило з контрольованого словника
/// ([doctorSpecialties]) і історію можна було надійно групувати за
/// напрямком. Повертає обраний рядок (включно з довільним текстом, якщо
/// обрано "Інше"), або null, якщо користувач закрив пікер без вибору.
Future<String?> showSpecialtyPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SpecialtyPickerSheet(current: current),
  );
}

class _SpecialtyPickerSheet extends StatefulWidget {
  final String? current;
  const _SpecialtyPickerSheet({required this.current});

  @override
  State<_SpecialtyPickerSheet> createState() => _SpecialtyPickerSheetState();
}

class _SpecialtyPickerSheetState extends State<_SpecialtyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickOther() async {
    final controller = TextEditingController(
      text: doctorSpecialties.contains(widget.current) ? '' : widget.current,
    );
    final custom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Інший напрямок'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Напр. Гомеопат'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Обрати'),
          ),
        ],
      ),
    );
    if (custom != null && custom.isNotEmpty && mounted) {
      Navigator.pop(context, custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = doctorSpecialties
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: Text('Напрямок лікаря', style: AppTextStyles.h3),
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
                    hintText: 'Пошук…',
                    hintStyle: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  style: AppTextStyles.bodyMd,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final s = filtered[index];
                  final isOther = s == otherDoctorSpecialty;
                  final selected = s == widget.current;
                  return ListTile(
                    title: Text(s, style: AppTextStyles.bodyLg),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: isOther
                        ? _pickOther
                        : () => Navigator.pop(context, s),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
