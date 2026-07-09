import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import 'wellbeing_history_screen.dart';

class AddWellbeingScheduleScreen extends ConsumerStatefulWidget {
  final int memberId;
  const AddWellbeingScheduleScreen({super.key, required this.memberId});

  @override
  ConsumerState<AddWellbeingScheduleScreen> createState() =>
      _AddWellbeingScheduleScreenState();
}

class _AddWellbeingScheduleScreenState
    extends ConsumerState<AddWellbeingScheduleScreen> {
  int _timesPerDay = 2;
  List<TimeOfDay> _slots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 20, minute: 0),
  ];
  String? _colorHex;
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await ref
        .read(wellbeingRepositoryProvider)
        .getScheduleByMember(widget.memberId);
    if (existing != null && mounted) {
      final times = List<String>.from(jsonDecode(existing.times) as List);
      setState(() {
        _timesPerDay = existing.timesPerDay;
        _slots = times.map((t) {
          final parts = t.split(':');
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
        _colorHex = existing.color;
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final timesJson = jsonEncode(_slots.map((t) {
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      }).toList());

      await ref.read(wellbeingRepositoryProvider).upsertSchedule(
            WellbeingSchedulesCompanion(
              memberId: Value(widget.memberId),
              timesPerDay: Value(_timesPerDay),
              times: Value(timesJson),
              isActive: const Value(true),
              color: Value(_colorHex),
            ),
          );

      await NotificationService.cancelAllWellbeingForMember(widget.memberId);
      final settings = ref.read(notificationSettingsProvider);
      for (var i = 0; i < _slots.length; i++) {
        final now = DateTime.now();
        final raw = DateTime(
            now.year, now.month, now.day, _slots[i].hour, _slots[i].minute);
        final at = settings.adjust(raw, memberId: widget.memberId);
        if (at == null) continue;
        await NotificationService.scheduleWellbeingDaily(
          memberId: widget.memberId,
          slotIndex: i,
          hour: at.hour,
          minute: at.minute,
        );
      }

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
                      Text('Самопочуття', style: AppTextStyles.h3),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WellbeingHistoryScreen(memberId: widget.memberId),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('Історія',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.textSub)),
                    ),
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
                              'Налаштуйте розклад збору зрізів самопочуття. '
                              'У призначений час на головному екрані з\'явиться картка для заповнення.',
                              style: AppTextStyles.bodySm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Frequency
                    Text('ЧАСТОТА НА ДЕНЬ', style: AppTextStyles.labelSm),
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
                                    '$n раз${n == 1 ? '' : n < 5 ? 'и' : 'ів'}',
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
                    Text('ЧАС ЗБОРУ', style: AppTextStyles.labelSm),
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
                                  'Зріз ${i + 1}',
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
                          _isSaving ? 'Зберігаємо...' : 'Зберегти розклад',
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
