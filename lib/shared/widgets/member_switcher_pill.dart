import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import 'section_label.dart';

/// Пілюля з аватаром/іменем активного профілю — відкриває [_MemberPickerSheet]
/// для швидкого перемикання між локальними профілями. Спільна для екранів,
/// де потрібно переглядати дані одного конкретного члена сім'ї за раз
/// (Розклад, Медкартка).
class MemberSwitcherPill extends StatelessWidget {
  final List<Member> members;
  final Member selected;
  final void Function(int) onSelect;

  const MemberSwitcherPill({
    super.key,
    required this.members,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _MemberPickerSheet(
          members: members,
          selectedId: selected.id,
          onSelect: onSelect,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarImage(index: selected.avatarIndex, size: 20),
            const SizedBox(width: 6),
            Text(selected.name, style: AppTextStyles.labelMd),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerSheet extends StatelessWidget {
  final List<Member> members;
  final int selectedId;
  final void Function(int) onSelect;

  const _MemberPickerSheet({
    required this.members,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SectionLabel(context.l10n.chooseProfileLabel),
            ),
            ...members.map((m) {
              final sel = m.id == selectedId;
              return ListTile(
                onTap: () {
                  onSelect(m.id);
                  Navigator.pop(context);
                },
                leading: AvatarImage(index: m.avatarIndex, size: 36),
                title: Text(m.name,
                    style: AppTextStyles.bodyMd.copyWith(
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400)),
                trailing: sel
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
