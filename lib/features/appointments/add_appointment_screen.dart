import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import 'appointments_history_screen.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  final int memberId;
  final DoctorAppointment? existing;
  const AddAppointmentScreen({super.key, required this.memberId, this.existing});

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState
    extends ConsumerState<AddAppointmentScreen> {
  late final TextEditingController _doctorController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late DateTime _date;
  late TimeOfDay _time;
  int _remindBeforeMin = 1440;
  bool _isSaving = false;

  static const _remindOptions = [
    (60, 'За 1 годину'),
    (1440, 'За день'),
    (2880, 'За 2 дні'),
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _doctorController = TextEditingController(text: ex?.doctorType ?? '');
    _locationController = TextEditingController(text: ex?.location ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    if (ex != null) {
      _date = ex.scheduledAt;
      _time = TimeOfDay(hour: ex.scheduledAt.hour, minute: ex.scheduledAt.minute);
      _remindBeforeMin = ex.remindBeforeMin ?? 1440;
    } else {
      _date = DateTime.now();
      _time = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити запис?'),
        content: const Text('Запис до лікаря буде видалено.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Видалити',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref
        .read(doctorAppointmentsRepositoryProvider)
        .delete(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final doctorType = _doctorController.text.trim();
    if (doctorType.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введіть тип лікаря')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final scheduledAt = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute,
      );
      final locationVal = _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim();
      final notesVal = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (widget.existing != null) {
        await ref.read(doctorAppointmentsRepositoryProvider).update(
              DoctorAppointmentsCompanion(
                id: Value(widget.existing!.id),
                doctorType: Value(doctorType),
                scheduledAt: Value(scheduledAt),
                location: Value(locationVal),
                remindBeforeMin: Value(_remindBeforeMin),
                notes: Value(notesVal),
              ),
            );
      } else {
        await ref.read(doctorAppointmentsRepositoryProvider).insert(
              DoctorAppointmentsCompanion.insert(
                memberId: widget.memberId,
                doctorType: doctorType,
                scheduledAt: scheduledAt,
                location: Value(locationVal),
                remindBeforeMin: Value(_remindBeforeMin),
                notes: Value(notesVal),
              ),
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
    final hh = _time.hour.toString().padLeft(2, '0');
    final mm = _time.minute.toString().padLeft(2, '0');

    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _BackHeader(
              title: isEdit ? 'Редагувати запис' : 'Запис до лікаря',
              onBack: () => Navigator.pop(context),
              trailingLabel: isEdit ? null : 'Список',
              onTrailing: isEdit ? null : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppointmentsHistoryScreen(),
                ),
              ),
              onDelete: isEdit ? _delete : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor type
                    _Label('Лікар або процедура'),
                    const SizedBox(height: 6),
                    _Input(
                      controller: _doctorController,
                      hint: 'Кардіолог, Терапевт, УЗД…',
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Location
                    _Label('Де'),
                    const SizedBox(height: 6),
                    _Input(
                      controller: _locationController,
                      hint: 'Клініка, адреса або онлайн',
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Date & time
                    _Label('Дата та час'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: _DateTimeBox(
                              label: 'ДАТА',
                              value: _formatDate(_date),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: _DateTimeBox(
                              label: 'ЧАС',
                              value: '$hh:$mm',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Remind before
                    _Label('Нагадати заздалегідь'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._remindOptions.map((opt) {
                          final sel = _remindBeforeMin == opt.$1;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _remindBeforeMin = opt.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
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
                        }),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Notes
                    _Label('Нотатка'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Що запитати, взяти з собою, номер поліса…',
                          hintStyle: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // PDF hint
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFDDD6FE), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Text('📄', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Додати виписку',
                                    style: AppTextStyles.labelMd.copyWith(
                                        color: const Color(0xFF4C1D95))),
                                const SizedBox(height: 3),
                                Text(
                                  'Сформувати PDF з ліками та симптомами за 30 днів',
                                  style: AppTextStyles.bodySm.copyWith(
                                      color: const Color(0xFF5B21B6)),
                                ),
                              ],
                            ),
                          ),
                          const Text('→',
                              style: TextStyle(
                                  fontSize: 18, color: Color(0xFF7C3AED))),
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
                          _isSaving
                              ? 'Зберігаємо...'
                              : (isEdit ? 'Зберегти зміни' : 'Зберегти нагадування'),
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

  String _formatDate(DateTime d) {
    const months = [
      '', 'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.h3.copyWith(
                  color: AppColors.textMain, fontSize: 15)),
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final String? trailingLabel;
  final VoidCallback? onTrailing;
  final VoidCallback? onDelete;
  const _BackHeader({
    required this.title,
    required this.onBack,
    this.trailingLabel,
    this.onTrailing,
    this.onDelete,
  });

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
          Expanded(child: Text(title, style: AppTextStyles.h3)),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailing,
              child: Text(
                trailingLabel!,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary),
              ),
            ),
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
                child: const Icon(Icons.delete_outline,
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
