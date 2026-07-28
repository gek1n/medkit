import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../core/utils/plan_access.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/medcard_icon_picker.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../plans/elly_denied_screen.dart';

class AddMedcardSectionScreen extends ConsumerStatefulWidget {
  final int memberId;
  final MedcardSection? existing;
  const AddMedcardSectionScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddMedcardSectionScreen> createState() => _AddMedcardSectionScreenState();
}

class _AddMedcardSectionScreenState extends ConsumerState<AddMedcardSectionScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _commentController;
  late String _iconKey;
  late String _colorHex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _commentController = TextEditingController(text: ex?.comment ?? '');
    _iconKey = ex?.iconKey ?? defaultMedcardIconKey;
    _colorHex = ex?.color ?? taskColorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picked = await showMedcardIconPicker(context, current: _iconKey);
    if (picked != null) setState(() => _iconKey = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.enterSectionNameError)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final commentVal = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();
      final ex = widget.existing;
      final int sectionId;
      if (ex != null) {
        sectionId = ex.id;
        await ref.read(medcardSectionsRepositoryProvider).update(
              MedcardSectionsCompanion(
                id: Value(ex.id),
                name: Value(name),
                iconKey: Value(_iconKey),
                color: Value(_colorHex),
                comment: Value(commentVal),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        sectionId = await ref.read(medcardSectionsRepositoryProvider).insert(
              MedcardSectionsCompanion.insert(
                memberId: widget.memberId,
                name: name,
                iconKey: Value(_iconKey),
                color: Value(_colorHex),
                comment: Value(commentVal),
              ),
            );
      }
      // Повертаємо id (не просто true) — щоб пікер Простору (SpacePicker),
      // якщо саме він відкрив цей екран для створення нового розділу,
      // міг одразу підставити щойно створений розділ як вибраний.
      if (mounted) Navigator.pop(context, sectionId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isMemberBlockedByPlan(ref, widget.memberId)) {
      return const EllyDeniedScreen();
    }
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(
              title: (isEdit ? context.l10n.editSectionTitle : context.l10n.newSectionTitle) +
                  memberNameSuffix(context, ref, widget.memberId),
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MkFieldLabel(context.l10n.sectionNameFieldLabel),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _nameController,
                      hint: context.l10n.sectionNameHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    MkFieldLabel(context.l10n.sectionIconFieldLabel),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickIcon,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (colorFromHex(_colorHex) ?? AppColors.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          medcardIconFor(_iconKey),
                          color: colorFromHex(_colorHex) ?? AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    TaskColorPicker(
                      selectedHex: _colorHex,
                      onChanged: (hex) => setState(() => _colorHex = hex),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    MkFieldLabel(context.l10n.sectionCommentFieldLabel),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _commentController,
                      hint: context.l10n.sectionCommentHint,
                      maxLength: 30,
                    ),
                    const SizedBox(height: 32),

                    MkSaveButton(isSaving: _isSaving, onPressed: _save),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
