import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';

// ── Provider key type ─────────────────────────────────────────────────────────

typedef _PK = ({int memberId, DateTime from, DateTime to});

// ── Providers ─────────────────────────────────────────────────────────────────

final _periodIntakesProvider =
    FutureProvider.family<List<Intake>, _PK>((ref, k) {
  return ref
      .watch(intakesRepositoryProvider)
      .getByMemberAndDateRange(k.memberId, k.from, k.to);
});

final _periodMedsProvider =
    FutureProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).getByMember(memberId);
});

final _periodWellbeingProvider =
    FutureProvider.family<List<WellbeingLog>, _PK>((ref, k) {
  return ref
      .watch(wellbeingRepositoryProvider)
      .getByMemberAndDateRange(k.memberId, k.from, k.to);
});

final _periodActivityLogsProvider =
    FutureProvider.family<List<ActivityLog>, _PK>((ref, k) {
  return ref
      .watch(activitiesRepositoryProvider)
      .getLogsByMemberAndDateRange(k.memberId, k.from, k.to);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerStatefulWidget {
  final int memberId;
  const AnalyticsScreen({super.key, required this.memberId});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _days = 30; // 7 / 30 / 90

  _PK get _pk {
    final to = DateTime.now().add(const Duration(days: 1));
    final from = to.subtract(Duration(days: _days));
    return (memberId: widget.memberId, from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    final pk = _pk;
    final intakesAsync = ref.watch(_periodIntakesProvider(pk));
    final medsAsync = ref.watch(_periodMedsProvider(widget.memberId));
    final wellbeingAsync = ref.watch(_periodWellbeingProvider(pk));
    final activityAsync = ref.watch(_periodActivityLogsProvider(pk));

    final intakes = intakesAsync.valueOrNull ?? [];
    final meds = medsAsync.valueOrNull ?? [];
    final wellbeing = wellbeingAsync.valueOrNull ?? [];
    final activityLogs = activityAsync.valueOrNull ?? [];

    final taken = intakes.where((i) => i.status == 'taken').length;
    final done =
        intakes.where((i) => i.status == 'taken' || i.status == 'skipped').length;
    final overallPct = done > 0 ? (taken / done * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _AnalyticsHeader(
                pct: overallPct,
                days: _days,
                onPeriodChanged: (d) => setState(() => _days = d),
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.xl),
                  _SectionTitle('По днях'),
                  const SizedBox(height: 10),
                  _DailyBarChart(intakes: intakes, days: _days),
                  const SizedBox(height: 6),
                  _BarLegend(),
                  const SizedBox(height: AppDimensions.xl),
                  _SectionTitle('По лікарствах'),
                  const SizedBox(height: 10),
                  ...meds.map((med) {
                    final medIntakes =
                        intakes.where((i) => i.medicationId == med.id).toList();
                    final t =
                        medIntakes.where((i) => i.status == 'taken').length;
                    final total = medIntakes.length;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _MedStatCard(med: med, taken: t, total: total),
                    );
                  }),
                  if (wellbeing.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.xl),
                    _SectionTitle('Самопочуття'),
                    const SizedBox(height: 10),
                    _WellbeingMiniChart(
                        logs: wellbeing, days: _days),
                  ],
                  if (activityLogs.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.xl),
                    _SectionTitle('Активність'),
                    const SizedBox(height: 10),
                    _ActivitySummary(logs: activityLogs),
                  ],
                  const SizedBox(height: AppDimensions.xl),
                  _PdfHint(),
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AnalyticsHeader extends StatelessWidget {
  final int pct;
  final int days;
  final ValueChanged<int> onPeriodChanged;
  final VoidCallback onBack;
  const _AnalyticsHeader({
    required this.pct,
    required this.days,
    required this.onPeriodChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [(7, 'Тиждень'), (30, 'Місяць'), (90, '3 місяці')];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.textMain),
                ),
              ),
              const SizedBox(width: 12),
              Text('Аналітика', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 20),
          Text('Дотримання режиму',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textSub)),
          const SizedBox(height: 4),
          Text(
            '$pct%',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primary,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'за останні $days днів',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 14),
          Row(
            children: periods
                .map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onPeriodChanged(p.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: days == p.$1
                                ? AppColors.primaryLight
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: days == p.$1
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: days == p.$1 ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            p.$2,
                            style: AppTextStyles.labelSm.copyWith(
                              color: days == p.$1
                                  ? AppColors.primary
                                  : AppColors.textSub,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Daily bar chart ───────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final List<Intake> intakes;
  final int days;
  const _DailyBarChart({required this.intakes, required this.days});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build per-day data: today is index days-1
    final dayData = List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayIntakes = intakes
          .where((x) =>
              !x.scheduledAt.isBefore(dayStart) &&
              x.scheduledAt.isBefore(dayEnd))
          .toList();

      final taken = dayIntakes.where((x) => x.status == 'taken').length;
      final total = dayIntakes.length;
      final ratio = total > 0 ? taken / total : -1.0; // -1 = no data
      final isToday = i == days - 1;

      return (day: day, ratio: ratio, isToday: isToday, total: total);
    });

    const maxH = 80.0;
    const barMinH = 4.0;

    return SizedBox(
      height: maxH + 20,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dayData.map((d) {
            Color barColor;
            double barH;

            if (d.ratio < 0) {
              barColor = AppColors.border;
              barH = barMinH;
            } else if (d.ratio >= 1.0) {
              barColor = const Color(0xFF4ADE80);
              barH = maxH;
            } else if (d.ratio > 0.5) {
              barColor = const Color(0xFFFBBF24);
              barH = maxH * d.ratio;
            } else {
              barColor = const Color(0xFFF87171);
              barH = (maxH * d.ratio).clamp(barMinH, maxH);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: days <= 7 ? 32 : days <= 30 ? 16 : 10,
                    height: barH,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      border: d.isToday
                          ? Border.all(
                              color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (days <= 30)
                    Text(
                      '${d.day.day}',
                      style: AppTextStyles.caption.copyWith(
                        color: d.isToday
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: d.isToday
                            ? FontWeight.w800
                            : FontWeight.w400,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFF4ADE80), 'Всі прийняті'),
      (Color(0xFFFBBF24), 'Частково'),
      (Color(0xFFF87171), 'Пропущено'),
    ];
    return Wrap(
      spacing: 16,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(item.$2,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSub)),
                ],
              ))
          .toList(),
    );
  }
}

// ── Med stat card ─────────────────────────────────────────────────────────────

class _MedStatCard extends StatelessWidget {
  final Medication med;
  final int taken;
  final int total;
  const _MedStatCard(
      {required this.med, required this.taken, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (taken / total * 100).round() : 0;
    final ratio = total > 0 ? taken / total : 0.0;

    Color pctColor;
    Color barColor;
    if (pct >= 90) {
      pctColor = AppColors.success;
      barColor = const Color(0xFF4ADE80);
    } else if (pct >= 70) {
      pctColor = AppColors.warning;
      barColor = const Color(0xFFFBBF24);
    } else {
      pctColor = AppColors.danger;
      barColor = const Color(0xFFF87171);
    }

    final emoji = switch (med.form) {
      'syrup' => '🍶',
      'drops' => '💧',
      'cream' => '🧴',
      'inhaler' => '💨',
      'injection' => '💉',
      _ => '💊',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name,
                    style: AppTextStyles.labelMd,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  total > 0 ? '$taken з $total прийомів' : 'Немає даних',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSub),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$pct%',
            style: AppTextStyles.h3.copyWith(color: pctColor, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// ── Wellbeing mini chart ──────────────────────────────────────────────────────

class _WellbeingMiniChart extends StatelessWidget {
  final List<WellbeingLog> logs;
  final int days;
  const _WellbeingMiniChart({required this.logs, required this.days});

  static Color _moodBarColor(int mood) {
    if (mood >= 4) return const Color(0xFF7C3AED);
    if (mood >= 3) return const Color(0xFFA78BFA);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    // Group by day — take last log per day
    final now = DateTime.now();
    final byDay = <int, int>{}; // dayIndex → mood (1-5)
    for (final log in logs) {
      final diff = now
          .difference(DateTime(
              log.loggedAt.year, log.loggedAt.month, log.loggedAt.day))
          .inDays;
      if (diff < days) {
        byDay[days - 1 - diff] = log.mood; // later logs overwrite
      }
    }

    const maxH = 48.0;
    const barW = 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: maxH + 20,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days, (i) {
                final mood = byDay[i];
                final isToday = i == days - 1;
                final h = mood != null ? (mood / 5 * maxH).clamp(8.0, maxH) : 4.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: barW,
                        height: h,
                        decoration: BoxDecoration(
                          color: mood != null
                              ? _moodBarColor(mood)
                              : AppColors.border,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          border: isToday
                              ? Border.all(
                                  color: const Color(0xFF4C1D95), width: 1.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (days <= 30)
                        Text(
                          '${(now.subtract(Duration(days: days - 1 - i))).day}',
                          style: AppTextStyles.caption.copyWith(
                            color: isToday
                                ? const Color(0xFF7C3AED)
                                : AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          children: const [
            _WbLegendItem(color: Color(0xFF7C3AED), label: 'Добре'),
            _WbLegendItem(color: Color(0xFFA78BFA), label: 'Нормально'),
            _WbLegendItem(color: Color(0xFFF87171), label: 'Погано'),
          ],
        ),
      ],
    );
  }
}

class _WbLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _WbLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSub)),
      ],
    );
  }
}

// ── Activity summary ──────────────────────────────────────────────────────────

class _ActivitySummary extends StatelessWidget {
  final List<ActivityLog> logs;
  const _ActivitySummary({required this.logs});

  @override
  Widget build(BuildContext context) {
    final done = logs.where((l) => l.status == 'done').length;
    final skipped = logs.where((l) => l.status == 'skipped').length;
    final total = logs.length;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    final tiles = [
      ('✅', '$done', 'виконано'),
      ('⏭', '$skipped', 'пропущено'),
      ('🔥', '$pct%', 'успішність'),
    ];

    return Row(
      children: tiles
          .map((t) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(t.$1, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.$2,
                          style: AppTextStyles.h3.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(t.$3,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── PDF hint ──────────────────────────────────────────────────────────────────

class _PdfHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLighter, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('📄', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Звіт для лікаря',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(
                  'Сформувати PDF з ліками та симптомами',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const Text('→',
              style: TextStyle(fontSize: 18, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTextStyles.labelLg);
}
