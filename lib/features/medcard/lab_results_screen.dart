import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/lab_results_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import 'add_lab_result_screen.dart';

final _labResultsProvider = StreamProvider.family<List<LabResult>, int>((
  ref,
  memberId,
) {
  return ref.watch(labResultsRepositoryProvider).watchByMember(memberId);
});

class LabResultsScreen extends ConsumerWidget {
  final int memberId;
  const LabResultsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(_labResultsProvider(memberId));

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
                  Expanded(child: Text('Аналізи', style: AppTextStyles.h3)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddLabResultScreen(memberId: memberId),
                      ),
                    ),
                    child: Text(
                      '+ Додати',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Помилка: $e')),
                data: (results) {
                  if (results.isEmpty) return const _EmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.md,
                      AppDimensions.screenPadding,
                      48,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _LabResultCard(
                        result: results[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddLabResultScreen(
                              memberId: memberId,
                              existing: results[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabResultCard extends StatelessWidget {
  final LabResult result;
  final VoidCallback onTap;
  const _LabResultCard({required this.result, required this.onTap});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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
                    result.testName?.isNotEmpty == true
                        ? result.testName!
                        : result.specialty,
                    style: AppTextStyles.labelLg,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.specialty} · ${_formatDate(result.takenAt)}',
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
              'Натисніть "+ Додати" щоб додати перший аналіз',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
