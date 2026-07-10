import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/lab_results_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/specialty_picker.dart';

class AddLabResultScreen extends ConsumerStatefulWidget {
  final int memberId;
  final LabResult? existing;
  const AddLabResultScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddLabResultScreen> createState() => _AddLabResultScreenState();
}

class _AddLabResultScreenState extends ConsumerState<AddLabResultScreen> {
  late final TextEditingController _testNameController;
  late final TextEditingController _notesController;
  String? _specialty;
  late DateTime _date;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _testNameController = TextEditingController(text: ex?.testName ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _specialty = ex?.specialty;
    _date = ex?.takenAt ?? DateTime.now();
    if (ex != null) {
      _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
    }
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSpecialty() async {
    final picked = await showSpecialtyPicker(context, current: _specialty);
    if (picked != null) setState(() => _specialty = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_specialty == null || _specialty!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Оберіть напрямок')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final testNameVal = _testNameController.text.trim().isEmpty
          ? null
          : _testNameController.text.trim();
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
        ).showSnackBar(SnackBar(content: Text('Помилка: $e')));
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
            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (isEdit ? 'Редагувати аналіз' : 'Новий аналіз') +
                          memberNameSuffix(ref, widget.memberId),
                      style: AppTextStyles.h3,
                    ),
                  ),
                ],
              ),
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
                    _Label('Напрямок'),
                    const SizedBox(height: 6),
                    _TapField(
                      value: _specialty ?? 'Оберіть напрямок',
                      filled: _specialty != null,
                      onTap: _pickSpecialty,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _Label('Назва аналізу'),
                    const SizedBox(height: 6),
                    _TextInput(
                      controller: _testNameController,
                      hint: 'Загальний аналіз крові…',
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _Label('Дата'),
                    const SizedBox(height: 6),
                    _TapField(
                      value: _formatDate(_date),
                      filled: true,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _Label('Нотатки'),
                    const SizedBox(height: 6),
                    _TextInput(
                      controller: _notesController,
                      hint: 'Результати, коментар лікаря…',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    DocumentsSection(
                      paths: _documentPaths,
                      onChanged: (paths) =>
                          setState(() => _documentPaths = paths),
                      label: 'Документи',
                    ),
                    const SizedBox(height: AppDimensions.xxl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSaving ? 'Зберігаємо...' : 'Зберегти',
                          style: AppTextStyles.labelLg.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTextStyles.labelSm);
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _TextInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
        style: AppTextStyles.bodyMd,
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final String value;
  final bool filled;
  final VoidCallback onTap;
  const _TapField({
    required this.value,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  color: filled ? AppColors.textMain : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
