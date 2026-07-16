import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/allergy_severity.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/allergies_repository.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import 'add_allergy_screen.dart';
import 'allergy_detail_screen.dart';

final _allergiesProvider = StreamProvider.family<List<Allergy>, int>((ref, memberId) {
  return ref.watch(allergiesRepositoryProvider).watchByMember(memberId);
});

class AllergiesScreen extends ConsumerWidget {
  final int memberId;
  const AllergiesScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allergiesAsync = ref.watch(_allergiesProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddAllergyScreen(memberId: memberId)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MkListHeader(title: context.l10n.allergiesTitle),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_allergiesProvider(memberId)),
                child: allergiesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                data: (allergies) {
                  if (allergies.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        MkEmptyState(
                          hint: context.l10n.allergiesEmptyHint,
                        ),
                      ],
                    );
                  }
                  // Найтяжчі — першими: це та інформація, яку варто побачити
                  // з першого погляду.
                  final sorted = [...allergies]..sort(
                      (a, b) => AllergySeverity.fromDb(b.severity)
                          .weight
                          .compareTo(AllergySeverity.fromDb(a.severity).weight));
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 48),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _AllergyCard(
                        allergy: sorted[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllergyDetailScreen(allergy: sorted[i]),
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

class _AllergyCard extends StatelessWidget {
  final Allergy allergy;
  final VoidCallback onTap;
  const _AllergyCard({required this.allergy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final severity = AllergySeverity.fromDb(allergy.severity);
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: severity == AllergySeverity.severe ? AppColors.danger : AppColors.border,
            width: severity == AllergySeverity.severe ? 1.5 : 1,
          ),
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
              child: const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.danger),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(allergy.allergen, style: AppTextStyles.labelLg),
                  if (allergy.reaction != null && allergy.reaction!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      allergy.reaction!,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severity.bgColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                severity.label(context),
                style: AppTextStyles.bodySm.copyWith(color: severity.color, fontWeight: FontWeight.w700),
              ),
            ),
            if ((jsonDecode(allergy.documentPaths) as List).isNotEmpty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
