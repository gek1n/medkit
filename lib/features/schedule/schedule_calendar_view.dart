import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../add/routine_view_screen.dart';
import '../appointments/reminder_view_screen.dart';
import '../medications/medication_detail_screen.dart';
import '../wellbeing/add_wellbeing_schedule_screen.dart';
import 'schedule_calendar_data.dart';
import 'schedule_category.dart';

const double _kHourRowHeight = 52;
const double _kTimeColWidth = 44;

Color _categoryAccent(ScheduleCategory c) => switch (c) {
      ScheduleCategory.meds => AppColors.primary,
      ScheduleCategory.reminders => const Color(0xFF72A8C7),
      ScheduleCategory.routine => const Color(0xFFF5A65C),
      ScheduleCategory.wellbeing => const Color(0xFFFF9B9B),
      ScheduleCategory.all => AppColors.primary,
    };

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// Календарний вигляд Розкладу — 2 сусідні дні поруч, свайп змінює пару на
// 1 день (rolling), а не пейджингом по 2. Дизайн навмисно "компактний":
// пункти лягають у СВОЮ годинну комірку (не пропорційно тривалості), при
// збігу часу — просто стек у порядку створення (без розкладки в колонки).
class ScheduleCalendarView extends ConsumerStatefulWidget {
  final int memberId;
  final ScheduleCategory category;
  final String search; // вже .trim().toLowerCase()

  const ScheduleCalendarView({
    super.key,
    required this.memberId,
    required this.category,
    required this.search,
  });

  @override
  ConsumerState<ScheduleCalendarView> createState() => _ScheduleCalendarViewState();
}

class _ScheduleCalendarViewState extends ConsumerState<ScheduleCalendarView> {
  static final DateTime _epoch = DateTime(2000, 1, 1);

  late final PageController _pageController;
  late int _pageIndex;
  Timer? _nowTimer;
  DateTime _now = DateTime.now();

  static int _pageForDate(DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(_epoch).inDays;
  static DateTime _dateForPage(int page) => _epoch.add(Duration(days: page));

  @override
  void initState() {
    super.initState();
    _pageIndex = _pageForDate(_now);
    _pageController = PageController(initialPage: _pageIndex);
    // Полоска поточного часу оновлюється сама — раз на хвилину достатньо,
    // це не секундна стрілка.
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToDate(DateTime date) {
    final target = _pageForDate(date);
    if (target == _pageIndex) return;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToToday() => _jumpToDate(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final dayA = _dateForPage(_pageIndex);
    final dayB = dayA.add(const Duration(days: 1));

    return Stack(
      children: [
        Column(
          children: [
            _CalendarWeekStrip(
              anchor: dayA,
              selectedA: dayA,
              selectedB: dayB,
              onSelect: _jumpToDate,
            ),
            const SizedBox(height: AppDimensions.sm),
            _CalendarDayHeaders(dayA: dayA, dayB: dayB),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (context, index) {
                  final a = _dateForPage(index);
                  final b = a.add(const Duration(days: 1));
                  return _CalendarTwoDayGrid(
                    key: ValueKey(index),
                    memberId: widget.memberId,
                    dayA: a,
                    dayB: b,
                    category: widget.category,
                    search: widget.search,
                    now: _now,
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          left: AppDimensions.screenPadding,
          bottom: AppDimensions.md,
          child: _TodayButton(onTap: _goToToday),
        ),
      ],
    );
  }
}

// ─── Тижнева стрічка дат ────────────────────────────────────────────────────

class _CalendarWeekStrip extends StatelessWidget {
  final DateTime anchor; // = dayA поточної сторінки
  final DateTime selectedA;
  final DateTime selectedB;
  final ValueChanged<DateTime> onSelect;

  const _CalendarWeekStrip({
    required this.anchor,
    required this.selectedA,
    required this.selectedB,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final weekdayFmt = DateFormat('E', locale);
    final today = DateTime.now();
    final days = List.generate(7, (i) => anchor.add(Duration(days: i - 2)));

    return SizedBox(
      height: 56,
      child: Row(
        children: days.map((d) {
          final selected = _isSameDay(d, selectedA) || _isSameDay(d, selectedB);
          final isToday = _isSameDay(d, today);
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayFmt.format(d).toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: !selected && isToday
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '${d.day}',
                      style: AppTextStyles.labelMd.copyWith(
                        color: selected
                            ? Colors.white
                            : (isToday ? AppColors.primary : AppColors.textMain),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Заголовки 2 колонок дня ────────────────────────────────────────────────

class _CalendarDayHeaders extends StatelessWidget {
  final DateTime dayA;
  final DateTime dayB;

  const _CalendarDayHeaders({required this.dayA, required this.dayB});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('E, d MMM', locale);
    final today = DateTime.now();

    Widget header(DateTime d) {
      final isToday = _isSameDay(d, today);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          child: Text(
            fmt.format(d),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(
              color: isToday ? AppColors.primary : AppColors.textSub,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        const SizedBox(width: _kTimeColWidth),
        header(dayA),
        const SizedBox(width: 1),
        header(dayB),
      ],
    );
  }
}

// ─── Кнопка "Сьогодні" ───────────────────────────────────────────────────────

class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Text(
          context.l10n.dayToday,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Сітка годин для пари днів ──────────────────────────────────────────────

class _CalendarTwoDayGrid extends ConsumerStatefulWidget {
  final int memberId;
  final DateTime dayA;
  final DateTime dayB;
  final ScheduleCategory category;
  final String search;
  final DateTime now;

  const _CalendarTwoDayGrid({
    super.key,
    required this.memberId,
    required this.dayA,
    required this.dayB,
    required this.category,
    required this.search,
    required this.now,
  });

  @override
  ConsumerState<_CalendarTwoDayGrid> createState() => _CalendarTwoDayGridState();
}

class _CalendarTwoDayGridState extends ConsumerState<_CalendarTwoDayGrid> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final showsToday =
        _isSameDay(widget.dayA, widget.now) || _isSameDay(widget.dayB, widget.now);
    final initialHour = showsToday ? (widget.now.hour - 2).clamp(0, 22) : 8;
    _scroll = ScrollController(initialScrollOffset: _kHourRowHeight * initialHour);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<CalendarItem> _filter(List<CalendarItem> items) {
    return items.where((i) {
      if (widget.category != ScheduleCategory.all && i.category != widget.category) {
        return false;
      }
      if (widget.search.isEmpty) return true;
      final title =
          i.type == CalendarItemType.wellbeing ? context.l10n.sectionWellbeing : i.title;
      return title.toLowerCase().contains(widget.search);
    }).toList();
  }

  void _openItem(CalendarItem item) {
    switch (item.type) {
      case CalendarItemType.medication:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicationDetailScreen(medicationId: item.id, memberId: item.memberId),
          ),
        );
      case CalendarItemType.reminder:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReminderViewScreen(reminderId: item.id)),
        );
      case CalendarItemType.routine:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoutineViewScreen(activityId: item.id)),
        );
      case CalendarItemType.wellbeing:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddWellbeingScheduleScreen(memberId: item.memberId),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsA = ref
        .watch(scheduleCalendarDayProvider((memberId: widget.memberId, date: widget.dayA)))
        .valueOrNull;
    final itemsB = ref
        .watch(scheduleCalendarDayProvider((memberId: widget.memberId, date: widget.dayB)))
        .valueOrNull;

    final loading = itemsA == null || itemsB == null;
    final aFiltered = loading ? const <CalendarItem>[] : _filter(itemsA);
    final bFiltered = loading ? const <CalendarItem>[] : _filter(itemsB);

    final noTimeA = aFiltered.where((i) => i.time == null).toList();
    final noTimeB = bFiltered.where((i) => i.time == null).toList();

    List<List<CalendarItem>> bucketByHour(List<CalendarItem> items) {
      final buckets = List.generate(24, (_) => <CalendarItem>[]);
      for (final i in items) {
        if (i.time == null) continue;
        buckets[i.time!.hour].add(i);
      }
      return buckets;
    }

    final hourlyA = bucketByHour(aFiltered);
    final hourlyB = bucketByHour(bFiltered);

    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noTimeA.isNotEmpty || noTimeB.isNotEmpty)
            _CalendarNoTimeRow(itemsA: noTimeA, itemsB: noTimeB, onTap: _openItem),
          LayoutBuilder(
            builder: (context, constraints) {
              final dayColWidth = (constraints.maxWidth - _kTimeColWidth - 1) / 2;
              return Stack(
                children: [
                  Column(
                    children: List.generate(24, (hour) {
                      return _CalendarHourRow(
                        hour: hour,
                        itemsA: hourlyA[hour],
                        itemsB: hourlyB[hour],
                        onTap: _openItem,
                      );
                    }),
                  ),
                  if (_isSameDay(widget.dayA, widget.now))
                    _CurrentTimeLine(now: widget.now, dayIndex: 0, dayColWidth: dayColWidth),
                  if (_isSameDay(widget.dayB, widget.now))
                    _CurrentTimeLine(now: widget.now, dayIndex: 1, dayColWidth: dayColWidth),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimensions.xl),
        ],
      ),
    );
  }
}

class _CalendarNoTimeRow extends StatelessWidget {
  final List<CalendarItem> itemsA;
  final List<CalendarItem> itemsB;
  final void Function(CalendarItem) onTap;

  const _CalendarNoTimeRow({required this.itemsA, required this.itemsB, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kTimeColWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                context.l10n.calendarNoTimeLabel,
                textAlign: TextAlign.right,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          Expanded(
            child: _CalendarCellItems(items: itemsA, onTap: onTap),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: _CalendarCellItems(items: itemsB, onTap: onTap),
          ),
        ],
      ),
    );
  }
}

class _CalendarHourRow extends StatelessWidget {
  final int hour;
  final List<CalendarItem> itemsA;
  final List<CalendarItem> itemsB;
  final void Function(CalendarItem) onTap;

  const _CalendarHourRow({
    required this.hour,
    required this.itemsA,
    required this.itemsB,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kHourRowHeight),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _kTimeColWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            Expanded(child: _CalendarCellItems(items: itemsA, onTap: onTap)),
            const SizedBox(width: 1),
            Expanded(child: _CalendarCellItems(items: itemsB, onTap: onTap)),
          ],
        ),
      ),
    );
  }
}

class _CalendarCellItems extends StatelessWidget {
  final List<CalendarItem> items;
  final void Function(CalendarItem) onTap;

  const _CalendarCellItems({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Column(
        children: items
            .map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _CalendarItemChip(item: i, onTap: () => onTap(i)),
                ))
            .toList(),
      ),
    );
  }
}

class _CalendarItemChip extends StatelessWidget {
  final CalendarItem item;
  final VoidCallback onTap;

  const _CalendarItemChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _categoryAccent(item.category);
    final title = item.type == CalendarItemType.wellbeing
        ? context.l10n.sectionWellbeing
        : item.title;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: accent, width: 3)),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.recurring) ...[
              const Icon(Icons.repeat_rounded, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.textMain, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentTimeLine extends StatelessWidget {
  final DateTime now;
  final int dayIndex; // 0 = ліва колонка (dayA), 1 = права (dayB)
  final double dayColWidth;

  const _CurrentTimeLine({
    required this.now,
    required this.dayIndex,
    required this.dayColWidth,
  });

  @override
  Widget build(BuildContext context) {
    final top = _kHourRowHeight * (now.hour + now.minute / 60.0);
    return Positioned(
      top: top,
      left: dayIndex == 0 ? _kTimeColWidth : _kTimeColWidth + dayColWidth + 1,
      width: dayColWidth,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(height: 1.5, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
