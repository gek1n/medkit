import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/attachment_cleanup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/chronic_conditions_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/specialty_picker.dart';

class AddChronicConditionScreen extends ConsumerStatefulWidget {
  final int memberId;
  final ChronicCondition? existing;
  const AddChronicConditionScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddChronicConditionScreen> createState() => _AddChronicConditionScreenState();
}

class _AddChronicConditionScreenState extends ConsumerState<AddChronicConditionScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  String? _specialty;
  DateTime? _diagnosedAt;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _specialty = ex?.specialty;
    _diagnosedAt = ex?.diagnosedAt;
    if (ex != null) {
      _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSpecialty() async {
    final result = await showSpecialtyPicker(context, current: _specialty);
    if (result != null) setState(() => _specialty = result);
  }

  Future<void> _pickDiagnosedAt() async {
    final picked = await showMedcardDatePicker(context, initialDate: _diagnosedAt ?? DateTime.now());
    if (picked != null) setState(() => _diagnosedAt = picked);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteConditionConfirmTitle),
        content: Text(context.l10n.deleteRecordBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.deleteAction, style: AppTextStyles.bodyMd.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AttachmentCleanupService.deletePaths(widget.existing!.documentPaths);
    await ref.read(chronicConditionsRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.enterConditionNameError)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final notesVal = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (widget.existing != null) {
        await ref.read(chronicConditionsRepositoryProvider).update(
              ChronicConditionsCompanion(
                id: Value(widget.existing!.id),
                name: Value(name),
                specialty: Value(_specialty),
                diagnosedAt: Value(_diagnosedAt),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        await ref.read(chronicConditionsRepositoryProvider).insert(
              ChronicConditionsCompanion.insert(
                memberId: widget.memberId,
                name: name,
                specialty: Value(_specialty),
                diagnosedAt: Value(_diagnosedAt),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
              ),
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))));
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
              title: (isEdit ? context.l10n.editConditionTitle : context.l10n.newConditionTitle) +
                  memberNameSuffix(context, ref, widget.memberId),
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
                    MkFieldLabel(context.l10n.fieldDiagnosis),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _nameController,
                      hint: context.l10n.conditionNameHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldDoctorSpecialty),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: _specialty ?? context.l10n.notSelectedValue,
                      filled: _specialty != null,
                      onTap: _pickSpecialty,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldDiagnosisDate),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: _diagnosedAt != null ? MKDateUtils.formatDate(context, _diagnosedAt!) : context.l10n.notSpecifiedValue,
                      filled: _diagnosedAt != null,
                      onTap: _pickDiagnosedAt,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldNotes),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      hint: context.l10n.conditionNotesHint,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    DocumentsSection(
                      paths: _documentPaths,
                      onChanged: (paths) => setState(() => _documentPaths = paths),
                      label: context.l10n.documentsLabel,
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
