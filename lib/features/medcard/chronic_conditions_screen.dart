import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/chronic_conditions_repository.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import 'add_chronic_condition_screen.dart';
import 'chronic_condition_detail_screen.dart';

final _conditionsProvider = StreamProvider.family<List<ChronicCondition>, int>((ref, memberId) {
  return ref.watch(chronicConditionsRepositoryProvider).watchByMember(memberId);
});

class ChronicConditionsScreen extends ConsumerWidget {
  final int memberId;
  const ChronicConditionsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(_conditionsProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddChronicConditionScreen(memberId: memberId)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MkListHeader(title: context.l10n.chronicConditionsSectionTitle),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_conditionsProvider(memberId)),
                child: conditionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                data: (conditions) {
                  if (conditions.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        MkEmptyState(
                          hint: context.l10n.chronicConditionsEmptyHint,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 48),
                    itemCount: conditions.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _ConditionCard(
                        condition: conditions[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChronicConditionDetailScreen(condition: conditions[i]),
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

class _ConditionCard extends StatelessWidget {
  final ChronicCondition condition;
  final VoidCallback onTap;
  const _ConditionCard({required this.condition, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDocs = (jsonDecode(condition.documentPaths) as List).isNotEmpty;
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
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.favorite_rounded, size: 20, color: AppColors.danger),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(condition.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (condition.specialty != null) condition.specialty!,
                      if (condition.diagnosedAt != null)
                        MKDateUtils.formatDate(context, condition.diagnosedAt!),
                    ].join(' · '),
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
