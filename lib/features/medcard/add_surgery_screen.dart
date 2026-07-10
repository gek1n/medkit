import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/attachment_cleanup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/surgeries_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';

class AddSurgeryScreen extends ConsumerStatefulWidget {
  final int memberId;
  final Surgery? existing;
  const AddSurgeryScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddSurgeryScreen> createState() => _AddSurgeryScreenState();
}

class _AddSurgeryScreenState extends ConsumerState<AddSurgeryScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late DateTime _performedAt;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _performedAt = ex?.performedAt ?? DateTime.now();
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

  Future<void> _pickPerformedAt() async {
    final picked = await showMedcardDatePicker(context, initialDate: _performedAt);
    if (picked != null) setState(() => _performedAt = picked);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити запис?'),
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
    await ref.read(surgeriesRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введіть назву операції')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final notesVal = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (widget.existing != null) {
        await ref.read(surgeriesRepositoryProvider).update(
              SurgeriesCompanion(
                id: Value(widget.existing!.id),
                name: Value(name),
                performedAt: Value(_performedAt),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        await ref.read(surgeriesRepositoryProvider).insert(
              SurgeriesCompanion.insert(
                memberId: widget.memberId,
                name: name,
                performedAt: _performedAt,
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
              title: (isEdit ? 'Редагувати запис' : 'Нова операція чи госпіталізація') +
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
                    MkFieldLabel('Назва'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _nameController,
                      hint: 'Апендектомія, госпіталізація…',
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel('Дата'),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: MKDateUtils.formatDate(_performedAt),
                      filled: true,
                      onTap: _pickPerformedAt,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel('Нотатки'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      hint: 'Лікарня, ускладнення, рекомендації…',
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
