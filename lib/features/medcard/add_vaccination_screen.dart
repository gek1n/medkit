import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/attachment_cleanup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/vaccinations_repository.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../today/providers/today_providers.dart';

class AddVaccinationScreen extends ConsumerStatefulWidget {
  final int memberId;
  final Vaccination? existing;
  const AddVaccinationScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddVaccinationScreen> createState() => _AddVaccinationScreenState();
}

class _AddVaccinationScreenState extends ConsumerState<AddVaccinationScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late DateTime _givenAt;
  DateTime? _nextDoseAt;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _givenAt = ex?.givenAt ?? DateTime.now();
    _nextDoseAt = ex?.nextDoseAt;
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

  Future<void> _pickGivenAt() async {
    final picked = await showMedcardDatePicker(context, initialDate: _givenAt);
    if (picked != null) setState(() => _givenAt = picked);
  }

  Future<void> _pickNextDoseAt() async {
    final now = DateTime.now();
    final picked = await showMedcardDatePicker(
      context,
      initialDate: _nextDoseAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextDoseAt = picked);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteVaccinationConfirmTitle),
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
    final id = widget.existing!.id;
    await NotificationService.cancelVaccinationReminder(id);
    await AttachmentCleanupService.deletePaths(widget.existing!.documentPaths);
    await ref.read(vaccinationsRepositoryProvider).delete(id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.enterVaccinationNameError)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final notesVal = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      int vaccinationId;

      if (widget.existing != null) {
        vaccinationId = widget.existing!.id;
        await ref.read(vaccinationsRepositoryProvider).update(
              VaccinationsCompanion(
                id: Value(vaccinationId),
                name: Value(name),
                givenAt: Value(_givenAt),
                nextDoseAt: Value(_nextDoseAt),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        vaccinationId = await ref.read(vaccinationsRepositoryProvider).insert(
              VaccinationsCompanion.insert(
                memberId: widget.memberId,
                name: name,
                givenAt: _givenAt,
                nextDoseAt: Value(_nextDoseAt),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
              ),
            );
      }

      final nextDoseAt = _nextDoseAt;
      if (nextDoseAt != null) {
        final settings = ref.read(notificationSettingsProvider);
        final members = ref.read(allMembersProvider).valueOrNull ?? [];
        String memberName = '';
        for (final m in members) {
          if (m.id == widget.memberId) {
            memberName = m.name;
            break;
          }
        }
        await NotificationService.scheduleVaccinationReminder(
          vaccinationId: vaccinationId,
          memberName: memberName,
          name: name,
          nextDoseAt: nextDoseAt,
          vibrationEnabled: settings.vibrationEnabled,
        );
      } else {
        await NotificationService.cancelVaccinationReminder(vaccinationId);
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
              title: (isEdit ? context.l10n.editVaccinationTitle : context.l10n.newVaccinationTitle) +
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
                    MkFieldLabel(context.l10n.vaccinationNameField),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _nameController,
                      hint: context.l10n.vaccinationNameHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldDateGiven),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: MKDateUtils.formatDate(context, _givenAt),
                      filled: true,
                      onTap: _pickGivenAt,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Row(
                      children: [
                        Expanded(child: MkFieldLabel(context.l10n.fieldNextDose)),
                        if (_nextDoseAt != null)
                          GestureDetector(
                            onTap: () => setState(() => _nextDoseAt = null),
                            child: Text(
                              context.l10n.removeAction,
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.danger),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MkTapField(
                      value: _nextDoseAt != null ? MKDateUtils.formatDate(context, _nextDoseAt!) : context.l10n.notScheduledValue,
                      filled: _nextDoseAt != null,
                      onTap: _pickNextDoseAt,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    MkFieldLabel(context.l10n.fieldNotes),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      hint: context.l10n.vaccinationNotesHint,
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
