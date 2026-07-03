import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/section_label.dart';
import '../add/add_activity_screen.dart';
import '../appointments/add_appointment_screen.dart';
import '../medications/add_medication_screen.dart';
import '../medications/medication_detail_screen.dart';
import '../wellbeing/add_wellbeing_schedule_screen.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _scheduleAllMembersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(membersRepositoryProvider).watchAll();
});

final _scheduleMedsProvider =
    StreamProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).watchByMember(memberId);
});

final _scheduleActivitiesProvider =
    StreamProvider.family<List<Activity>, int>((ref, memberId) {
  return ref.watch(activitiesRepositoryProvider).watchByMember(memberId);
});

final _scheduleAppointmentsProvider =
    StreamProvider.family<List<DoctorAppointment>, int>((ref, memberId) {
  return ref.watch(doctorAppointmentsRepositoryProvider).watchUpcoming(memberId);
});

final _scheduleWellbeingScheduleProvider =
    StreamProvider.family<WellbeingSchedule?, int>((ref, memberId) {
  return ref.watch(wellbeingRepositoryProvider).watchScheduleByMember(memberId);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_scheduleAllMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: membersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) {
          if (members.isEmpty) {
            return const _EmptyMembers();
          }
          final memberId = _selectedMemberId ?? members.first.id;
          return _ScheduleBody(
            members: members,
            selectedMemberId: memberId,
            onMemberChanged: (id) => setState(() => _selectedMemberId = id),
          );
        },
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _ScheduleBody extends ConsumerWidget {
  final List<Member> members;
  final int selectedMemberId;
  final void Function(int) onMemberChanged;

  const _ScheduleBody({
    required this.members,
    required this.selectedMemberId,
    required this.onMemberChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(_scheduleMedsProvider(selectedMemberId));
    final activitiesAsync = ref.watch(_scheduleActivitiesProvider(selectedMemberId));
    final appointmentsAsync = ref.watch(_scheduleAppointmentsProvider(selectedMemberId));
    final wellbeingScheduleAsync = ref.watch(_scheduleWellbeingScheduleProvider(selectedMemberId));

    final member = members.firstWhere(
      (m) => m.id == selectedMemberId,
      orElse: () => members.first,
    );

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.bg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.lg,
                  AppDimensions.screenPadding,
                  AppDimensions.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Розклад', style: AppTextStyles.h2),
                    Text(
                      member.name,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Member filter
        if (members.length > 1)
          SliverToBoxAdapter(
            child: _MemberFilterStrip(
              members: members,
              selectedId: selectedMemberId,
              onSelect: onMemberChanged,
            ),
          ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppDimensions.xl),

              // ── Ліки ──────────────────────────────────────────────────
              _SectionHeader(
                emoji: '💊',
                title: 'Ліки',
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMedicationScreen(memberId: selectedMemberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              medsAsync.when(
                loading: () => const _SectionLoading(),
                error: (e, _) => Text('$e'),
                data: (meds) {
                  if (meds.isEmpty) {
                    return _EmptySection(
                      hint: 'Немає активних ліків',
                      onAdd: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddMedicationScreen(memberId: selectedMemberId),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: meds
                        .map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicationDetailScreen(
                                      medicationId: m.id,
                                      memberId: selectedMemberId,
                                    ),
                                  ),
                                ),
                                child: _MedCard(med: m),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── Активності ────────────────────────────────────────────
              _SectionHeader(
                emoji: '🚶',
                title: 'Активності',
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddActivityScreen(memberId: selectedMemberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              activitiesAsync.when(
                loading: () => const _SectionLoading(),
                error: (e, _) => Text('$e'),
                data: (activities) {
                  if (activities.isEmpty) {
                    return _EmptySection(
                      hint: 'Немає активних занять',
                      onAdd: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddActivityScreen(memberId: selectedMemberId),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: activities
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddActivityScreen(
                                      memberId: selectedMemberId,
                                      existing: a,
                                    ),
                                  ),
                                ),
                                child: _ActivityCard(activity: a),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── Самопочуття ───────────────────────────────────────────
              _SectionHeader(
                emoji: '💜',
                title: 'Самопочуття',
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddWellbeingScheduleScreen(memberId: selectedMemberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              wellbeingScheduleAsync.when(
                loading: () => const _SectionLoading(),
                error: (e, _) => Text('$e'),
                data: (schedule) {
                  if (schedule == null) {
                    return _EmptySection(
                      hint: 'Розклад не налаштовано',
                      onAdd: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddWellbeingScheduleScreen(memberId: selectedMemberId),
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddWellbeingScheduleScreen(memberId: selectedMemberId),
                      ),
                    ),
                    child: _WellbeingScheduleCard(schedule: schedule),
                  );
                },
              ),

              const SizedBox(height: AppDimensions.xl),

              // ── Лікарі ────────────────────────────────────────────────
              _SectionHeader(
                emoji: '🩺',
                title: 'Прийоми лікарів',
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddAppointmentScreen(memberId: selectedMemberId),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              appointmentsAsync.when(
                loading: () => const _SectionLoading(),
                error: (e, _) => Text('$e'),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return _EmptySection(
                      hint: 'Немає запланованих прийомів',
                      onAdd: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddAppointmentScreen(memberId: selectedMemberId),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: appointments
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddAppointmentScreen(
                                      memberId: selectedMemberId,
                                      existing: a,
                                    ),
                                  ),
                                ),
                                child: _AppointmentCard(appointment: a),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.emoji, required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: SectionLabel(title)),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
          ),
      ],
    );
  }
}

// ─── Med card ─────────────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final Medication med;
  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    return MkCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Center(
              child: Text(_formEmoji(med.form), style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(
                  '${_doseStr(med)} · ${_repeatStr(med)}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          if (med.totalCount > 0) _PillBadge(remaining: med.remainingCount, total: med.totalCount),
          const SizedBox(width: AppDimensions.sm),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  String _doseStr(Medication m) =>
      '${m.doseAmount.toStringAsFixed(m.doseAmount == m.doseAmount.roundToDouble() ? 0 : 1)} ${m.doseUnit}';

  String _repeatStr(Medication m) => switch (m.repeatType) {
        'daily' => 'щодня',
        'alternate' => 'через день',
        'weekdays' => 'певні дні',
        'every_n' => 'кожні N днів',
        'cycle' => 'циклом',
        _ => '',
      };

  String _formEmoji(String form) => switch (form) {
        'syrup' => '🍶',
        'drops' => '💧',
        'cream' => '🧴',
        'inhaler' => '💨',
        'injection' => '💉',
        _ => '💊',
      };
}

class _PillBadge extends StatelessWidget {
  final int remaining;
  final int total;
  const _PillBadge({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? remaining / total : 0.0;
    final color = pct > 0.3
        ? AppColors.success
        : pct > 0.1
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$remaining', style: AppTextStyles.labelSm.copyWith(color: color)),
    );
  }
}

// ─── Activity card ────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return MkCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Center(
              child: Text(_typeEmoji(activity.type), style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.name, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(
                  '${activity.durationMin} хв · ${_daysStr(activity.repeatDays)}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  String _typeEmoji(String type) => switch (type) {
        'walk' => '🚶',
        'workout' => '🏋️',
        'yoga' => '🧘',
        'cycling' => '🚴',
        _ => '⚡',
      };

  String _daysStr(String repeatDaysJson) {
    try {
      final raw = repeatDaysJson.replaceAll('[', '').replaceAll(']', '');
      final days = raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (days.length == 7) return 'щодня';
      const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
      return days.where((d) => d >= 1 && d <= 7).map((d) => names[d - 1]).join(', ');
    } catch (_) {
      return '';
    }
  }
}

// ─── Appointment card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm', 'uk');
    return MkCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.doctorType, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(
                  fmt.format(appointment.scheduledAt),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                ),
                if (appointment.location != null && appointment.location!.isNotEmpty)
                  Text(
                    appointment.location!,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

// ─── Wellbeing schedule card ──────────────────────────────────────────────────

class _WellbeingScheduleCard extends StatelessWidget {
  final WellbeingSchedule schedule;
  const _WellbeingScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    List<String> times = [];
    try {
      times = List<String>.from(jsonDecode(schedule.times) as List);
    } catch (_) {}

    final timesStr = times.isEmpty ? '—' : times.join(', ');
    final freqStr = '${schedule.timesPerDay} раз${schedule.timesPerDay == 1 ? '' : schedule.timesPerDay < 5 ? 'и' : 'ів'} на день';

    return MkCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Center(
              child: Text('💜', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(freqStr, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(
                  timesStr,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

// ─── Member filter strip ──────────────────────────────────────────────────────

class _MemberFilterStrip extends StatelessWidget {
  final List<Member> members;
  final int selectedId;
  final void Function(int) onSelect;

  const _MemberFilterStrip({
    required this.members,
    required this.selectedId,
    required this.onSelect,
  });

  static const _avatars = ['🧑', '👩', '👨', '👧', '👦', '👴', '👵', '🧒'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = members[i];
          final selected = m.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _avatars[m.avatarIndex % _avatars.length],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    m.name,
                    style: AppTextStyles.labelMd.copyWith(
                      color: selected ? Colors.white : AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String hint;
  final VoidCallback? onAdd;
  const _EmptySection({required this.hint, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            hint,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          if (onAdd != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onAdd,
              child: Text(
                'Додати',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('👤', style: TextStyle(fontSize: 52)),
          SizedBox(height: 16),
          Text('Профіль не знайдено'),
        ],
      ),
    );
  }
}
