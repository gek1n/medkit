import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../../shared/widgets/form_chips.dart';
import '../../shared/widgets/tag_search_filter_bar.dart';
import '../medications/medication_detail_screen.dart';

enum _MedStatus { ongoing, finished, cancelled }

extension on _MedStatus {
  String label(BuildContext context) => switch (this) {
        _MedStatus.ongoing => context.l10n.medStatusOngoing,
        _MedStatus.finished => context.l10n.medStatusFinished,
        _MedStatus.cancelled => context.l10n.medStatusCancelled,
      };

  Color get fg => switch (this) {
        _MedStatus.ongoing => AppColors.primary,
        _MedStatus.finished => AppColors.info,
        _MedStatus.cancelled => AppColors.textMuted,
      };

  Color get bg => switch (this) {
        _MedStatus.ongoing => AppColors.primaryLight,
        _MedStatus.finished => AppColors.infoLight,
        _MedStatus.cancelled => AppColors.border,
      };
}

/// Статус виводиться з наявних полів (isActive/endDate/updatedAt) — без
/// нового поля в схемі: [softDelete] лише виставляє isActive=false й
/// оновлює updatedAt, реальну причину зупинки ("відмінив" чи "закінчив
/// курс") ніде не записує. Якщо зупинили на/після запланованої дати
/// завершення курсу — вважаємо, що курс дійшов кінця природно; якщо
/// раніше (або курс був безстроковий) — відмінили.
_MedStatus _statusOf(Medication m) {
  if (m.isActive) return _MedStatus.ongoing;
  if (m.endDate != null && !m.updatedAt.isBefore(m.endDate!)) {
    return _MedStatus.finished;
  }
  return _MedStatus.cancelled;
}

final _archiveProvider = StreamProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).watchAllByMember(memberId);
});

class MedicationArchiveScreen extends ConsumerStatefulWidget {
  final int memberId;
  const MedicationArchiveScreen({super.key, required this.memberId});

  @override
  ConsumerState<MedicationArchiveScreen> createState() => _MedicationArchiveScreenState();
}

class _MedicationArchiveScreenState extends ConsumerState<MedicationArchiveScreen> {
  String _search = '';
  Set<String> _selectedStatuses = {};

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(_archiveProvider(widget.memberId));

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
                  Expanded(child: Text(context.l10n.medCardArchiveTitle, style: AppTextStyles.h3)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding, 0, AppDimensions.screenPadding, AppDimensions.sm),
              child: TagSearchFilterBar(
                searchHint: context.l10n.searchHint,
                onSearchChanged: (v) => setState(() => _search = v),
                tagsLoader: () async =>
                    _MedStatus.values.map((s) => s.label(context)).toList(),
                selectedTags: _selectedStatuses,
                onTagsChanged: (v) => setState(() => _selectedStatuses = v),
                filterAllLabel: context.l10n.allStatusesFilter,
                filterSheetTitle: context.l10n.medStatusFilterPickerTitle,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_archiveProvider(widget.memberId)),
                child: medsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                  data: (meds) {
                    if (meds.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          MkEmptyState(hint: context.l10n.medicationArchiveEmptyHint),
                        ],
                      );
                    }
                    final query = _search.trim().toLowerCase();
                    final filtered = meds.where((m) {
                      final matchesQuery = query.isEmpty ||
                          m.name.toLowerCase().contains(query) ||
                          (medFormLabels(context)[m.form] ?? m.form).toLowerCase().contains(query);
                      final matchesStatus = _selectedStatuses.isEmpty ||
                          _selectedStatuses.contains(_statusOf(m).label(context));
                      return matchesQuery && matchesStatus;
                    }).toList();
                    if (filtered.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          MkEmptyState(hint: context.l10n.noResultsFoundHint),
                        ],
                      );
                    }
                    final sorted = [...filtered]..sort((a, b) => b.startDate.compareTo(a.startDate));
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 48),
                      itemCount: sorted.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                        child: _ArchiveCard(
                          med: sorted[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MedicationDetailScreen(
                                medicationId: sorted[i].id,
                                memberId: widget.memberId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onTap;
  const _ArchiveCard({required this.med, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(med);
    final range = med.endDate != null
        ? '${MKDateUtils.formatDate(context, med.startDate)} — ${MKDateUtils.formatDate(context, med.endDate!)}'
        : context.l10n.medArchiveDateRangeOngoing(MKDateUtils.formatDate(context, med.startDate));

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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: MedcardIcon(med.iconKey ?? 'form_cream', size: 24),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    '${medFormLabels(context)[med.form] ?? med.form} · $range',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status.bg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                status.label(context),
                style: AppTextStyles.bodySm.copyWith(color: status.fg, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
