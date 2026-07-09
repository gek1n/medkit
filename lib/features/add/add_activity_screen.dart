import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../../core/utils/plan_access.dart';
import '../plans/elly_denied_screen.dart';
import '../today/providers/today_providers.dart';

class AddActivityScreen extends ConsumerStatefulWidget {
  final int memberId;
  final Activity? existing;
  const AddActivityScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

typedef _Slot = ({TimeOfDay time, int? duration});

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  String? _type;
  late final TextEditingController _nameController;
  late final TextEditingController _youtubeController;
  String? _colorHex;
  List<_Slot> _slots = [(time: const TimeOfDay(hour: 8, minute: 30), duration: null)];
  Set<int> _weekdays = {1, 2, 3, 4, 5};
  bool _reminder = true;
  bool _isSaving = false;
  bool _loaded = false;

  static const _types = [
    ('walk', Icons.directions_walk_rounded, 'Прогулянка'),
    ('workout', Icons.fitness_center_rounded, 'Зарядка'),
    ('gym', Icons.fitness_center_rounded, 'Тренування'),
    ('yoga', Icons.self_improvement_rounded, 'Йога / ЛФК'),
    ('cycling', Icons.directions_bike_rounded, 'Велосипед'),
    ('custom', Icons.add_rounded, 'Своє'),
  ];

  static const _dayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _youtubeController = TextEditingController(text: ex?.youtubeUrl ?? '');
    _colorHex = ex?.color;
    if (ex != null) {
      _type = ex.type;
      _reminder = (ex.reminderBeforeMin ?? 0) > 0;
      try {
        final days = List<int>.from(jsonDecode(ex.repeatDays ?? '[]') as List);
        _weekdays = days.toSet();
      } catch (_) {}
      _loadSlots(ex.id);
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadSlots(int activityId) async {
    final slots = await ref
        .read(activitiesRepositoryProvider)
        .getSlotsForActivity(activityId);
    if (mounted) {
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
        }
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити активність?'),
        content: const Text('Активність буде вилучена з розкладу.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Видалити',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref
        .read(activitiesRepositoryProvider)
        .softDelete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_type == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Оберіть тип активності')));
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введіть назву активності')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(activitiesRepositoryProvider);
      final repeatDays = jsonEncode(_weekdays.toList()..sort());
      final youtubeUrl = _youtubeController.text.trim();
      final int activityId;

      if (widget.existing != null) {
        await repo.updateActivity(ActivitiesCompanion(
          id: Value(widget.existing!.id),
          name: Value(name),
          type: Value(_type!),
          repeatDays: Value(repeatDays),
          reminderBeforeMin: Value(_reminder ? 10 : 0),
          youtubeUrl: Value(youtubeUrl.isEmpty ? null : youtubeUrl),
          color: Value(_colorHex),
        ));
        activityId = widget.existing!.id;
      } else {
        activityId = await repo.insertActivity(ActivitiesCompanion.insert(
          memberId: widget.memberId,
          name: name,
          type: Value(_type!),
          repeatDays: Value(repeatDays),
          reminderBeforeMin: Value(_reminder ? 10 : 0),
          youtubeUrl: Value(youtubeUrl.isEmpty ? null : youtubeUrl),
          color: Value(_colorHex),
        ));
      }

      final slots = _slots.asMap().entries.map((e) {
        final hh = e.value.time.hour.toString().padLeft(2, '0');
        final mm = e.value.time.minute.toString().padLeft(2, '0');
        return ActivitySlotsCompanion.insert(
          activityId: activityId,
          timeOfDay: '$hh:$mm',
          durationMin: Value(e.value.duration ?? 0),
          sortOrder: Value(e.key),
        );
      }).toList();
      await repo.replaceSlots(activityId, slots);

      ref.invalidate(generateTodayActivityLogsProvider);
      ref.invalidate(tomorrowActivityLogsProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Помилка: $e')));
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
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(
              title: isEdit ? 'Редагувати активність' : 'Активність',
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
                    // Type grid
                    _Label('Тип активності'),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.2,
                      children: _types.map((t) {
                        final sel = _type != null && _type == t.$1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = t.$1;
                              if (t.$1 != 'custom' &&
                                  _nameController.text.trim().isEmpty) {
                                _nameController.text = t.$3;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? AppColors.success
                                    : AppColors.border,
                                width: sel ? 2 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(t.$2,
                                    size: 22,
                                    color: sel
                                        ? const Color(0xFF15803D)
                                        : AppColors.textMuted),
                                const SizedBox(height: 4),
                                Text(
                                  t.$3,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: sel
                                        ? const Color(0xFF15803D)
                                        : AppColors.textMuted,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Name
                    _Label('Назва'),
                    const SizedBox(height: 6),
                    _Input(controller: _nameController, hint: 'Назва активності'),
                    const SizedBox(height: AppDimensions.lg),

                    // YouTube link
                    _Label('Посилання на YouTube'),
                    const SizedBox(height: 6),
                    _Input(
                      controller: _youtubeController,
                      hint: 'https://youtube.com/watch?v=...',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Відео тренування чи клип — прев\'ю показуватиметься у картці на сьогодні',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Slots
                    _Label('Розклад'),
                    const SizedBox(height: 8),
                    ..._slots.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ActivitySlot(
                            index: e.key,
                            time: e.value.time,
                            duration: e.value.duration,
                            onTimeTap: () => _pickTime(e.key),
                            onDurationTap: () => _pickDuration(e.key),
                            onRemove: _slots.length > 1
                                ? () => setState(() => _slots.removeAt(e.key))
                                : null,
                          ),
                        )),
                    GestureDetector(
                      onTap: () => setState(() => _slots.add((
                            time: TimeOfDay(hour: (8 + _slots.length) % 24, minute: 0),
                            duration: null,
                          ))),
                      child: _DashedAdd('Додати ще заняття'),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Weekdays
                    _Label('Дні тижня'),
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
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                _dayNames[day],
                                style: AppTextStyles.labelSm.copyWith(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Reminder
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_outlined,
                              color: AppColors.textSub, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Нагадування',
                                    style: AppTextStyles.labelMd),
                                Text('За 10 хвилин до кожного заняття',
                                    style: AppTextStyles.bodySm),
                              ],
                            ),
                          ),
                          Switch(
                            value: _reminder,
                            onChanged: (v) => setState(() => _reminder = v),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    TaskColorPicker(
                      selectedHex: _colorHex,
                      onChanged: (hex) => setState(() => _colorHex = hex),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSaving ? 'Зберігаємо...' : (isEdit ? 'Зберегти зміни' : 'Зберегти активність'),
                          style: AppTextStyles.labelLg
                              .copyWith(color: Colors.white),
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

  Future<void> _pickTime(int index) async {
    final picked =
        await showWheelTimePicker(context, initialTime: _slots[index].time);
    if (picked != null) {
      setState(() {
        _slots[index] = (time: picked, duration: _slots[index].duration);
      });
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
    // -1 — sentinel для "Не вказано"
    setState(() {
      _slots[index] = (
        time: _slots[index].time,
        duration: picked == -1 ? null : (picked ?? _slots[index].duration),
      );
    });
  }
}

// ─── Slot widget ──────────────────────────────────────────────────────────────

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

  static String _fmtDuration(int min) {
    if (min < 60) return '$min хв';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '$h год' : '$h год $m хв';
  }

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
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Заняття ${index + 1}',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Text('видалити',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SlotField(label: 'Час', value: '$hh:$mm', onTap: onTimeTap),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotField(
                  label: 'Тривалість',
                  value: duration != null ? _fmtDuration(duration!) : '—',
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

// ─── Duration picker ──────────────────────────────────────────────────────────

class _DurationPicker extends StatefulWidget {
  final int? current; // в минутах, null = не вказано
  const _DurationPicker({this.current});

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  static const _minuteOptions = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  late bool _notSpecified;
  late int _hours;
  late int _minuteIdx; // индекс в _minuteOptions

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
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
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
                    Text('Тривалість', style: AppTextStyles.h3),
                    Text('Необов\'язково',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              // Переключатель "Не вказано"
              GestureDetector(
                onTap: () => setState(() => _notSpecified = !_notSpecified),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _notSpecified
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _notSpecified ? AppColors.primary : AppColors.border,
                      width: _notSpecified ? 2 : 1.5,
                    ),
                  ),
                  child: Text(
                    'Не вказано',
                    style: AppTextStyles.labelMd.copyWith(
                      color: _notSpecified
                          ? AppColors.primary
                          : AppColors.textSub,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Барабанный пикер
          AnimatedOpacity(
            opacity: _notSpecified ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _notSpecified,
              child: SizedBox(
                height: 160,
                child: Row(
                  children: [
                    // Годинники
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
                            onSelectedItemChanged: (i) =>
                                setState(() => _hours = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 4,
                              builder: (_, i) => Center(
                                child: Text(
                                  '$i год',
                                  style: AppTextStyles.bodyLg.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _hours == i
                                        ? AppColors.primary
                                        : AppColors.textSub,
                                    fontSize: _hours == i ? 18 : 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Хвилини
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
                            onSelectedItemChanged: (i) =>
                                setState(() => _minuteIdx = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: _minuteOptions.length,
                              builder: (_, i) {
                                final sel = _minuteIdx == i;
                                return Center(
                                  child: Text(
                                    '${_minuteOptions[i].toString().padLeft(2, '0')} хв',
                                    style: AppTextStyles.bodyLg.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.textSub,
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _notSpecified
                    ? 'Без тривалості'
                    : 'Зберегти · ${_totalMin < 60 ? '$_totalMin хв' : '${_totalMin ~/ 60} год ${_totalMin % 60 == 0 ? '' : '${_totalMin % 60} хв'}'.trim()}',
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

// ─── Reusable widgets ─────────────────────────────────────────────────────────

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
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Color(0xFFDC2626)),
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
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm,
      );
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
          hintStyle:
              AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
  const _SlotField({required this.label, required this.value, this.hint = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(value,
                style: AppTextStyles.labelMd.copyWith(
                    color: hint ? AppColors.textMuted : AppColors.textMain)),
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
          Text('＋',
              style: AppTextStyles.bodyMd
                  .copyWith(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
