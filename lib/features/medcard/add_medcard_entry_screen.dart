import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/medcard_entry_tag_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/plan_access.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_entries_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/field_sheet.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/space_picker.dart';
import '../../shared/widgets/tags_field.dart';
import '../plans/elly_denied_screen.dart';

class AddMedcardEntryScreen extends ConsumerStatefulWidget {
  final MedcardSection section;
  final MedcardEntry? existing;
  const AddMedcardEntryScreen({super.key, required this.section, this.existing});

  @override
  ConsumerState<AddMedcardEntryScreen> createState() => _AddMedcardEntryScreenState();
}

class _AddMedcardEntryScreenState extends ConsumerState<AddMedcardEntryScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _locationController;
  List<String> _tags = [];
  List<String> _documentPaths = [];
  late DateTime _recordDate;
  late int _sectionId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleController = TextEditingController(text: ex?.title ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _locationController = TextEditingController(text: ex?.location ?? '');
    _recordDate = ex?.recordDate ?? DateTime.now();
    _sectionId = ex?.sectionId ?? widget.section.id;
    if (ex != null) {
      try {
        _tags = List<String>.from(jsonDecode(ex.tags) as List);
      } catch (_) {}
      try {
        _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showMedcardDatePicker(
      context,
      initialDate: _recordDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteSurgeryConfirmTitle),
        content: Text(ctx.l10n.deleteEntryConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.l10n.deleteAction,
              style: AppTextStyles.bodyMd.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(medcardEntriesRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.enterEntryTitleError)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await MedcardEntryTagLibraryService.addAll(_tags);
      final notesVal =
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      final locationVal =
          _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
      final ex = widget.existing;
      if (ex != null) {
        await ref.read(medcardEntriesRepositoryProvider).update(
              MedcardEntriesCompanion(
                id: Value(ex.id),
                sectionId: Value(_sectionId),
                title: Value(title),
                recordDate: Value(_recordDate),
                notes: Value(notesVal),
                tags: Value(jsonEncode(_tags)),
                location: Value(locationVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        await ref.read(medcardEntriesRepositoryProvider).insert(
              MedcardEntriesCompanion.insert(
                sectionId: _sectionId,
                memberId: widget.section.memberId,
                title: title,
                recordDate: _recordDate,
                notes: Value(notesVal),
                tags: Value(jsonEncode(_tags)),
                location: Value(locationVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
              ),
            );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime d) {
    final l10n = context.l10n;
    final months = [
      '',
      l10n.monthGenJan,
      l10n.monthGenFeb,
      l10n.monthGenMar,
      l10n.monthGenApr,
      l10n.monthGenMay,
      l10n.monthGenJun,
      l10n.monthGenJul,
      l10n.monthGenAug,
      l10n.monthGenSep,
      l10n.monthGenOct,
      l10n.monthGenNov,
      l10n.monthGenDec,
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isMemberBlockedByPlan(ref, widget.section.memberId)) {
      return const EllyDeniedScreen();
    }
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(
              title: isEdit ? context.l10n.editEntryTitle : context.l10n.newEntryTitle,
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
                    MkFieldLabel(context.l10n.entryTitleFieldLabel),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _titleController,
                      hint: context.l10n.entryTitleHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Нотатка — окремим завжди розгорнутим полем одразу під
                    // назвою (не чіпсом/шторкою), щоб її було видно й зручно
                    // заповнювати без зайвого тапу.
                    MkFieldLabel(context.l10n.noteSingularLabel),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      maxLines: 4,
                      hint: context.l10n.entryNotesHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Решта полів — компактними чіпсами
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FieldChip(
                          icon: Icons.calendar_today_rounded,
                          label: context.l10n.entryDateFieldLabel,
                          value: _formatDate(_recordDate),
                          onTap: _pickDate,
                        ),
                        FieldChip(
                          icon: Icons.sell_outlined,
                          label: context.l10n.reminderTagsFieldLabel,
                          value: _tags.isEmpty ? null : _tags.join(', '),
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.reminderTagsFieldLabel,
                            child: TagsField(
                              tags: _tags,
                              onChanged: (t) => setState(() => _tags = t),
                              hint: context.l10n.reminderTagsHint,
                              loadHistory: MedcardEntryTagLibraryService.getAll,
                            ),
                          ),
                        ),
                        SpaceChip(
                          memberId: widget.section.memberId,
                          sectionId: _sectionId,
                          onChanged: (id) =>
                              setState(() => _sectionId = id ?? widget.section.id),
                        ),
                        FieldChip(
                          icon: Icons.location_on_outlined,
                          label: context.l10n.fieldWhere,
                          value: _locationController.text.trim().isEmpty
                              ? null
                              : _locationController.text.trim(),
                          onTap: () async {
                            await showFieldSheet(
                              context,
                              title: context.l10n.fieldWhere,
                              child: MkTextField(
                                controller: _locationController,
                                hint: context.l10n.locationHint,
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                        FieldChip(
                          icon: Icons.attach_file_rounded,
                          label: context.l10n.reminderPhotoLabel,
                          value: _documentPaths.isEmpty
                              ? null
                              : '${_documentPaths.length}',
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.reminderPhotoLabel,
                            child: DocumentsSection(
                              paths: _documentPaths,
                              onChanged: (paths) => setState(() => _documentPaths = paths),
                              label: context.l10n.reminderPhotoLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    MkSaveButton(
                      isSaving: _isSaving,
                      onPressed: _save,
                      label: isEdit ? context.l10n.saveChangesAction : context.l10n.saveAction,
                    ),
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
