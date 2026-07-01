import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/schedules_repository.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  final int memberId;
  const AddMedicationScreen({super.key, required this.memberId});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _doseAmountController = TextEditingController(text: '1');
  final _doseUnitController = TextEditingController(text: 'мг');

  String _form = 'tablet';
  String _foodRelation = 'after';
  String _repeatType = 'daily';
  int _timesPerDay = 1;

  // Time slots: list of TimeOfDay
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  // Repeat config for weekdays
  final Set<int> _weekdays = {1, 2, 3, 4, 5}; // 1=Mon..7=Sun
  int _everyNDays = 3;
  int _cycleOn = 21;
  int _cycleOff = 7;

  // Duration
  bool _isPermanent = false;
  int _durationDays = 7;

  // Pill count
  int _totalCount = 0;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _doseAmountController.dispose();
    _doseUnitController.dispose();
    super.dispose();
  }

  void _setTimesPerDay(int n) {
    setState(() {
      _timesPerDay = n;
      while (_times.length < n) {
        _times.add(_defaultTime(_times.length));
      }
      while (_times.length > n) {
        _times.removeLast();
      }
    });
  }

  TimeOfDay _defaultTime(int index) => switch (index) {
        0 => const TimeOfDay(hour: 8, minute: 0),
        1 => const TimeOfDay(hour: 14, minute: 0),
        2 => const TimeOfDay(hour: 20, minute: 0),
        _ => TimeOfDay(hour: 8 + index * 4, minute: 0),
      };

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введіть назву ліків')));
      return;
    }

    final doseAmount =
        double.tryParse(_doseAmountController.text.trim()) ?? 1.0;
    final doseUnit = _doseUnitController.text.trim().isEmpty
        ? 'мг'
        : _doseUnitController.text.trim();

    final repeatConfig = _buildRepeatConfig();
    final now = DateTime.now();
    final endDate = _isPermanent
        ? null
        : DateTime(now.year, now.month, now.day)
            .add(Duration(days: _durationDays));

    setState(() => _isSaving = true);
    try {
      final medRepo = ref.read(medicationsRepositoryProvider);
      final schedRepo = ref.read(schedulesRepositoryProvider);

      final medId = await medRepo.insert(MedicationsCompanion.insert(
        memberId: widget.memberId,
        name: name,
        form: Value(_form),
        doseAmount: doseAmount,
        doseUnit: Value(doseUnit),
        foodRelation: Value(_foodRelation),
        repeatType: Value(_repeatType),
        repeatConfig: Value(jsonEncode(repeatConfig)),
        startDate: now,
        endDate: Value(endDate),
        totalCount: Value(_totalCount),
        remainingCount: Value(_totalCount),
      ));

      for (int i = 0; i < _times.length; i++) {
        final t = _times[i];
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        await schedRepo.insert(SchedulesCompanion.insert(
          medicationId: medId,
          timeOfDay: '$hh:$mm',
          sortOrder: Value(i),
        ));
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic> _buildRepeatConfig() => switch (_repeatType) {
        'weekdays' => {'days': _weekdays.toList()..sort()},
        'every_n' => {'n': _everyNDays},
        'cycle' => {'on': _cycleOn, 'off': _cycleOff},
        _ => {},
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(title: 'Лікарство', onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan CTA
                    _ScanCta(),
                    const _OrDivider(),

                    // Name
                    _FormLabel('Назва'),
                    const SizedBox(height: 6),
                    _TextField(
                        controller: _nameController,
                        hint: 'Назва препарату'),
                    const SizedBox(height: AppDimensions.lg),

                    // Dose
                    _FormLabel('Дозування'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _TextField(
                            controller: _doseAmountController,
                            hint: '500',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _TextField(
                              controller: _doseUnitController,
                              hint: 'мг / мл / краплі'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Form
                    _FormLabel('Форма випуску'),
                    const SizedBox(height: 8),
                    _FormChips(
                      selected: _form,
                      onSelect: (f) => setState(() => _form = f),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Times per day
                    _FormLabel('Частота прийому'),
                    const SizedBox(height: 8),
                    _FrequencyGrid(
                      selected: _timesPerDay,
                      onSelect: _setTimesPerDay,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Time slots
                    _FormLabel('Час прийому'),
                    const SizedBox(height: 8),
                    ..._times.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TimeSlot(
                            index: e.key,
                            time: e.value,
                            foodRelation: _foodRelation,
                            onTimeTap: () => _pickTime(e.key),
                            onFoodTap: () => _pickFood(),
                            onRemove: _times.length > 1
                                ? () => setState(() => _times.removeAt(e.key))
                                : null,
                          ),
                        )),
                    GestureDetector(
                      onTap: () => setState(() {
                        _times.add(_defaultTime(_times.length));
                        _timesPerDay = _times.length;
                      }),
                      child: _DashedAdd('Додати ще прийом'),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Repeat
                    _FormLabel('Повтор'),
                    const SizedBox(height: 8),
                    _RepeatSection(
                      selected: _repeatType,
                      weekdays: _weekdays,
                      everyN: _everyNDays,
                      cycleOn: _cycleOn,
                      cycleOff: _cycleOff,
                      onSelect: (r) => setState(() => _repeatType = r),
                      onWeekdayToggle: (d) => setState(() {
                        if (_weekdays.contains(d)) {
                          _weekdays.remove(d);
                        } else {
                          _weekdays.add(d);
                        }
                      }),
                      onEveryNChanged: (n) =>
                          setState(() => _everyNDays = n),
                      onCycleChanged: (on, off) =>
                          setState(() {
                            _cycleOn = on;
                            _cycleOff = off;
                          }),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Duration
                    _FormLabel('Тривалість курсу'),
                    const SizedBox(height: 8),
                    _DurationSection(
                      isPermanent: _isPermanent,
                      days: _durationDays,
                      onPermanentToggle: (v) =>
                          setState(() => _isPermanent = v),
                      onDaysSelect: (d) =>
                          setState(() => _durationDays = d),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Pill count
                    _FormLabel('Таблеток у упаковці'),
                    const SizedBox(height: 8),
                    _PillCountRow(
                      count: _totalCount,
                      onDecrement: () => setState(() {
                        if (_totalCount > 0) _totalCount--;
                      }),
                      onIncrement: () => setState(() => _totalCount++),
                    ),
                    const SizedBox(height: 32),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd)),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSaving
                              ? 'Зберігаємо...'
                              : 'Зберегти та переглянути розклад →',
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  Future<void> _pickFood() async {
    const options = {
      'before': 'До їжі',
      'after': 'Після їжі',
      'with': 'Під час їжі',
      'any': 'Незалежно від їжі',
    };
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Відносно їжі', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            ...options.entries.map((e) => ListTile(
                  title: Text(e.value, style: AppTextStyles.bodyMd),
                  trailing: _foodRelation == e.key
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, e.key),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _foodRelation = result);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _BackHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.textMain),
            ),
          ),
          const SizedBox(width: 12),
          Text(title, style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

class _ScanCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сканувати рецепт',
                    style: AppTextStyles.labelLg
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text('AI заповнить все автоматично по фото',
                    style: AppTextStyles.bodySm
                        .copyWith(
                            color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          Icon(Icons.play_arrow,
              color: Colors.white.withValues(alpha: 0.7), size: 20),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('або введіть вручну',
                style:
                    AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelSm,
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _TextField(
      {required this.controller, required this.hint, this.keyboardType});

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
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMain),
      ),
    );
  }
}

// ─── Form chips ───────────────────────────────────────────────────────────────

class _FormChips extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _FormChips({required this.selected, required this.onSelect});

  static const _forms = [
    ('tablet', '💊', 'Таблетка'),
    ('capsule', '💊', 'Капсула'),
    ('syrup', '🍶', 'Сироп'),
    ('drops', '💧', 'Краплі'),
    ('cream', '🧴', 'Крем'),
    ('inhaler', '💨', 'Інгалятор'),
    ('injection', '💉', 'Ін\'єкція'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _forms
          .map((f) => GestureDetector(
                onTap: () => onSelect(f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == f.$1
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected == f.$1
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '${f.$2} ${f.$3}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: selected == f.$1
                          ? Colors.white
                          : AppColors.textMain,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Frequency grid ───────────────────────────────────────────────────────────

class _FrequencyGrid extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;

  const _FrequencyGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: [1, 2, 3, 4].map((n) {
        final sel = selected == n;
        return GestureDetector(
          onTap: () => onSelect(n),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$n×',
                  style: AppTextStyles.h3.copyWith(
                      color: sel ? Colors.white : AppColors.textMain,
                      fontSize: 18),
                ),
                Text(
                  'в день',
                  style: AppTextStyles.bodySm.copyWith(
                      color: sel
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Time slot ────────────────────────────────────────────────────────────────

class _TimeSlot extends StatelessWidget {
  final int index;
  final TimeOfDay time;
  final String foodRelation;
  final VoidCallback onTimeTap;
  final VoidCallback onFoodTap;
  final VoidCallback? onRemove;

  const _TimeSlot({
    required this.index,
    required this.time,
    required this.foodRelation,
    required this.onTimeTap,
    required this.onFoodTap,
    this.onRemove,
  });

  static const _timeEmojis = ['☀️', '🕑', '🌙', '🌚'];
  static const _foodLabels = {
    'before': 'До їжі',
    'after': 'Після їжі',
    'with': 'Під час',
    'any': 'Будь-коли',
  };

  @override
  Widget build(BuildContext context) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final emoji = _timeEmojis[index % _timeEmojis.length];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Прийом ${index + 1}',
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Text('видалити',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SlotField(
                  label: 'Час',
                  value: '$hh:$mm',
                  onTap: onTimeTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotField(
                  label: 'Відносно їжі',
                  value: _foodLabels[foodRelation] ?? foodRelation,
                  onTap: onFoodTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SlotField(
      {required this.label, required this.value, required this.onTap});

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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Text(
              value,
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.primary),
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
          const Text('＋',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Repeat section ───────────────────────────────────────────────────────────

class _RepeatSection extends StatelessWidget {
  final String selected;
  final Set<int> weekdays;
  final int everyN;
  final int cycleOn;
  final int cycleOff;
  final void Function(String) onSelect;
  final void Function(int) onWeekdayToggle;
  final void Function(int) onEveryNChanged;
  final void Function(int, int) onCycleChanged;

  const _RepeatSection({
    required this.selected,
    required this.weekdays,
    required this.everyN,
    required this.cycleOn,
    required this.cycleOff,
    required this.onSelect,
    required this.onWeekdayToggle,
    required this.onEveryNChanged,
    required this.onCycleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RepeatOption(
          value: 'daily',
          label: 'Щодня',
          sub: null,
          selected: selected,
          onSelect: onSelect,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'alternate',
          label: 'Через день',
          sub: 'Пн, Ср, Пт, Нд…',
          selected: selected,
          onSelect: onSelect,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'weekdays',
          label: 'Певні дні тижня',
          sub: weekdays.isEmpty ? '' : _weekdayNames(weekdays),
          selected: selected,
          onSelect: onSelect,
          expanded: selected == 'weekdays'
              ? _WeekdayPicker(
                  selected: weekdays, onToggle: onWeekdayToggle)
              : null,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'every_n',
          label: 'Кожні N днів',
          sub: 'Наприклад кожні 3 дні',
          selected: selected,
          onSelect: onSelect,
          expanded: selected == 'every_n'
              ? _StepperRow(
                  label: 'Кожні',
                  suffix: 'днів',
                  value: everyN,
                  onDecrement: () =>
                      everyN > 2 ? onEveryNChanged(everyN - 1) : null,
                  onIncrement: () => onEveryNChanged(everyN + 1),
                )
              : null,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'cycle',
          label: 'Циклом',
          sub: 'N днів пити — M днів перерва',
          selected: selected,
          onSelect: onSelect,
          expanded: selected == 'cycle'
              ? Column(
                  children: [
                    _StepperRow(
                      label: 'Пити',
                      suffix: 'днів',
                      value: cycleOn,
                      onDecrement: () =>
                          cycleOn > 1 ? onCycleChanged(cycleOn - 1, cycleOff) : null,
                      onIncrement: () =>
                          onCycleChanged(cycleOn + 1, cycleOff),
                    ),
                    const SizedBox(height: 8),
                    _StepperRow(
                      label: 'Перерва',
                      suffix: 'днів',
                      value: cycleOff,
                      onDecrement: () =>
                          cycleOff > 1 ? onCycleChanged(cycleOn, cycleOff - 1) : null,
                      onIncrement: () =>
                          onCycleChanged(cycleOn, cycleOff + 1),
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  String _weekdayNames(Set<int> days) {
    const names = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return (days.toList()..sort()).map((d) => names[d]).join(', ');
  }
}

class _RepeatOption extends StatelessWidget {
  final String value;
  final String label;
  final String? sub;
  final String selected;
  final void Function(String) onSelect;
  final Widget? expanded;

  const _RepeatOption({
    required this.value,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onSelect,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 2 : 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.labelMd),
                      if (sub != null && sub!.isNotEmpty)
                        Text(sub!,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ],
            ),
            if (sel && expanded != null) ...[
              const SizedBox(height: 12),
              expanded!,
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final Set<int> selected;
  final void Function(int) onToggle;

  const _WeekdayPicker({required this.selected, required this.onToggle});

  static const _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final sel = selected.contains(day);
        return GestureDetector(
          onTap: () => onToggle(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.bgPage,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _days[i],
                style: AppTextStyles.labelSm.copyWith(
                  color: sel ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String suffix;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _StepperRow({
    required this.label,
    required this.suffix,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.bodyMd),
        const Spacer(),
        _CountBtn(icon: '−', onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value $suffix',
              style: AppTextStyles.labelLg
                  .copyWith(color: AppColors.primary)),
        ),
        _CountBtn(icon: '＋', onTap: onIncrement),
      ],
    );
  }
}

// ─── Duration section ─────────────────────────────────────────────────────────

class _DurationSection extends StatelessWidget {
  final bool isPermanent;
  final int days;
  final void Function(bool) onPermanentToggle;
  final void Function(int) onDaysSelect;

  const _DurationSection({
    required this.isPermanent,
    required this.days,
    required this.onPermanentToggle,
    required this.onDaysSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ...[7, 14, 30].map((d) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      onPermanentToggle(false);
                      onDaysSelect(d);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: !isPermanent && days == d
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !isPermanent && days == d
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$d днів',
                        style: AppTextStyles.labelMd.copyWith(
                          color: !isPermanent && days == d
                              ? Colors.white
                              : AppColors.textMain,
                        ),
                      ),
                    ),
                  ),
                )),
            GestureDetector(
              onTap: () => onPermanentToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isPermanent ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPermanent ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  '♾️ Постійно',
                  style: AppTextStyles.labelMd.copyWith(
                    color: isPermanent ? Colors.white : AppColors.textMain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Pill count ───────────────────────────────────────────────────────────────

class _PillCountRow extends StatelessWidget {
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _PillCountRow({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CountBtn(icon: '−', onTap: count > 0 ? onDecrement : null),
        const SizedBox(width: 16),
        Text(
          count == 0 ? 'Не вказано' : '$count',
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        _CountBtn(icon: '＋', onTap: onIncrement),
        const SizedBox(width: 12),
        if (count > 0)
          Text(
            'таблеток',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
      ],
    );
  }
}

class _CountBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;

  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primaryLight : AppColors.bgPage,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: onTap != null ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: 18,
              color: onTap != null ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
