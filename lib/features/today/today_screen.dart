import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../shared/widgets/section_label.dart';
import '../analytics/analytics_screen.dart';
import '../wellbeing/wellbeing_check_screen.dart';
import 'providers/today_providers.dart';
import 'widgets/family_status_strip.dart';

// ─── Unified day item ─────────────────────────────────────────────────────────

enum _ItemType { intake, activity, appointment, wellbeing }

class _DayItem {
  final _ItemType type;
  final DateTime scheduledAt;
  final Object? _data;

  const _DayItem._({required this.type, required this.scheduledAt, Object? data})
      : _data = data;

  Intake? get intake => _data is Intake ? _data : null;
  ActivityLog? get activityLog => _data is ActivityLog ? _data : null;
  DoctorAppointment? get appointment => _data is DoctorAppointment ? _data : null;

  static _DayItem fromIntake(Intake i) =>
      _DayItem._(type: _ItemType.intake, scheduledAt: i.scheduledAt, data: i);
  static _DayItem fromActivity(ActivityLog l) =>
      _DayItem._(type: _ItemType.activity, scheduledAt: l.scheduledAt, data: l);
  static _DayItem fromAppointment(DoctorAppointment a) =>
      _DayItem._(type: _ItemType.appointment, scheduledAt: a.scheduledAt, data: a);
  static _DayItem fromWellbeing(DateTime dt) =>
      _DayItem._(type: _ItemType.wellbeing, scheduledAt: dt);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(generateTodayIntakesProvider);
    ref.watch(generateTodayActivityLogsProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final activeId = ref.watch(activeMemberIdProvider);

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
        return _TodayContent(
          member: member,
          showSwitchBanner: activeId != null && member.role != 'owner',
        );
      },
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _TodayContent extends ConsumerWidget {
  final Member member;
  final bool showSwitchBanner;
  const _TodayContent({required this.member, this.showSwitchBanner = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));
    final activityLogsAsync = ref.watch(todayActivityLogsProvider(member.id));
    final medsAsync = ref.watch(todayMedicationsProvider(member.id));
    final activitiesAsync = ref.watch(todayActivitiesProvider(member.id));
    final appointmentsAsync = ref.watch(todayAppointmentsProvider(member.id));
    final membersAsync = ref.watch(allMembersProvider);
    final wellbeingScheduleAsync = ref.watch(todayWellbeingScheduleProvider(member.id));
    final wellbeingLogsAsync = ref.watch(todayWellbeingLogsProvider(member.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: intakesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (intakes) {
          final meds = medsAsync.valueOrNull ?? [];
          final activities = activitiesAsync.valueOrNull ?? [];
          final activityLogs = activityLogsAsync.valueOrNull ?? [];
          final appointments = appointmentsAsync.valueOrNull ?? [];
          final members = membersAsync.valueOrNull ?? [];

          final taken = intakes.where((i) => i.status == 'taken').length;
          final total = intakes.length;

          final now = DateTime.now();
          final oneHourAgo = now.subtract(const Duration(hours: 1));
          final oneHourAhead = now.add(const Duration(hours: 1));

          // ── Wellbeing slots ──────────────────────────────────────────────
          final schedule = wellbeingScheduleAsync.valueOrNull;
          final todayWbLogs = wellbeingLogsAsync.valueOrNull ?? [];
          final activeWbSlots = <DateTime>[];
          final missedWbSlots = <DateTime>[];
          final upcomingWbSlots = <DateTime>[];
          final doneWbSlots = <DateTime>[];

          if (schedule != null && schedule.isActive) {
            final today = DateTime(now.year, now.month, now.day);
            final slotDts = (List<String>.from(
                    jsonDecode(schedule.times) as List))
                .map((t) {
              final p = t.split(':');
              return DateTime(today.year, today.month, today.day,
                  int.parse(p[0]), int.parse(p[1]));
            }).toList()
              ..sort();
            final endOfDay =
                DateTime(today.year, today.month, today.day, 23, 59, 59);

            for (int i = 0; i < slotDts.length; i++) {
              final slotDt = slotDts[i];
              final windowEnd =
                  i + 1 < slotDts.length ? slotDts[i + 1] : endOfDay;
              final hasLog = todayWbLogs.any((l) =>
                  l.loggedAt.isAfter(
                      slotDt.subtract(const Duration(minutes: 30))) &&
                  l.loggedAt.isBefore(windowEnd));
              if (hasLog) {
                doneWbSlots.add(slotDt);
              } else if (now.isAfter(windowEnd)) {
                missedWbSlots.add(slotDt);
              } else if (!slotDt.isBefore(oneHourAgo) &&
                  slotDt.isBefore(oneHourAhead)) {
                activeWbSlots.add(slotDt);
              } else if (slotDt.isBefore(oneHourAgo)) {
                // Between 1h ago and window close — still active
                activeWbSlots.add(slotDt);
              } else {
                upcomingWbSlots.add(slotDt);
              }
            }
          }

          // ── Intake buckets ───────────────────────────────────────────────
          bool isPending(Intake i) {
            if (i.status == 'snoozed' &&
                i.snoozedUntil != null &&
                i.snoozedUntil!.isAfter(now)) return false;
            return i.status == 'pending' || i.status == 'snoozed';
          }

          final pendingIntakes = intakes.where(isPending).toList();
          final missedIntakes =
              pendingIntakes.where((i) => i.scheduledAt.isBefore(oneHourAgo)).toList();
          final activeIntakes = pendingIntakes
              .where((i) =>
                  !i.scheduledAt.isBefore(oneHourAgo) &&
                  i.scheduledAt.isBefore(oneHourAhead))
              .toList();
          final upcomingIntakes = pendingIntakes
              .where((i) => !i.scheduledAt.isBefore(oneHourAhead))
              .toList();
          final doneIntakes = intakes
              .where((i) => i.status == 'taken' || i.status == 'skipped')
              .toList();

          // ── Activity log buckets ─────────────────────────────────────────
          final pendingLogs =
              activityLogs.where((l) => l.status == 'pending').toList();
          final missedActivities =
              pendingLogs.where((l) => l.scheduledAt.isBefore(oneHourAgo)).toList();
          final activeActivities = pendingLogs
              .where((l) =>
                  !l.scheduledAt.isBefore(oneHourAgo) &&
                  l.scheduledAt.isBefore(oneHourAhead))
              .toList();
          final upcomingActivities = pendingLogs
              .where((l) => !l.scheduledAt.isBefore(oneHourAhead))
              .toList();
          final doneActivities = activityLogs
              .where((l) => l.status == 'done' || l.status == 'skipped')
              .toList();

          // ── Appointment split ────────────────────────────────────────────
          final pastAppointments =
              appointments.where((a) => a.scheduledAt.isBefore(now)).toList();
          final futureAppointments =
              appointments.where((a) => !a.scheduledAt.isBefore(now)).toList();

          // ── Unified schedule (upcoming, sorted) ──────────────────────────
          final scheduleItems = <_DayItem>[
            ...upcomingIntakes.map(_DayItem.fromIntake),
            ...upcomingActivities.map(_DayItem.fromActivity),
            ...upcomingWbSlots.map(_DayItem.fromWellbeing),
            ...futureAppointments.map(_DayItem.fromAppointment),
          ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          // ── Next event ──────────────────────────────────────────────────
          DateTime? nextAt;
          String? nextLabel;
          void checkNext(DateTime dt, String label) {
            if (nextAt == null || dt.isBefore(nextAt!)) {
              nextAt = dt;
              nextLabel = label;
            }
          }
          for (final i in [...activeIntakes, ...upcomingIntakes]) {
            final med = meds.where((m) => m.id == i.medicationId).firstOrNull;
            checkNext(i.scheduledAt, med?.name ?? 'Ліки');
          }
          for (final l in [...activeActivities, ...upcomingActivities]) {
            final a = activities.where((a) => a.id == l.activityId).firstOrNull;
            checkNext(l.scheduledAt, a?.name ?? 'Активність');
          }
          for (final dt in [...activeWbSlots, ...upcomingWbSlots]) {
            checkNext(dt, 'Самопочуття');
          }
          for (final a in futureAppointments) {
            checkNext(a.scheduledAt, a.doctorType);
          }

          // ── Done / past (sorted) ─────────────────────────────────────────
          final doneItems = <_DayItem>[
            ...doneIntakes.map(_DayItem.fromIntake),
            ...doneActivities.map(_DayItem.fromActivity),
            ...doneWbSlots.map(_DayItem.fromWellbeing),
            ...pastAppointments.map(_DayItem.fromAppointment),
          ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          final hasMissed = missedIntakes.isNotEmpty ||
              missedActivities.isNotEmpty ||
              missedWbSlots.isNotEmpty;
          final hasActive = activeIntakes.isNotEmpty ||
              activeActivities.isNotEmpty ||
              activeWbSlots.isNotEmpty;

          return CustomScrollView(
            slivers: [
              if (showSwitchBanner)
                SliverToBoxAdapter(child: _SwitchBanner(name: member.name)),

              // Hero
              SliverToBoxAdapter(
                child: _CompactHero(
                  member: member,
                  taken: taken,
                  total: total,
                  nextAt: nextAt,
                  nextLabel: nextLabel,
                  onAnalyticsTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AnalyticsScreen(memberId: member.id)),
                  ),
                  onAddWellbeing: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            WellbeingCheckScreen(memberId: member.id)),
                  ),
                ),
              ),

              // 1. Сім'я
              if (members.length > 1)
                SliverToBoxAdapter(
                  child: _SectionPad(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Сім\'я'),
                        const SizedBox(height: AppDimensions.md),
                        FamilyStatusStrip(
                          members: members,
                          currentMemberId: member.id,
                          ref: ref,
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Ви пропустили
              if (hasMissed)
                SliverToBoxAdapter(
                  child: _MissedSection(
                    intakes: missedIntakes,
                    activityLogs: missedActivities,
                    wellbeingSlots: missedWbSlots,
                    meds: meds,
                    activities: activities,
                    memberId: member.id,
                    ref: ref,
                  ),
                ),

              // 3. Зараз
              if (hasActive)
                SliverToBoxAdapter(
                  child: _ActiveNowSection(
                    intakes: activeIntakes,
                    activityLogs: activeActivities,
                    wellbeingSlots: activeWbSlots,
                    meds: meds,
                    activities: activities,
                    memberId: member.id,
                    ref: ref,
                  ),
                ),

              // 4. Розклад на сьогодні
              if (scheduleItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _ScheduleSection(
                    title: 'Розклад на сьогодні',
                    items: scheduleItems,
                    meds: meds,
                    activities: activities,
                    memberId: member.id,
                  ),
                ),

              // 5. Коротко про завтра
              SliverToBoxAdapter(
                child: _TomorrowSection(
                  memberId: member.id,
                  meds: meds,
                  activities: activities,
                  wellbeingSchedule: schedule,
                ),
              ),

              // 6. Виконано / Не виконано
              if (doneItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _DoneAccordion(
                    items: doneItems,
                    meds: meds,
                    activities: activities,
                    memberId: member.id,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              if (!hasMissed &&
                  !hasActive &&
                  scheduleItems.isEmpty &&
                  doneItems.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✅', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text('На сьогодні нічого немає',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        SizedBox(height: 8),
                        Text('Натисніть + щоб додати',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textSub)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Next Event Line ──────────────────────────────────────────────────────────

class _NextEventChip extends StatelessWidget {
  final DateTime? nextAt;
  final String? nextLabel;
  const _NextEventChip({this.nextAt, this.nextLabel});

  @override
  Widget build(BuildContext context) {
    if (nextAt == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅', style: TextStyle(fontSize: 11)),
            SizedBox(width: 5),
            Text(
              'Все виконано',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final diff = nextAt!.difference(DateTime.now());
    final timeStr = diff.inMinutes <= 0
        ? 'зараз'
        : diff.inMinutes < 60
            ? 'через ${diff.inMinutes} хв'
            : 'о ${nextAt!.hour.toString().padLeft(2, '0')}:${nextAt!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            timeStr,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text('·',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11)),
          ),
          Flexible(
            child: Text(
              nextLabel ?? '',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section padding helper ───────────────────────────────────────────────────

class _SectionPad extends StatelessWidget {
  final Widget child;
  const _SectionPad({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding, 16,
            AppDimensions.screenPadding, 0),
        child: child,
      );
}

// ─── Compact Hero ─────────────────────────────────────────────────────────────

class _CompactHero extends StatelessWidget {
  final Member member;
  final int taken, total;
  final DateTime? nextAt;
  final String? nextLabel;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onAddWellbeing;

  const _CompactHero({
    required this.member,
    required this.taken,
    required this.total,
    required this.nextAt,
    required this.nextLabel,
    required this.onAnalyticsTap,
    required this.onAddWellbeing,
  });

  static const _avatars = ['🧑', '👩', '👨', '👧', '👦', '👴', '👵', '🧒'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding, 12,
              AppDimensions.screenPadding, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Text(
                  _avatars[member.avatarIndex % _avatars.length],
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),

                // Name + next event
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _NextEventChip(nextAt: nextAt, nextLabel: nextLabel),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Quick wellbeing button
                GestureDetector(
                  onTap: onAddWellbeing,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(height: 3),
                        Text(
                          'Зараз\nболить',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Missed Section ───────────────────────────────────────────────────────────

class _MissedSection extends StatelessWidget {
  final List<Intake> intakes;
  final List<ActivityLog> activityLogs;
  final List<DateTime> wellbeingSlots;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final WidgetRef ref;

  const _MissedSection({
    required this.intakes,
    required this.activityLogs,
    required this.wellbeingSlots,
    required this.meds,
    required this.activities,
    required this.memberId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFFF97316), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Ви пропустили',
                style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2410C))),
          ]),
          const SizedBox(height: 8),
          ...intakes.map((i) {
            final med =
                meds.where((m) => m.id == i.medicationId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  _ActiveIntakeCard(intake: i, med: med, ref: ref, missed: true),
            );
          }),
          ...activityLogs.map((l) {
            final activity =
                activities.where((a) => a.id == l.activityId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActiveActivityCard(
                  log: l, ref: ref, activity: activity, missed: true),
            );
          }),
          ...wellbeingSlots.map((dt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActiveWellbeingCard(
                    scheduledAt: dt, memberId: memberId, missed: true),
              )),
        ],
      ),
    );
  }
}

// ─── Active Now Section ───────────────────────────────────────────────────────

class _ActiveNowSection extends StatelessWidget {
  final List<Intake> intakes;
  final List<ActivityLog> activityLogs;
  final List<DateTime> wellbeingSlots;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final WidgetRef ref;

  const _ActiveNowSection({
    required this.intakes,
    required this.activityLogs,
    required this.wellbeingSlots,
    required this.meds,
    required this.activities,
    required this.memberId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Зараз',
                style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain)),
          ]),
          const SizedBox(height: 8),
          ...intakes.map((i) {
            final med =
                meds.where((m) => m.id == i.medicationId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActiveIntakeCard(intake: i, med: med, ref: ref),
            );
          }),
          ...activityLogs.map((l) {
            final activity =
                activities.where((a) => a.id == l.activityId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  _ActiveActivityCard(log: l, ref: ref, activity: activity),
            );
          }),
          ...wellbeingSlots.map((dt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActiveWellbeingCard(
                    scheduledAt: dt, memberId: memberId),
              )),
        ],
      ),
    );
  }
}

// ─── Schedule Section (unified timeline) ─────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final String title;
  final List<_DayItem> items;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final bool dimmed;

  const _ScheduleSection({
    required this.title,
    required this.items,
    required this.meds,
    required this.activities,
    required this.memberId,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                return _ScheduleRow(
                  item: e.value,
                  meds: meds,
                  activities: activities,
                  memberId: memberId,
                  isLast: e.key == items.length - 1,
                  dimmed: dimmed,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Row ─────────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  final _DayItem item;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final bool isLast;
  final bool dimmed;

  const _ScheduleRow({
    required this.item,
    required this.meds,
    required this.activities,
    required this.memberId,
    required this.isLast,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final (emoji, title, subtitle) = _info();
    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: isLast ? Radius.zero : Radius.zero,
              bottom: isLast ? const Radius.circular(16) : Radius.zero,
            ),
            onTap: item.type == _ItemType.wellbeing
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              WellbeingCheckScreen(memberId: memberId)),
                    )
                : null,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      _fmt(item.scheduledAt),
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w600)),
                        if (subtitle != null)
                          Text(subtitle,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (item.type == _ItemType.wellbeing && !dimmed)
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (!isLast)
            const Divider(
                height: 1,
                thickness: 1,
                indent: 14,
                endIndent: 14,
                color: AppColors.border),
        ],
      ),
    );
  }

  (String, String, String?) _info() {
    switch (item.type) {
      case _ItemType.intake:
        final med =
            meds.where((m) => m.id == item.intake!.medicationId).firstOrNull;
        return ('💊', med?.name ?? 'Ліки',
            med != null ? '${med.doseAmount} ${med.doseUnit}' : null);
      case _ItemType.activity:
        final a = activities
            .where((a) => a.id == item.activityLog!.activityId)
            .firstOrNull;
        return (_actEmoji(a?.type), a?.name ?? 'Активність', null);
      case _ItemType.appointment:
        return ('👨‍⚕️', item.appointment!.doctorType,
            item.appointment!.location);
      case _ItemType.wellbeing:
        return ('🩺', 'Самопочуття', null);
    }
  }

  String _actEmoji(String? t) => switch (t) {
        'walk' => '🚶',
        'workout' => '🏋️',
        'gym' => '💪',
        'yoga' => '🧘',
        'cycling' => '🚴',
        _ => '🏃',
      };

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Tomorrow Section ─────────────────────────────────────────────────────────

class _TomorrowSection extends ConsumerWidget {
  final int memberId;
  final List<Medication> meds;
  final List<Activity> activities;
  final WellbeingSchedule? wellbeingSchedule;

  const _TomorrowSection({
    required this.memberId,
    required this.meds,
    required this.activities,
    this.wellbeingSchedule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakesAsync = ref.watch(tomorrowIntakesProvider(memberId));
    final actLogsAsync = ref.watch(tomorrowActivityLogsProvider(memberId));
    final apptsAsync = ref.watch(tomorrowAppointmentsProvider(memberId));

    final items = <_DayItem>[];
    if (intakesAsync.hasValue) {
      items.addAll(intakesAsync.value!.map(_DayItem.fromIntake));
    }
    if (actLogsAsync.hasValue) {
      items.addAll(actLogsAsync.value!.map(_DayItem.fromActivity));
    }
    if (apptsAsync.hasValue) {
      items.addAll(apptsAsync.value!.map(_DayItem.fromAppointment));
    }
    if (wellbeingSchedule != null && wellbeingSchedule!.isActive) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final td = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final times =
          List<String>.from(jsonDecode(wellbeingSchedule!.times) as List);
      for (final t in times) {
        final p = t.split(':');
        items.add(_DayItem.fromWellbeing(DateTime(
            td.year, td.month, td.day, int.parse(p[0]), int.parse(p[1]))));
      }
    }

    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final top5 = items.take(5).toList();

    if (top5.isEmpty) return const SizedBox.shrink();

    return _ScheduleSection(
      title: 'Коротко про завтра',
      items: top5,
      meds: meds,
      activities: activities,
      memberId: memberId,
    );
  }
}

// ─── Done Accordion ───────────────────────────────────────────────────────────

class _DoneAccordion extends StatelessWidget {
  final List<_DayItem> items;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;

  const _DoneAccordion({
    required this.items,
    required this.meds,
    required this.activities,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPad(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ExpansionTile(
            leading:
                const Text('✅', style: TextStyle(fontSize: 18)),
            title: Text(
              'Виконано · ${items.length}',
              style: AppTextStyles.bodyMd
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            children: items.asMap().entries.map((e) {
              return _ScheduleRow(
                item: e.value,
                meds: meds,
                activities: activities,
                memberId: memberId,
                isLast: e.key == items.length - 1,
                dimmed: true,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Active Intake Card ────────────────────────────────────────────────────────

class _ActiveIntakeCard extends StatelessWidget {
  final Intake intake;
  final Medication? med;
  final WidgetRef ref;
  final bool missed;

  const _ActiveIntakeCard(
      {required this.intake, this.med, required this.ref, this.missed = false});

  @override
  Widget build(BuildContext context) {
    final accent = missed ? const Color(0xFFF97316) : AppColors.primary;
    final photoPath = _firstPhoto(med?.photoPaths);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (photoPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(photoPath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(accent)),
                  )
                else
                  _placeholder(accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med?.name ?? 'Ліки',
                          style: AppTextStyles.bodyLg
                              .copyWith(fontWeight: FontWeight.w700)),
                      if (med != null)
                        Text('${med!.doseAmount} ${med!.doseUnit}',
                            style: AppTextStyles.bodySm),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.access_time, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(_fmt(intake.scheduledAt),
                            style: AppTextStyles.bodySm.copyWith(
                                color: accent, fontWeight: FontWeight.w700)),
                        if (missed) ...[
                          const SizedBox(width: 6),
                          Text('пропущено',
                              style: AppTextStyles.bodySm.copyWith(
                                  color: const Color(0xFFF97316))),
                        ],
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ActionRow(
            accent: accent,
            onDone: () =>
                ref.read(intakesRepositoryProvider).markTaken(intake.id),
            onSkip: () =>
                ref.read(intakesRepositoryProvider).markSkipped(intake.id),
            onSnooze: (min) => ref.read(intakesRepositoryProvider).markSnoozed(
                intake.id, DateTime.now().add(Duration(minutes: min))),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color accent) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('💊', style: TextStyle(fontSize: 28))),
      );

  String? _firstPhoto(String? json) {
    if (json == null || json == '[]') return null;
    try {
      final list = jsonDecode(json) as List;
      return list.isNotEmpty ? list.first as String : null;
    } catch (_) {
      return null;
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Active Activity Card ─────────────────────────────────────────────────────

class _ActiveActivityCard extends StatelessWidget {
  final ActivityLog log;
  final Activity? activity;
  final WidgetRef ref;
  final bool missed;

  const _ActiveActivityCard(
      {required this.log, this.activity, required this.ref, this.missed = false});

  @override
  Widget build(BuildContext context) {
    final accent =
        missed ? const Color(0xFFF97316) : const Color(0xFF22C55E);
    final emoji = _actEmoji(activity?.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity?.name ?? 'Активність',
                          style: AppTextStyles.bodyLg
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.access_time, size: 12, color: accent),
                        const SizedBox(width: 4),
                        Text(_fmt(log.scheduledAt),
                            style: AppTextStyles.bodySm.copyWith(
                                color: accent, fontWeight: FontWeight.w700)),
                        if (missed) ...[
                          const SizedBox(width: 6),
                          Text('пропущено',
                              style: AppTextStyles.bodySm.copyWith(
                                  color: const Color(0xFFF97316))),
                        ],
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ActionRow(
            accent: accent,
            onDone: () => ref
                .read(activitiesRepositoryProvider)
                .markLogDone(log.id),
            onSkip: () => ref
                .read(activitiesRepositoryProvider)
                .markLogSkipped(log.id),
            onSnooze: (min) => ref
                .read(activitiesRepositoryProvider)
                .snoozeLog(log.id,
                    DateTime.now().add(Duration(minutes: min))),
          ),
        ],
      ),
    );
  }

  String _actEmoji(String? t) => switch (t) {
        'walk' => '🚶',
        'workout' => '🏋️',
        'gym' => '💪',
        'yoga' => '🧘',
        'cycling' => '🚴',
        _ => '🏃',
      };

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Active Wellbeing Card ────────────────────────────────────────────────────

class _ActiveWellbeingCard extends StatelessWidget {
  final DateTime scheduledAt;
  final int memberId;
  final bool missed;

  const _ActiveWellbeingCard(
      {required this.scheduledAt,
      required this.memberId,
      this.missed = false});

  @override
  Widget build(BuildContext context) {
    final accent =
        missed ? const Color(0xFFF97316) : const Color(0xFF8B5CF6);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WellbeingCheckScreen(memberId: memberId)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('🩺', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missed
                        ? 'Пропущений зріз'
                        : 'Час перевірити самопочуття',
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time, size: 12, color: accent),
                    const SizedBox(width: 4),
                    Text(_fmt(scheduledAt),
                        style: AppTextStyles.bodySm.copyWith(
                            color: accent, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
            Text(missed ? 'Заповнити' : 'Відкрити',
                style: AppTextStyles.bodySm
                    .copyWith(color: accent, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: accent),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onSkip;
  final void Function(int minutes) onSnooze;
  final Color accent;

  const _ActionRow({
    required this.onDone,
    required this.onSkip,
    required this.onSnooze,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: AppColors.border, width: 1))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDone,
              child: Container(
                height: 44,
                color: accent.withValues(alpha: 0.08),
                child: Center(
                  child: Text('✓ Виконано',
                      style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: GestureDetector(
              onTap: onSkip,
              child: const SizedBox(
                height: 44,
                child: Center(
                  child: Text('✕ Пропустити',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: PopupMenuButton<int>(
              onSelected: onSnooze,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 10, child: Text('10 хвилин')),
                PopupMenuItem(value: 30, child: Text('30 хвилин')),
                PopupMenuItem(value: 60, child: Text('1 година')),
              ],
              child: const SizedBox(
                height: 44,
                child: Center(
                  child: Text('🕐 Перенести',
                      style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Switch Banner ─────────────────────────────────────────────────────────────

class _SwitchBanner extends ConsumerWidget {
  final String name;
  const _SwitchBanner({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        ),
        child: Row(
          children: [
            const Text('👁', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ви дивитесь профіль: $name',
                  style: AppTextStyles.bodySm.copyWith(
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(activeMemberIdProvider.notifier).state = null,
              child: Text('Повернутись',
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

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
