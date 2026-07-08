import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/med_form_icons.dart';
import '../../core/utils/task_color.dart';
import '../../core/utils/youtube_utils.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/section_label.dart';
import '../add/add_type_sheet.dart';
import '../analytics/analytics_screen.dart';
import '../medications/medication_detail_screen.dart';
import '../wellbeing/wellbeing_check_screen.dart';
import 'providers/today_providers.dart';
import 'widgets/family_status_strip.dart';

// Час, на який приймання фактично заплановано зараз — з урахуванням
// перенесення (snoozedUntil), а не лише вихідний scheduledAt. Використовується
// для класифікації на "зараз/пропустили/розклад", щоб перенесений прийом не
// одразу "стрибав" у пропущені, оминаючи "зараз", коли настає його новий час.
extension _IntakeEffectiveDue on Intake {
  DateTime get effectiveDue =>
      status == 'snoozed' && snoozedUntil != null ? snoozedUntil! : scheduledAt;
}

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
      _DayItem._(type: _ItemType.intake, scheduledAt: i.effectiveDue, data: i);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTypeSheet(context, memberId: member.id),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          final activeWindowStart = now.subtract(const Duration(minutes: 15));
          final activeWindowEnd = now.add(const Duration(minutes: 15));

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
              } else if (slotDt.isBefore(activeWindowStart)) {
                // Слоти, що настали більш ніж 15 хвилин тому, просто не
                // показуємо — щоб щойно доданий/змінений розклад не
                // одразу заповнював сьогодні "пропущеними" зрізами.
                continue;
              } else if (now.isAfter(windowEnd)) {
                missedWbSlots.add(slotDt);
              } else if (slotDt.isBefore(activeWindowEnd)) {
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
          final missedIntakes = pendingIntakes
              .where((i) => i.effectiveDue.isBefore(activeWindowStart))
              .toList();
          final activeIntakes = pendingIntakes
              .where((i) =>
                  !i.effectiveDue.isBefore(activeWindowStart) &&
                  i.effectiveDue.isBefore(activeWindowEnd))
              .toList();
          final upcomingIntakes = pendingIntakes
              .where((i) => !i.effectiveDue.isBefore(activeWindowEnd))
              .toList();
          final doneIntakes = intakes
              .where((i) => i.status == 'taken' || i.status == 'skipped')
              .toList();

          // ── Activity log buckets ─────────────────────────────────────────
          final pendingLogs =
              activityLogs.where((l) => l.status == 'pending').toList();
          final missedActivities = pendingLogs
              .where((l) => l.scheduledAt.isBefore(activeWindowStart))
              .toList();
          final activeActivities = pendingLogs
              .where((l) =>
                  !l.scheduledAt.isBefore(activeWindowStart) &&
                  l.scheduledAt.isBefore(activeWindowEnd))
              .toList();
          final upcomingActivities = pendingLogs
              .where((l) => !l.scheduledAt.isBefore(activeWindowEnd))
              .toList();
          final doneActivities = activityLogs
              .where((l) => l.status == 'done' || l.status == 'skipped')
              .toList();

          // ── Appointment buckets ───────────────────────────────────────────
          final pendingAppointments =
              appointments.where((a) => a.status == 'pending').toList();
          final missedAppointments = pendingAppointments
              .where((a) => a.scheduledAt.isBefore(activeWindowStart))
              .toList();
          final activeAppointments = pendingAppointments
              .where((a) =>
                  !a.scheduledAt.isBefore(activeWindowStart) &&
                  a.scheduledAt.isBefore(activeWindowEnd))
              .toList();
          final upcomingAppointments = pendingAppointments
              .where((a) => !a.scheduledAt.isBefore(activeWindowEnd))
              .toList();
          final doneAppointments =
              appointments.where((a) => a.status != 'pending').toList();

          // ── Unified schedule (upcoming, sorted) ──────────────────────────
          final scheduleItems = <_DayItem>[
            ...upcomingIntakes.map(_DayItem.fromIntake),
            ...upcomingActivities.map(_DayItem.fromActivity),
            ...upcomingWbSlots.map(_DayItem.fromWellbeing),
            ...upcomingAppointments.map(_DayItem.fromAppointment),
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
            checkNext(i.effectiveDue, med?.name ?? 'Ліки');
          }
          for (final l in [...activeActivities, ...upcomingActivities]) {
            final a = activities.where((a) => a.id == l.activityId).firstOrNull;
            checkNext(l.scheduledAt, a?.name ?? 'Активність');
          }
          for (final dt in [...activeWbSlots, ...upcomingWbSlots]) {
            checkNext(dt, 'Самопочуття');
          }
          for (final a in [...activeAppointments, ...upcomingAppointments]) {
            checkNext(a.scheduledAt, a.doctorType);
          }

          // ── Done / past (sorted) ─────────────────────────────────────────
          final doneItems = <_DayItem>[
            ...doneIntakes.map(_DayItem.fromIntake),
            ...doneActivities.map(_DayItem.fromActivity),
            ...doneWbSlots.map(_DayItem.fromWellbeing),
            ...doneAppointments.map(_DayItem.fromAppointment),
          ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          final hasMissed = missedIntakes.isNotEmpty ||
              missedActivities.isNotEmpty ||
              missedWbSlots.isNotEmpty ||
              missedAppointments.isNotEmpty;
          final hasActive = activeIntakes.isNotEmpty ||
              activeActivities.isNotEmpty ||
              activeWbSlots.isNotEmpty ||
              activeAppointments.isNotEmpty;
          final allDoneToday = !hasMissed &&
              !hasActive &&
              scheduleItems.isEmpty &&
              doneItems.isNotEmpty;

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

              // Все виконано на сьогодні
              if (allDoneToday)
                const SliverToBoxAdapter(child: _AllDoneBanner()),

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
                    appointments: missedAppointments,
                    meds: meds,
                    activities: activities,
                    memberId: member.id,
                    ref: ref,
                    wellbeingSchedule: schedule,
                  ),
                ),

              // 3. Зараз
              if (hasActive)
                SliverToBoxAdapter(
                  child: _ActiveNowSection(
                    intakes: activeIntakes,
                    activityLogs: activeActivities,
                    wellbeingSlots: activeWbSlots,
                    appointments: activeAppointments,
                    meds: meds,
                    activities: activities,
                    memberId: member.id,
                    ref: ref,
                    wellbeingSchedule: schedule,
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
                    wellbeingSchedule: schedule,
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
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('На сьогодні нічого немає',
                            style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Натисніть + щоб додати',
                            style: AppTextStyles.bodyMd.copyWith(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Все виконано',
              style: AppTextStyles.bodyMd.copyWith(
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
            style: AppTextStyles.bodyMd.copyWith(
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
              style: AppTextStyles.bodyMd.copyWith(
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

// ─── All Done Banner ──────────────────────────────────────────────────────────

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    return _SectionPad(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Image.asset('assets/illustrations/all-done-hero.png', height: 96),
            const SizedBox(height: 12),
            Text(
              'Все виконано на сьогодні!',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Чудова робота — так тримати',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
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
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6), width: 2),
                  ),
                  child: AvatarImage(index: member.avatarIndex, size: 56),
                ),
                const SizedBox(width: 12),

                // Name + next event
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.bodyMd.copyWith(
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
                          style: AppTextStyles.bodyMd.copyWith(
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
  final List<DoctorAppointment> appointments;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final WidgetRef ref;
  final WellbeingSchedule? wellbeingSchedule;

  const _MissedSection({
    required this.intakes,
    required this.activityLogs,
    required this.wellbeingSlots,
    required this.appointments,
    required this.meds,
    required this.activities,
    required this.memberId,
    required this.ref,
    this.wellbeingSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <(DateTime, Widget)>[
      for (final i in intakes)
        (
          i.effectiveDue,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveIntakeCard(
                intake: i,
                med: meds.where((m) => m.id == i.medicationId).firstOrNull,
                ref: ref,
                missed: true),
          ),
        ),
      for (final l in activityLogs)
        (
          l.scheduledAt,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveActivityCard(
                log: l,
                ref: ref,
                activity:
                    activities.where((a) => a.id == l.activityId).firstOrNull,
                missed: true),
          ),
        ),
      for (final dt in wellbeingSlots)
        (
          dt,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveWellbeingCard(
                scheduledAt: dt,
                memberId: memberId,
                missed: true,
                wellbeingSchedule: wellbeingSchedule),
          ),
        ),
      for (final a in appointments)
        (
          a.scheduledAt,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveAppointmentCard(
                appointment: a, ref: ref, missed: true),
          ),
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

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
          ...cards.map((c) => c.$2),
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
  final List<DoctorAppointment> appointments;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final WidgetRef ref;
  final WellbeingSchedule? wellbeingSchedule;

  const _ActiveNowSection({
    required this.intakes,
    required this.activityLogs,
    required this.wellbeingSlots,
    required this.appointments,
    required this.meds,
    required this.activities,
    required this.memberId,
    required this.ref,
    this.wellbeingSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <(DateTime, Widget)>[
      for (final i in intakes)
        (
          i.effectiveDue,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveIntakeCard(
                intake: i,
                med: meds.where((m) => m.id == i.medicationId).firstOrNull,
                ref: ref),
          ),
        ),
      for (final l in activityLogs)
        (
          l.scheduledAt,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveActivityCard(
                log: l,
                ref: ref,
                activity:
                    activities.where((a) => a.id == l.activityId).firstOrNull),
          ),
        ),
      for (final dt in wellbeingSlots)
        (
          dt,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveWellbeingCard(
                scheduledAt: dt,
                memberId: memberId,
                wellbeingSchedule: wellbeingSchedule),
          ),
        ),
      for (final a in appointments)
        (
          a.scheduledAt,
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveAppointmentCard(appointment: a, ref: ref),
          ),
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

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
          ...cards.map((c) => c.$2),
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
  final WellbeingSchedule? wellbeingSchedule;
  final bool dimmed;

  const _ScheduleSection({
    required this.title,
    required this.items,
    required this.meds,
    required this.activities,
    required this.memberId,
    this.wellbeingSchedule,
    this.dimmed = false,
  });

  static const _dayParts = ['Ранок', 'День', 'Вечір', 'Ніч'];

  @override
  Widget build(BuildContext context) {
    final buckets = <String, List<_DayItem>>{
      for (final p in _dayParts) p: [],
    };
    for (final item in items) {
      buckets[_dayPartOf(item.scheduledAt)]!.add(item);
    }

    return _SectionPad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 10),
          for (final part in _dayParts)
            if (buckets[part]!.isNotEmpty) ...[
              _DayPartHeader(part: part),
              const SizedBox(height: 8),
              ...buckets[part]!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ScheduleCard(
                      item: item,
                      meds: meds,
                      activities: activities,
                      memberId: memberId,
                      wellbeingSchedule: wellbeingSchedule,
                      dimmed: dimmed,
                    ),
                  )),
              const SizedBox(height: 4),
            ],
        ],
      ),
    );
  }
}

String _dayPartOf(DateTime dt) {
  final h = dt.hour;
  if (h >= 6 && h < 12) return 'Ранок';
  if (h >= 12 && h < 18) return 'День';
  if (h >= 18 && h < 22) return 'Вечір';
  return 'Ніч';
}

IconData _dayPartIcon(String part) => switch (part) {
      'Ранок' => Icons.wb_twilight_rounded,
      'День' => Icons.wb_sunny_rounded,
      'Вечір' => Icons.nights_stay_rounded,
      _ => Icons.nightlight_round,
    };

Color _scheduleCategoryColor(_ItemType type) => switch (type) {
      _ItemType.appointment => const Color(0xFF72A8C7),
      _ItemType.intake => const Color(0xFFF08060),
      _ItemType.activity => const Color(0xFFA58BC9),
      _ItemType.wellbeing => const Color(0xFF6AAF8B),
    };

class _DayPartHeader extends StatelessWidget {
  final String part;
  const _DayPartHeader({required this.part});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_dayPartIcon(part), size: 13, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(part.toUpperCase(), style: AppTextStyles.labelSm),
      ],
    );
  }
}

// ─── Schedule Card (кожен пункт — окрема картка) ─────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final _DayItem item;
  final List<Medication> meds;
  final List<Activity> activities;
  final int memberId;
  final WellbeingSchedule? wellbeingSchedule;
  final bool dimmed;

  const _ScheduleCard({
    required this.item,
    required this.meds,
    required this.activities,
    required this.memberId,
    this.wellbeingSchedule,
    this.dimmed = false,
  });

  Color get _color {
    final customHex = switch (item.type) {
      _ItemType.intake => _resolvedMed?.color,
      _ItemType.activity => _resolvedActivity?.color,
      _ItemType.appointment => item.appointment!.color,
      _ItemType.wellbeing => wellbeingSchedule?.color,
    };
    return colorFromHex(customHex) ?? _scheduleCategoryColor(item.type);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = _scheduleItemInfo(item,
        med: _resolvedMed, activity: _resolvedActivity);
    final color = _color;

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 34, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(title,
                                    style: AppTextStyles.bodyMd
                                        .copyWith(fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              Text(_fmt(item.scheduledAt),
                                  style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.textSub,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: AppTextStyles.bodySm
                                    .copyWith(color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!dimmed)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textMuted),
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Medication? get _resolvedMed => item.type == _ItemType.intake
      ? meds.where((m) => m.id == item.intake!.medicationId).firstOrNull
      : null;

  Activity? get _resolvedActivity => item.type == _ItemType.activity
      ? activities.where((a) => a.id == item.activityLog!.activityId).firstOrNull
      : null;

  void _handleTap(BuildContext context) {
    if (item.type == _ItemType.wellbeing) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WellbeingCheckScreen(memberId: memberId)),
      );
      return;
    }
    // Ліки — повна картка препарату (фото, розклад, залишок), а не легкий
    // попап, який показує лише те, що вже видно на самій картці.
    if (item.type == _ItemType.intake) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicationDetailScreen(
              medicationId: item.intake!.medicationId, memberId: memberId),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ScheduleItemDetailsSheet(item: item, activity: _resolvedActivity),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

(IconData, String, String?) _scheduleItemInfo(_DayItem item,
    {Medication? med, Activity? activity}) {
  switch (item.type) {
    case _ItemType.intake:
      return (
        medFormIcon(med?.form ?? 'tablet'),
        med?.name ?? 'Ліки',
        med != null
            ? '${med.doseAmount.toStringAsFixed(med.doseAmount == med.doseAmount.roundToDouble() ? 0 : 1)} ${med.doseUnit}'
            : null
      );
    case _ItemType.activity:
      return (_scheduleActIcon(activity?.type), activity?.name ?? 'Активність', null);
    case _ItemType.appointment:
      return (Icons.medical_services_rounded, item.appointment!.doctorType,
          item.appointment!.location);
    case _ItemType.wellbeing:
      return (Icons.favorite_rounded, 'Самопочуття', null);
  }
}

IconData _scheduleActIcon(String? t) => switch (t) {
      'walk' => Icons.directions_walk_rounded,
      'workout' => Icons.fitness_center_rounded,
      'gym' => Icons.fitness_center_rounded,
      'yoga' => Icons.self_improvement_rounded,
      'cycling' => Icons.directions_bike_rounded,
      _ => Icons.directions_run_rounded,
    };

// ─── Schedule item details modal ──────────────────────────────────────────────

// Показується лише для activity/appointment — ліки (intake) ведуть напряму
// на MedicationDetailScreen (повна картка препарату), wellbeing на свій
// власний екран чек-іну.
class _ScheduleItemDetailsSheet extends StatelessWidget {
  final _DayItem item;
  final Activity? activity;

  const _ScheduleItemDetailsSheet({required this.item, this.activity});

  @override
  Widget build(BuildContext context) {
    final color = _scheduleCategoryColor(item.type);
    final (icon, title, _) =
        _scheduleItemInfo(item, activity: activity);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: AppTextStyles.h3)),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                  label: 'Час', value: _fmt(item.scheduledAt)),
              if (activity != null)
                _DetailRow(
                    label: 'Тривалість', value: '${activity!.durationMin} хв'),
              if (item.type == _ItemType.appointment &&
                  item.appointment!.location != null &&
                  item.appointment!.location!.isNotEmpty)
                _DetailRow(label: 'Місце', value: item.appointment!.location!),
              if (item.type == _ItemType.appointment &&
                  item.appointment!.notes != null &&
                  item.appointment!.notes!.isNotEmpty)
                _DetailRow(label: 'Нотатки', value: item.appointment!.notes!),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.labelSm),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

// ─── Schedule Row (компактний вигляд — лише для "Виконано") ──────────────────

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
    final (icon, title, subtitle) = _info();
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
                  Icon(icon, size: 18, color: AppColors.primary),
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
                    const Icon(Icons.chevron_right_rounded,
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

  (IconData, String, String?) _info() {
    switch (item.type) {
      case _ItemType.intake:
        final med =
            meds.where((m) => m.id == item.intake!.medicationId).firstOrNull;
        return (Icons.medication_rounded, med?.name ?? 'Ліки',
            med != null ? '${med.doseAmount} ${med.doseUnit}' : null);
      case _ItemType.activity:
        final a = activities
            .where((a) => a.id == item.activityLog!.activityId)
            .firstOrNull;
        return (_actIcon(a?.type), a?.name ?? 'Активність', null);
      case _ItemType.appointment:
        return (Icons.medical_services_rounded, item.appointment!.doctorType,
            item.appointment!.location);
      case _ItemType.wellbeing:
        return (Icons.favorite_rounded, 'Самопочуття', null);
    }
  }

  IconData _actIcon(String? t) => switch (t) {
        'walk' => Icons.directions_walk_rounded,
        'workout' => Icons.fitness_center_rounded,
        'gym' => Icons.fitness_center_rounded,
        'yoga' => Icons.self_improvement_rounded,
        'cycling' => Icons.directions_bike_rounded,
        _ => Icons.directions_run_rounded,
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
      wellbeingSchedule: wellbeingSchedule,
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
                const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
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

const _foodRelationLabels = {
  'any': 'Незалежно від їжі',
  'before': 'До їжі',
  'after': 'Після їжі',
  'with': 'Під час їжі',
};

IconData _foodRelationIcon(String v) => switch (v) {
      'before' => Icons.schedule_rounded,
      'after' => Icons.restaurant_rounded,
      'with' => Icons.ramen_dining_rounded,
      _ => Icons.check_circle_outline_rounded,
    };

// doseComment живе всередині відповідної фази в med.phases (json), а не в
// самому intake — тому шукаємо активну на дату intake фазу так само, як для
// розрахунку залишку в medication_detail_screen.
String? _doseComment(Medication med, DateTime scheduledAt) {
  if (med.phases == null) return null;
  try {
    final phases =
        List<Map<String, dynamic>>.from(jsonDecode(med.phases!) as List);
    final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final daysElapsed = day
        .difference(DateTime(
          med.startDate.year,
          med.startDate.month,
          med.startDate.day,
        ))
        .inDays;
    int accumulated = 0;
    Map<String, dynamic>? activePhase;
    for (final phase in phases) {
      final dur = phase['durationDays'] as int?;
      if (dur == null) {
        activePhase = phase;
        break;
      }
      accumulated += dur;
      if (daysElapsed < accumulated) {
        activePhase = phase;
        break;
      }
    }
    activePhase ??= phases.isNotEmpty ? phases.last : null;
    final comment = activePhase?['doseComment'] as String?;
    return (comment != null && comment.isNotEmpty) ? comment : null;
  } catch (_) {
    return null;
  }
}

// "Перенести" повинно рахувати нові N хвилин від часу, на який пункт зараз
// заплановано (or від now, якщо цей час вже минув), а не від поточного
// моменту — інакше перенесення ще не настанулого прийому "відкочує" його
// у минуле відносно запланованого часу.
DateTime _snoozeFrom(DateTime due) {
  final now = DateTime.now();
  return due.isAfter(now) ? due : now;
}

String? _firstMedPhoto(String? json) {
  if (json == null || json == '[]') return null;
  try {
    final list = jsonDecode(json) as List;
    return list.isNotEmpty ? list.first as String : null;
  } catch (_) {
    return null;
  }
}

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
    // Іконка/шапка завжди зберігають кастомний колір препарату (обраний
    // користувачем) — перефарбовується лише обводка картки, час і кнопка
    // "Виконано" (через accent).
    final iconColor = colorFromHex(med?.color) ?? AppColors.primary;
    final photoPath = _firstMedPhoto(med?.photoPaths);
    final comment =
        med != null ? _doseComment(med!, intake.scheduledAt) : null;

    return Container(
      clipBehavior: Clip.antiAlias,
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
          if (photoPath != null)
            _MediaHeader(
              photoPath: photoPath,
              accent: iconColor,
              onZoom: () => _openDetails(context),
            )
          else
            _IconHeader(
              icon: medFormIcon(med?.form ?? 'tablet'),
              accent: iconColor,
              onZoom: med != null ? () => _openDetails(context) : null,
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(med?.name ?? 'Ліки',
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmt(intake.effectiveDue),
                        style: AppTextStyles.h3.copyWith(
                            color: accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (missed) ...[
                  const SizedBox(height: 2),
                  Text('пропущено',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: const Color(0xFFF97316),
                          fontWeight: FontWeight.w700)),
                ],
                if (med != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: medFormIcon(med!.form),
                        label:
                            '${med!.doseAmount.toStringAsFixed(med!.doseAmount == med!.doseAmount.roundToDouble() ? 0 : 1)} ${med!.doseUnit}',
                      ),
                      _InfoChip(
                        icon: _foodRelationIcon(med!.foodRelation),
                        label: _foodRelationLabels[med!.foodRelation] ??
                            med!.foodRelation,
                      ),
                    ],
                  ),
                ],
                if (comment != null) ...[
                  const SizedBox(height: 8),
                  _CommentNote(text: comment),
                ],
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
                intake.id,
                _snoozeFrom(intake.effectiveDue).add(Duration(minutes: min))),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context) {
    // Повна картка препарату (фото, розклад, залишок) — не легкий попап.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationDetailScreen(
            medicationId: intake.medicationId, memberId: med!.memberId),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Media header (photo/video variant) ──────────────────────────────────────

class _MediaHeader extends StatelessWidget {
  final String photoPath;
  final Color accent;
  final VoidCallback onZoom;

  const _MediaHeader(
      {required this.photoPath, required this.accent, required this.onZoom});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<Uint8List>(
          future: PhotoService.decryptedBytes(photoPath),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Container(
                width: double.infinity,
                height: 220,
                color: accent.withValues(alpha: 0.1),
              );
            }
            return Image.memory(
              snap.data!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 220,
                color: accent.withValues(alpha: 0.1),
              ),
            );
          },
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: onZoom,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Video header (YouTube thumbnail + play button) ──────────────────────────

class _VideoMediaHeader extends StatelessWidget {
  final String thumbnailUrl;
  final Color accent;
  final VoidCallback onTap;

  const _VideoMediaHeader(
      {required this.thumbnailUrl, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            thumbnailUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: double.infinity,
              height: 220,
              color: accent.withValues(alpha: 0.1),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Icon header (no photo/video variant) ────────────────────────────────────

class _IconHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback? onZoom;

  const _IconHeader({required this.icon, required this.accent, this.onZoom});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 72,
          color: accent.withValues(alpha: 0.08),
          child: Center(child: Icon(icon, size: 32, color: accent)),
        ),
        if (onZoom != null)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: onZoom,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Info chip / comment note ─────────────────────────────────────────────────
// Винесено в окремі непрозорі блоки з іконкою замість дрібного сірого/курсивного
// тексту — так само читабельно і при збільшеному системному розмірі шрифту
// (для людей із порушеннями зору), а не лише при стандартному масштабі.

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSub),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.textMain)),
        ],
      ),
    );
  }
}

class _CommentNote extends StatelessWidget {
  final String text;
  const _CommentNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined,
              size: 16, color: AppColors.textSub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
          ),
        ],
      ),
    );
  }
}


// ─── Active Activity Card ─────────────────────────────────────────────────────

class _ActiveActivityCard extends StatefulWidget {
  final ActivityLog log;
  final Activity? activity;
  final WidgetRef ref;
  final bool missed;

  const _ActiveActivityCard(
      {required this.log, this.activity, required this.ref, this.missed = false});

  @override
  State<_ActiveActivityCard> createState() => _ActiveActivityCardState();
}

class _ActiveActivityCardState extends State<_ActiveActivityCard> {
  bool _playing = false;

  void _stopVideo() {
    if (_playing) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.missed ? const Color(0xFFF97316) : const Color(0xFF22C55E);
    final iconColor =
        colorFromHex(widget.activity?.color) ?? const Color(0xFF22C55E);
    final icon = _actIcon(widget.activity?.type);
    final videoId = youtubeVideoId(widget.activity?.youtubeUrl ?? '');
    final thumbnailUrl = youtubeThumbnailUrl(widget.activity?.youtubeUrl);

    return Container(
      clipBehavior: Clip.antiAlias,
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
          if (videoId != null)
            _playing
                ? _InlineYoutubePlayer(videoId: videoId)
                : _VideoMediaHeader(
                    thumbnailUrl: thumbnailUrl!,
                    accent: iconColor,
                    onTap: () => setState(() => _playing = true),
                  )
          else
            Container(
              width: double.infinity,
              height: 72,
              color: iconColor.withValues(alpha: 0.08),
              child: Center(child: Icon(icon, size: 32, color: iconColor)),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(widget.activity?.name ?? 'Активність',
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmt(widget.log.scheduledAt),
                        style: AppTextStyles.h3.copyWith(
                            color: accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (widget.missed) ...[
                  const SizedBox(height: 2),
                  Text('пропущено',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: const Color(0xFFF97316),
                          fontWeight: FontWeight.w700)),
                ],
                if (widget.activity != null &&
                    widget.activity!.durationMin > 0) ...[
                  const SizedBox(height: 10),
                  _InfoChip(
                      icon: icon, label: '${widget.activity!.durationMin} хв'),
                ],
              ],
            ),
          ),
          _ActionRow(
            accent: accent,
            onDone: () {
              _stopVideo();
              widget.ref
                  .read(activitiesRepositoryProvider)
                  .markLogDone(widget.log.id);
            },
            onSkip: () {
              _stopVideo();
              widget.ref
                  .read(activitiesRepositoryProvider)
                  .markLogSkipped(widget.log.id);
            },
            onSnooze: (min) {
              _stopVideo();
              widget.ref.read(activitiesRepositoryProvider).snoozeLog(
                  widget.log.id,
                  _snoozeFrom(widget.log.scheduledAt)
                      .add(Duration(minutes: min)));
            },
          ),
        ],
      ),
    );
  }

  IconData _actIcon(String? t) => switch (t) {
        'walk' => Icons.directions_walk_rounded,
        'workout' => Icons.fitness_center_rounded,
        'gym' => Icons.fitness_center_rounded,
        'yoga' => Icons.self_improvement_rounded,
        'cycling' => Icons.directions_bike_rounded,
        _ => Icons.directions_run_rounded,
      };

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Inline YouTube player (грає в застосунку, з можливістю на весь екран) ───

class _InlineYoutubePlayer extends StatefulWidget {
  final String videoId;
  const _InlineYoutubePlayer({required this.videoId});

  @override
  State<_InlineYoutubePlayer> createState() => _InlineYoutubePlayerState();
}

class _InlineYoutubePlayerState extends State<_InlineYoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller);
  }
}

// ─── Active Wellbeing Card ────────────────────────────────────────────────────

class _ActiveWellbeingCard extends ConsumerWidget {
  final DateTime scheduledAt;
  final int memberId;
  final bool missed;
  final WellbeingSchedule? wellbeingSchedule;

  const _ActiveWellbeingCard(
      {required this.scheduledAt,
      required this.memberId,
      this.missed = false,
      this.wellbeingSchedule});

  Future<void> _skip(WidgetRef ref) {
    return ref.read(wellbeingRepositoryProvider).insertLog(
          WellbeingLogsCompanion.insert(
            memberId: memberId,
            mood: 0,
            loggedAt: Value(scheduledAt),
            skipped: const Value(true),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent =
        missed ? const Color(0xFFF97316) : const Color(0xFF5FAE7C);
    final iconColor =
        colorFromHex(wellbeingSchedule?.color) ?? const Color(0xFF5FAE7C);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WellbeingCheckScreen(memberId: memberId)),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
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
            Container(
              width: double.infinity,
              height: 72,
              color: iconColor.withValues(alpha: 0.08),
              child: Center(
                  child: Icon(Icons.favorite_rounded,
                      size: 32, color: iconColor)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          missed
                              ? 'Пропущений зріз'
                              : 'Час перевірити самопочуття',
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_fmt(scheduledAt),
                          style: AppTextStyles.h3.copyWith(
                              color: accent, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  if (missed) ...[
                    const SizedBox(height: 2),
                    Text('пропущено',
                        style: AppTextStyles.bodyMd.copyWith(
                            color: const Color(0xFFF97316),
                            fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColors.border, width: 1))),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _skip(ref),
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text('✕ Пропустити',
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 44, color: AppColors.border),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          missed ? 'Заповнити' : 'Відкрити',
                          style: AppTextStyles.bodyMd.copyWith(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Active Appointment Card ──────────────────────────────────────────────────

class _ActiveAppointmentCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final WidgetRef ref;
  final bool missed;

  const _ActiveAppointmentCard(
      {required this.appointment, required this.ref, this.missed = false});

  @override
  Widget build(BuildContext context) {
    final accent = missed
        ? const Color(0xFFF97316)
        : (colorFromHex(appointment.color) ?? const Color(0xFF72A8C7));
    final iconColor = colorFromHex(appointment.color) ?? const Color(0xFF72A8C7);

    return Container(
      clipBehavior: Clip.antiAlias,
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
          _IconHeader(
            icon: Icons.medical_services_rounded,
            accent: iconColor,
            onZoom: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _ScheduleItemDetailsSheet(
                  item: _DayItem.fromAppointment(appointment)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(appointment.doctorType,
                          style: AppTextStyles.h3
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmt(appointment.scheduledAt),
                        style: AppTextStyles.h3.copyWith(
                            color: accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (missed) ...[
                  const SizedBox(height: 2),
                  Text('пропущено',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: const Color(0xFFF97316),
                          fontWeight: FontWeight.w700)),
                ],
                if (appointment.location != null &&
                    appointment.location!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoChip(
                      icon: Icons.place_rounded, label: appointment.location!),
                ],
              ],
            ),
          ),
          _ActionRow(
            accent: accent,
            onDone: () => ref
                .read(doctorAppointmentsRepositoryProvider)
                .markAttended(appointment.id),
            onSkip: () => ref
                .read(doctorAppointmentsRepositoryProvider)
                .markSkipped(appointment.id),
            onSnooze: (min) => ref
                .read(doctorAppointmentsRepositoryProvider)
                .reschedule(
                    appointment.id,
                    _snoozeFrom(appointment.scheduledAt)
                        .add(Duration(minutes: min))),
          ),
        ],
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
              onTap: onSkip,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text('✕ Пропустити',
                      style: AppTextStyles.bodyMd.copyWith(
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
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: AppColors.textSub),
                      const SizedBox(width: 4),
                      Text('Перенести',
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSub,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          Expanded(
            child: GestureDetector(
              onTap: onDone,
              child: Container(
                height: 44,
                color: accent.withValues(alpha: 0.08),
                child: Center(
                  child: Text('✓ Виконано',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
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
            const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF92400E)),
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
            const Icon(Icons.medication_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Ласкаво просимо до Elly',
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
