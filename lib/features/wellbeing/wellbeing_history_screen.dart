import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import 'symptom_picker_sheet.dart';
import 'wellbeing_check_screen.dart';

// ────────────────────────────── provider ──────────────────────────────

// StreamProvider — реактивний, без періоду: показуємо всю історію, гортати
// можна скільки завгодно (SliverList вже лінивий сам по собі).
final _wellbeingHistoryProvider =
    StreamProvider.family<List<WellbeingLog>, int>((ref, memberId) {
  return ref
      .watch(wellbeingRepositoryProvider)
      .watchByMember(memberId)
      // "Пропустити" не несе реальних даних про настрій — не показуємо в історії.
      .map((logs) => logs.where((l) => !l.skipped).toList());
});

// ────────────────────────────── screen ──────────────────────────────

class WellbeingHistoryScreen extends ConsumerWidget {
  final int memberId;
  const WellbeingHistoryScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_wellbeingHistoryProvider(memberId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: logsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
        data: (logs) => _HistoryBody(memberId: memberId, logs: logs),
      ),
    );
  }
}

// ────────────────────────────── body ──────────────────────────────

class _HistoryBody extends StatelessWidget {
  final int memberId;
  final List<WellbeingLog> logs;

  const _HistoryBody({
    required this.memberId,
    required this.logs,
  });

  // Group logs by date (yMd), return sorted desc
  Map<DateTime, List<WellbeingLog>> get _grouped {
    final map = <DateTime, List<WellbeingLog>>{};
    for (final log in logs) {
      final d = DateTime(
          log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      (map[d] ??= []).add(log);
    }
    final sorted = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sorted) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(memberId: memberId),
                const SizedBox(height: AppDimensions.md),
                _MiniChart(logs: logs),
                const SizedBox(height: AppDimensions.lg),
              ],
            ),
          ),
        ),
        if (grouped.isEmpty)
          SliverToBoxAdapter(child: _EmptyState())
        else
          SliverList(
            delegate: SliverChildListDelegate([
              ...grouped.entries.map((e) => _DayGroup(
                    date: e.key,
                    logs: e.value,
                  )),
              _SendToDoctorCard(),
              const SizedBox(height: 48),
            ]),
          ),
      ],
    );
  }
}

// ────────────────────────────── header ──────────────────────────────

class _Header extends StatelessWidget {
  final int memberId;
  const _Header({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.xl,
        AppDimensions.screenPadding,
        0,
      ),
      child: Row(
        children: [
          MkBackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.historyLabel, style: AppTextStyles.h2),
                Text(
                  context.l10n.wellbeingByDaySubtitle,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WellbeingCheckScreen(memberId: memberId),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.primaryLighter),
              ),
              child: Text(
                context.l10n.addWellbeingSlotAction,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── period chips ──────────────────────────────

// ────────────────────────────── mini chart ──────────────────────────────

class _MiniChart extends StatelessWidget {
  final List<WellbeingLog> logs;

  const _MiniChart({required this.logs});

  static const _moodEmoji = ['', '😣', '😕', '😐', '🙂', '😄'];

  static Color _barColor(double avg) {
    if (avg >= 4.5) return const Color(0xFF4C9A6A);
    if (avg >= 3.5) return const Color(0xFF8FCBA4);
    if (avg >= 2.5) return const Color(0xFFB7DDC2);
    return const Color(0xFFFCA5A5);
  }

  static String _moodEmojiFor(double avg) {
    return _moodEmoji[avg.round().clamp(1, 5)];
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Always show last 7 days for the mini chart
    final chartDays = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    // Map day → avg mood
    final dayMoods = <DateTime, List<int>>{};
    for (final log in logs) {
      final d = DateTime(
          log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      (dayMoods[d] ??= []).add(log.mood);
    }

    // Month name
    final l10n = context.l10n;
    final months = [
      '',
      l10n.monthNomJan,
      l10n.monthNomFeb,
      l10n.monthNomMar,
      l10n.monthNomApr,
      l10n.monthNomMay,
      l10n.monthNomJun,
      l10n.monthNomJul,
      l10n.monthNomAug,
      l10n.monthNomSep,
      l10n.monthNomOct,
      l10n.monthNomNov,
      l10n.monthNomDec,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.primaryLighter),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.moodChartTitle(months[today.month]),
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartDays.map((d) {
                  final moods = dayMoods[d];
                  final isToday = d ==
                      DateTime(today.year, today.month, today.day);
                  final hasData = moods != null && moods.isNotEmpty;
                  final avg = hasData
                      ? moods.reduce((a, b) => a + b) / moods.length
                      : 0.0;
                  final barH = hasData ? 8.0 + avg * 8 : 4.0;
                  final color =
                      hasData ? _barColor(avg) : AppColors.border;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasData)
                          Text(
                            _moodEmojiFor(avg),
                            style: const TextStyle(fontSize: 11),
                          )
                        else
                          const SizedBox(height: 14),
                        const SizedBox(height: 2),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 2),
                          height: barH,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                            border: isToday
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: chartDays.map((d) {
                return Expanded(
                  child: Text(
                    '${d.day}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textMuted),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── day group ──────────────────────────────

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<WellbeingLog> logs;

  const _DayGroup({required this.date, required this.logs});

  List<String> _weekdays(BuildContext context) {
    final l10n = context.l10n;
    return [
      '',
      l10n.weekdayFullMon,
      l10n.weekdayFullTue,
      l10n.weekdayFullWed,
      l10n.weekdayFullThu,
      l10n.weekdayFullFri,
      l10n.weekdayFullSat,
      l10n.weekdayFullSun,
    ];
  }

  List<String> _months(BuildContext context) {
    final l10n = context.l10n;
    return [
      '',
      l10n.monthGenJan,
      l10n.monthGenFeb,
      l10n.monthGenMar,
      l10n.monthGenApr,
      l10n.monthGenMay,
      l10n.monthGenJun,
      l10n.monthGenJul,
      l10n.monthGenAug,
      l10n.monthGenSep,
      l10n.monthGenOct,
      l10n.monthGenNov,
      l10n.monthGenDec,
    ];
  }

  String _dateLabel(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final suffix = date == today
        ? context.l10n.todayLowerLabel
        : date == yesterday
            ? context.l10n.yesterdayLowerLabel
            : _weekdays(context)[date.weekday];
    return '${date.day} ${_months(context)[date.month]} · $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        0,
        AppDimensions.screenPadding,
        AppDimensions.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel(context),
            style: AppTextStyles.bodyMd
                .copyWith(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...logs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _LogCard(log: log),
              )),
        ],
      ),
    );
  }
}

// ────────────────────────────── log card ──────────────────────────────

class _LogCard extends StatelessWidget {
  final WellbeingLog log;
  const _LogCard({required this.log});

  static const _moodEmoji = ['', '😣', '😕', '😐', '🙂', '😄'];

  IconData _timeIcon() {
    final h = log.loggedAt.hour;
    return h < 12
        ? Icons.wb_sunny_rounded
        : (h < 18 ? Icons.schedule_rounded : Icons.dark_mode_rounded);
  }

  String _timeLabel() {
    final h = log.loggedAt.hour;
    final hh = h.toString().padLeft(2, '0');
    final mm = log.loggedAt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool get _isBad => log.mood <= 2;

  @override
  Widget build(BuildContext context) {
    final symptoms = _parseSymptoms(context, log.symptomsJson);
    final emoji = _moodEmoji[log.mood.clamp(1, 5)];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: _isBad ? AppColors.dangerLight : AppColors.bg,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: _isBad
              ? const Color(0xFFFECACA)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_timeIcon(), size: 12, color: AppColors.textSub),
                    const SizedBox(width: 3),
                    Text(
                      _timeLabel(),
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
                if (symptoms.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: symptoms
                        .map((s) => _SymptomChip(label: s))
                        .toList(),
                  ),
                ],
                if (log.comment != null &&
                    log.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.quotedCommentLabel(log.comment!),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSub,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseSymptoms(BuildContext context, String json) {
    try {
      final List<dynamic> keys = jsonDecode(json);
      return keys.map((k) => symptomLabelFor(context, k as String)).toList();
    } catch (_) {
      return [];
    }
  }
}

// ────────────────────────────── symptom chip ──────────────────────────────

class _SymptomChip extends StatelessWidget {
  final String label;
  const _SymptomChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ────────────────────────────── empty ──────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.favorite_border_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(context.l10n.noWellbeingLogsTitle, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            context.l10n.noWellbeingLogsHint,
            style:
                AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── send to doctor ──────────────────────────────

class _SendToDoctorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.comingSoonEllipsis)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPadding,
          4,
          AppDimensions.screenPadding,
          0,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Center(
                  child: Icon(Icons.medical_services_rounded,
                      size: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sendDiaryToDoctorLabel,
                      style: AppTextStyles.labelMd
                          .copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.diarySummaryHint,
                      style: AppTextStyles.bodySm.copyWith(
                          color:
                              Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Text(context.l10n.arrowRightLabel,
                  style: AppTextStyles.h3.copyWith(
                      color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}
