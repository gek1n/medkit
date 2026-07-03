import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  final int memberId;
  const AddMedicationScreen({super.key, required this.memberId});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _MedPhase {
  List<TimeOfDay> times;
  int? durationDays; // null = permanent
  bool intervalMode;
  int intervalHours;
  TimeOfDay intervalStart;
  double doseAmount;
  String doseComment;

  _MedPhase({
    required this.times,
    this.durationDays,
    this.intervalMode = false,
    this.intervalHours = 4,
    this.intervalStart = const TimeOfDay(hour: 8, minute: 0),
    this.doseAmount = 1.0,
    this.doseComment = '',
  });

  List<TimeOfDay> get effectiveTimes {
    if (!intervalMode) return times;
    final result = <TimeOfDay>[];
    int h = intervalStart.hour;
    int m = intervalStart.minute;
    while (h < 24) {
      result.add(TimeOfDay(hour: h, minute: m));
      h += intervalHours;
    }
    return result;
  }
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _nameController = TextEditingController();

  String _form = 'tablet';
  String _foodRelation = 'after';
  String _repeatType = 'daily';

  // Phases
  late List<_MedPhase> _phases;

  // Repeat config for weekdays
  final Set<int> _weekdays = {1, 2, 3, 4, 5}; // 1=Mon..7=Sun
  int _everyNDays = 3;
  int _cycleOn = 21;
  int _cycleOff = 7;

  // Stock tracking
  bool _trackStock = false;
  int _availableCount = 0;

  // Photos
  List<String> _photoPaths = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phases = [
      _MedPhase(
        times: [const TimeOfDay(hour: 6, minute: 0)],
        durationDays: 7,
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static String _unitForForm(String form) => switch (form) {
        'tablet'      => 'табл.',
        'capsule'     => 'капс.',
        'syrup'       => 'мл',
        'drops'       => 'крап.',
        'cream'       => 'г',
        'inhaler'     => 'вдих',
        'injection'   => 'мл',
        'suppository' => 'свіча',
        'vial'        => 'фл.',
        _             => 'шт.',
      };

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введіть назву ліків')));
      return;
    }

    final doseUnit = _unitForForm(_form);
    final repeatConfig = _buildRepeatConfig();
    final now = DateTime.now();

    // Build phases JSON (doseAmount per phase)
    final phasesJson = jsonEncode(_phases
        .map((p) => {
              'times': p.effectiveTimes
                  .map((t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                  .toList(),
              'durationDays': p.durationDays,
              'doseAmount': p.doseAmount,
              if (p.doseComment.isNotEmpty) 'doseComment': p.doseComment,
            })
        .toList());
    // Use first phase dose as the top-level doseAmount for legacy display
    final doseAmount = _phases.isNotEmpty ? _phases.first.doseAmount : 1.0;

    // Compute endDate from phases
    DateTime? endDate;
    int totalDays = 0;
    bool hasPermanent = false;
    for (final p in _phases) {
      if (p.durationDays == null) {
        hasPermanent = true;
        break;
      }
      totalDays += p.durationDays!;
    }
    if (!hasPermanent) {
      endDate = DateTime(now.year, now.month, now.day)
          .add(Duration(days: totalDays));
    }

    setState(() => _isSaving = true);
    try {
      final medRepo = ref.read(medicationsRepositoryProvider);

      await medRepo.insert(MedicationsCompanion.insert(
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
        totalCount: Value(_availableCount),
        remainingCount: Value(_availableCount),
        photoPaths: Value(jsonEncode(_photoPaths)),
        phases: Value(phasesJson),
      ));

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
            _BackHeader(title: 'Ліки', onBack: () => Navigator.pop(context)),
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

                    // Form (перша — визначає одиницю)
                    _FormLabel('Форма випуску'),
                    const SizedBox(height: 8),
                    _FormChips(
                      selected: _form,
                      onSelect: (f) => setState(() => _form = f),
                    ),
                    const SizedBox(height: AppDimensions.lg),


                    // Phases
                    _FormLabel('Фази курсу'),
                    const SizedBox(height: 8),
                    ..._phases.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PhaseCard(
                            index: e.key,
                            phase: e.value,
                            form: _form,
                            canRemove: _phases.length > 1,
                            isLast: e.key == _phases.length - 1,
                            onChanged: (p) =>
                                setState(() => _phases[e.key] = p),
                            onRemove: () =>
                                setState(() => _phases.removeAt(e.key)),
                            onPickTime: (idx) => _pickPhaseTime(e.key, idx),
                          ),
                        )),
                    if (_phases.length < 4)
                      GestureDetector(
                        onTap: () {
                          final lastHour = _phases.isNotEmpty &&
                                  _phases.last.times.isNotEmpty
                              ? _phases.last.times.last.hour
                              : 5;
                          final nextHour =
                              lastHour < 23 ? lastHour + 1 : 23;
                          setState(() => _phases.add(
                                _MedPhase(
                                  times: [
                                    TimeOfDay(hour: nextHour, minute: 0)
                                  ],
                                  durationDays: 7,
                                ),
                              ));
                        },
                        child: _DashedAdd('Додати фазу'),
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

                    // Optional block
                    _OptionalSection(
                      trackStock: _trackStock,
                      availableCount: _availableCount,
                      phases: _phases,
                      doseAmount: _phases.isNotEmpty
                          ? _phases.first.doseAmount
                          : 1.0,
                      doseUnit: _unitForForm(_form),
                      onTrackToggle: (v) =>
                          setState(() => _trackStock = v),
                      onDecrement: () => setState(() {
                        if (_availableCount > 0) _availableCount--;
                      }),
                      onIncrement: () =>
                          setState(() => _availableCount++),
                      onEdit: (v) => setState(() => _availableCount = v),
                      photoPaths: _photoPaths,
                      onPhotosChanged: (paths) =>
                          setState(() => _photoPaths = paths),
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

  Future<void> _pickPhaseTime(int phaseIdx, int timeIdx) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _phases[phaseIdx].times[timeIdx],
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _phases[phaseIdx].times[timeIdx] = picked);
    }
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
    ('tablet',      '💊', 'Таблетка'),
    ('capsule',     '💊', 'Капсула'),
    ('suppository', '🕯️', 'Свічі'),
    ('vial',        '🧪', 'Флакон'),
    ('syrup',       '🍶', 'Сироп'),
    ('drops',       '💧', 'Краплі'),
    ('cream',       '🧴', 'Крем'),
    ('inhaler',     '💨', 'Інгалятор'),
    ('injection',   '💉', 'Ін\'єкція'),
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

// ─── Phase card ───────────────────────────────────────────────────────────────

class _PhaseCard extends StatelessWidget {
  final int index;
  final _MedPhase phase;
  final String form;
  final bool canRemove;
  final bool isLast;
  final void Function(_MedPhase) onChanged;
  final VoidCallback onRemove;
  final void Function(int) onPickTime;

  const _PhaseCard({
    required this.index,
    required this.phase,
    required this.form,
    required this.canRemove,
    required this.isLast,
    required this.onChanged,
    required this.onRemove,
    required this.onPickTime,
  });

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) =>
      showTimePicker(
        context: context,
        initialTime: initial,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        ),
      );

  Future<int?> _pickInt(
    BuildContext context, {
    required String title,
    required int value,
    required String suffix,
  }) async {
    final ctrl = TextEditingController(text: '$value');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: suffix),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPermanent = phase.durationDays == null;
    final preview = phase.effectiveTimes.map(_fmt).join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Фаза ${index + 1}',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.primary)),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Text('видалити',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Mode toggle
          Text('ЧАС ПРИЙОМУ',
              style: AppTextStyles.labelSm.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _ModeTab(
                  label: 'Конкретний час',
                  active: !phase.intervalMode,
                  onTap: () => onChanged(_MedPhase(
                    times: phase.times,
                    durationDays: phase.durationDays,
                    intervalMode: false,
                    intervalHours: phase.intervalHours,
                    intervalStart: phase.intervalStart,
                  )),
                ),
                _ModeTab(
                  label: 'Кожні N годин',
                  active: phase.intervalMode,
                  onTap: () => onChanged(_MedPhase(
                    times: phase.times,
                    durationDays: phase.durationDays,
                    intervalMode: true,
                    intervalHours: phase.intervalHours,
                    intervalStart: phase.intervalStart,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Content by mode
          if (!phase.intervalMode) ...[
            // ── Конкретний час ──
            ...phase.times.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked =
                              await _pickTime(context, e.value);
                          if (picked != null) {
                            final updated =
                                List<TimeOfDay>.from(phase.times);
                            updated[e.key] = picked;
                            onChanged(_MedPhase(
                              times: updated,
                              durationDays: phase.durationDays,
                              intervalMode: false,
                              intervalHours: phase.intervalHours,
                              intervalStart: phase.intervalStart,
                            ));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.primary, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(_fmt(e.value),
                                  style: AppTextStyles.labelMd
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (phase.times.length > 1)
                        GestureDetector(
                          onTap: () {
                            final updated =
                                List<TimeOfDay>.from(phase.times)
                                  ..removeAt(e.key);
                            onChanged(_MedPhase(
                              times: updated,
                              durationDays: phase.durationDays,
                              intervalMode: false,
                              intervalHours: phase.intervalHours,
                              intervalStart: phase.intervalStart,
                            ));
                          },
                          child: const Icon(Icons.close,
                              size: 18, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                )),
            GestureDetector(
              onTap: () {
                final lastHour = phase.times.isNotEmpty
                    ? phase.times.last.hour
                    : 5;
                final nextHour = lastHour < 23 ? lastHour + 1 : 23;
                final updated = List<TimeOfDay>.from(phase.times)
                  ..add(TimeOfDay(hour: nextHour, minute: 0));
                onChanged(_MedPhase(
                  times: updated,
                  durationDays: phase.durationDays,
                  intervalMode: false,
                  intervalHours: phase.intervalHours,
                  intervalStart: phase.intervalStart,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text('Додати час',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // ── Кожні N годин ──
            Row(
              children: [
                // Інтервал
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ІНТЕРВАЛ',
                        style:
                            AppTextStyles.labelSm.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _CountBtn(
                          icon: '−',
                          onTap: phase.intervalHours <= 1
                              ? null
                              : () => onChanged(_MedPhase(
                                    times: phase.times,
                                    durationDays: phase.durationDays,
                                    intervalMode: true,
                                    intervalHours: phase.intervalHours - 1,
                                    intervalStart: phase.intervalStart,
                                  )),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final v = await _pickInt(context,
                                title: 'Інтервал',
                                value: phase.intervalHours,
                                suffix: 'год');
                            if (v != null) {
                              onChanged(_MedPhase(
                                times: phase.times,
                                durationDays: phase.durationDays,
                                intervalMode: true,
                                intervalHours: v,
                                intervalStart: phase.intervalStart,
                              ));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            child: Text(
                              '${phase.intervalHours} год',
                              style: AppTextStyles.labelLg
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        _CountBtn(
                          icon: '＋',
                          onTap: phase.intervalHours >= 23
                              ? null
                              : () => onChanged(_MedPhase(
                                    times: phase.times,
                                    durationDays: phase.durationDays,
                                    intervalMode: true,
                                    intervalHours: phase.intervalHours + 1,
                                    intervalStart: phase.intervalStart,
                                  )),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Початок
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ПОЧАТОК',
                        style:
                            AppTextStyles.labelSm.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await _pickTime(
                            context, phase.intervalStart);
                        if (picked != null) {
                          onChanged(_MedPhase(
                            times: phase.times,
                            durationDays: phase.durationDays,
                            intervalMode: true,
                            intervalHours: phase.intervalHours,
                            intervalStart: picked,
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primary, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(_fmt(phase.intervalStart),
                                style: AppTextStyles.labelMd
                                    .copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Preview
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                preview,
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.textSub),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.primary),
          const SizedBox(height: 10),

          // Dose per intake
          Text('КІЛЬКІСТЬ НА ПРИЙОМ',
              style: AppTextStyles.labelSm.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          _DoseRow(
            value: phase.doseAmount,
            form: form,
            onChanged: (v) => onChanged(_copyPhase(phase, doseAmount: v)),
          ),
          const SizedBox(height: 8),
          _DoseCommentField(
            value: phase.doseComment,
            onChanged: (c) => onChanged(_copyPhase(phase, doseComment: c)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.primary),
          const SizedBox(height: 10),

          // Duration stepper
          Text('ТРИВАЛІСТЬ',
              style: AppTextStyles.labelSm.copyWith(fontSize: 10)),
          const SizedBox(height: 6),
          Row(
            children: [
              AnimatedOpacity(
                opacity: isPermanent ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  children: [
                    _CountBtn(
                      icon: '−',
                      onTap: isPermanent || (phase.durationDays ?? 1) <= 1
                          ? null
                          : () => onChanged(_copyPhase(
                              phase, durationDays: phase.durationDays! - 1)),
                    ),
                    GestureDetector(
                      onTap: isPermanent
                          ? null
                          : () async {
                              final v = await _pickInt(context,
                                  title: 'Кількість днів',
                                  value: phase.durationDays ?? 1,
                                  suffix: 'дн.');
                              if (v != null) {
                                onChanged(_copyPhase(phase,
                                    durationDays: v));
                              }
                            },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isPermanent
                              ? '— дн.'
                              : '${phase.durationDays} дн.',
                          style: AppTextStyles.labelLg
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    _CountBtn(
                      icon: '＋',
                      onTap: isPermanent
                          ? null
                          : () => onChanged(_copyPhase(phase,
                              durationDays: (phase.durationDays ?? 0) + 1)),
                    ),
                  ],
                ),
              ),
              if (isLast) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('або',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textMuted)),
                ),
                GestureDetector(
                  onTap: () => onChanged(
                      _copyPhase(phase, durationDays: isPermanent ? 7 : -1)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPermanent
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPermanent
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      'Постійно',
                      style: AppTextStyles.labelMd.copyWith(
                        color: isPermanent
                            ? Colors.white
                            : AppColors.textMain,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  _MedPhase _copyPhase(_MedPhase p,
          {int? durationDays, double? doseAmount, String? doseComment}) =>
      _MedPhase(
        times: p.times,
        durationDays:
            durationDays == -1 ? null : (durationDays ?? p.durationDays),
        intervalMode: p.intervalMode,
        intervalHours: p.intervalHours,
        intervalStart: p.intervalStart,
        doseAmount: doseAmount ?? p.doseAmount,
        doseComment: doseComment ?? p.doseComment,
      );
}

// ─── Dose comment ─────────────────────────────────────────────────────────────

class _DoseCommentField extends StatefulWidget {
  final String value;
  final void Function(String) onChanged;

  const _DoseCommentField({required this.value, required this.onChanged});

  @override
  State<_DoseCommentField> createState() => _DoseCommentFieldState();
}

class _DoseCommentFieldState extends State<_DoseCommentField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
      decoration: InputDecoration(
        hintText: 'Коментар до дози (необов\'язково)',
        hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Dose row ─────────────────────────────────────────────────────────────────

class _DoseRow extends StatelessWidget {
  final double value;
  final String form;
  final void Function(double) onChanged;

  const _DoseRow({
    required this.value,
    required this.form,
    required this.onChanged,
  });

  // Форми, де є сенс вводити дробові порції (¼, ½ таблетки)
  static const _fractionalForms = {'tablet', 'capsule'};

  static const _presets = <double>[0.25, 0.5, 1.0, 1.5, 2.0, 3.0];
  static final _labels = <double, String>{
    0.25: '¼',
    0.5: '½',
    1.0: '1',
    1.5: '1½',
    2.0: '2',
    3.0: '3',
  };

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    // округлення до 2 знаків
    return double.parse(v.toStringAsFixed(2))
        .toString()
        .replaceAll(RegExp(r'\.?0+$'), '');
  }

  Future<void> _openInput(BuildContext context) async {
    final ctrl = TextEditingController(text: _fmt(value));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Кількість на прийом'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'наприклад 2.5'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(
                  ctrl.text.trim().replaceAll(',', '.'));
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_fractionalForms.contains(form)) {
      // ── Чипи з дробами ──
      final isCustom = !_presets.contains(value);
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ..._presets.map((p) {
            final sel = value == p;
            return GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  _labels[p] ?? _fmt(p),
                  style: AppTextStyles.labelMd.copyWith(
                      color: sel ? Colors.white : AppColors.textMain),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _openInput(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isCustom ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isCustom ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                isCustom ? _fmt(value) : '…',
                style: AppTextStyles.labelMd.copyWith(
                    color:
                        isCustom ? Colors.white : AppColors.textMuted),
              ),
            ),
          ),
        ],
      );
    } else {
      // ── Числовий інпут (мл, краплі, г, вдихи тощо) ──
      return GestureDetector(
        onTap: () => _openInput(context),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmt(value),
                style: AppTextStyles.labelLg
                    .copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ),
      );
    }
  }
}

// ─── Mode tab ─────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ),
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

class _DurationSection extends StatefulWidget {
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
  State<_DurationSection> createState() => _DurationSectionState();
}

class _DurationSectionState extends State<_DurationSection> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.isPermanent ? '' : '${widget.days}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Числовой инпут
        AnimatedOpacity(
          opacity: widget.isPermanent ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
              child: Row(
                children: [
                  // Кнопка −
                  GestureDetector(
                    onTap: widget.isPermanent
                        ? null
                        : () {
                            final v = (widget.days - 1).clamp(1, 365);
                            widget.onDaysSelect(v);
                            _ctrl.text = '$v';
                          },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(Icons.remove,
                          size: 18,
                          color: widget.isPermanent
                              ? AppColors.textMuted
                              : AppColors.textMain),
                    ),
                  ),
                  // Инпут
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: !widget.isPermanent,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isPermanent
                            ? AppColors.textMuted
                            : AppColors.textMain,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '—',
                        hintStyle: AppTextStyles.bodyLg
                            .copyWith(color: AppColors.textMuted),
                        suffixText: widget.isPermanent ? '' : ' дн.',
                        suffixStyle: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSub),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n >= 1 && n <= 365) {
                          widget.onPermanentToggle(false);
                          widget.onDaysSelect(n);
                        }
                      },
                    ),
                  ),
                  // Кнопка +
                  GestureDetector(
                    onTap: widget.isPermanent
                        ? null
                        : () {
                            final v = (widget.days + 1).clamp(1, 365);
                            widget.onDaysSelect(v);
                            _ctrl.text = '$v';
                          },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(Icons.add,
                          size: 18,
                          color: widget.isPermanent
                              ? AppColors.textMuted
                              : AppColors.textMain),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 10),
        // Кнопка "Постійно"
        GestureDetector(
          onTap: () {
            widget.onPermanentToggle(!widget.isPermanent);
            if (!widget.isPermanent) {
              _ctrl.text = '';
            } else {
              _ctrl.text = '${widget.days}';
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isPermanent
                  ? AppColors.primary
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isPermanent
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: Text(
              'Постійно',
              style: AppTextStyles.labelMd.copyWith(
                color: widget.isPermanent
                    ? Colors.white
                    : AppColors.textMain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Optional section ─────────────────────────────────────────────────────────

class _OptionalSection extends StatefulWidget {
  final bool trackStock;
  final int availableCount;
  final List<_MedPhase> phases;
  final double doseAmount;
  final String doseUnit;
  final List<String> photoPaths;
  final void Function(bool) onTrackToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final void Function(int) onEdit;
  final void Function(List<String>) onPhotosChanged;

  const _OptionalSection({
    required this.trackStock,
    required this.availableCount,
    required this.phases,
    required this.doseAmount,
    required this.doseUnit,
    required this.photoPaths,
    required this.onTrackToggle,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
    required this.onPhotosChanged,
  });

  @override
  State<_OptionalSection> createState() => _OptionalSectionState();
}

class _OptionalSectionState extends State<_OptionalSection> {
  bool _expanded = false;

  // Загальна кількість прийомів за курс (одиниць ліків)
  int _totalIntakes() {
    double total = 0;
    for (final phase in widget.phases) {
      final days = phase.durationDays ?? 0;
      final intakesPerDay = phase.effectiveTimes.length;
      total += days * intakesPerDay * widget.doseAmount;
    }
    return total.ceil();
  }

  @override
  Widget build(BuildContext context) {
    final needed = _totalIntakes();
    final toBuy = (needed - widget.availableCount).clamp(0, 99999);

    return Column(
      children: [
        // Заголовок-тоглер
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded,
                    size: 18, color: AppColors.textSub),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Додаткові параметри',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textSub),
                  ),
                ),
                Text(
                  'Необов\'язково',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 20, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),

        // Розкривний вміст
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Фото упаковки
                _PhotoSection(
                  paths: widget.photoPaths,
                  onChanged: widget.onPhotosChanged,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Галочка відстеження
                GestureDetector(
                  onTap: () => widget.onTrackToggle(!widget.trackStock),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: widget.trackStock
                              ? AppColors.primary
                              : AppColors.bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.trackStock
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: widget.trackStock
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Відстежувати та нагадувати про залишок',
                          style: AppTextStyles.bodyMd,
                        ),
                      ),
                    ],
                  ),
                ),

                // Поля наявності та розрахунку
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),

                      Text('В наявності', style: AppTextStyles.labelMd),
                      const SizedBox(height: 4),
                      Text(
                        'Скільки ${widget.doseUnit} є зараз',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      _PillCountRow(
                        count: widget.availableCount,
                        unit: widget.doseUnit,
                        onDecrement: widget.onDecrement,
                        onIncrement: widget.onIncrement,
                        onEdit: widget.onEdit,
                      ),

                      if (needed > 0) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: toBuy > 0
                                ? AppColors.primaryLight
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: toBuy > 0
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                toBuy > 0
                                    ? Icons.shopping_bag_outlined
                                    : Icons.check_circle_outline,
                                size: 20,
                                color: toBuy > 0
                                    ? AppColors.primary
                                    : Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: toBuy > 0
                                    ? RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.bodyMd,
                                          children: [
                                            const TextSpan(
                                                text: 'Потрібно докупити: '),
                                            TextSpan(
                                              text:
                                                  '$toBuy ${widget.doseUnit}',
                                              style: AppTextStyles.labelMd
                                                  .copyWith(
                                                      color:
                                                          AppColors.primary),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' (курс: $needed, є: ${widget.availableCount})',
                                              style: AppTextStyles.bodySm
                                                  .copyWith(
                                                      color: AppColors
                                                          .textMuted),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        'Вистачить на весь курс',
                                        style: AppTextStyles.bodyMd.copyWith(
                                            color: Colors.green.shade700),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  crossFadeState: widget.trackStock
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ─── Pill count ───────────────────────────────────────────────────────────────

class _PillCountRow extends StatelessWidget {
  final int count;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final void Function(int) onEdit;

  const _PillCountRow({
    required this.count,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CountBtn(icon: '−', onTap: count > 0 ? onDecrement : null),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            final ctrl = TextEditingController(text: '$count');
            final result = await showDialog<int>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Кількість'),
                content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(suffixText: unit),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Скасувати'),
                  ),
                  TextButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text.trim());
                      Navigator.pop(ctx, v != null && v >= 0 ? v : null);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            if (result != null) onEdit(result);
          },
          child: Text(
            '$count',
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 16),
        _CountBtn(icon: '＋', onTap: onIncrement),
        const SizedBox(width: 12),
        Text(
          unit,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
        ),
      ],
    );
  }
}

// ─── Photo section ────────────────────────────────────────────────────────────

class _PhotoSection extends StatefulWidget {
  final List<String> paths;
  final void Function(List<String>) onChanged;

  const _PhotoSection({required this.paths, required this.onChanged});

  @override
  State<_PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends State<_PhotoSection> {
  final Map<String, String> _absCache = {};
  bool _loading = false;

  Future<String> _abs(String rel) async {
    return _absCache[rel] ??=
        await PhotoService.absolutePath(rel);
  }

  Future<void> _add() async {
    setState(() => _loading = true);
    try {
      final path = await PhotoService.showPickerDialog(context);
      if (path != null) {
        widget.onChanged([...widget.paths, path]);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String rel) async {
    await PhotoService.delete(rel);
    _absCache.remove(rel);
    widget.onChanged(widget.paths.where((p) => p != rel).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Фото упаковки', style: AppTextStyles.labelMd),
            const Spacer(),
            if (_loading)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              GestureDetector(
                onTap: _add,
                child: Text('Додати',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primary)),
              ),
          ],
        ),
        if (widget.paths.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Допоможе не переплутати ліки',
            style:
                AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ] else ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.paths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final rel = widget.paths[i];
                return FutureBuilder<String>(
                  future: _abs(rel),
                  builder: (ctx, snap) {
                    final abs = snap.data;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: abs != null
                              ? Image.file(
                                  File(abs),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.primaryLight,
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _remove(rel),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Count button ─────────────────────────────────────────────────────────────

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
