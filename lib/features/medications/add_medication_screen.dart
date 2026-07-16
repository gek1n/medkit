import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/services/ai_usage_service.dart';
import '../../core/services/camera_permission_service.dart';
import '../../core/services/marketing_topics_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/services/prescription_scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../core/utils/plan_access.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../shared/widgets/food_relation_picker.dart';
import '../../shared/widgets/form_chips.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../plans/elly_denied_screen.dart';
import '../plans/plans_screen.dart';
import '../scan/prescription_scan_screen.dart';
import '../today/providers/today_providers.dart';

TimeOfDay _defaultTimeForSchedule(String s) => switch (s) {
  'morning' => const TimeOfDay(hour: 8, minute: 0),
  'afternoon' => const TimeOfDay(hour: 13, minute: 0),
  'evening' => const TimeOfDay(hour: 19, minute: 0),
  'night' => const TimeOfDay(hour: 22, minute: 0),
  _ => const TimeOfDay(hour: 8, minute: 0),
};

class AddMedicationScreen extends ConsumerStatefulWidget {
  final int? memberId;
  final Medication? existing;
  // Транзитний префіл із голосової команди (не з БД, на відміну від
  // [existing]) — та ж модель, що й для скану рецепта.
  final ScannedMedication? voicePrefill;
  // Онбординг: власного профілю ще не існує в БД на момент показу цього
  // екрана (створюється лише в кінці онбордингу, інакше _RootRouter
  // перемкнув би застосунок на головний екран до завершення решти кроків).
  // Коли задано — стандартний флоу створення (форма + скан) лишається без
  // змін, але замість запису в БД компаньйон (з фіктивним memberId, який
  // викликач підмінить на реальний) повертається сюди, а екран одразу
  // закривається з результатом true.
  final void Function(MedicationsCompanion draft)? onDraftCreated;
  const AddMedicationScreen({
    super.key,
    this.memberId,
    this.existing,
    this.voicePrefill,
    this.onDraftCreated,
  }) : assert(
         memberId != null || onDraftCreated != null,
         'AddMedicationScreen needs either memberId or onDraftCreated',
       );

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
  String _foodRelation = 'unspecified';
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

  // Card color (null = дефолтний колір типу завдання)
  String? _colorHex;

  // Побічні ефекти, знайдені ІІ під час сканування рецепта/упаковки —
  // null для ручного додавання чи редагування (форма немає поля для їх
  // ручного введення, лише зберігає/показує те, що прийшло зі сканування).
  List<String>? _sideEffects;

  bool _isSaving = false;

  // null = ще завантажується; true/false — чи лишились безкоштовні спроби
  // скану (завжди true для платних планів).
  bool? _canScan;

  // null = необмежено (платний план) — тоді лічильник у банері не показуємо.
  int? _scansRemaining;

  Future<void> _refreshScanAvailability() async {
    final plan = ref.read(planProvider);
    if (plan.isPaid) {
      if (mounted) {
        setState(() {
          _canScan = true;
          _scansRemaining = null;
        });
      }
      return;
    }
    final used = await ref.read(aiUsageServiceProvider).getPhotoScansUsed();
    final remaining = (AiUsageService.photoScanLimit - used).clamp(0, AiUsageService.photoScanLimit);
    if (remaining == 0) unawaited(MarketingTopicsService.markHitScanLimit());
    if (mounted) {
      setState(() {
        _canScan = remaining > 0;
        _scansRemaining = remaining;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshScanAvailability();
    final ex = widget.existing;
    if (ex == null) {
      final prefill = widget.voicePrefill;
      if (prefill != null) {
        _applyPrefill(prefill);
      } else {
        _phases = [
          _MedPhase(
            times: [const TimeOfDay(hour: 6, minute: 0)],
            durationDays: 7,
          ),
        ];
      }
      return;
    }

    _nameController.text = ex.name;
    _form = ex.form;
    _foodRelation = ex.foodRelation;
    _repeatType = ex.repeatType;
    _colorHex = ex.color;
    _trackStock = ex.stockPercent != null;
    _availableCount = ex.remainingCount;
    try {
      _photoPaths = List<String>.from(jsonDecode(ex.photoPaths) as List);
    } catch (_) {}
    if (ex.sideEffects != null) {
      try {
        _sideEffects = List<String>.from(jsonDecode(ex.sideEffects!) as List);
      } catch (_) {}
    }

    try {
      final cfg = jsonDecode(ex.repeatConfig) as Map<String, dynamic>;
      switch (ex.repeatType) {
        case 'weekdays':
          _weekdays
            ..clear()
            ..addAll(List<int>.from(cfg['days'] as List));
          break;
        case 'every_n':
          _everyNDays = cfg['n'] as int;
          break;
        case 'cycle':
          _cycleOn = cfg['on'] as int;
          _cycleOff = cfg['off'] as int;
          break;
      }
    } catch (_) {}

    try {
      final rawPhases = List<Map<String, dynamic>>.from(
        jsonDecode(ex.phases ?? '[]') as List,
      );
      if (rawPhases.isNotEmpty) {
        _phases = rawPhases.map((p) {
          final times = List<String>.from(p['times'] as List).map((t) {
            final parts = t.split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }).toList();
          return _MedPhase(
            times: times,
            durationDays: p['durationDays'] as int?,
            doseAmount: (p['doseAmount'] as num).toDouble(),
            doseComment: p['doseComment'] as String? ?? '',
          );
        }).toList();
      } else {
        _phases = [
          _MedPhase(times: [const TimeOfDay(hour: 6, minute: 0)]),
        ];
      }
    } catch (_) {
      _phases = [
        _MedPhase(times: [const TimeOfDay(hour: 6, minute: 0)]),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _unitForForm(String form) => unitForMedForm(context, form);

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterMedicationNameError)),
      );
      return;
    }

    final doseUnit = _unitForForm(_form);
    final repeatConfig = _buildRepeatConfig();
    final now = DateTime.now();

    // Build phases JSON (doseAmount per phase)
    final phasesJson = jsonEncode(
      _phases
          .map(
            (p) => {
              'times': p.effectiveTimes
                  .map(
                    (t) =>
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                  )
                  .toList(),
              'durationDays': p.durationDays,
              'doseAmount': p.doseAmount,
              if (p.doseComment.isNotEmpty) 'doseComment': p.doseComment,
            },
          )
          .toList(),
    );
    // Use first phase dose as the top-level doseAmount for legacy display
    final doseAmount = _phases.isNotEmpty ? _phases.first.doseAmount : 1.0;

    // Compute endDate from phases — при редагуванні відлічуємо від
    // оригінальної дати початку курсу, а не від моменту збереження.
    final baseStart = widget.existing?.startDate ?? now;
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
      endDate = DateTime(
        baseStart.year,
        baseStart.month,
        baseStart.day,
      ).add(Duration(days: totalDays));
    }

    final isPercentForm = isPercentTrackedForm(_form);
    final ex = widget.existing;

    if (widget.onDraftCreated != null) {
      // Онбординг — memberId ще не існує, реальний підставить викликач.
      widget.onDraftCreated!(
        MedicationsCompanion.insert(
          memberId: 0,
          name: name,
          form: Value(_form),
          doseAmount: doseAmount,
          doseUnit: Value(doseUnit),
          foodRelation: Value(_foodRelation),
          repeatType: Value(_repeatType),
          repeatConfig: Value(jsonEncode(repeatConfig)),
          startDate: now,
          endDate: Value(endDate),
          totalCount: Value(isPercentForm ? 0 : _availableCount),
          remainingCount: Value(isPercentForm ? 0 : _availableCount),
          stockPercent: Value(_trackStock && isPercentForm ? 100 : null),
          openedAt: Value(_trackStock && isPercentForm ? now : null),
          photoPaths: Value(jsonEncode(_photoPaths)),
          phases: Value(phasesJson),
          color: Value(_colorHex),
          sideEffects: Value(_sideEffects == null ? null : jsonEncode(_sideEffects)),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final medRepo = ref.read(medicationsRepositoryProvider);

      if (ex != null) {
        await medRepo.update(
          MedicationsCompanion(
            id: Value(ex.id),
            memberId: Value(ex.memberId),
            name: Value(name),
            form: Value(_form),
            doseAmount: Value(doseAmount),
            doseUnit: Value(doseUnit),
            foodRelation: Value(_foodRelation),
            repeatType: Value(_repeatType),
            repeatConfig: Value(jsonEncode(repeatConfig)),
            startDate: Value(baseStart),
            endDate: Value(endDate),
            totalCount: Value(isPercentForm ? 0 : _availableCount),
            remainingCount: Value(isPercentForm ? 0 : _availableCount),
            stockPercent: Value(
              _trackStock && isPercentForm ? (ex.stockPercent ?? 100) : null,
            ),
            openedAt: Value(
              _trackStock && isPercentForm ? (ex.openedAt ?? now) : null,
            ),
            photoPaths: Value(jsonEncode(_photoPaths)),
            phases: Value(phasesJson),
            color: Value(_colorHex),
            sideEffects: Value(_sideEffects == null ? null : jsonEncode(_sideEffects)),
          ),
        );
      } else {
        await medRepo.insert(
          MedicationsCompanion.insert(
            memberId: widget.memberId!,
            name: name,
            form: Value(_form),
            doseAmount: doseAmount,
            doseUnit: Value(doseUnit),
            foodRelation: Value(_foodRelation),
            repeatType: Value(_repeatType),
            repeatConfig: Value(jsonEncode(repeatConfig)),
            startDate: now,
            endDate: Value(endDate),
            totalCount: Value(isPercentForm ? 0 : _availableCount),
            remainingCount: Value(isPercentForm ? 0 : _availableCount),
            stockPercent: Value(_trackStock && isPercentForm ? 100 : null),
            openedAt: Value(_trackStock && isPercentForm ? now : null),
            photoPaths: Value(jsonEncode(_photoPaths)),
            phases: Value(phasesJson),
            color: Value(_colorHex),
            sideEffects: Value(_sideEffects == null ? null : jsonEncode(_sideEffects)),
          ),
        );
      }

      ref.invalidate(generateTodayIntakesProvider);
      ref.invalidate(tomorrowIntakesProvider);

      if (mounted) Navigator.of(context).pop();
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteMedicationConfirmTitle),
        content: Text(context.l10n.deleteMedicationConfirmBody),
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
        .read(medicationsRepositoryProvider)
        .softDelete(widget.existing!.id);
    ref.invalidate(generateTodayIntakesProvider);
    ref.invalidate(tomorrowIntakesProvider);
    if (mounted) Navigator.pop(context);
  }

  Map<String, dynamic> _buildRepeatConfig() => switch (_repeatType) {
    'weekdays' => {'days': _weekdays.toList()..sort()},
    'every_n' => {'n': _everyNDays},
    'cycle' => {'on': _cycleOn, 'off': _cycleOff},
    _ => {},
  };

  @override
  Widget build(BuildContext context) {
    if (isMemberBlockedByPlan(ref, widget.memberId)) {
      return const EllyDeniedScreen();
    }
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(
              title:
                  (isEdit
                      ? context.l10n.editMedicationTitle
                      : context.l10n.medsTitle) +
                  (widget.memberId != null
                      ? memberNameSuffix(context, ref, widget.memberId!)
                      : ''),
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
                    if (!isEdit) ...[
                      // Scan CTA
                      GestureDetector(
                        onTap: _isSaving ? null : _openScan,
                        child: _ScanCta(
                          locked: _canScan == false,
                          remaining: _scansRemaining,
                        ),
                      ),
                      const _OrDivider(),
                    ],

                    // Name
                    _FormLabel(context.l10n.fieldName),
                    const SizedBox(height: 6),
                    _TextField(
                      controller: _nameController,
                      hint: context.l10n.medicationNameHint,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Form (перша — визначає одиницю)
                    _FormLabel(context.l10n.medicationFormLabel),
                    const SizedBox(height: 8),
                    FormChips(
                      selected: _form,
                      onSelect: (f) => setState(() => _form = f),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Phases
                    _FormLabel(context.l10n.coursePhasesLabel),
                    const SizedBox(height: 8),
                    ..._phases.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PhaseCard(
                          index: e.key,
                          phase: e.value,
                          canRemove: _phases.length > 1,
                          isLast: e.key == _phases.length - 1,
                          foodRelation: _foodRelation,
                          onFoodRelationChanged: (v) =>
                              setState(() => _foodRelation = v),
                          onChanged: (p) => setState(() => _phases[e.key] = p),
                          onRemove: () =>
                              setState(() => _phases.removeAt(e.key)),
                          onPickTime: (idx) => _pickPhaseTime(e.key, idx),
                        ),
                      ),
                    ),
                    if (_phases.length < 4)
                      GestureDetector(
                        onTap: () {
                          final lastHour =
                              _phases.isNotEmpty &&
                                  _phases.last.times.isNotEmpty
                              ? _phases.last.times.last.hour
                              : 5;
                          final nextHour = lastHour < 23 ? lastHour + 1 : 23;
                          setState(
                            () => _phases.add(
                              _MedPhase(
                                times: [TimeOfDay(hour: nextHour, minute: 0)],
                                durationDays: 7,
                              ),
                            ),
                          );
                        },
                        child: _DashedAdd(context.l10n.addPhaseAction),
                      ),
                    const SizedBox(height: AppDimensions.lg),

                    // Repeat
                    _FormLabel(context.l10n.repeatSectionLabel),
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
                      onEveryNChanged: (n) => setState(() => _everyNDays = n),
                      onCycleChanged: (on, off) => setState(() {
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
                      form: _form,
                      onTrackToggle: (v) => setState(() => _trackStock = v),
                      onDecrement: () => setState(() {
                        if (_availableCount > 0) _availableCount--;
                      }),
                      onIncrement: () => setState(() => _availableCount++),
                      onEdit: (v) => setState(() => _availableCount = v),
                      photoPaths: _photoPaths,
                      onPhotosChanged: (paths) =>
                          setState(() => _photoPaths = paths),
                      colorHex: _colorHex,
                      onColorChanged: (hex) => setState(() => _colorHex = hex),
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
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSaving
                              ? context.l10n.savingLabel
                              : (isEdit
                                    ? context.l10n.saveChangesAction
                                    : widget.onDraftCreated != null
                                        ? context.l10n.saveAndContinueAction
                                        : context
                                              .l10n
                                              .saveAndViewScheduleAction),
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

  Future<void> _pickPhaseTime(int phaseIdx, int timeIdx) async {
    final picked = await showWheelTimePicker(
      context,
      initialTime: _phases[phaseIdx].times[timeIdx],
    );
    if (picked != null) {
      setState(() => _phases[phaseIdx].times[timeIdx] = picked);
    }
  }

  Future<void> _openScan() async {
    if (_canScan == false) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlansScreen()),
      );
      return;
    }

    final results = await Navigator.push<List<ScannedMedication>>(
      context,
      MaterialPageRoute(builder: (_) => const PrescriptionScanScreen()),
    );
    if (results == null || results.isEmpty || !mounted) return;

    if (!ref.read(planProvider).isPaid) {
      await ref.read(aiUsageServiceProvider).recordPhotoScan();
      await _refreshScanAvailability();
    }

    // Екран сканування вже дав користувачу перевірити й відредагувати кожен
    // препарат окремо (акордеон з чекбоксом-згодою) — тут лише зберігаємо
    // те, що підтверджено, без додаткового кроку "прев'ю у формі".
    await _bulkSaveScanned(results);
  }

  // Спільна логіка заповнення форми — викликається і з initState (голосовий
  // префіл, без setState — ще до першого build), і з _prefillFrom (скан
  // рецепта на вже змонтованому екрані, обгорнуто в setState там).
  void _applyPrefill(ScannedMedication m) {
    _nameController.text = m.name;
    if (m.form != null) _form = m.form!;
    if (m.foodRelation != null) _foodRelation = m.foodRelation!;
    _sideEffects = m.sideEffects;
    final times = (m.scheduleTimes ?? const ['morning'])
        .map(_defaultTimeForSchedule)
        .toList();
    _phases = [
      _MedPhase(
        times: times,
        durationDays: m.durationDays ?? 7,
        doseAmount: m.doseAmount ?? 1.0,
      ),
    ];
  }

  MedicationsCompanion _companionFromScanned(ScannedMedication m, DateTime now) {
    final times = (m.scheduleTimes ?? const ['morning'])
        .map(
          (s) =>
              '${_defaultTimeForSchedule(s).hour.toString().padLeft(2, '0')}:${_defaultTimeForSchedule(s).minute.toString().padLeft(2, '0')}',
        )
        .toList();
    final duration = m.durationDays ?? 7;
    final form = m.form ?? 'tablet';
    final phasesJson = jsonEncode([
      {
        'times': times,
        'durationDays': duration,
        'doseAmount': m.doseAmount ?? 1.0,
      },
    ]);

    return MedicationsCompanion.insert(
      memberId: widget.memberId ?? 0,
      name: m.name,
      form: Value(form),
      doseAmount: m.doseAmount ?? 1.0,
      doseUnit: Value(m.doseUnit ?? _unitForForm(form)),
      foodRelation: Value(m.foodRelation ?? 'unspecified'),
      repeatType: const Value('daily'),
      repeatConfig: const Value('{}'),
      startDate: now,
      endDate: Value(
        DateTime(now.year, now.month, now.day).add(Duration(days: duration)),
      ),
      phases: Value(phasesJson),
      sideEffects: Value(
        m.sideEffects == null || m.sideEffects!.isEmpty ? null : jsonEncode(m.sideEffects),
      ),
    );
  }

  Future<void> _bulkSaveScanned(List<ScannedMedication> meds) async {
    final now = DateTime.now();

    if (widget.onDraftCreated != null) {
      for (final m in meds) {
        widget.onDraftCreated!(_companionFromScanned(m, now));
      }
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final medRepo = ref.read(medicationsRepositoryProvider);
      for (final m in meds) {
        await medRepo.insert(_companionFromScanned(m, now));
      }

      ref.invalidate(generateTodayIntakesProvider);
      ref.invalidate(tomorrowIntakesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bulkSavedSnackbar(meds.length)),
          ),
        );
        Navigator.of(context).pop(true);
      }
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
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  const _BackHeader({required this.title, required this.onBack, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 12,
      ),
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

class _ScanCta extends StatelessWidget {
  final bool locked;
  // null = платний план (необмежено, лічильник не показуємо).
  final int? remaining;
  const _ScanCta({this.locked = false, this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C9A6A), Color(0xFF3B7A56)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -6,
            child: Image.asset(
              'assets/illustrations/elly-telling.png',
              height: 116,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 96, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: locked
                        ? [
                            const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.moreInEllyPlusLabel,
                              style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ]
                        : [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.aiLabel,
                              style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.scanPrescriptionTitle,
                  style: AppTextStyles.labelLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.scanPrescriptionSubtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (remaining != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.scansRemainingLabel(remaining!),
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
            child: Text(
              context.l10n.orEnterManuallyLabel,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
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
    return Text(label.toUpperCase(), style: AppTextStyles.labelSm);
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextField({required this.controller, required this.hint});

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMain),
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
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
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

// ─── Phase card ───────────────────────────────────────────────────────────────

class _PhaseCard extends StatelessWidget {
  final int index;
  final _MedPhase phase;
  final bool canRemove;
  final bool isLast;
  final String foodRelation;
  final void Function(String) onFoodRelationChanged;
  final void Function(_MedPhase) onChanged;
  final VoidCallback onRemove;
  final void Function(int) onPickTime;

  const _PhaseCard({
    required this.index,
    required this.phase,
    required this.canRemove,
    required this.isLast,
    required this.foodRelation,
    required this.onFoodRelationChanged,
    required this.onChanged,
    required this.onRemove,
    required this.onPickTime,
  });

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) =>
      showWheelTimePicker(context, initialTime: initial);

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
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: Text(context.l10n.okAction),
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
              Text(
                context.l10n.phaseCardTitle(index + 1),
                style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              if (canRemove)
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
          const SizedBox(height: 10),

          // Dose per intake + Відносно їжі — в один рядок двома колонками
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.doseAmountLabel,
                      style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    _DoseRow(
                      value: phase.doseAmount,
                      onChanged: (v) =>
                          onChanged(_copyPhase(phase, doseAmount: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.foodRelationSectionLabel,
                      style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showFoodRelationPicker(
                          context,
                          current: foodRelation,
                        );
                        if (picked != null) onFoodRelationChanged(picked);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                foodRelationLabels(context)[foodRelation] ?? foodRelation,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.textMain,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          Text(
            context.l10n.durationSectionLabel,
            style: AppTextStyles.labelSm.copyWith(fontSize: 10),
          ),
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
                          : () => onChanged(
                              _copyPhase(
                                phase,
                                durationDays: phase.durationDays! - 1,
                              ),
                            ),
                    ),
                    GestureDetector(
                      onTap: isPermanent
                          ? null
                          : () async {
                              final v = await _pickInt(
                                context,
                                title: context.l10n.daysCountDialogTitle,
                                value: phase.durationDays ?? 1,
                                suffix: context.l10n.daysSuffix,
                              );
                              if (v != null) {
                                onChanged(_copyPhase(phase, durationDays: v));
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isPermanent
                              ? context.l10n.daysCountDashLabel
                              : context.l10n.daysCountLabel(
                                  phase.durationDays!,
                                ),
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    _CountBtn(
                      icon: '＋',
                      onTap: isPermanent
                          ? null
                          : () => onChanged(
                              _copyPhase(
                                phase,
                                durationDays: (phase.durationDays ?? 0) + 1,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              if (isLast) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    context.l10n.orLabel,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(
                    _copyPhase(phase, durationDays: isPermanent ? 7 : -1),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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
                      context.l10n.permanentLabel,
                      style: AppTextStyles.labelMd.copyWith(
                        color: isPermanent ? Colors.white : AppColors.textMain,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.primary),
          const SizedBox(height: 10),

          // Час прийому
          Text(
            context.l10n.intakeTimeSectionLabel,
            style: AppTextStyles.labelSm.copyWith(fontSize: 10),
          ),
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
                  label: context.l10n.specificTimeLabel,
                  active: !phase.intervalMode,
                  onTap: () => onChanged(
                    _MedPhase(
                      times: phase.times,
                      durationDays: phase.durationDays,
                      intervalMode: false,
                      intervalHours: phase.intervalHours,
                      intervalStart: phase.intervalStart,
                    ),
                  ),
                ),
                _ModeTab(
                  label: context.l10n.everyNHoursLabel,
                  active: phase.intervalMode,
                  onTap: () => onChanged(
                    _MedPhase(
                      times: phase.times,
                      durationDays: phase.durationDays,
                      intervalMode: true,
                      intervalHours: phase.intervalHours,
                      intervalStart: phase.intervalStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Content by mode
          if (!phase.intervalMode) ...[
            // ── Конкретний час ──
            ...phase.times.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await _pickTime(context, e.value);
                        if (picked != null) {
                          final updated = List<TimeOfDay>.from(phase.times);
                          updated[e.key] = picked;
                          onChanged(
                            _MedPhase(
                              times: updated,
                              durationDays: phase.durationDays,
                              intervalMode: false,
                              intervalHours: phase.intervalHours,
                              intervalStart: phase.intervalStart,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _fmt(e.value),
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (phase.times.length > 1)
                      GestureDetector(
                        onTap: () {
                          final updated = List<TimeOfDay>.from(phase.times)
                            ..removeAt(e.key);
                          onChanged(
                            _MedPhase(
                              times: updated,
                              durationDays: phase.durationDays,
                              intervalMode: false,
                              intervalHours: phase.intervalHours,
                              intervalStart: phase.intervalStart,
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                final lastHour = phase.times.isNotEmpty
                    ? phase.times.last.hour
                    : 5;
                final nextHour = lastHour < 23 ? lastHour + 1 : 23;
                final updated = List<TimeOfDay>.from(phase.times)
                  ..add(TimeOfDay(hour: nextHour, minute: 0));
                onChanged(
                  _MedPhase(
                    times: updated,
                    durationDays: phase.durationDays,
                    intervalMode: false,
                    intervalHours: phase.intervalHours,
                    intervalStart: phase.intervalStart,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.addTimeAction,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
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
                    Text(
                      context.l10n.intervalLabel,
                      style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _CountBtn(
                          icon: '−',
                          onTap: phase.intervalHours <= 1
                              ? null
                              : () => onChanged(
                                  _MedPhase(
                                    times: phase.times,
                                    durationDays: phase.durationDays,
                                    intervalMode: true,
                                    intervalHours: phase.intervalHours - 1,
                                    intervalStart: phase.intervalStart,
                                  ),
                                ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final v = await _pickInt(
                              context,
                              title: context.l10n.intervalDialogTitle,
                              value: phase.intervalHours,
                              suffix: context.l10n.hoursSuffix,
                            );
                            if (v != null) {
                              onChanged(
                                _MedPhase(
                                  times: phase.times,
                                  durationDays: phase.durationDays,
                                  intervalMode: true,
                                  intervalHours: v,
                                  intervalStart: phase.intervalStart,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              context.l10n.hoursCountLabel(
                                phase.intervalHours,
                              ),
                              style: AppTextStyles.labelLg.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        _CountBtn(
                          icon: '＋',
                          onTap: phase.intervalHours >= 23
                              ? null
                              : () => onChanged(
                                  _MedPhase(
                                    times: phase.times,
                                    durationDays: phase.durationDays,
                                    intervalMode: true,
                                    intervalHours: phase.intervalHours + 1,
                                    intervalStart: phase.intervalStart,
                                  ),
                                ),
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
                    Text(
                      context.l10n.startLabel,
                      style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await _pickTime(
                          context,
                          phase.intervalStart,
                        );
                        if (picked != null) {
                          onChanged(
                            _MedPhase(
                              times: phase.times,
                              durationDays: phase.durationDays,
                              intervalMode: true,
                              intervalHours: phase.intervalHours,
                              intervalStart: picked,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _fmt(phase.intervalStart),
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                preview,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _MedPhase _copyPhase(
    _MedPhase p, {
    int? durationDays,
    double? doseAmount,
    String? doseComment,
  }) => _MedPhase(
    times: p.times,
    durationDays: durationDays == -1 ? null : (durationDays ?? p.durationDays),
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
        hintText: context.l10n.doseCommentHint,
        hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Dose row ─────────────────────────────────────────────────────────────────

class _DoseRow extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;

  const _DoseRow({required this.value, required this.onChanged});

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    // округлення до 2 знаків
    return double.parse(
      v.toStringAsFixed(2),
    ).toString().replaceAll(RegExp(r'\.?0+$'), '');
  }

  Future<void> _openInput(BuildContext context) async {
    final ctrl = TextEditingController(text: _fmt(value));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.doseAmountDialogTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.doseAmountExampleHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: Text(context.l10n.okAction),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openInput(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_fmt(value), style: AppTextStyles.labelLg),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mode tab ─────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

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
          label: context.l10n.repeatDailyCap,
          sub: null,
          selected: selected,
          onSelect: onSelect,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'alternate',
          label: context.l10n.repeatAlternateCap,
          sub: context.l10n.weekdayExampleLabel,
          selected: selected,
          onSelect: onSelect,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'weekdays',
          label: context.l10n.weekdaysOptionLabel,
          sub: weekdays.isEmpty ? '' : _weekdayNames(context, weekdays),
          selected: selected,
          onSelect: onSelect,
          expanded: selected == 'weekdays'
              ? _WeekdayPicker(selected: weekdays, onToggle: onWeekdayToggle)
              : null,
        ),
        const SizedBox(height: 6),
        _RepeatOption(
          value: 'every_n',
          label: context.l10n.everyNDaysOptionLabel,
          sub: context.l10n.everyNDaysExampleLabel,
          selected: selected,
          onSelect: onSelect,
          expanded: selected == 'every_n'
              ? _StepperRow(
                  label: context.l10n.everyLabel,
                  suffix: context.l10n.daysSuffixWord,
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
          label: context.l10n.cycleOptionLabel,
          sub: context.l10n.cycleExampleLabel,
          selected: selected,
          onSelect: onSelect,
          expanded: selected == 'cycle'
              ? Column(
                  children: [
                    _StepperRow(
                      label: context.l10n.drinkLabel,
                      suffix: context.l10n.daysSuffixWord,
                      value: cycleOn,
                      onDecrement: () => cycleOn > 1
                          ? onCycleChanged(cycleOn - 1, cycleOff)
                          : null,
                      onIncrement: () => onCycleChanged(cycleOn + 1, cycleOff),
                    ),
                    const SizedBox(height: 8),
                    _StepperRow(
                      label: context.l10n.breakLabel,
                      suffix: context.l10n.daysSuffixWord,
                      value: cycleOff,
                      onDecrement: () => cycleOff > 1
                          ? onCycleChanged(cycleOn, cycleOff - 1)
                          : null,
                      onIncrement: () => onCycleChanged(cycleOn, cycleOff + 1),
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  String _weekdayNames(BuildContext context, Set<int> days) {
    final names = [
      '',
      context.l10n.dayMon,
      context.l10n.dayTue,
      context.l10n.dayWed,
      context.l10n.dayThu,
      context.l10n.dayFri,
      context.l10n.daySat,
      context.l10n.daySun,
    ];
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
            width: sel ? 2 : 1.5,
          ),
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
                        Text(
                          sub!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
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
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        )
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

  @override
  Widget build(BuildContext context) {
    final days = [
      context.l10n.dayMon,
      context.l10n.dayTue,
      context.l10n.dayWed,
      context.l10n.dayThu,
      context.l10n.dayFri,
      context.l10n.daySat,
      context.l10n.daySun,
    ];
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
                days[i],
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
          child: Text(
            '$value $suffix',
            style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
          ),
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
      text: widget.isPermanent ? '' : '${widget.days}',
    );
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
                    child: Icon(
                      Icons.remove_rounded,
                      size: 18,
                      color: widget.isPermanent
                          ? AppColors.textMuted
                          : AppColors.textMain,
                    ),
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
                      hintStyle: AppTextStyles.bodyLg.copyWith(
                        color: AppColors.textMuted,
                      ),
                      suffixText: widget.isPermanent
                          ? ''
                          : ' ${context.l10n.daysSuffix}',
                      suffixStyle: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSub,
                      ),
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
                    child: Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: widget.isPermanent
                          ? AppColors.textMuted
                          : AppColors.textMain,
                    ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isPermanent ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isPermanent
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: Text(
              context.l10n.permanentLabel,
              style: AppTextStyles.labelMd.copyWith(
                color: widget.isPermanent ? Colors.white : AppColors.textMain,
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
  final String form;
  final List<String> photoPaths;
  final String? colorHex;
  final void Function(bool) onTrackToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final void Function(int) onEdit;
  final void Function(List<String>) onPhotosChanged;
  final void Function(String) onColorChanged;

  const _OptionalSection({
    required this.trackStock,
    required this.availableCount,
    required this.phases,
    required this.doseAmount,
    required this.doseUnit,
    required this.form,
    required this.photoPaths,
    required this.colorHex,
    required this.onTrackToggle,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
    required this.onPhotosChanged,
    required this.onColorChanged,
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
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.optionalParamsLabel,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ),
                Text(
                  context.l10n.optionalLabel,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
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
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.trackStockLabel,
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

                      if (isPercentTrackedForm(widget.form)) ...[
                        Text(
                          context.l10n.vialPackageLabel,
                          style: AppTextStyles.labelMd,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.markAsOpenedHint,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ] else ...[
                        Text(
                          context.l10n.inStockLabel,
                          style: AppTextStyles.labelMd,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.howManyNowLabel(widget.doseUnit),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PillCountRow(
                          count: widget.availableCount,
                          unit: widget.doseUnit,
                          onDecrement: widget.onDecrement,
                          onIncrement: widget.onIncrement,
                          onEdit: widget.onEdit,
                        ),
                      ],

                      if (!isPercentTrackedForm(widget.form) && needed > 0) ...[
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
                                    : Icons.check_circle_outline_rounded,
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
                                            TextSpan(
                                              text:
                                                  context.l10n.needToBuyLabel,
                                            ),
                                            TextSpan(
                                              text: '$toBuy ${widget.doseUnit}',
                                              style: AppTextStyles.labelMd
                                                  .copyWith(
                                                    color: AppColors.primary,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: context.l10n
                                                  .courseAvailableLabel(
                                                    needed,
                                                    widget.availableCount,
                                                  ),
                                              style: AppTextStyles.bodySm
                                                  .copyWith(
                                                    color: AppColors.textMuted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        context.l10n.enoughForCourseLabel,
                                        style: AppTextStyles.bodyMd.copyWith(
                                          color: Colors.green.shade700,
                                        ),
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

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Кастомний колір картки
                TaskColorPicker(
                  selectedHex: widget.colorHex,
                  onChanged: widget.onColorChanged,
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
                title: Text(context.l10n.quantityHint),
                content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(suffixText: unit),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.actionCancel),
                  ),
                  TextButton(
                    onPressed: () {
                      final v = int.tryParse(ctrl.text.trim());
                      Navigator.pop(ctx, v != null && v >= 0 ? v : null);
                    },
                    child: Text(context.l10n.okAction),
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
  final Map<String, Uint8List> _bytesCache = {};
  bool _loading = false;

  Future<Uint8List> _decrypted(String rel) async {
    return _bytesCache[rel] ??= await PhotoService.decryptedBytes(rel);
  }

  Future<void> _add() async {
    setState(() => _loading = true);
    try {
      // Якщо дозвіл вже перманентно відхилений — новий виклик pickImage лише
      // мовчки провалиться (ОС не показує діалог вдруге), тож перевіряємо
      // заздалегідь і ведемо одразу в налаштування застосунку замість цього.
      final granted = await CameraPermissionService.ensureGranted();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.noCameraAccessError)),
          );
        }
        return;
      }
      final path = await PhotoService.pickAndSave(ImageSource.camera);
      if (path != null) {
        widget.onChanged([...widget.paths, path]);
      }
    } on PlatformException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cameraOpenError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String rel) async {
    await PhotoService.delete(rel);
    _bytesCache.remove(rel);
    widget.onChanged(widget.paths.where((p) => p != rel).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.packagePhotoLabel, style: AppTextStyles.labelMd),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _loading ? null : _add,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.addPhotoAction,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.addPhotoHint,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.l10n.packagePhotoLabel, style: AppTextStyles.labelMd),
            const Spacer(),
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              GestureDetector(
                onTap: _add,
                child: Text(
                  context.l10n.addAction,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.paths.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final rel = widget.paths[i];
              return FutureBuilder<Uint8List>(
                future: _decrypted(rel),
                builder: (ctx, snap) {
                  final bytes = snap.data;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: bytes != null
                            ? Image.memory(
                                bytes,
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
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
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
            color: onTap != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            icon,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 18,
              color: onTap != null ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
