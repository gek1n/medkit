import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/attachment_cleanup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/member_name_suffix.dart';
import '../../core/utils/plan_access.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../today/providers/today_providers.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_date_picker.dart';
import '../../shared/widgets/mk_form_fields.dart';
import '../../shared/widgets/specialty_picker.dart';
import '../../shared/widgets/task_color_picker.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../plans/elly_denied_screen.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  final int memberId;
  final DoctorAppointment? existing;
  // Транзитний префіл із голосової команди (не з БД, на відміну від
  // [existing]) — той самий підхід, що й voicePrefill в AddMedicationScreen.
  // Дата/час не приходять — voice/parse на бекенді їх не розпізнає, тож
  // лишаємо дефолтні (сьогодні), користувач підправить сам.
  final String? voicePrefillDoctorType;
  const AddAppointmentScreen({
    super.key,
    required this.memberId,
    this.existing,
    this.voicePrefillDoctorType,
  });

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  late final TextEditingController _doctorController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late DateTime _date;
  late TimeOfDay _time;
  int _remindBeforeMin = 1440;
  String? _colorHex;
  List<String> _documentPaths = [];
  bool _isSaving = false;

  bool get _isPastVisit =>
      DateTime(_date.year, _date.month, _date.day).isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );

  static const _remindOptions = [
    (60, 'За 1 годину'),
    (1440, 'За день'),
    (2880, 'За 2 дні'),
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _doctorController = TextEditingController(
      text: ex?.doctorType ?? widget.voicePrefillDoctorType ?? '',
    );
    _locationController = TextEditingController(text: ex?.location ?? '');
    _notesController = TextEditingController(text: ex?.notes ?? '');
    _colorHex = ex?.color;
    if (ex != null) {
      _documentPaths = List<String>.from(jsonDecode(ex.documentPaths) as List);
      _date = ex.scheduledAt;
      _time = TimeOfDay(
        hour: ex.scheduledAt.hour,
        minute: ex.scheduledAt.minute,
      );
      _remindBeforeMin = ex.remindBeforeMin;
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
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Видалити',
              style: AppTextStyles.bodyMd.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AttachmentCleanupService.deletePaths(widget.existing!.documentPaths);
    await ref
        .read(doctorAppointmentsRepositoryProvider)
        .delete(widget.existing!.id);
    await NotificationService.cancelAppointmentReminder(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    // Дозволяємо минулі дати — цей самий екран використовується і для
    // запису майбутнього візиту з нагадуванням, і для внесення заднім
    // числом того, що вже відбулось (walk-in візит, стара історія).
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

  Future<void> _pickSpecialty() async {
    final picked = await showSpecialtyPicker(
      context,
      current: _doctorController.text.trim(),
    );
    if (picked != null) setState(() => _doctorController.text = picked);
  }

  Future<void> _save() async {
    final doctorType = _doctorController.text.trim();
    if (doctorType.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введіть тип лікаря')));
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

      final int appointmentId;
      if (widget.existing != null) {
        appointmentId = widget.existing!.id;
        await ref
            .read(doctorAppointmentsRepositoryProvider)
            .update(
              DoctorAppointmentsCompanion(
                id: Value(appointmentId),
                doctorType: Value(doctorType),
                scheduledAt: Value(scheduledAt),
                location: Value(locationVal),
                remindBeforeMin: Value(_remindBeforeMin),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                color: Value(_colorHex),
              ),
            );
      } else {
        appointmentId = await ref
            .read(doctorAppointmentsRepositoryProvider)
            .insert(
              DoctorAppointmentsCompanion.insert(
                memberId: widget.memberId,
                doctorType: doctorType,
                scheduledAt: scheduledAt,
                location: Value(locationVal),
                remindBeforeMin: Value(_remindBeforeMin),
                notes: Value(notesVal),
                documentPaths: Value(jsonEncode(_documentPaths)),
                color: Value(_colorHex),
              ),
            );
      }

      final settings = ref.read(notificationSettingsProvider);
      final rawReminderAt = scheduledAt.subtract(
        Duration(minutes: _remindBeforeMin),
      );
      final remindAt = settings.adjust(
        rawReminderAt,
        memberId: widget.memberId,
      );
      if (remindAt != null) {
        final members = ref.read(allMembersProvider).valueOrNull ?? [];
        String memberName = '';
        for (final m in members) {
          if (m.id == widget.memberId) {
            memberName = m.name;
            break;
          }
        }
        await NotificationService.scheduleAppointmentReminder(
          appointmentId: appointmentId,
          memberName: memberName,
          doctorType: doctorType,
          location: locationVal,
          scheduledAt: remindAt,
          remindBeforeMin: 0,
          vibrationEnabled: settings.vibrationEnabled,
          repeatMinutes: settings.repeatMinutes,
        );
      } else {
        await NotificationService.cancelAppointmentReminder(appointmentId);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка: $e')));
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
                  (isEdit
                      ? 'Редагувати запис'
                      : (_isPastVisit ? 'Записати візит' : 'Запис до лікаря')) +
                  memberNameSuffix(ref, widget.memberId),
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
                    // Doctor type
                    MkFieldLabel('Напрямок лікаря'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _doctorController,
                      hint: 'Оберіть напрямок',
                      readOnly: true,
                      onTap: _pickSpecialty,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Location
                    MkFieldLabel('Де'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _locationController,
                      hint: 'Клініка, адреса або онлайн',
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Date & time
                    MkFieldLabel('Дата та час'),
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
                            child: _DateTimeBox(label: 'ЧАС', value: '$hh:$mm'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Remind before — не потрібно для візиту, що вже минув
                    if (!_isPastVisit) ...[
                      MkFieldLabel('Нагадати заздалегідь'),
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
                          }),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.lg),
                    ],

                    // Notes — до візиту це "що запитати", після — висновок лікаря
                    MkFieldLabel(_isPastVisit ? 'Висновок лікаря' : 'Нотатка'),
                    const SizedBox(height: 6),
                    MkTextField(
                      controller: _notesController,
                      maxLines: 3,
                      hint: _isPastVisit
                          ? 'Що сказав лікар, рекомендації, призначення…'
                          : 'Що запитати, взяти з собою, номер поліса…',
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    DocumentsSection(
                      paths: _documentPaths,
                      onChanged: (paths) =>
                          setState(() => _documentPaths = paths),
                      label: 'Документи',
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    TaskColorPicker(
                      selectedHex: _colorHex,
                      onChanged: (hex) => setState(() => _colorHex = hex),
                    ),
                    const SizedBox(height: 32),

                    MkSaveButton(
                      isSaving: _isSaving,
                      onPressed: _save,
                      label: isEdit
                          ? 'Зберегти зміни'
                          : (_isPastVisit
                                ? 'Зберегти візит'
                                : 'Зберегти нагадування'),
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
      '',
      'січня',
      'лютого',
      'березня',
      'квітня',
      'травня',
      'червня',
      'липня',
      'серпня',
      'вересня',
      'жовтня',
      'листопада',
      'грудня',
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
