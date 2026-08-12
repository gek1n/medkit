import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../core/utils/plan_access.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../core/utils/task_color.dart';
import '../../shared/widgets/assignee_picker.dart';
import '../../shared/widgets/field_sheet.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import '../plans/elly_denied_screen.dart';
import 'wellbeing_history_screen.dart';

class AddWellbeingScheduleScreen extends ConsumerStatefulWidget {
  final int? memberId;
  // Онбординг: власного профілю ще не існує в БД на момент показу цього
  // екрана. Коли задано — форма лишається без змін, але замість запису в БД
  // (та планування сповіщень) повертає компаньйон (з фіктивним memberId,
  // який викликач підмінить) — той самий патерн, що й AddMedicationScreen.
  final void Function(WellbeingSchedulesCompanion draft)? onDraftCreated;
  const AddWellbeingScheduleScreen({
    super.key,
    this.memberId,
    this.onDraftCreated,
  }) : assert(
          memberId != null || onDraftCreated != null,
          'AddWellbeingScheduleScreen needs either memberId or onDraftCreated',
        );

  @override
  ConsumerState<AddWellbeingScheduleScreen> createState() =>
      _AddWellbeingScheduleScreenState();
}

class _AddWellbeingScheduleScreenState
    extends ConsumerState<AddWellbeingScheduleScreen> {
  int _timesPerDay = 2;
  // #325-доробка: "Кому" — без ротації, null означає "лише widget.memberId".
  AssigneeSelection? _assignees;
  List<TimeOfDay> _slots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 20, minute: 0),
  ];
  String? _colorHex;
  bool _isSaving = false;
  bool _loaded = false;
  bool _hasActiveExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.memberId != null) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final existing = await ref
        .read(wellbeingRepositoryProvider)
        .getScheduleByMember(widget.memberId!);
    if (existing != null && mounted) {
      final times = List<String>.from(jsonDecode(existing.times) as List);
      setState(() {
        _timesPerDay = existing.timesPerDay;
        _slots = times.map((t) {
          final parts = t.split(':');
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
        _colorHex = existing.color;
        _hasActiveExisting = existing.isActive;
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  void _setTimesPerDay(int count) {
    setState(() {
      _timesPerDay = count;
      if (_slots.length < count) {
        final defaults = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 13, minute: 0),
          const TimeOfDay(hour: 17, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
        while (_slots.length < count) {
          _slots.add(defaults[_slots.length % defaults.length]);
        }
      } else {
        _slots = _slots.sublist(0, count);
      }
    });
  }

  Future<void> _pickTime(int index) async {
    final picked =
        await showWheelTimePicker(context, initialTime: _slots[index]);
    if (picked != null) setState(() => _slots[index] = picked);
  }

  Future<void> _disable() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.disableWellbeingConfirmTitle),
        content: Text(ctx.l10n.disableWellbeingConfirmBody),
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
    await ref.read(wellbeingRepositoryProvider).setActive(widget.memberId!, false);
    await NotificationService.cancelAllWellbeingForMember(widget.memberId!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final timesJson = jsonEncode(_slots.map((t) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }).toList());

    if (widget.onDraftCreated != null) {
      widget.onDraftCreated!(
        WellbeingSchedulesCompanion.insert(
          memberId: 0,
          timesPerDay: Value(_timesPerDay),
          times: Value(timesJson),
          isActive: const Value(true),
          color: Value(_colorHex),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(wellbeingRepositoryProvider).upsertSchedule(
            WellbeingSchedulesCompanion(
              memberId: Value(widget.memberId!),
              timesPerDay: Value(_timesPerDay),
              times: Value(timesJson),
              isActive: const Value(true),
              color: Value(_colorHex),
            ),
          );

      await NotificationService.cancelAllWellbeingForMember(widget.memberId!);
      final wellbeingRepo = ref.read(wellbeingRepositoryProvider);
      final saved = await wellbeingRepo.getScheduleByMember(widget.memberId!);
      if (saved != null) {
        await wellbeingRepo.scheduleNotificationsForSchedule(saved);
      }

      // #325-доробка: "Кому" — без ротації, кожен додатково обраний одразу
      // отримує власний незалежний розклад (upsertSchedule і так один-на-
      // -члена, повторний виклик з іншим memberId просто створює/оновлює
      // ЙОГО власний рядок, нічого спільного з widget.memberId).
      final sel = _assignees;
      if (sel != null) {
        for (final id in sel.localMemberIds) {
          if (id == widget.memberId) continue;
          await wellbeingRepo.upsertSchedule(
            WellbeingSchedulesCompanion(
              memberId: Value(id),
              timesPerDay: Value(_timesPerDay),
              times: Value(timesJson),
              isActive: const Value(true),
              color: Value(_colorHex),
            ),
          );
          await NotificationService.cancelAllWellbeingForMember(id);
          final extraSaved = await wellbeingRepo.getScheduleByMember(id);
          if (extraSaved != null) {
            await wellbeingRepo.scheduleNotificationsForSchedule(extraSaved);
          }
        }
        for (final uuid in sel.peerPersonUuids) {
          final peer =
              ref.read(allFamilyPeersProvider).where((p) => p.personUuid == uuid).firstOrNull;
          if (peer == null) continue;
          await submitWellbeingScheduleProposal(
            ref,
            peer,
            WellbeingSchedulesCompanion.insert(
              memberId: 0,
              timesPerDay: Value(_timesPerDay),
              times: Value(timesJson),
              isActive: const Value(true),
              color: Value(_colorHex),
            ),
          );
        }
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      MkBackButton(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      Text(
                        '${context.l10n.wellbeingTitle}${widget.memberId != null ? memberNameSuffix(context, ref, widget.memberId!) : ''}',
                        style: AppTextStyles.h3,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.memberId != null)
                        GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WellbeingHistoryScreen(
                                memberId: widget.memberId!),
                          ),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                      if (_hasActiveExisting) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _disable,
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
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, size: 24, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.l10n.wellbeingScheduleInfoText,
                              style: AppTextStyles.bodySm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Frequency
                    Text(context.l10n.frequencyPerDayLabel, style: AppTextStyles.labelSm),
                    const SizedBox(height: 8),
                    Row(
                      children: [1, 2, 3, 4].map((n) {
                        final sel = _timesPerDay == n;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _setTimesPerDay(n),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primaryLight
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: sel ? 2 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    context.l10n.timesCountShort(n),
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.textSub,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Time slots
                    Text(context.l10n.collectionTimeLabel, style: AppTextStyles.labelSm),
                    const SizedBox(height: 8),
                    ...List.generate(_timesPerDay, (i) {
                      final t = _slots[i];
                      final hh = t.hour.toString().padLeft(2, '0');
                      final mm = t.minute.toString().padLeft(2, '0');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _pickTime(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0F000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 6)),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(
                                  context.l10n.wellbeingSlotNumberLabel(i + 1),
                                  style: AppTextStyles.bodyMd
                                      .copyWith(color: AppColors.textSub),
                                ),
                                const Spacer(),
                                Text(
                                  '$hh:$mm',
                                  style: AppTextStyles.bodyLg.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 18, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppDimensions.lg),

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
                          onChanged: (hex) => setState(() => _colorHex = hex),
                        ),
                      ),
                    ),
                    if (widget.memberId != null) ...[
                      const SizedBox(height: AppDimensions.md),
                      AssigneeFieldChip(
                        selection: _assignees ??
                            AssigneeSelection(
                                localMemberIds: {widget.memberId!}, peerPersonUuids: const {}, mode: 'all'),
                        onTap: () async {
                          final result = await showAssigneePicker(
                            context,
                            initial: _assignees ??
                                AssigneeSelection(
                                    localMemberIds: {widget.memberId!}, peerPersonUuids: const {}, mode: 'all'),
                          );
                          if (result != null) setState(() => _assignees = result);
                        },
                      ),
                    ],
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
                          _isSaving ? context.l10n.savingLabel : context.l10n.saveScheduleAction,
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
}
