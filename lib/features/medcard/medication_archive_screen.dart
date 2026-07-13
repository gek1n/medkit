import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/med_form_icons.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../../shared/widgets/form_chips.dart';
import '../medications/add_medication_screen.dart';

enum _MedStatus { ongoing, finished, cancelled }

extension on _MedStatus {
  String get label => switch (this) {
        _MedStatus.ongoing => 'Триває',
        _MedStatus.finished => 'Завершено',
        _MedStatus.cancelled => 'Відмінено',
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

class MedicationArchiveScreen extends ConsumerWidget {
  final int memberId;
  const MedicationArchiveScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(_archiveProvider(memberId));

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
                  Expanded(child: Text('Архів ліків', style: AppTextStyles.h3)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_archiveProvider(memberId)),
                child: medsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Помилка: $e')),
                  data: (meds) {
                    if (meds.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          MkEmptyState(hint: 'Тут з\'являться всі ліки, які ви колись додавали'),
                        ],
                      );
                    }
                    final sorted = [...meds]..sort((a, b) => b.startDate.compareTo(a.startDate));
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
                              builder: (_) => AddMedicationScreen(memberId: memberId, existing: sorted[i]),
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
        ? '${MKDateUtils.formatDate(med.startDate)} — ${MKDateUtils.formatDate(med.endDate!)}'
        : '${MKDateUtils.formatDate(med.startDate)} — досі';

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
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(medFormIcon(med.form), size: 20, color: AppColors.textSub),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    '${medFormLabels[med.form] ?? med.form} · $range',
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
                status.label,
                style: AppTextStyles.bodySm.copyWith(color: status.fg, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
