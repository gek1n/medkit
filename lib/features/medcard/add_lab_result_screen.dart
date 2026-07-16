import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/attachment_cleanup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/lab_results_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/lab_test_picker.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/specialty_picker.dart';

class AddLabResultScreen extends ConsumerStatefulWidget {
  final int memberId;
  final LabResult? existing;
  const AddLabResultScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddLabResultScreen> createState() => _AddLabResultScreenState();
}

class _AddLabResultScreenState extends ConsumerState<AddLabResultScreen> {
  late final TextEditingController _notesController;
  String? _specialty;
  String? _testName;
  late DateTime _date;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _specialty = ex?.specialty;
    _testName = ex?.testName;
    _date = ex?.takenAt ?? DateTime.now();
    if (ex != null) {
      _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSpecialty() async {
    final picked = await showSpecialtyPicker(context, current: _specialty);
    if (picked != null) setState(() => _specialty = picked);
  }

  Future<void> _pickTestName() async {
    final picked = await showLabTestPicker(context, current: _testName);
    if (picked != null) setState(() => _testName = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showMedcardDatePicker(context, initialDate: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteLabResultConfirmTitle),
        content: Text(context.l10n.deleteWithDocsBody),
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
    await ref.read(labResultsRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_specialty == null || _specialty!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.chooseSpecialtyValue)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final testNameTrimmed = _testName?.trim() ?? '';
      final testNameVal = testNameTrimmed.isEmpty ? null : testNameTrimmed;
      final notesVal = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (widget.existing != null) {
        await ref
            .read(labResultsRepositoryProvider)
            .update(
              LabResultsCompanion(
                id: Value(widget.existing!.id),
                specialty: Value(_specialty!),
                testName: Value(testNameVal),
                takenAt: Value(_date),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        await ref
            .read(labResultsRepositoryProvider)
            .insert(
              LabResultsCompanion.insert(
                memberId: widget.memberId,
                specialty: _specialty!,
                testName: Value(testNameVal),
                takenAt: _date,
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
              ),
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(
              title: (isEdit ? context.l10n.editLabResultTitle : context.l10n.newLabResultTitle) +
                  memberNameSuffix(context, ref, widget.memberId),
              onBack: () => Navigator.pop(context),
              onDelete: isEdit ? _delete : null,
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
                    MkFieldLabel(context.l10n.fieldSpecialty),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: _specialty ?? context.l10n.chooseSpecialtyValue,
                      filled: _specialty != null,
                      onTap: _pickSpecialty,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldTestName),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: _testName ?? context.l10n.chooseTestNameValue,
                      filled: _testName != null,
                      onTap: _pickTestName,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldDate),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: _formatDate(_date),
                      filled: true,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldNotes),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      hint: context.l10n.labResultNotesHint,
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
