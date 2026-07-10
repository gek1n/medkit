import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/attachment_cleanup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/allergy_severity.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/allergies_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_form_fields.dart';

class AddAllergyScreen extends ConsumerStatefulWidget {
  final int memberId;
  final Allergy? existing;
  const AddAllergyScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddAllergyScreen> createState() => _AddAllergyScreenState();
}

class _AddAllergyScreenState extends ConsumerState<AddAllergyScreen> {
  late final TextEditingController _allergenController;
  late final TextEditingController _reactionController;
  late final TextEditingController _notesController;
  AllergySeverity _severity = AllergySeverity.mild;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _allergenController = TextEditingController(text: ex?.allergen ?? '');
    _reactionController = TextEditingController(text: ex?.reaction ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    if (ex != null) {
      _severity = AllergySeverity.fromDb(ex.severity);
      _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
    }
  }

  @override
  void dispose() {
    _allergenController.dispose();
    _reactionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити алергію?'),
        content: const Text('Запис буде видалено.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Видалити', style: AppTextStyles.bodyMd.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AttachmentCleanupService.deletePaths(widget.existing!.documentPaths);
    await ref.read(allergiesRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final allergen = _allergenController.text.trim();
    if (allergen.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введіть назву алергену')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final reactionVal =
          _reactionController.text.trim().isEmpty ? null : _reactionController.text.trim();
      final notesVal = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (widget.existing != null) {
        await ref.read(allergiesRepositoryProvider).update(
              AllergiesCompanion(
                id: Value(widget.existing!.id),
                allergen: Value(allergen),
                reaction: Value(reactionVal),
                severity: Value(_severity.name),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        await ref.read(allergiesRepositoryProvider).insert(
              AllergiesCompanion.insert(
                memberId: widget.memberId,
                allergen: allergen,
                reaction: Value(reactionVal),
                severity: Value(_severity.name),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
              ),
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(
              title: (isEdit ? 'Редагувати алергію' : 'Нова алергія') +
                  memberNameSuffix(ref, widget.memberId),
              onBack: () => Navigator.pop(context),
              onDelete: isEdit ? _delete : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MkFieldLabel('Алерген'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _allergenController,
                      hint: 'Пеніцилін, горіхи, пилок…',
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel('Тяжкість'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AllergySeverity.values.map((s) {
                        final sel = s == _severity;
                        return GestureDetector(
                          onTap: () => setState(() => _severity = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? s.bgColor : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? s.color : AppColors.border,
                                width: sel ? 2 : 1.5,
                              ),
                            ),
                            child: Text(
                              s.label,
                              style: AppTextStyles.labelMd.copyWith(
                                color: sel ? s.color : AppColors.textMain,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel('Реакція'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _reactionController,
                      hint: 'Висип, набряк, задишка…',
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel('Нотатки'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      hint: 'Додаткові деталі…',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    DocumentsSection(
                      paths: _documentPaths,
                      onChanged: (paths) => setState(() => _documentPaths = paths),
                      label: 'Документи',
                    ),
                    const SizedBox(height: AppDimensions.xxl),
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
