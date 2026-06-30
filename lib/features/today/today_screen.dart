import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/models/family_member.dart';
import '../../data/models/med_intake.dart';
import '../../shared/widgets/pro_gate.dart';
import '../../shared/widgets/section_label.dart';
import 'widgets/family_status_strip.dart';
import 'widgets/today_med_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late List<MedIntake> _intakes;

  final List<FamilyMember> _family = const [
    FamilyMember(
      id: '1',
      name: 'Я',
      avatar: '🧑',
      role: FamilyMemberRole.owner,
      takenToday: 1,
      totalToday: 3,
    ),
    FamilyMember(
      id: '2',
      name: 'Мама',
      avatar: '👩',
      role: FamilyMemberRole.member,
      takenToday: 3,
      totalToday: 3,
    ),
    FamilyMember(
      id: '3',
      name: 'Тато',
      avatar: '👴',
      role: FamilyMemberRole.dependent,
      takenToday: 1,
      totalToday: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _intakes = [
      MedIntake(
        id: '1',
        medicationId: 'm1',
        medicationName: 'Еналаприл',
        medicationDose: '10 мг',
        medicationEmoji: '💊',
        scheduledAt: DateTime(now.year, now.month, now.day, 8),
        status: IntakeStatus.taken,
        takenAt: DateTime(now.year, now.month, now.day, 8, 5),
      ),
      MedIntake(
        id: '2',
        medicationId: 'm2',
        medicationName: 'Метформін',
        medicationDose: '500 мг',
        medicationEmoji: '💊',
        scheduledAt: DateTime(now.year, now.month, now.day, 13),
        status: IntakeStatus.pending,
      ),
      MedIntake(
        id: '3',
        medicationId: 'm3',
        medicationName: 'Омега-3',
        medicationDose: '1 капсула',
        medicationEmoji: '💊',
        scheduledAt: DateTime(now.year, now.month, now.day, 13),
        status: IntakeStatus.pending,
      ),
      MedIntake(
        id: '4',
        medicationId: 'm1',
        medicationName: 'Еналаприл',
        medicationDose: '10 мг',
        medicationEmoji: '💊',
        scheduledAt: DateTime(now.year, now.month, now.day, 20),
        status: IntakeStatus.pending,
      ),
    ];
  }

  void _markTaken(String id) => setState(() {
        _intakes = _intakes
            .map((e) => e.id == id
                ? e.copyWith(
                    status: IntakeStatus.taken, takenAt: DateTime.now())
                : e)
            .toList();
      });

  void _markSkipped(String id) => setState(() {
        _intakes = _intakes
            .map((e) =>
                e.id == id ? e.copyWith(status: IntakeStatus.skipped) : e)
            .toList();
      });

  int get _takenCount => _intakes.where((e) => e.isTaken).length;
  int get _totalCount => _intakes.length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = _intakes.where((e) => e.isPending).toList();
    final done = _intakes.where((e) => !e.isPending).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.lg),
                _ProgressCard(
                    taken: _takenCount, total: _totalCount, l10n: l10n),
                const SizedBox(height: AppDimensions.xxl),
                SectionLabel(l10n.sectionFamily,
                    action: l10n.actionAll, onAction: () {}),
                const SizedBox(height: AppDimensions.md),
                ProGate(
                  locked: !AppConfig.canAddFamilyMembers &&
                      _family.length > 1,
                  title: l10n.familyProRequired,
                  body: l10n.familyProBody,
                  child: FamilyStatusStrip(members: _family),
                ),
                const SizedBox(height: AppDimensions.xxl),
                if (pending.isNotEmpty) ...[
                  SectionLabel(l10n.sectionScheduled),
                  const SizedBox(height: AppDimensions.md),
                  ...pending.map((intake) => TodayMedCard(
                        intake: intake,
                        onTake: () => _markTaken(intake.id),
                        onSkip: () => _markSkipped(intake.id),
                      )),
                  const SizedBox(height: AppDimensions.xxl),
                ],
                if (done.isNotEmpty) ...[
                  SectionLabel(l10n.sectionDone),
                  const SizedBox(height: AppDimensions.md),
                  ...done.map((intake) => TodayMedCard(
                        intake: intake,
                        onTake: () {},
                        onSkip: () {},
                      )),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final now = DateTime.now();
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: 72,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
            left: AppDimensions.screenPadding, bottom: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MKDateUtils.formatDate(now), style: AppTextStyles.h3),
            Text(MKDateUtils.formatDayName(now),
                style: AppTextStyles.bodySm),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
              right: AppDimensions.lg, bottom: 8),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🧑', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int taken;
  final int total;
  final AppLocalizations l10n;

  const _ProgressCard(
      {required this.taken, required this.total, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? taken / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B35A8), Color(0xFF9B6DE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayProgressTitle(taken, total),
                      style:
                          AppTextStyles.h1.copyWith(color: Colors.white),
                    ),
                    Text(
                      l10n.todayProgressSubtitle,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.todayProgressPercent((pct * 100).round()),
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
