import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../add/routine_view_screen.dart';
import '../today/providers/today_providers.dart';

final _rotatingActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).watchAllRotating();
});

/// Всі рутинні справи сім'ї з ротацією виконавців, одним екраном — без
/// необхідності перемикатись між профілями, щоб побачити, чия сьогодні
/// черга. Тап на картку веде до RoutineViewScreen (повна інформація +
/// обмін/пропуск черги).
class FamilyDutiesScreen extends ConsumerWidget {
  const FamilyDutiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(_rotatingActivitiesProvider);
    final members = ref.watch(allMembersProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(context.l10n.routineAllRoutinesScreenTitle,
                        style: AppTextStyles.h3),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activitiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) =>
                    Center(child: Text(context.l10n.errorGeneric('$e'))),
                data: (activities) {
                  if (activities.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.routineNoAssigneesHint,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      0,
                      AppDimensions.screenPadding,
                      40,
                    ),
                    itemCount: activities.length,
                    itemBuilder: (context, i) =>
                        _DutyCard(activity: activities[i], members: members),
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

class _DutyCard extends ConsumerWidget {
  final Activity activity;
  final List<Member> members;
  const _DutyCard({required this.activity, required this.members});

  String _memberName(int id) =>
      members.where((m) => m.id == id).map((m) => m.name).firstOrNull ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorFromHex(activity.color) ?? AppColors.primary;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoutineViewScreen(activityId: activity.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const AssetIcon('task_routine', size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  FutureBuilder<int>(
                    future: ref
                        .read(activitiesRepositoryProvider)
                        .assigneeForDate(activity, DateTime.now()),
                    builder: (context, snap) {
                      final name =
                          snap.hasData ? _memberName(snap.data!) : '';
                      return Text(
                        name.isEmpty
                            ? ''
                            : context.l10n.routineWhoseTurnLabel(name),
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSub),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
