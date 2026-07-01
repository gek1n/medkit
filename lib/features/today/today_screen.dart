import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/section_label.dart';
import '../analytics/analytics_screen.dart';
import 'providers/today_providers.dart';
import 'widgets/family_status_strip.dart';
import 'widgets/today_med_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Генеруємо прийоми для сьогодні при відкритті
    ref.watch(generateTodayIntakesProvider);

    final memberAsync = ref.watch(currentMemberProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('Помилка: $e')),
      ),
      data: (member) {
        if (member == null) return const _EmptyState();
        return _TodayContent(member: member);
      },
    );
  }
}

class _TodayContent extends ConsumerWidget {
  final Member member;
  const _TodayContent({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));
    final membersAsync = ref.watch(allMembersProvider);
    // activityLogsAsync буде використано після реалізації активностей

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: intakesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (intakes) {
          final pending = intakes.where((i) => i.status == 'pending' || i.status == 'snoozed').toList();
          final done = intakes.where((i) => i.status == 'taken' || i.status == 'skipped').toList();
          final taken = intakes.where((i) => i.status == 'taken').length;
          final total = intakes.length;
          final progress = total > 0 ? taken / total : 0.0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, l10n, member, taken, total, progress),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppDimensions.xl),
                    membersAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (members) => members.length > 1
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionLabel(l10n.sectionFamily),
                                const SizedBox(height: AppDimensions.md),
                                FamilyStatusStrip(
                                  members: members,
                                  currentMemberId: member.id,
                                  ref: ref,
                                ),
                                const SizedBox(height: AppDimensions.xl),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (pending.isNotEmpty) ...[
                      SectionLabel(l10n.sectionScheduled),
                      const SizedBox(height: AppDimensions.md),
                      ...pending.map((intake) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDimensions.sm),
                            child: TodayMedCard(
                              intake: intake,
                              ref: ref,
                            ),
                          )),
                      const SizedBox(height: AppDimensions.xl),
                    ],
                    if (done.isNotEmpty) ...[
                      SectionLabel(l10n.sectionDone),
                      const SizedBox(height: AppDimensions.md),
                      ...done.map((intake) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDimensions.sm),
                            child: TodayMedCard(
                              intake: intake,
                              ref: ref,
                            ),
                          )),
                      const SizedBox(height: AppDimensions.xl),
                    ],
                    if (intakes.isEmpty)
                      _buildEmptyDay(l10n),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    Member member,
    int taken,
    int total,
    double progress,
  ) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            AppDimensions.lg,
            AppDimensions.screenPadding,
            0,
          ),
          child: MkCard(
            color: AppColors.primary,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _avatarEmoji(member.avatarIndex),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: AppTextStyles.h3
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            l10n.todayProgressTitle(taken, total),
                            style: AppTextStyles.bodyMd.copyWith(
                                color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AnalyticsScreen(memberId: member.id),
                        ),
                      ),
                      child: Text(
                        l10n.todayProgressPercent(
                            (progress * 100).round()),
                        style: AppTextStyles.h2.copyWith(
                            color: Colors.white, fontSize: 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  l10n.todayProgressSubtitle,
                  style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDay(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('✅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Ліків на сьогодні немає',
              style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Натисніть + щоб додати',
              style:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
        ],
      ),
    );
  }

  String _avatarEmoji(int index) {
    const avatars = ['🧑', '👩', '👨', '👧', '👦', '👴', '👵', '🧒'];
    return avatars[index % avatars.length];
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text('Ласкаво просимо до MedKit',
                style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Додайте свій профіль щоб розпочати',
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textSub)),
          ],
        ),
      ),
    );
  }
}
