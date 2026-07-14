import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/lab_results_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../../shared/widgets/specialty_picker.dart';
import 'add_lab_result_screen.dart';
import 'lab_result_detail_screen.dart';

final _labResultsProvider = StreamProvider.family<List<LabResult>, int>((
  ref,
  memberId,
) {
  return ref.watch(labResultsRepositoryProvider).watchByMember(memberId);
});

class LabResultsScreen extends ConsumerStatefulWidget {
  final int memberId;
  const LabResultsScreen({super.key, required this.memberId});

  @override
  ConsumerState<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends ConsumerState<LabResultsScreen> {
  String? _specialty;

  Future<void> _pickSpecialty() async {
    final picked = await showSpecialtyPicker(context, current: _specialty);
    if (picked != null) setState(() => _specialty = picked);
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(_labResultsProvider(widget.memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddLabResultScreen(memberId: widget.memberId)),
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
                  Expanded(child: Text('Аналізи', style: AppTextStyles.h3)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SpecialtyFilterChip(
                  specialty: _specialty,
                  onTap: _pickSpecialty,
                  onClear: () => setState(() => _specialty = null),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_labResultsProvider(widget.memberId)),
                child: resultsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Помилка: $e')),
                data: (allResults) {
                  final results = _specialty == null
                      ? allResults
                      : allResults.where((r) => r.specialty == _specialty).toList();
                  if (results.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_EmptyState(filtered: _specialty != null)],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                            builder: (_) => LabResultDetailScreen(result: results[i]),
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

class _SpecialtyFilterChip extends StatelessWidget {
  final String? specialty;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _SpecialtyFilterChip({
    required this.specialty,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final active = specialty != null;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              specialty ?? 'Усі напрямки',
              style: AppTextStyles.labelMd.copyWith(
                color: active ? AppColors.primary : AppColors.textSub,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
              ),
            ],
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
  final bool filtered;
  const _EmptyState({this.filtered = false});
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
            Text(filtered ? 'Немає аналізів за цим напрямком' : 'Ще нічого не додано',
                style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Спробуйте обрати інший напрямок або скиньте фільтр'
                  : 'Натисніть "+ Додати" щоб додати перший аналіз',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
