import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../shared/widgets/field_sheet.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/space_picker.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../core/utils/plan_access.dart';
import '../plans/elly_denied_screen.dart';
import '../today/providers/today_providers.dart';

typedef _Slot = ({TimeOfDay time, int? duration});

String _formatDuration(BuildContext context, int totalMinutes) {
  final l10n = context.l10n;
  if (totalMinutes < 60) return l10n.durationMinutes(totalMinutes);
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return m == 0 ? l10n.hoursCountLabel(h) : l10n.durationHoursMinutesLabel(h, m);
}

String weekdayLabel(BuildContext context, int weekday) {
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

/// Форма створення/редагування Рутинної справи — гнучкі повтори (щодня/дні
/// тижня/раз на місяць/кожні N днів/N разів на тиждень будь-якими днями),
/// сімейна ротація виконавців, чек-лист підкроків. Легасі-поля старого
/// повного редактора (сітка типів Спорт, YouTube-посилання) прибрані з UI —
/// жоден живий виклик цього екрана вже не використовує compactMode:false.
class AddActivityScreen extends ConsumerStatefulWidget {
  final int memberId;
  final Activity? existing;
  final bool hideTypePicker;
  final String? forcedType;
  final bool compactMode;
  const AddActivityScreen({
    super.key,
    required this.memberId,
    this.existing,
    this.hideTypePicker = false,
    this.forcedType,
    this.compactMode = false,
  });

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  late final TextEditingController _nameController;
  String? _colorHex;
  int? _sectionId;
  bool _reminder = true;
  bool _isSaving = false;
  bool _loaded = false;

  String _repeatType = 'weekly';
  Set<int> _weekdays = {1, 2, 3, 4, 5};
  int _dayOfMonth = DateTime.now().day;
  int _intervalDays = 3;
  int _weeklyGoalCount = 3;

  bool _hasFixedTime = true;
  List<_Slot> _slots = [
    (time: const TimeOfDay(hour: 8, minute: 30), duration: null),
  ];

  List<int> _assigneeIds = [];
  String _rotationMode = 'fixed';
  List<String> _steps = [];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _colorHex = ex?.color;
    if (ex != null) {
      _sectionId = ex.sectionId;
      _reminder = ex.reminderBeforeMin > 0;
      _repeatType = ex.repeatType;
      _dayOfMonth = ex.repeatDayOfMonth ?? DateTime.now().day;
      _intervalDays = ex.repeatIntervalDays ?? 3;
      _weeklyGoalCount = ex.weeklyGoalCount ?? 3;
      _rotationMode = ex.rotationMode;
      try {
        final days = List<int>.from(jsonDecode(ex.repeatDays) as List);
        _weekdays = days.toSet();
      } catch (_) {}
      try {
        final steps = jsonDecode(ex.stepsJson ?? '[]') as List;
        _steps = steps.map((s) => (s as Map)['title'] as String).toList();
      } catch (_) {}
      _loadExisting(ex.id);
    } else {
      _assigneeIds = [widget.memberId];
      _loaded = true;
    }
  }

  Future<void> _loadExisting(int activityId) async {
    final repo = ref.read(activitiesRepositoryProvider);
    final slots = await repo.getSlotsForActivity(activityId);
    final assignees = await repo.getAssignees(activityId);
    if (!mounted) return;
    setState(() {
      if (slots.isNotEmpty) {
        _slots = slots.map((s) {
          final parts = s.timeOfDay.split(':');
          return (
            time: TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            ),
            duration: (s.durationMin == 0) ? null : s.durationMin,
          );
        }).toList();
        _hasFixedTime = true;
      } else {
        _hasFixedTime = false;
      }
      _assigneeIds = assignees.isNotEmpty
          ? assignees.map((a) => a.memberId).toList()
          : [widget.existing!.memberId];
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteActivityConfirmTitle),
        content: Text(context.l10n.deleteActivityConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.deleteAction,
              style: AppTextStyles.bodyMd.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref
        .read(activitiesRepositoryProvider)
        .softDelete(widget.existing!.id);
    ref.invalidate(generateTodayActivityLogsProvider);
    ref.invalidate(tomorrowActivityLogsProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterActivityNameError)),
      );
      return;
    }
    if (_repeatType == 'weekly' && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noDaysSelectedHint)),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(activitiesRepositoryProvider);
      final repeatDaysJson = jsonEncode(_weekdays.toList()..sort());
      final stepsJsonStr = _steps.isEmpty
          ? null
          : jsonEncode(_steps.map((t) => {'title': t}).toList());
      final showTime = _hasFixedTime && _repeatType != 'weeklyGoal';
      final activityDuration =
          showTime && _slots.isNotEmpty ? (_slots.first.duration ?? 0) : 0;
      final int activityId;

      if (widget.existing != null) {
        await repo.updateActivity(
          ActivitiesCompanion(
            id: Value(widget.existing!.id),
            name: Value(name),
            type: const Value('routine'),
            durationMin: Value(activityDuration),
            repeatDays: Value(repeatDaysJson),
            repeatType: Value(_repeatType),
            repeatDayOfMonth:
                Value(_repeatType == 'monthly' ? _dayOfMonth : null),
            repeatIntervalDays:
                Value(_repeatType == 'everyNDays' ? _intervalDays : null),
            weeklyGoalCount:
                Value(_repeatType == 'weeklyGoal' ? _weeklyGoalCount : null),
            rotationMode:
                Value(_assigneeIds.length > 1 ? _rotationMode : 'fixed'),
            stepsJson: Value(stepsJsonStr),
            reminderBeforeMin: Value(_reminder ? 10 : 0),
            color: Value(_colorHex),
            sectionId: Value(_sectionId),
          ),
        );
        activityId = widget.existing!.id;
      } else {
        activityId = await repo.insertActivity(
          ActivitiesCompanion.insert(
            memberId: widget.memberId,
            name: name,
            type: const Value('routine'),
            durationMin: Value(activityDuration),
            repeatDays: Value(repeatDaysJson),
            repeatType: Value(_repeatType),
            repeatDayOfMonth:
                Value(_repeatType == 'monthly' ? _dayOfMonth : null),
            repeatIntervalDays:
                Value(_repeatType == 'everyNDays' ? _intervalDays : null),
            weeklyGoalCount:
                Value(_repeatType == 'weeklyGoal' ? _weeklyGoalCount : null),
            rotationAnchorDate: Value(DateTime.now()),
            rotationMode:
                Value(_assigneeIds.length > 1 ? _rotationMode : 'fixed'),
            stepsJson: Value(stepsJsonStr),
            reminderBeforeMin: Value(_reminder ? 10 : 0),
            color: Value(_colorHex),
            sectionId: Value(_sectionId),
          ),
        );
      }

      final poolIds = _assigneeIds.isEmpty ? [widget.memberId] : _assigneeIds;
      await repo.replaceAssignees(activityId, poolIds);

      final slotsToSave = showTime
          ? _slots.asMap().entries.map((e) {
              final hh = e.value.time.hour.toString().padLeft(2, '0');
              final mm = e.value.time.minute.toString().padLeft(2, '0');
              return ActivitySlotsCompanion.insert(
                activityId: activityId,
                timeOfDay: '$hh:$mm',
                durationMin: Value(e.value.duration ?? 0),
                sortOrder: Value(e.key),
              );
            }).toList()
          : <ActivitySlotsCompanion>[];
      await repo.replaceSlots(activityId, slotsToSave);

      ref.invalidate(generateTodayActivityLogsProvider);
      ref.invalidate(tomorrowActivityLogsProvider);

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

  String _repeatSummary(BuildContext context) {
    switch (_repeatType) {
      case 'daily':
        return context.l10n.reminderRepeatDailyLabel;
      case 'monthly':
        return '${context.l10n.reminderRepeatMonthlyLabel} · $_dayOfMonth';
      case 'everyNDays':
        return context.l10n.routineIntervalDaysValueLabel(_intervalDays);
      case 'weeklyGoal':
        return context.l10n.routineWeeklyGoalValueLabel(_weeklyGoalCount);
      case 'weekly':
      default:
        final sorted = _weekdays.toList()..sort();
        return sorted.isEmpty
            ? context.l10n.noDaysSelectedHint
            : (sorted.length == 7
                ? context.l10n.repeatDaily
                : sorted.map((d) => weekdayLabel(context, d)).join(', '));
    }
  }

  String _assigneeSummary(BuildContext context, List<Member> members) {
    if (_assigneeIds.length <= 1) {
      final id = _assigneeIds.isNotEmpty ? _assigneeIds.first : widget.memberId;
      final m = members.where((x) => x.id == id).firstOrNull;
      return m?.name ?? '';
    }
    return context.l10n.routineRotationSummary(_assigneeIds.length);
  }

  @override
  Widget build(BuildContext context) {
    if (isMemberBlockedByPlan(ref, widget.memberId)) {
      return const EllyDeniedScreen();
    }
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    final isEdit = widget.existing != null;
    final members = ref.watch(allMembersProvider).valueOrNull ?? [];
    final showTime = _hasFixedTime && _repeatType != 'weeklyGoal';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(
              title: (isEdit
                      ? context.l10n.editActivityTitle
                      : context.l10n.newRoutineTitle) +
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
                    // Пояснення, чим рутина відрізняється від разового
                    // нагадування — без цього рядка форма виглядає як
                    // звичайний дубль форми нагадування, і незрозуміло,
                    // навіщо взагалі окремий тип.
                    if (!isEdit)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppDimensions.lg),
                        child: Text(
                          context.l10n.routineFormExplainer,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSub),
                        ),
                      ),
                    _Label(context.l10n.fieldName),
                    const SizedBox(height: 6),
                    _Input(
                      controller: _nameController,
                      hint: context.l10n.activityNameHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FieldChip(
                          icon: Icons.repeat_rounded,
                          label: context.l10n.routineRepeatSectionLabel,
                          value: _repeatSummary(context),
                          forceLabel: true,
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.routineRepeatSectionLabel,
                            child: _ScheduleFieldsSheet(
                              initialRepeatType: _repeatType,
                              initialWeekdays: _weekdays,
                              initialDayOfMonth: _dayOfMonth,
                              initialIntervalDays: _intervalDays,
                              initialWeeklyGoalCount: _weeklyGoalCount,
                              initialHasFixedTime: _hasFixedTime,
                              initialSlots: _slots,
                              onChanged: (v) => setState(() {
                                _repeatType = v.repeatType;
                                _weekdays = v.weekdays;
                                _dayOfMonth = v.dayOfMonth;
                                _intervalDays = v.intervalDays;
                                _weeklyGoalCount = v.weeklyGoalCount;
                                _hasFixedTime = v.hasFixedTime;
                                _slots = v.slots;
                              }),
                            ),
                          ),
                        ),
                        // Хто виконує/Кроки — те, що реально відрізняє
                        // рутину від нагадування (сімейна ротація,
                        // чек-лист), тож стоять одразу після розкладу, а
                        // не в кінці серед косметичних полів.
                        FieldChip(
                          icon: Icons.people_outline_rounded,
                          label: context.l10n.routineWhoDoesLabel,
                          value: _assigneeSummary(context, members),
                          forceLabel: _assigneeIds.length <= 1,
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.routineWhoDoesLabel,
                            child: _AssigneesSheet(
                              members: members,
                              initialSelected: _assigneeIds,
                              initialRotationMode: _rotationMode,
                              onChanged: (ids, mode) => setState(() {
                                _assigneeIds = ids;
                                _rotationMode = mode;
                              }),
                            ),
                          ),
                        ),
                        FieldChip(
                          icon: Icons.checklist_rounded,
                          label: context.l10n.routineStepsLabel,
                          value: _steps.isEmpty ? null : '${_steps.length}',
                          forceLabel: _steps.isEmpty,
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.routineStepsSheetTitle,
                            child: _StepsSheet(
                              initialSteps: _steps,
                              onChanged: (steps) =>
                                  setState(() => _steps = steps),
                            ),
                          ),
                        ),
                        if (showTime)
                          FieldChip(
                            icon: Icons.notifications_outlined,
                            label: context.l10n.reminderLabel,
                            value: _reminder ? 'on' : null,
                            forceLabel: true,
                            onTap: () => setState(() => _reminder = !_reminder),
                          ),
                        FieldChip(
                          icon: Icons.palette_outlined,
                          label: context.l10n.taskColorPickerLabel,
                          value: _colorHex,
                          forceLabel: true,
                          swatchColor: colorFromHex(_colorHex),
                          onTap: () => showFieldSheet(
                            context,
                            title: context.l10n.taskColorPickerLabel,
                            child: TaskColorPicker(
                              selectedHex: _colorHex,
                              onChanged: (hex) =>
                                  setState(() => _colorHex = hex),
                            ),
                          ),
                        ),
                        SpaceChip(
                          memberId: widget.memberId,
                          sectionId: _sectionId,
                          onChanged: (id) => setState(() => _sectionId = id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
                          _isSaving
                              ? context.l10n.savingLabel
                              : (isEdit
                                  ? context.l10n.saveChangesAction
                                  : context.l10n.saveActivityAction),
                          style: AppTextStyles.labelLg.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
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

// ─── Розклад: тип повтору + залежні поля + час ─────────────────────────────

typedef _ScheduleValues = ({
  String repeatType,
  Set<int> weekdays,
  int dayOfMonth,
  int intervalDays,
  int weeklyGoalCount,
  bool hasFixedTime,
  List<_Slot> slots,
});

class _ScheduleFieldsSheet extends StatefulWidget {
  final String initialRepeatType;
  final Set<int> initialWeekdays;
  final int initialDayOfMonth;
  final int initialIntervalDays;
  final int initialWeeklyGoalCount;
  final bool initialHasFixedTime;
  final List<_Slot> initialSlots;
  final ValueChanged<_ScheduleValues> onChanged;

  const _ScheduleFieldsSheet({
    required this.initialRepeatType,
    required this.initialWeekdays,
    required this.initialDayOfMonth,
    required this.initialIntervalDays,
    required this.initialWeeklyGoalCount,
    required this.initialHasFixedTime,
    required this.initialSlots,
    required this.onChanged,
  });

  @override
  State<_ScheduleFieldsSheet> createState() => _ScheduleFieldsSheetState();
}

class _ScheduleFieldsSheetState extends State<_ScheduleFieldsSheet> {
  late String _repeatType;
  late Set<int> _weekdays;
  late int _dayOfMonth;
  late int _intervalDays;
  late int _weeklyGoalCount;
  late bool _hasFixedTime;
  late List<_Slot> _slots;

  @override
  void initState() {
    super.initState();
    _repeatType = widget.initialRepeatType;
    _weekdays = {...widget.initialWeekdays};
    _dayOfMonth = widget.initialDayOfMonth;
    _intervalDays = widget.initialIntervalDays;
    _weeklyGoalCount = widget.initialWeeklyGoalCount;
    _hasFixedTime = widget.initialHasFixedTime;
    _slots = [...widget.initialSlots];
  }

  void _emit() {
    widget.onChanged((
      repeatType: _repeatType,
      weekdays: _weekdays,
      dayOfMonth: _dayOfMonth,
      intervalDays: _intervalDays,
      weeklyGoalCount: _weeklyGoalCount,
      hasFixedTime: _hasFixedTime,
      slots: _slots,
    ));
  }

  static const _options = [
    ('daily', Icons.today_rounded),
    ('weekly', Icons.view_week_rounded),
    ('monthly', Icons.calendar_month_rounded),
    ('everyNDays', Icons.repeat_rounded),
    ('weeklyGoal', Icons.flag_rounded),
  ];

  String _optionLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (type) {
      'daily' => l10n.reminderRepeatDailyLabel,
      'weekly' => l10n.reminderRepeatWeeklyLabel,
      'monthly' => l10n.reminderRepeatMonthlyLabel,
      'everyNDays' => l10n.routineRepeatEveryNDaysOption,
      _ => l10n.routineRepeatWeeklyGoalOption,
    };
  }

  Future<void> _openRepeatTypeSheet() async {
    await showFieldSheet(
      context,
      title: context.l10n.routineRepeatSectionLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((opt) {
          final sel = _repeatType == opt.$1;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(opt.$2,
                size: 22, color: sel ? AppColors.primary : AppColors.textMuted),
            title: Text(
              _optionLabel(context, opt.$1),
              style: AppTextStyles.bodyMd.copyWith(
                color: sel ? AppColors.primary : AppColors.textMain,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            trailing: sel
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () {
              setState(() => _repeatType = opt.$1);
              _emit();
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickTime(int index) async {
    final picked = await showWheelTimePicker(
      context,
      initialTime: _slots[index].time,
    );
    if (picked != null) {
      setState(() {
        _slots[index] = (time: picked, duration: _slots[index].duration);
      });
      _emit();
    }
  }

  Future<void> _pickDuration(int index) async {
    final current = _slots[index].duration;
    final picked = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DurationPicker(current: current),
    );
    if (!mounted) return;
    setState(() {
      _slots[index] = (
        time: _slots[index].time,
        duration: picked == -1 ? null : (picked ?? _slots[index].duration),
      );
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _openRepeatTypeSheet,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _optionLabel(context, _repeatType),
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        if (_repeatType == 'weekly') ...[
          _Label(context.l10n.weekdaysLabel),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = i + 1;
              final sel = _weekdays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _weekdays.remove(day);
                    } else {
                      _weekdays.add(day);
                    }
                  });
                  _emit();
                },
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
                      weekdayLabel(context, day),
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
        if (_repeatType == 'monthly') ...[
          _Label(context.l10n.reminderMonthlyDayFieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(31, (i) {
              final day = i + 1;
              final sel = _dayOfMonth == day;
              return GestureDetector(
                onTap: () {
                  setState(() => _dayOfMonth = day);
                  _emit();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
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
        if (_repeatType == 'everyNDays') ...[
          _Label(context.l10n.routineIntervalDaysValueLabel(_intervalDays)),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  setState(() =>
                      _intervalDays = (_intervalDays - 1).clamp(1, 90));
                  _emit();
                },
              ),
              Expanded(
                child: Center(
                  child: Text('$_intervalDays', style: AppTextStyles.h3),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: () {
                  setState(() =>
                      _intervalDays = (_intervalDays + 1).clamp(1, 90));
                  _emit();
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
        if (_repeatType == 'weeklyGoal') ...[
          _Label(
              context.l10n.routineWeeklyGoalValueLabel(_weeklyGoalCount)),
          const SizedBox(height: 8),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  setState(() =>
                      _weeklyGoalCount = (_weeklyGoalCount - 1).clamp(1, 7));
                  _emit();
                },
              ),
              Expanded(
                child: Center(
                  child: Text('$_weeklyGoalCount', style: AppTextStyles.h3),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: () {
                  setState(() =>
                      _weeklyGoalCount = (_weeklyGoalCount + 1).clamp(1, 7));
                  _emit();
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
        if (_repeatType != 'weeklyGoal') ...[
          _Label(context.l10n.routineTimeFieldLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeToggle(
                  label: context.l10n.routineFixedTimeOption,
                  selected: _hasFixedTime,
                  onTap: () {
                    setState(() {
                      _hasFixedTime = true;
                      if (_slots.isEmpty) {
                        _slots = [
                          (
                            time: const TimeOfDay(hour: 8, minute: 30),
                            duration: null
                          ),
                        ];
                      }
                    });
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeToggle(
                  label: context.l10n.routineNoFixedTimeOption,
                  selected: !_hasFixedTime,
                  onTap: () {
                    setState(() {
                      _hasFixedTime = false;
                      _slots = [];
                    });
                    _emit();
                  },
                ),
              ),
            ],
          ),
          if (_hasFixedTime) ...[
            const SizedBox(height: AppDimensions.md),
            ..._slots.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActivitySlot(
                      index: e.key,
                      time: e.value.time,
                      duration: e.value.duration,
                      onTimeTap: () => _pickTime(e.key),
                      onDurationTap: () => _pickDuration(e.key),
                      onRemove: _slots.length > 1
                          ? () {
                              setState(() => _slots.removeAt(e.key));
                              _emit();
                            }
                          : null,
                    ),
                  ),
                ),
            GestureDetector(
              onTap: () {
                setState(() => _slots.add((
                      time: TimeOfDay(hour: (8 + _slots.length) % 24, minute: 0),
                      duration: null,
                    )));
                _emit();
              },
              child: _DashedAdd(context.l10n.addAnotherActivityAction),
            ),
          ],
          const SizedBox(height: AppDimensions.lg),
        ],
      ],
    );
  }
}

class _TimeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.primary : AppColors.textSub,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      );
}

// ─── Хто виконує: фіксований виконавець або ротація ────────────────────────

class _AssigneesSheet extends StatefulWidget {
  final List<Member> members;
  final List<int> initialSelected;
  final String initialRotationMode;
  final void Function(List<int> ids, String rotationMode) onChanged;

  const _AssigneesSheet({
    required this.members,
    required this.initialSelected,
    required this.initialRotationMode,
    required this.onChanged,
  });

  @override
  State<_AssigneesSheet> createState() => _AssigneesSheetState();
}

class _AssigneesSheetState extends State<_AssigneesSheet> {
  late List<int> _selected;
  late String _rotationMode;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.initialSelected];
    _rotationMode = widget.initialRotationMode;
  }

  void _emit() => widget.onChanged(_selected, _rotationMode);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.members.map((m) {
          final sel = _selected.contains(m.id);
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            value: sel,
            title: Text(m.name, style: AppTextStyles.bodyMd),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  if (!_selected.contains(m.id)) _selected.add(m.id);
                } else {
                  _selected.remove(m.id);
                }
              });
              _emit();
            },
          );
        }),
        if (_selected.length > 1) ...[
          const SizedBox(height: 8),
          _Label(context.l10n.routineRotationCadenceLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('perOccurrence', context.l10n.routineRotationCadencePerOccurrence),
              ('weekly', context.l10n.routineRotationCadenceWeekly),
              ('monthly', context.l10n.routineRotationCadenceMonthly),
            ].map((opt) {
              final sel = _rotationMode == opt.$1;
              return GestureDetector(
                onTap: () {
                  setState(() => _rotationMode = opt.$1);
                  _emit();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    opt.$2,
                    style: AppTextStyles.labelMd.copyWith(
                      color: sel ? AppColors.primary : AppColors.textSub,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Кроки виконання ────────────────────────────────────────────────────────

class _StepsSheet extends StatefulWidget {
  final List<String> initialSteps;
  final ValueChanged<List<String>> onChanged;
  const _StepsSheet({required this.initialSteps, required this.onChanged});

  @override
  State<_StepsSheet> createState() => _StepsSheetState();
}

class _StepsSheetState extends State<_StepsSheet> {
  late List<String> _steps;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _steps = [...widget.initialSteps];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    setState(() => _steps.add(v));
    widget.onChanged(_steps);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.value, style: AppTextStyles.bodyMd),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _steps.removeAt(e.key));
                      widget.onChanged(_steps);
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            )),
        if (_steps.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Input(
                controller: _controller,
                hint: context.l10n.routineAddStepHint,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _add,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Слот часу ──────────────────────────────────────────────────────────────

class _ActivitySlot extends StatelessWidget {
  final int index;
  final TimeOfDay time;
  final int? duration;
  final VoidCallback onTimeTap;
  final VoidCallback onDurationTap;
  final VoidCallback? onRemove;

  const _ActivitySlot({
    required this.index,
    required this.time,
    required this.duration,
    required this.onTimeTap,
    required this.onDurationTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.activitySessionNumberLabel(index + 1),
                style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Text(
                    context.l10n.removePhaseAction,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SlotField(
                  label: context.l10n.detailLabelTime,
                  value: '$hh:$mm',
                  onTap: onTimeTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotField(
                  label: context.l10n.detailLabelDuration,
                  value: duration != null
                      ? _formatDuration(context, duration!)
                      : '—',
                  hint: duration == null,
                  onTap: onDurationTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Тривалість ─────────────────────────────────────────────────────────────

class _DurationPicker extends StatefulWidget {
  final int? current;
  const _DurationPicker({this.current});

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  static const _minuteOptions = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  late bool _notSpecified;
  late int _hours;
  late int _minuteIdx;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    final cur = widget.current;
    _notSpecified = cur == null || cur == 0;
    _hours = _notSpecified ? 0 : (cur! ~/ 60).clamp(0, 3);
    final rawMin = _notSpecified ? 0 : (cur! % 60);
    _minuteIdx = (_minuteOptions.indexOf(rawMin)).clamp(0, _minuteOptions.length - 1);
    if (_minuteIdx < 0) _minuteIdx = 0;
    _hourCtrl = FixedExtentScrollController(initialItem: _hours);
    _minCtrl = FixedExtentScrollController(initialItem: _minuteIdx);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  int get _totalMin => _hours * 60 + _minuteOptions[_minuteIdx];

  void _confirm() {
    if (_notSpecified) {
      Navigator.pop(context, -1);
    } else {
      final total = _totalMin;
      Navigator.pop(context, total == 0 ? -1 : total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.detailLabelDuration, style: AppTextStyles.h3),
                    Text(
                      context.l10n.optionalLabel,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _notSpecified = !_notSpecified),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _notSpecified ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _notSpecified ? AppColors.primary : AppColors.border,
                      width: _notSpecified ? 2 : 1.5,
                    ),
                  ),
                  child: Text(
                    context.l10n.notSpecifiedValue,
                    style: AppTextStyles.labelMd.copyWith(
                      color: _notSpecified ? AppColors.primary : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _notSpecified ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _notSpecified,
              child: SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _PickerHighlight(),
                          ListWheelScrollView.useDelegate(
                            controller: _hourCtrl,
                            itemExtent: 44,
                            perspective: 0.003,
                            diameterRatio: 1.8,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setState(() => _hours = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 4,
                              builder: (_, i) => Center(
                                child: Text(
                                  context.l10n.hoursCountLabel(i),
                                  style: AppTextStyles.bodyLg.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _hours == i ? AppColors.primary : AppColors.textSub,
                                    fontSize: _hours == i ? 18 : 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _PickerHighlight(),
                          ListWheelScrollView.useDelegate(
                            controller: _minCtrl,
                            itemExtent: 44,
                            perspective: 0.003,
                            diameterRatio: 1.8,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setState(() => _minuteIdx = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: _minuteOptions.length,
                              builder: (_, i) {
                                final sel = _minuteIdx == i;
                                return Center(
                                  child: Text(
                                    context.l10n.minutesWithValueLabel(
                                      _minuteOptions[i].toString().padLeft(2, '0'),
                                    ),
                                    style: AppTextStyles.bodyLg.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: sel ? AppColors.primary : AppColors.textSub,
                                      fontSize: sel ? 18 : 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _notSpecified
                    ? context.l10n.noDurationLabel
                    : context.l10n.saveWithDurationLabel(_formatDuration(context, _totalMin)),
                style: AppTextStyles.labelLg.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerHighlight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ─── Спільні дрібні віджети ─────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  const _BackHeader({required this.title, required this.onBack, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppTextStyles.h3)),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36,
                height: 36,
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
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);

  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: AppTextStyles.labelSm);
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Input({required this.controller, required this.hint});

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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        style: AppTextStyles.bodyMd,
      ),
    );
  }
}

class _SlotField extends StatelessWidget {
  final String label;
  final String value;
  final bool hint;
  final VoidCallback? onTap;
  const _SlotField({
    required this.label,
    required this.value,
    this.hint = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value,
              style: AppTextStyles.labelMd.copyWith(
                color: hint ? AppColors.textMuted : AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedAdd extends StatelessWidget {
  final String label;
  const _DashedAdd(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '＋',
            style: AppTextStyles.bodyMd.copyWith(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
