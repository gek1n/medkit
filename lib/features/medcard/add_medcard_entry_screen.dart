import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/shared_tags_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/plan_access.dart';
import '../../core/utils/rich_note_format.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_entries_repository.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../shared/widgets/assignee_picker.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/field_sheet.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/rich_note_toolbar.dart';
import '../../shared/widgets/space_picker.dart';
import '../../shared/widgets/tags_field.dart';
import '../plans/elly_denied_screen.dart';

class AddMedcardEntryScreen extends ConsumerStatefulWidget {
  final MedcardSection section;
  final MedcardEntry? existing;
  // Крок 4.4.3 плану: коли задано — замість запису в локальну базу
  // компаньйон повертається сюди (щоб надіслати як record_proposal піру),
  // той самий патерн, що вже є в AddMedicationScreen/AddActivityScreen.
  // [section] лишається required і в цьому режимі — це синтетичний розділ
  // піра (peerMedcardSectionsProvider), достатній, щоб знати назву й
  // sectionSyncUuid, куди саме запис додається; переобрати ІНШИЙ розділ
  // піра тут не можна (SpaceChip читає лише локальну базу) — ховається.
  final void Function(MedcardEntriesCompanion draft)? onDraftCreated;
  const AddMedcardEntryScreen({
    super.key,
    required this.section,
    this.existing,
    this.onDraftCreated,
  });

  @override
  ConsumerState<AddMedcardEntryScreen> createState() =>
      _AddMedcardEntryScreenState();
}

class _AddMedcardEntryScreenState extends ConsumerState<AddMedcardEntryScreen> {
  late final TextEditingController _titleController;
  late final RichNoteEditingController _notesController;
  late final TextEditingController _locationController;
  final FocusNode _notesFocusNode = FocusNode();
  List<String> _tags = [];
  List<String> _documentPaths = [];
  late DateTime _recordDate;
  late int _sectionId;
  bool _isSaving = false;
  // #325-доробка: "Чия нотатка" — без ротації, null означає "лише
  // widget.section.memberId". Лише для НОВОГО запису, не draft/edit.
  AssigneeSelection? _assignees;

  // Тайтл на весь екран (#324-доробка "нотатка на весь екран"): за
  // замовчуванням підставляється "Нова нотатка", і поки користувач НЕ
  // торкнувся поля назви вручну — перші 20 символів основного тексту самі
  // підставляються туди. Щойно назву відредаговано вручну — автопідстановка
  // назавжди вимикається для цього сеансу редагування (як і для вже
  // існуючих записів — їхню назву теж ніколи не переписуємо автоматично).
  bool _titleManuallyEdited = false;
  bool _suppressTitleListener = false;
  bool _defaultTitleApplied = false;

  // Смужка чипсів унизу горизонтально скролиться і лежить близько до
  // лівого краю екрана — на iOS її горизонтальний скрол конкурує з
  // системним жестом "смахнути з краю назад" за той самий напрямок руху, і
  // жест назад інколи "перемагає" замість скролу (закриваючи екран
  // напівпадково). Поки палець активно скролить чипси — вимикаємо
  // pop-жест через PopScope (це вимикає й сам розпізнавач свайпу-назад, а
  // не лише його результат), решта екрана лишається зі звичайним
  // свайпом-назад.
  bool _chipStripDragging = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleController = TextEditingController(text: ex?.title ?? '');
    _notesController = RichNoteEditingController(text: ex?.notes ?? '');
    _locationController = TextEditingController(text: ex?.location ?? '');
    _recordDate = ex?.recordDate ?? DateTime.now();
    _sectionId = ex?.sectionId ?? widget.section.id;
    _titleManuallyEdited = ex != null;
    if (ex != null) {
      try {
        _tags = List<String>.from(jsonDecode(ex.tags) as List);
      } catch (_) {}
      try {
        _documentPaths = List<String>.from(
          jsonDecode(ex.documentPaths) as List,
        );
      } catch (_) {}
    }
    _titleController.addListener(() {
      if (_suppressTitleListener) return;
      if (!_titleManuallyEdited) setState(() => _titleManuallyEdited = true);
    });
    _notesController.addListener(_syncTitleFromNotesIfNeeded);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultTitleApplied &&
        widget.existing == null &&
        _titleController.text.isEmpty) {
      _defaultTitleApplied = true;
      _setTitle(context.l10n.newNoteTitle);
    }
  }

  void _setTitle(String text) {
    _suppressTitleListener = true;
    _titleController.text = text;
    _suppressTitleListener = false;
  }

  void _syncTitleFromNotesIfNeeded() {
    if (_titleManuallyEdited) return;
    final body = _notesController.text.trim();
    final newTitle = body.isEmpty
        ? context.l10n.newNoteTitle
        : (body.length <= 20 ? body : body.substring(0, 20));
    if (newTitle != _titleController.text) _setTitle(newTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _notesFocusNode.dispose();
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
    await ref
        .read(medcardEntriesRepositoryProvider)
        .delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterEntryTitleError)),
      );
      return;
    }
    setState(() => _isSaving = true);
    final defaultNotesSectionName = context.l10n.defaultNotesSectionName;
    try {
      await SharedTagsLibraryService.addAll(_tags);
      final notesVal = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      final locationVal = _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim();
      if (widget.onDraftCreated != null) {
        // memberId/sectionId — синтетичні, лише для узгодженості форми;
        // реальні значення на боці піра підставляться при застосуванні
        // record_proposal (FamilyPeerSyncService._insertRecord).
        widget.onDraftCreated!(
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
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final ex = widget.existing;
      if (ex != null) {
        await ref
            .read(medcardEntriesRepositoryProvider)
            .update(
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
        await ref
            .read(medcardEntriesRepositoryProvider)
            .insert(
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

        // #325-доробка: "Чия нотатка" — без ротації, лише локальні
        // (не пір — розділи Поличок у пірів окремі й потребують власного
        // ручного вибору, автоматично для кількох одразу це не зробити
        // безпечно) додатково обрані профілі. Кожен отримує СВІЙ автоматично
        // створений розділ "Нотатки" (той самий #169-механізм) — не
        // _sectionId (той належить member.memberId, чужий FK).
        final extraIds =
            _assignees?.localMemberIds.where(
              (id) => id != widget.section.memberId,
            ) ??
            const [];
        for (final id in extraIds) {
          final defaultSectionId = await ref
              .read(medcardSectionsRepositoryProvider)
              .getOrCreateDefaultNotesSection(id, defaultNotesSectionName);
          await ref
              .read(medcardEntriesRepositoryProvider)
              .insert(
                MedcardEntriesCompanion.insert(
                  sectionId: defaultSectionId,
                  memberId: id,
                  title: title,
                  recordDate: _recordDate,
                  notes: Value(notesVal),
                  tags: Value(jsonEncode(_tags)),
                  location: Value(locationVal),
                  documentPaths: Value(jsonEncode(_documentPaths)),
                ),
              );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))),
        );
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
    if (widget.onDraftCreated == null &&
        isMemberBlockedByPlan(ref, widget.section.memberId)) {
      return const EllyDeniedScreen();
    }
    final isEdit = widget.existing != null;
    return PopScope(
      canPop: !_chipStripDragging,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Заголовок: назад, назва (клікабельна/редагована прямо тут,
              // не окремим полем нижче), видалити, зберегти. ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MkBackButton(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isEdit)
                      GestureDetector(
                        onTap: _delete,
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _isSaving ? null : _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          // Той самий колір, що й MkSaveButton (стандартна
                          // кнопка "Зберегти" по всій медкартці) — лише в
                          // компактній пілюлі, бо цей екран без нижньої
                          // панелі (все в шапці, щоб лишити місце під текст).
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          _isSaving
                              ? context.l10n.savingLabel
                              : context.l10n.saveAction,
                          style: AppTextStyles.labelMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Тіло нотатки — займає весь доступний простір. ──────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _notesController,
                      focusNode: _notesFocusNode,
                      inputFormatters: [RichNoteListContinuationFormatter()],
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        hintText: context.l10n.entryNotesHint,
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.textMuted,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Панель форматування — під нотаткою. ─────────────────────────
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: RichNoteToolbar(
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                ),
              ),

              // ── Решта полів — компактними чіпсами прямо під панеллю. ────────
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  10,
                  AppDimensions.screenPadding,
                  10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification && !_chipStripDragging) {
                      setState(() => _chipStripDragging = true);
                    } else if (n is ScrollEndNotification &&
                        _chipStripDragging) {
                      setState(() => _chipStripDragging = false);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Порядок чипсів: Дата → Фото → Теги → Кому → Де
                        // (SpaceChip — окремо, структурне поле "яка полиця", не
                        // частина цього переліку — лишається одразу за Датою).
                        FieldChip(
                          icon: Icons.calendar_today_rounded,
                          label: context.l10n.entryDateFieldLabel,
                          value: _formatDate(_recordDate),
                          onTap: _pickDate,
                        ),
                        if (widget.onDraftCreated == null) ...[
                          const SizedBox(width: 8),
                          SpaceChip(
                            memberId: widget.section.memberId,
                            sectionId: _sectionId,
                            onChanged: (id) => setState(
                              () => _sectionId = id ?? widget.section.id,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
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
                              onChanged: (paths) =>
                                  setState(() => _documentPaths = paths),
                              label: context.l10n.reminderPhotoLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              loadHistory: SharedTagsLibraryService.getAll,
                            ),
                          ),
                        ),
                        if (widget.onDraftCreated == null &&
                            widget.existing == null) ...[
                          const SizedBox(width: 8),
                          AssigneeFieldChip(
                            selection:
                                _assignees ??
                                AssigneeSelection(
                                  localMemberIds: {widget.section.memberId},
                                  peerPersonUuids: const {},
                                  mode: 'all',
                                ),
                            onTap: () async {
                              final result = await showAssigneePicker(
                                context,
                                showPeers: false,
                                initial:
                                    _assignees ??
                                    AssigneeSelection(
                                      localMemberIds: {widget.section.memberId},
                                      peerPersonUuids: const {},
                                      mode: 'all',
                                    ),
                              );
                              if (result != null)
                                setState(() => _assignees = result);
                            },
                          ),
                        ],
                        const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
