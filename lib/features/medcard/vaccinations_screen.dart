import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/vaccinations_repository.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import 'add_vaccination_screen.dart';
import 'vaccination_detail_screen.dart';

final _vaccinationsProvider = StreamProvider.family<List<Vaccination>, int>((ref, memberId) {
  return ref.watch(vaccinationsRepositoryProvider).watchByMember(memberId);
});

class VaccinationsScreen extends ConsumerWidget {
  final int memberId;
  const VaccinationsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinationsAsync = ref.watch(_vaccinationsProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddVaccinationScreen(memberId: memberId)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const MkListHeader(title: 'Щеплення'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_vaccinationsProvider(memberId)),
                child: vaccinationsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Помилка: $e')),
                data: (vaccinations) {
                  if (vaccinations.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        MkEmptyState(
                          hint: 'Натисніть "+ Додати" щоб додати перше щеплення',
                        ),
                      ],
                    );
                  }
                  // Ті, де скоро/прострочена ревакцинація — першими: саме це
                  // варто побачити з першого погляду.
                  final sorted = [...vaccinations]..sort((a, b) {
                      final aUrgency = _urgency(a.nextDoseAt);
                      final bUrgency = _urgency(b.nextDoseAt);
                      if (aUrgency != bUrgency) return aUrgency.compareTo(bUrgency);
                      return b.givenAt.compareTo(a.givenAt);
                    });
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 48),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _VaccinationCard(
                        vaccination: sorted[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VaccinationDetailScreen(vaccination: sorted[i]),
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

  // 0 = прострочена, 1 = найближчі 30 днів, 2 = далі в майбутньому, 3 = немає
  static int _urgency(DateTime? nextDoseAt) {
    if (nextDoseAt == null) return 3;
    final daysLeft = nextDoseAt.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 0;
    if (daysLeft <= 30) return 1;
    return 2;
  }
}

class _VaccinationCard extends StatelessWidget {
  final Vaccination vaccination;
  final VoidCallback onTap;
  const _VaccinationCard({required this.vaccination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDocs = (jsonDecode(vaccination.documentPaths) as List).isNotEmpty;
    final next = vaccination.nextDoseAt;
    final urgency = VaccinationsScreen._urgency(next);

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: urgency <= 1 ? AppColors.warning : AppColors.border,
            width: urgency <= 1 ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.vaccines_rounded, size: 20, color: AppColors.warning),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vaccination.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    'Введено ${MKDateUtils.formatDate(vaccination.givenAt)}',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            if (next != null) ...[
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgency == 0
                      ? AppColors.dangerLight
                      : urgency == 1
                          ? AppColors.warningLight
                          : AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  urgency == 0 ? 'Прострочено' : MKDateUtils.formatDate(next),
                  style: AppTextStyles.bodySm.copyWith(
                    color: urgency == 0
                        ? AppColors.danger
                        : urgency == 1
                            ? AppColors.warning
                            : AppColors.textSub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (hasDocs) ...[
              const SizedBox(width: 6),
              const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
