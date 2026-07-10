import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../data/repositories/lab_results_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/specialty_picker.dart';
import '../appointments/add_appointment_screen.dart';
import 'add_lab_result_screen.dart';

final _memberAppointmentsProvider =
    StreamProvider.family<List<DoctorAppointment>, int>((ref, memberId) {
      return ref
          .watch(doctorAppointmentsRepositoryProvider)
          .watchByMember(memberId);
    });

final _memberLabResultsProvider = StreamProvider.family<List<LabResult>, int>((
  ref,
  memberId,
) {
  return ref.watch(labResultsRepositoryProvider).watchByMember(memberId);
});

/// Об'єднана хронологія візитів (`DoctorAppointments`) і аналізів
/// (`LabResults`) для одного члена сім'ї, з фільтром за напрямком — щоб на
/// прийомі можна було швидко показати лікарю все, що з ним пов'язано.
class SpecialtyHistoryScreen extends ConsumerStatefulWidget {
  final int memberId;
  const SpecialtyHistoryScreen({super.key, required this.memberId});

  @override
  ConsumerState<SpecialtyHistoryScreen> createState() =>
      _SpecialtyHistoryScreenState();
}

class _SpecialtyHistoryScreenState
    extends ConsumerState<SpecialtyHistoryScreen> {
  String? _specialty;

  Future<void> _pickSpecialty() async {
    final picked = await showSpecialtyPicker(context, current: _specialty);
    if (picked != null) setState(() => _specialty = picked);
  }

  @override
  Widget build(BuildContext context) {
    final aptsAsync = ref.watch(_memberAppointmentsProvider(widget.memberId));
    final labsAsync = ref.watch(_memberLabResultsProvider(widget.memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Історія за напрямком',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddAppointmentScreen(memberId: widget.memberId),
                      ),
                    ),
                    child: Text(
                      '+ Візит',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  onTap: _pickSpecialty,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _specialty != null
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      border: Border.all(
                        color: _specialty != null
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: _specialty != null
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _specialty ?? 'Усі напрямки',
                          style: AppTextStyles.labelMd.copyWith(
                            color: _specialty != null
                                ? AppColors.primary
                                : AppColors.textSub,
                          ),
                        ),
                        if (_specialty != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _specialty = null),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Expanded(
              child: aptsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Помилка: $e')),
                data: (apts) => labsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('Помилка: $e')),
                  data: (labs) => _Timeline(
                    apts: _specialty == null
                        ? apts
                        : apts
                              .where((a) => a.doctorType == _specialty)
                              .toList(),
                    labs: _specialty == null
                        ? labs
                        : labs.where((l) => l.specialty == _specialty).toList(),
                    memberId: widget.memberId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry {
  final DateTime date;
  final DoctorAppointment? appointment;
  final LabResult? labResult;
  _TimelineEntry.appointment(this.appointment)
    : date = appointment!.scheduledAt,
      labResult = null;
  _TimelineEntry.lab(this.labResult)
    : date = labResult!.takenAt,
      appointment = null;
}

class _Timeline extends StatelessWidget {
  final List<DoctorAppointment> apts;
  final List<LabResult> labs;
  final int memberId;
  const _Timeline({
    required this.apts,
    required this.labs,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <_TimelineEntry>[
      ...apts.map(_TimelineEntry.appointment),
      ...labs.map(_TimelineEntry.lab),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (entries.isEmpty) return const _EmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.md,
        AppDimensions.screenPadding,
        48,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: e.appointment != null
              ? _AppointmentEntry(
                  apt: e.appointment!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddAppointmentScreen(
                        memberId: memberId,
                        existing: e.appointment,
                      ),
                    ),
                  ),
                )
              : _LabEntry(
                  result: e.labResult!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLabResultScreen(
                        memberId: memberId,
                        existing: e.labResult,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class _AppointmentEntry extends StatelessWidget {
  final DoctorAppointment apt;
  final VoidCallback onTap;
  const _AppointmentEntry({required this.apt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Візит · ${apt.doctorType}',
                    style: AppTextStyles.labelLg,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    apt.location != null && apt.location!.isNotEmpty
                        ? '${_formatDate(apt.scheduledAt)} · ${apt.location}'
                        : _formatDate(apt.scheduledAt),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                  if (apt.notes != null && apt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      apt.notes!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if ((jsonDecode(apt.documentPaths) as List).isNotEmpty)
              const Icon(
                Icons.attach_file_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _LabEntry extends StatelessWidget {
  final LabResult result;
  final VoidCallback onTap;
  const _LabEntry({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.biotech_rounded,
                size: 20,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Аналіз · ${result.testName?.isNotEmpty == true ? result.testName! : result.specialty}',
                    style: AppTextStyles.labelLg,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(result.takenAt),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            if ((jsonDecode(result.documentPaths) as List).isNotEmpty)
              const Icon(
                Icons.attach_file_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/illustrations/elly-docs.png', height: 140),
            const SizedBox(height: 16),
            Text('Ще нічого не додано', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Візити й аналізи з\'являться тут',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
