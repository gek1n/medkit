import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';

class AddActivityScreen extends ConsumerStatefulWidget {
  final int memberId;
  const AddActivityScreen({super.key, required this.memberId});

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  String _type = 'walk';
  final _nameController = TextEditingController(text: 'Ранкова прогулянка');
  int _durationMin = 30;
  final List<TimeOfDay> _slots = [const TimeOfDay(hour: 8, minute: 30)];
  final Set<int> _weekdays = {1, 2, 3, 4, 5};
  bool _reminder = true;
  bool _isSaving = false;

  static const _types = [
    ('walk', '🚶', 'Прогулянка'),
    ('workout', '🏋️', 'Зарядка'),
    ('gym', '💪', 'Тренування'),
    ('yoga', '🧘', 'Йога / ЛФК'),
    ('cycling', '🚴', 'Велосипед'),
    ('custom', '＋', 'Своє'),
  ];

  static const _durations = [15, 30, 45, 60];
  static const _dayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введіть назву активності')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(activitiesRepositoryProvider);
      final activityId = await repo.insertActivity(ActivitiesCompanion.insert(
        memberId: widget.memberId,
        name: name,
        type: Value(_type),
        durationMin: Value(_durationMin),
        repeatDays: Value(jsonEncode(_weekdays.toList()..sort())),
        reminderBeforeMin: Value(_reminder ? 10 : 0),
      ));

      final slots = _slots.asMap().entries.map((e) {
        final hh = e.value.hour.toString().padLeft(2, '0');
        final mm = e.value.minute.toString().padLeft(2, '0');
        return ActivitySlotsCompanion.insert(
          activityId: activityId,
          timeOfDay: '$hh:$mm',
          durationMin: Value(_durationMin),
          sortOrder: Value(e.key),
        );
      }).toList();
      await repo.insertSlots(slots);

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(
                title: 'Активність', onBack: () => Navigator.pop(context)),
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
                        final sel = _type == t.$1;
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
                                Text(t.$2,
                                    style: const TextStyle(fontSize: 22)),
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

                    // Duration
                    _Label('Тривалість'),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 0,
                      childAspectRatio: 2,
                      children: _durations.map((d) {
                        final sel = _durationMin == d;
                        return GestureDetector(
                          onTap: () => setState(() => _durationMin = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
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
                                d < 60 ? '$d хв' : '1 год',
                                style: AppTextStyles.labelMd.copyWith(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.textSub,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Slots
                    _Label('Розклад'),
                    const SizedBox(height: 8),
                    ..._slots.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ActivitySlot(
                            index: e.key,
                            time: e.value,
                            duration: _durationMin,
                            onTimeTap: () => _pickTime(e.key),
                            onRemove: _slots.length > 1
                                ? () =>
                                    setState(() => _slots.removeAt(e.key))
                                : null,
                          ),
                        )),
                    GestureDetector(
                      onTap: () => setState(() => _slots
                          .add(TimeOfDay(hour: 17 + _slots.length, minute: 0))),
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
                          _isSaving ? 'Зберігаємо...' : 'Зберегти активність',
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
      initialTime: _slots[index],
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _slots[index] = picked);
  }
}

// ─── Slot widget ──────────────────────────────────────────────────────────────

class _ActivitySlot extends StatelessWidget {
  final int index;
  final TimeOfDay time;
  final int duration;
  final VoidCallback onTimeTap;
  final VoidCallback? onRemove;

  const _ActivitySlot({
    required this.index,
    required this.time,
    required this.duration,
    required this.onTimeTap,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Заняття ${index + 1}',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.primary)),
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
              Expanded(child: _SlotField(label: 'Час', value: '$hh:$mm', onTap: onTimeTap)),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotField(
                  label: 'Тривалість',
                  value: duration < 60 ? '$duration хв' : '1 год',
                  onTap: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _BackHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
  final VoidCallback? onTap;
  const _SlotField({required this.label, required this.value, this.onTap});

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
              border:
                  Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Text(value,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary)),
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
              style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
