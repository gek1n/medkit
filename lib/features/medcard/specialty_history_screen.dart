import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../data/repositories/lab_results_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../../shared/widgets/photo_gallery_viewer.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/specialty_picker.dart';
import '../appointments/add_appointment_screen.dart';
import 'lab_result_detail_screen.dart';

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
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddAppointmentScreen(memberId: widget.memberId)),
        ),
      ),
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
    final now = DateTime.now();
    final all = <_TimelineEntry>[
      ...apts.map(_TimelineEntry.appointment),
      ...labs.map(_TimelineEntry.lab),
    ];

    if (all.isEmpty) return const _EmptyState();

    // Аналізи завжди в минулому (дата взяття), тож "заплановані" тут — це
    // лише майбутні візити до лікаря.
    final upcoming = all.where((e) => e.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = all.where((e) => !e.date.isAfter(now)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    Widget entryTile(_TimelineEntry e) => Padding(
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
                      builder: (_) => LabResultDetailScreen(result: e.labResult!),
                    ),
                  ),
                ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.md,
        AppDimensions.screenPadding,
        48,
      ),
      children: [
        if (upcoming.isNotEmpty) ...[
          const SectionLabel('Заплановані'),
          const SizedBox(height: AppDimensions.sm),
          ...upcoming.map(entryTile),
          const SizedBox(height: AppDimensions.md),
        ],
        if (past.isNotEmpty) ...[
          const SectionLabel('Минулі'),
          const SizedBox(height: AppDimensions.sm),
          ...past.map(entryTile),
        ],
      ],
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
    return _FeedCard(
      icon: Icons.medical_services_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      title: 'Візит · ${apt.doctorType}',
      subtitle: apt.location != null && apt.location!.isNotEmpty
          ? '${_formatDate(apt.scheduledAt)} · ${apt.location}'
          : _formatDate(apt.scheduledAt),
      notes: apt.notes,
      documentPathsJson: apt.documentPaths,
      onTap: onTap,
    );
  }
}

class _LabEntry extends StatelessWidget {
  final LabResult result;
  final VoidCallback onTap;
  const _LabEntry({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _FeedCard(
      icon: Icons.biotech_rounded,
      iconColor: AppColors.info,
      iconBg: AppColors.infoLight,
      title: 'Аналіз · ${result.testName?.isNotEmpty == true ? result.testName! : result.specialty}',
      subtitle: _formatDate(result.takenAt),
      notes: result.notes,
      documentPathsJson: result.documentPaths,
      onTap: onTap,
    );
  }
}

/// Картка-"пост" у стилі стрічки: заголовок з іконкою, дата/місце,
/// нотатки-підпис, а нижче — сітка фото (тап відкриває перегляд із
/// масштабуванням і гортанням) та окремі чипи для PDF (тап — "Поділитися",
/// той самий підхід, що й у [DocumentsSection]).
class _FeedCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? notes;
  final String documentPathsJson;
  final VoidCallback onTap;

  const _FeedCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.notes,
    required this.documentPathsJson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paths = List<String>.from(jsonDecode(documentPathsJson) as List);
    final images = paths.where((p) => !PhotoService.isPdf(p)).toList();
    final pdfs = paths.where(PhotoService.isPdf).toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.labelLg),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(notes!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMain)),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: images.asMap().entries.map((e) {
                return GestureDetector(
                  onTap: () => showPhotoGalleryViewer(context, imagePaths: images, initialIndex: e.key),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: FutureBuilder<Uint8List>(
                        future: PhotoService.decryptedBytes(e.value),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              color: AppColors.bgPage,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          return Image.memory(snapshot.data!, fit: BoxFit.cover);
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (pdfs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pdfs
                  .map((p) => GestureDetector(
                        onTap: () => PhotoService.shareDecrypted(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.danger),
                              SizedBox(width: 6),
                              Text('PDF', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
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
