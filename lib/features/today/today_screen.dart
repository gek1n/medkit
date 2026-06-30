import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/models/family_member.dart';
import '../../data/models/med_intake.dart';
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
      takenToday: 0,
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
                ? e.copyWith(status: IntakeStatus.taken, takenAt: DateTime.now())
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
    final visibleFamily = AppConfig.canAddFamilyMembers
        ? _family
        : _family.take(1).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: _ProgressRingCard(
              taken: _takenCount,
              total: _totalCount,
              l10n: l10n,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding, AppDimensions.xxl,
                  AppDimensions.screenPadding, AppDimensions.md),
              child: SectionLabel(
                l10n.sectionFamily,
                action: l10n.actionAll,
                onAction: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: AppDimensions.screenPadding),
              child: FamilyStatusStrip(
                members: visibleFamily,
                showProHint: !AppConfig.canAddFamilyMembers && _family.length > 1,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.xxl),
                  SectionLabel(l10n.sectionScheduled),
                  const SizedBox(height: AppDimensions.md),
                  ...pending.map((intake) => TodayMedCard(
                        intake: intake,
                        onTake: () => _markTaken(intake.id),
                        onSkip: () => _markSkipped(intake.id),
                      )),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.xxl),
                  SectionLabel(l10n.sectionDone),
                  const SizedBox(height: AppDimensions.md),
                  ...done.map((intake) => TodayMedCard(
                        intake: intake,
                        onTake: () {},
                        onSkip: () {},
                      )),
                ],
                const SizedBox(height: AppDimensions.xxl),
                SectionLabel(l10n.wellbeingTitle),
                const SizedBox(height: AppDimensions.md),
                _WellbeingCheckin(l10n: l10n),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final now = DateTime.now();
    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.todayGreeting,
            style: AppTextStyles.h3,
          ),
          Text(
            '${MKDateUtils.formatDate(now)}, ${MKDateUtils.formatDayName(now)}',
            style: AppTextStyles.bodySm,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.lg),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderLight),
      ),
    );
  }
}

class _ProgressRingCard extends StatelessWidget {
  final int taken;
  final int total;
  final AppLocalizations l10n;

  const _ProgressRingCard({
    required this.taken,
    required this.total,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? taken / total : 0.0;
    final skipped = 0;
    final pending = total - taken - skipped;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.screenPadding),
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primaryMid, width: 1.5),
      ),
      child: Row(
        children: [
          _RingSvg(percent: pct),
          const SizedBox(width: AppDimensions.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(pct * 100).round()}%',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.todayProgressSubtitle,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    _RingLegend(
                        dot: AppColors.success,
                        label: l10n.todayLegendTaken(taken)),
                    const SizedBox(width: AppDimensions.md),
                    _RingLegend(
                        dot: AppColors.textMuted,
                        label: l10n.todayLegendPending(pending)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingSvg extends StatelessWidget {
  final double percent;
  const _RingSvg({required this.percent});

  @override
  Widget build(BuildContext context) {
    const size = 80.0;
    const strokeWidth = 8.0;
    const radius = (size - strokeWidth) / 2;
    const circumference = 2 * 3.14159 * radius;
    final offset = circumference * (1 - percent);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -1.5708,
            child: CustomPaint(
              size: const Size(size, size),
              painter: _RingPainter(
                percent: percent,
                circumference: circumference,
                offset: offset,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final double circumference;
  final double offset;
  final double strokeWidth;

  const _RingPainter({
    required this.percent,
    required this.circumference,
    required this.offset,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = AppColors.primaryMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14159 * percent,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}

class _RingLegend extends StatelessWidget {
  final Color dot;
  final String label;
  const _RingLegend({required this.dot, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}

class _WellbeingCheckin extends StatefulWidget {
  final AppLocalizations l10n;
  const _WellbeingCheckin({required this.l10n});

  @override
  State<_WellbeingCheckin> createState() => _WellbeingCheckinState();
}

class _WellbeingCheckinState extends State<_WellbeingCheckin> {
  int? _selected;

  static const _emojis = ['😣', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final labels = [
      widget.l10n.wellbeingBad,
      widget.l10n.wellbeingMeh,
      widget.l10n.wellbeingOk,
      widget.l10n.wellbeingGood,
      widget.l10n.wellbeingGreat,
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.l10n.wellbeingQuestion,
            style: AppTextStyles.labelMd.copyWith(
              color: const Color(0xFF4C1D95),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_emojis.length, (i) {
              final selected = _selected == i;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEDE9FE)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFDDD6FE),
                      width: selected ? 2 : 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                              blurRadius: 0,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(_emojis[i],
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((l) => Text(
                      l,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
