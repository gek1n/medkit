import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/models/family_member.dart';
import '../../data/models/med_intake.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/section_label.dart';
import 'widgets/family_status_strip.dart';
import 'widgets/today_med_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final List<FamilyMember> _members = const [
    FamilyMember(id: '1', name: 'Ти', avatar: '🧑', role: FamilyMemberRole.owner, takenToday: 2, totalToday: 4),
    FamilyMember(id: '2', name: 'Мама', avatar: '👩', role: FamilyMemberRole.member, takenToday: 3, totalToday: 3),
    FamilyMember(id: '3', name: 'Тато', avatar: '👨', role: FamilyMemberRole.dependent, takenToday: 1, totalToday: 2),
  ];

  late List<MedIntake> _intakes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _intakes = [
      MedIntake(id: '1', medicationId: 'm1', medicationName: 'Метформін', medicationDose: '500 мг', medicationEmoji: '💊',
          scheduledAt: DateTime(now.year, now.month, now.day, 8, 0), status: IntakeStatus.taken, takenAt: DateTime(now.year, now.month, now.day, 8, 5)),
      MedIntake(id: '2', medicationId: 'm2', medicationName: 'Омега-3', medicationDose: '1000 мг', medicationEmoji: '💊',
          scheduledAt: DateTime(now.year, now.month, now.day, 12, 0), status: IntakeStatus.taken, takenAt: DateTime(now.year, now.month, now.day, 12, 10)),
      MedIntake(id: '3', medicationId: 'm3', medicationName: 'Вітамін D3', medicationDose: '2000 МО', medicationEmoji: '💊',
          scheduledAt: DateTime(now.year, now.month, now.day, 14, 0), status: IntakeStatus.pending),
      MedIntake(id: '4', medicationId: 'm4', medicationName: 'Магній В6', medicationDose: '400 мг', medicationEmoji: '💊',
          scheduledAt: DateTime(now.year, now.month, now.day, 20, 0), status: IntakeStatus.pending),
    ];
  }

  int get _takenCount => _intakes.where((i) => i.isTaken).length;
  int get _totalCount => _intakes.length;
  double get _progress => _totalCount > 0 ? _takenCount / _totalCount : 0;

  void _markTaken(String id) {
    setState(() {
      final idx = _intakes.indexWhere((i) => i.id == id);
      if (idx != -1) _intakes[idx] = _intakes[idx].copyWith(status: IntakeStatus.taken, takenAt: DateTime.now());
    });
  }

  void _markSkipped(String id) {
    setState(() {
      final idx = _intakes.indexWhere((i) => i.id == id);
      if (idx != -1) _intakes[idx] = _intakes[idx].copyWith(status: IntakeStatus.skipped);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = _intakes.where((i) => i.isPending).toList();
    final done = _intakes.where((i) => !i.isPending).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(l10n)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.xl),
                SectionLabel(l10n.sectionFamily),
                const SizedBox(height: AppDimensions.md),
                FamilyStatusStrip(members: _members),
                const SizedBox(height: AppDimensions.xl),
                if (pending.isNotEmpty) ...[
                  SectionLabel(l10n.sectionScheduled),
                  const SizedBox(height: AppDimensions.md),
                  ...pending.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: TodayMedCard(intake: i, onTaken: () => _markTaken(i.id), onSkipped: () => _markSkipped(i.id)),
                  )),
                  const SizedBox(height: AppDimensions.xl),
                ],
                if (done.isNotEmpty) ...[
                  SectionLabel(l10n.sectionDone),
                  const SizedBox(height: AppDimensions.md),
                  ...done.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: TodayMedCard(intake: i, onTaken: null, onSkipped: null),
                  )),
                  const SizedBox(height: AppDimensions.xl),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.screenPadding, AppDimensions.lg, AppDimensions.screenPadding, 0),
          child: MkCard(
            color: AppColors.primary,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💊', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.appName, style: AppTextStyles.h2.copyWith(color: Colors.white)),
                          Text(
                            l10n.todayProgressTitle(_takenCount, _totalCount),
                            style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.todayProgressPercent((_progress * 100).round()),
                      style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 32),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  l10n.todayProgressSubtitle,
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
