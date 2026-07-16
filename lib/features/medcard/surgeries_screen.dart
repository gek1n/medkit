import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/surgeries_repository.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import 'add_surgery_screen.dart';
import 'surgery_detail_screen.dart';

final _surgeriesProvider = StreamProvider.family<List<Surgery>, int>((ref, memberId) {
  return ref.watch(surgeriesRepositoryProvider).watchByMember(memberId);
});

class SurgeriesScreen extends ConsumerWidget {
  final int memberId;
  const SurgeriesScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surgeriesAsync = ref.watch(_surgeriesProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddSurgeryScreen(memberId: memberId)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MkListHeader(title: context.l10n.surgeriesSectionTitle),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_surgeriesProvider(memberId)),
                child: surgeriesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                data: (surgeries) {
                  if (surgeries.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        MkEmptyState(
                          hint: context.l10n.surgeriesEmptyHint,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 48),
                    itemCount: surgeries.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _SurgeryCard(
                        surgery: surgeries[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurgeryDetailScreen(surgery: surgeries[i]),
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

class _SurgeryCard extends StatelessWidget {
  final Surgery surgery;
  final VoidCallback onTap;
  const _SurgeryCard({required this.surgery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDocs = (jsonDecode(surgery.documentPaths) as List).isNotEmpty;
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
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.local_hospital_rounded, size: 20, color: AppColors.warning),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surgery.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    MKDateUtils.formatDate(context, surgery.performedAt),
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
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
