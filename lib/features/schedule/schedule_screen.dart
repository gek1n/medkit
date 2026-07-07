import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/med_form_icons.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/section_label.dart';
import '../add/add_activity_screen.dart';
import '../add/add_type_sheet.dart';
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

// ─── Category ────────────────────────────────────────────────────────────────

enum _ScheduleCategory { meds, activities, wellbeing, appointments }

extension on _ScheduleCategory {
  IconData get icon => switch (this) {
        _ScheduleCategory.meds => Icons.medication_rounded,
        _ScheduleCategory.activities => Icons.directions_walk_rounded,
        _ScheduleCategory.wellbeing => Icons.favorite_rounded,
        _ScheduleCategory.appointments => Icons.medical_services_rounded,
      };

  String get label => switch (this) {
        _ScheduleCategory.meds => 'Ліки',
        _ScheduleCategory.activities => 'Активності',
        _ScheduleCategory.wellbeing => 'Самопочуття',
        _ScheduleCategory.appointments => 'Лікарі',
      };
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int? _selectedMemberId;
  _ScheduleCategory _category = _ScheduleCategory.meds;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_scheduleAllMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTypeSheet(context, memberId: _selectedMemberId),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            category: _category,
            onCategoryChanged: (c) => setState(() => _category = c),
            search: _search,
            onSearchChanged: (s) => setState(() => _search = s),
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
  final _ScheduleCategory category;
  final void Function(_ScheduleCategory) onCategoryChanged;
  final String search;
  final void Function(String) onSearchChanged;

  const _ScheduleBody({
    required this.members,
    required this.selectedMemberId,
    required this.onMemberChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.search,
    required this.onSearchChanged,
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

    final q = search.trim().toLowerCase();

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

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding, AppDimensions.md,
              AppDimensions.screenPadding, 0,
            ),
            child: _SearchField(
              value: search,
              hint: 'Пошук по всіх розділах',
              onChanged: onSearchChanged,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding, AppDimensions.sm,
              AppDimensions.screenPadding, 0,
            ),
            child: _CategorySegmentControl(
              selected: category,
              onChanged: onCategoryChanged,
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppDimensions.lg),

              if (q.isEmpty) ...[
                if (category == _ScheduleCategory.meds) ...[
                  _SectionHeader(
                    icon: Icons.medication_rounded,
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
                ],

                if (category == _ScheduleCategory.activities) ...[
                  _SectionHeader(
                    icon: Icons.directions_walk_rounded,
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
                              builder: (_) =>
                                  AddActivityScreen(memberId: selectedMemberId),
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
                ],

                if (category == _ScheduleCategory.wellbeing) ...[
                  _SectionHeader(
                    icon: Icons.favorite_rounded,
                    title: 'Самопочуття',
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddWellbeingScheduleScreen(memberId: selectedMemberId),
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
                ],

                if (category == _ScheduleCategory.appointments) ...[
                  _SectionHeader(
                    icon: Icons.medical_services_rounded,
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
                ],
              ] else
                Builder(builder: (context) {
                  final meds = (medsAsync.valueOrNull ?? [])
                      .where((m) => m.name.toLowerCase().contains(q))
                      .toList();
                  final activities = (activitiesAsync.valueOrNull ?? [])
                      .where((a) => a.name.toLowerCase().contains(q))
                      .toList();
                  final appointments = (appointmentsAsync.valueOrNull ?? [])
                      .where((a) => a.doctorType.toLowerCase().contains(q))
                      .toList();

                  final anyFound = meds.isNotEmpty ||
                      activities.isNotEmpty ||
                      appointments.isNotEmpty;

                  if (!anyFound) {
                    return const _EmptySection(hint: 'Нічого не знайдено');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meds.isNotEmpty) ...[
                        const _SectionHeader(icon: Icons.medication_rounded, title: 'Ліки'),
                        const SizedBox(height: AppDimensions.md),
                        ...meds.map((m) => Padding(
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
                            )),
                        const SizedBox(height: AppDimensions.xl),
                      ],
                      if (activities.isNotEmpty) ...[
                        const _SectionHeader(icon: Icons.directions_walk_rounded, title: 'Активності'),
                        const SizedBox(height: AppDimensions.md),
                        ...activities.map((a) => Padding(
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
                            )),
                        const SizedBox(height: AppDimensions.xl),
                      ],
                      if (appointments.isNotEmpty) ...[
                        const _SectionHeader(icon: Icons.medical_services_rounded, title: 'Прийоми лікарів'),
                        const SizedBox(height: AppDimensions.md),
                        ...appointments.map((a) => Padding(
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
                            )),
                      ],
                    ],
                  );
                }),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Category segment control ────────────────────────────────────────────────

class _CategorySegmentControl extends StatelessWidget {
  final _ScheduleCategory selected;
  final ValueChanged<_ScheduleCategory> onChanged;

  const _CategorySegmentControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _ScheduleCategory.values.map((c) {
          final active = c == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.icon, size: 16, color: active ? Colors.white : AppColors.textMuted),
                    const SizedBox(height: 2),
                    Text(
                      c.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: active ? Colors.white : AppColors.textMuted,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _ctrl.text) {
      _ctrl.value = _ctrl.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          suffixIcon: _ctrl.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 18),
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.icon, required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
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
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
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
              child: Icon(medFormIcon(med.form), size: 22, color: AppColors.primary),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
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
              child: Icon(_typeIcon(activity.type), size: 22, color: AppColors.primary),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'walk' => Icons.directions_walk_rounded,
        'workout' => Icons.fitness_center_rounded,
        'yoga' => Icons.self_improvement_rounded,
        'cycling' => Icons.directions_bike_rounded,
        _ => Icons.bolt_rounded,
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
              child: Icon(Icons.medical_services_rounded, size: 22, color: AppColors.primary),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
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
              color: const Color(0xFFEFF7F1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Center(
              child: Icon(Icons.favorite_rounded, size: 22, color: AppColors.primary),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
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
                  AvatarImage(index: m.avatarIndex, size: 18),
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
          Icon(Icons.person_off_rounded, size: 52, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('Профіль не знайдено'),
        ],
      ),
    );
  }
}
