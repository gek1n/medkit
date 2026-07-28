import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/attachment_cleanup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/reminder_tags_library_service.dart';
import '../../core/services/reminder_title_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../core/utils/plan_access.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/reminders_repository.dart';
import '../today/providers/today_providers.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/field_sheet.dart';
import '../../shared/widgets/medcard_icon_picker.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/reminder_title_field.dart';
import '../../shared/widgets/space_picker.dart';
import '../../shared/widgets/tags_field.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../plans/elly_denied_screen.dart';

typedef _Slot = TimeOfDay;

/// Об'єднана форма "Нагадування" — заміна окремих Зустрічі/Спорт/Прості
/// завдання. Перше поле після назви — "Коли нагадати" (одноразово/щодня/
/// певні дні тижня/щороку), яке підміняє решту полів розкладу під собою.
class AddAppointmentScreen extends ConsumerStatefulWidget {
  final int memberId;
  final Reminder? existing;
  const AddAppointmentScreen({
    super.key,
    required this.memberId,
    this.existing,
  });

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  List<String> _tags = [];

  // 'none' | 'daily' | 'weekly' | 'yearly'
  String _repeatType = 'none';
  late DateTime _date; // 'none'/'yearly' — рік ігнорується для 'yearly'
  late TimeOfDay _time; // 'none'/'yearly'
  int _remindBeforeMin = 1440;
  List<_Slot> _slots = [const TimeOfDay(hour: 8, minute: 0)]; // 'daily'/'weekly'
  Set<int> _weekdays = {1, 2, 3, 4, 5}; // 'weekly'

  String? _colorHex;
  late String _iconKey;
  int? _sectionId;
  List<String> _documentPaths = [];
  bool _isSaving = false;
  bool _loaded = false;

  bool get _isPastVisit =>
      _repeatType == 'none' &&
      DateTime(_date.year, _date.month, _date.day).isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );

  List<(int, String)> _remindOptions(BuildContext context) {
    final l10n = context.l10n;
    return [
      (60, l10n.remindBefore1Hour),
      (1440, l10n.remindBefore1Day),
      (2880, l10n.remindBefore2Days),
    ];
  }

  static String _dayLabel(BuildContext context, int weekday) {
    final l10n = context.l10n;
    return switch (weekday) {
      1 => l10n.dayMon,
      2 => l10n.dayTue,
      3 => l10n.dayWed,
      4 => l10n.dayThu,
      5 => l10n.dayFri,
      6 => l10n.daySat,
      _ => l10n.daySun,
    };
  }

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleController = TextEditingController(text: ex?.doctorType ?? '');
    _locationController = TextEditingController(text: ex?.location ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _colorHex = ex?.color;
    _iconKey = ex?.iconKey ?? 'calendar';
    _sectionId = ex?.sectionId;
    if (ex != null) {
      _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
      try {
        _tags = List<String>.from(jsonDecode(ex.tags) as List);
      } catch (_) {}
      _repeatType = ex.repeatType;
      _date = ex.scheduledAt;
      _time = TimeOfDay(
        hour: ex.scheduledAt.hour,
        minute: ex.scheduledAt.minute,
      );
      _remindBeforeMin = ex.remindBeforeMin;
      if (_repeatType == 'weekly') {
        try {
          final cfg = jsonDecode(ex.repeatConfig) as Map<String, dynamic>;
          _weekdays = Set<int>.from(cfg['days'] as List);
        } catch (_) {}
      }
      if (_repeatType == 'daily' || _repeatType == 'weekly') {
        _loadSlots(ex.id);
      } else {
        _loaded = true;
      }
    } else {
      _date = DateTime.now();
      _time = const TimeOfDay(hour: 10, minute: 0);
      _loaded = true;
    }
  }

  Future<void> _loadSlots(int reminderId) async {
    final slots =
        await ref.read(remindersRepositoryProvider).getSlotsForReminder(reminderId);
    if (mounted) {
      setState(() {
        if (slots.isNotEmpty) {
          _slots = slots.map((s) {
            final parts = s.timeOfDay.split(':');
            return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }).toList();
        }
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteSurgeryConfirmTitle),
        content: Text(ctx.l10n.deleteAppointmentBody),
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
    await AttachmentCleanupService.deletePaths(widget.existing!.documentPaths);
    await ref.read(remindersRepositoryProvider).delete(widget.existing!.id);
    await NotificationService.cancelAppointmentReminder(widget.existing!.id);
    await NotificationService.cancelRecurringReminder(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    // Дозволяємо минулі дати — цей самий екран використовується і для
    // майбутнього нагадування, і для внесення заднім числом того, що вже
    // відбулось (лише для 'none').
    final picked = await showMedcardDatePicker(
      context,
      initialDate: _date,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showWheelTimePicker(context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickSlotTime(int index) async {
    final picked = await showWheelTimePicker(context, initialTime: _slots[index]);
    if (picked != null) setState(() => _slots[index] = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.enterReminderTitleError)));
      return;
    }
    if ((_repeatType == 'daily' || _repeatType == 'weekly') && _slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addAtLeastOneTimeError)),
      );
      return;
    }
    if (_repeatType == 'weekly' && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseAtLeastOneDayError)),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final scheduledAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      final locationVal = _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim();
      final notesVal = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      final tagsJson = jsonEncode(_tags);
      final repeatConfig = _repeatType == 'weekly'
          ? jsonEncode({'days': _weekdays.toList()..sort()})
          : '{}';

      await ReminderTitleLibraryService.add(title);
      await ReminderTagsLibraryService.addAll(_tags);

      final int reminderId;
      if (widget.existing != null) {
        reminderId = widget.existing!.id;
        await ref.read(remindersRepositoryProvider).update(
              RemindersCompanion(
                id: Value(reminderId),
                doctorType: Value(title),
                tags: Value(tagsJson),
                scheduledAt: Value(scheduledAt),
                location: Value(locationVal),
                remindBeforeMin: Value(_remindBeforeMin),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                color: Value(_colorHex),
                iconKey: Value(_iconKey),
                sectionId: Value(_sectionId),
                repeatType: Value(_repeatType),
                repeatConfig: Value(repeatConfig),
              ),
            );
      } else {
        reminderId = await ref.read(remindersRepositoryProvider).insert(
              RemindersCompanion.insert(
                memberId: widget.memberId,
                doctorType: title,
                tags: Value(tagsJson),
                scheduledAt: scheduledAt,
                location: Value(locationVal),
                remindBeforeMin: Value(_remindBeforeMin),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                color: Value(_colorHex),
                iconKey: Value(_iconKey),
                sectionId: Value(_sectionId),
                repeatType: Value(_repeatType),
                repeatConfig: Value(repeatConfig),
              ),
            );
      }

      final remindersRepo = ref.read(remindersRepositoryProvider);
      if (_repeatType == 'daily' || _repeatType == 'weekly') {
        final slotCompanions = _slots.asMap().entries.map((e) {
          final hh = e.value.hour.toString().padLeft(2, '0');
          final mm = e.value.minute.toString().padLeft(2, '0');
          return ReminderSlotsCompanion.insert(
            reminderId: reminderId,
            timeOfDay: '$hh:$mm',
            sortOrder: Value(e.key),
          );
        }).toList();
        await remindersRepo.replaceSlots(reminderId, slotCompanions);
      } else {
        await remindersRepo.replaceSlots(reminderId, const []);
      }

      final settings = ref.read(notificationSettingsProvider);
      final members = ref.read(allMembersProvider).valueOrNull ?? [];
      String memberName = '';
      for (final m in members) {
        if (m.id == widget.memberId) {
          memberName = m.name;
          break;
        }
      }

      await NotificationService.cancelAppointmentReminder(reminderId);
      await NotificationService.cancelRecurringReminder(reminderId);

      switch (_repeatType) {
        case 'none':
          final rawReminderAt = scheduledAt.subtract(Duration(minutes: _remindBeforeMin));
          final remindAt = settings.adjust(rawReminderAt, memberId: widget.memberId);
          if (remindAt != null) {
            await NotificationService.scheduleAppointmentReminder(
              appointmentId: reminderId,
              memberName: memberName,
              doctorType: title,
              location: locationVal,
              scheduledAt: remindAt,
              remindBeforeMin: 0,
              vibrationEnabled: settings.vibrationEnabled,
              repeatMinutes: settings.repeatMinutes,
            );
          }
          break;
        case 'yearly':
          await NotificationService.scheduleYearlyReminder(
            reminderId: reminderId,
            memberName: memberName,
            title: title,
            location: locationVal,
            date: scheduledAt,
            remindBeforeMin: _remindBeforeMin,
            vibrationEnabled: settings.vibrationEnabled,
          );
          break;
        case 'daily':
          {
            final adjusted = <(int, int)>[];
            for (final t in _slots) {
              final now = DateTime.now();
              final raw = DateTime(now.year, now.month, now.day, t.hour, t.minute);
              final at = settings.adjust(raw, memberId: widget.memberId);
              if (at != null) adjusted.add((at.hour, at.minute));
            }
            if (adjusted.isNotEmpty) {
              await NotificationService.scheduleDailyReminderSlots(
                reminderId: reminderId,
                memberName: memberName,
                title: title,
                slots: adjusted,
                vibrationEnabled: settings.vibrationEnabled,
              );
            }
          }
          break;
        case 'weekly':
          {
            final adjusted = <(int, int)>[];
            for (final t in _slots) {
              final now = DateTime.now();
              final raw = DateTime(now.year, now.month, now.day, t.hour, t.minute);
              final at = settings.adjust(raw, memberId: widget.memberId);
              if (at != null) adjusted.add((at.hour, at.minute));
            }
            if (adjusted.isNotEmpty) {
              await NotificationService.scheduleWeeklyReminderSlots(
                reminderId: reminderId,
                memberName: memberName,
                title: title,
                weekdays: _weekdays.toList(),
                slots: adjusted,
                vibrationEnabled: settings.vibrationEnabled,
              );
            }
          }
          break;
      }

      if (mounted) Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    if (isMemberBlockedByPlan(ref, widget.memberId)) {
      return const EllyDeniedScreen();
    }
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final hh = _time.hour.toString().padLeft(2, '0');
    final mm = _time.minute.toString().padLeft(2, '0');

    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(
              title:
                  (isEdit ? context.l10n.editSurgeryTitle : context.l10n.newAppointmentTitle) +
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
                    // Назва
                    MkFieldLabel(context.l10n.reminderTitleFieldLabel),
                    const SizedBox(height: 6),
                    ReminderTitleField(
                      controller: _titleController,
                      hint: context.l10n.reminderTitleHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Коли нагадати — визначає решту полів розкладу нижче
                    MkFieldLabel(context.l10n.reminderRepeatSectionLabel),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ('none', context.l10n.reminderRepeatOnceLabel),
                        ('daily', context.l10n.reminderRepeatDailyLabel),
                        ('weekly', context.l10n.reminderRepeatWeeklyLabel),
                        ('yearly', context.l10n.reminderRepeatYearlyLabel),
                      ].map((opt) {
                        final sel = _repeatType == opt.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _repeatType = opt.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primaryLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? AppColors.primary : AppColors.border,
                                width: sel ? 2 : 1.5,
                              ),
                            ),
                            child: Text(
                              opt.$2,
                              style: AppTextStyles.labelMd.copyWith(
                                color: sel ? AppColors.primary : AppColors.textMain,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    if (_repeatType == 'none' || _repeatType == 'yearly') ...[
                      MkFieldLabel(
                        _repeatType == 'yearly'
                            ? context.l10n.reminderYearlyDateFieldLabel
                            : context.l10n.fieldDateTime,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: _DateTimeBox(
                                label: context.l10n.dateCapsLabel,
                                value: _formatDate(_date),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickTime,
                              child: _DateTimeBox(label: context.l10n.timeCapsLabel, value: '$hh:$mm'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.lg),
                    ],

                    if (_repeatType == 'weekly') ...[
                      MkFieldLabel(context.l10n.weekdaysLabel),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final sel = _weekdays.contains(day);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (sel) {
                                _weekdays.remove(day);
                              } else {
                                _weekdays.add(day);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: sel ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _dayLabel(context, day),
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: sel ? Colors.white : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                    ],

                    if (_repeatType == 'daily' || _repeatType == 'weekly') ...[
                      MkFieldLabel(context.l10n.reminderTimesFieldLabel),
                      const SizedBox(height: 8),
                      ..._slots.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => _pickSlotTime(e.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 18, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(
                                        context.l10n.timeSlotNumberLabel(e.key + 1),
                                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${e.value.hour.toString().padLeft(2, '0')}:${e.value.minute.toString().padLeft(2, '0')}',
                                        style: AppTextStyles.bodyLg.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (_slots.length > 1) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => setState(() => _slots.removeAt(e.key)),
                                          child: const Icon(Icons.close_rounded,
                                              size: 18, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      GestureDetector(
                        onTap: () => setState(() => _slots.add(
                              TimeOfDay(hour: (8 + _slots.length) % 24, minute: 0),
                            )),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.addAnotherTimeAction,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                    ],

                    // Решта полів — компактними чіпсами
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FieldChip(
                          icon: Icons.notes_rounded,
                          label: context.l10n.noteSingularLabel,
                          value: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                          onTap: () async {
                            await showFieldSheet(
                              context,
                              title: context.l10n.noteSingularLabel,
                              child: MkTextField(
                                controller: _notesController,
                                maxLines: 3,
                                hint: context.l10n.reminderNoteHint,
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                        // Remind before — лише для разового/щорічного (для
                        // щоденного/тижневого нагадування час слоту й Є
                        // моментом нагадування, "заздалегідь" тут не має сенсу.
                        if (_repeatType == 'none' || _repeatType == 'yearly')
                          if (!_isPastVisit)
                            FieldChip(
                              icon: Icons.notifications_outlined,
                              label: context.l10n.remindBeforeLabel,
                              value: _remindOptions(context)
                                  .where((o) => o.$1 == _remindBeforeMin)
                                  .firstOrNull
                                  ?.$2,
                              onTap: () => showFieldSheet(
                                context,
                                title: context.l10n.remindBeforeLabel,
                                child: Wrap(
                                  spacing: 8,
                                  children: _remindOptions(context).map((opt) {
                                    final sel = _remindBeforeMin == opt.$1;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() => _remindBeforeMin = opt.$1);
                                        Navigator.pop(context);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? AppColors.primaryLight
                                              : AppColors.surface,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.border,
                                            width: sel ? 2 : 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          opt.$2,
                                          style: AppTextStyles.labelMd.copyWith(
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.textMain,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        SpaceChip(
                          memberId: widget.memberId,
                          sectionId: _sectionId,
                          onChanged: (id) => setState(() => _sectionId = id),
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
                              loadHistory: ReminderTagsLibraryService.getAll,
                            ),
                          ),
                        ),
                        FieldChip(
                          icon: medcardIconFor(_iconKey),
                          label: context.l10n.taskColorPickerLabel,
                          value: _colorHex,
                          forceLabel: true,
                          swatchColor: colorFromHex(_colorHex),
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.taskColorPickerLabel,
                            child: StatefulBuilder(
                              builder: (sheetContext, setSheetState) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TaskColorPicker(
                                    selectedHex: _colorHex,
                                    onChanged: (hex) {
                                      setState(() => _colorHex = hex);
                                      setSheetState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  MkFieldLabel(context.l10n.sectionIconFieldLabel),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showMedcardIconPicker(
                                        sheetContext,
                                        current: _iconKey,
                                      );
                                      if (picked != null) {
                                        setState(() => _iconKey = picked);
                                        setSheetState(() {});
                                      }
                                    },
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: (colorFromHex(_colorHex) ??
                                                AppColors.primary)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMd,
                                        ),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Icon(
                                        medcardIconFor(_iconKey),
                                        color: colorFromHex(_colorHex) ??
                                            AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    MkSaveButton(
                      isSaving: _isSaving,
                      onPressed: _save,
                      label: isEdit
                          ? context.l10n.saveChangesAction
                          : context.l10n.saveReminderAction,
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
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DateTimeBox extends StatelessWidget {
  final String label;
  final String value;
  const _DateTimeBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSm),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textMain,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
