import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/med_form_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../add/add_activity_screen.dart';
import '../add/add_type_sheet.dart';
import '../appointments/add_appointment_screen.dart';
import '../medications/add_medication_screen.dart';
import '../today/providers/today_providers.dart' show activeMemberIdProvider;
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

enum _ScheduleCategory { all, meds, appointments, activities, wellbeing }

extension on _ScheduleCategory {
  IconData get icon => switch (this) {
        _ScheduleCategory.all => Icons.grid_view_rounded,
        _ScheduleCategory.meds => Icons.medication_rounded,
        _ScheduleCategory.activities => Icons.directions_walk_rounded,
        _ScheduleCategory.wellbeing => Icons.favorite_rounded,
        _ScheduleCategory.appointments => Icons.medical_services_rounded,
      };

  String get label => switch (this) {
        _ScheduleCategory.all => 'Усі',
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
  _ScheduleCategory _category = _ScheduleCategory.all;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    // Якщо десь у застосунку активовано перегляд "від імені" іншого члена
    // сім'ї — Розклад теж підхоплює цей вибір (доки користувач сам не
    // перемкне когось локально через _MemberSwitcherPill).
    ref.listen<int?>(activeMemberIdProvider, (prev, next) {
      if (next != prev) setState(() => _selectedMemberId = next);
    });
    final activeId = ref.watch(activeMemberIdProvider);
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
          final memberId = _selectedMemberId ?? activeId ?? members.first.id;
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
    Member? owner;
    for (final m in members) {
      if (m.role == 'owner') {
        owner = m;
        break;
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(_scheduleMedsProvider(selectedMemberId));
        ref.invalidate(_scheduleActivitiesProvider(selectedMemberId));
        ref.invalidate(_scheduleAppointmentsProvider(selectedMemberId));
        ref.invalidate(_scheduleWellbeingScheduleProvider(selectedMemberId));
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (owner != null && member.id != owner.id)
          SliverToBoxAdapter(
            child: SwitchProfileBanner(
              name: member.name,
              onReturn: () {
                // Скидаємо і глобальний activeMemberIdProvider — інакше при
                // поверненні на цей екран (наприклад, через нижню навігацію)
                // _selectedMemberId знову підхопить старе глобальне значення
                // через ref.listen вище, і кнопка виглядатиме так, ніби
                // нічого не робить.
                ref.read(activeMemberIdProvider.notifier).state = null;
                onMemberChanged(owner!.id);
              },
            ),
          ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Розклад', style: AppTextStyles.h2),
                    ),
                    if (members.length > 1)
                      _MemberSwitcherPill(
                        members: members,
                        selected: member,
                        onSelect: onMemberChanged,
                      ),
                  ],
                ),
              ),
            ),
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
            padding: const EdgeInsets.only(top: AppDimensions.sm),
            child: _CategoryChipsRow(
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
                if (category == _ScheduleCategory.all ||
                    category == _ScheduleCategory.meds) ...[
                  const _SectionHeader(
                    icon: Icons.medication_rounded,
                    title: 'Ліки',
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
                ],

                if (category == _ScheduleCategory.all ||
                    category == _ScheduleCategory.appointments) ...[
                  const _SectionHeader(
                    icon: Icons.medical_services_rounded,
                    title: 'Прийоми лікарів',
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
                  const SizedBox(height: AppDimensions.xl),
                ],

                if (category == _ScheduleCategory.all ||
                    category == _ScheduleCategory.activities) ...[
                  const _SectionHeader(
                    icon: Icons.directions_walk_rounded,
                    title: 'Активності',
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
                  const SizedBox(height: AppDimensions.xl),
                ],

                if (category == _ScheduleCategory.all ||
                    category == _ScheduleCategory.wellbeing) ...[
                  const _SectionHeader(
                    icon: Icons.favorite_rounded,
                    title: 'Самопочуття',
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
      ),
    );
  }
}

// ─── Category chips row ──────────────────────────────────────────────────────

class _CategoryChipsRow extends StatelessWidget {
  final _ScheduleCategory selected;
  final ValueChanged<_ScheduleCategory> onChanged;

  const _CategoryChipsRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding),
        itemCount: _ScheduleCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _ScheduleCategory.values[i];
          final active = c == selected;
          return GestureDetector(
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon,
                      size: 16,
                      color: active ? Colors.white : AppColors.textSub),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: AppTextStyles.labelMd.copyWith(
                        color: active ? Colors.white : AppColors.textMain),
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
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

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: SectionLabel(title)),
      ],
    );
  }
}

// Спільне тло для рядків розкладу: біла картка з тінню + кольорова смужка
// зліва (колір самого завдання, як на "Сьогодні") + опційний блок праворуч
// від шеврону (залишок/дата), по центру висоти картки.
BoxDecoration _taskCardDecoration() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: const [
        BoxShadow(
            color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
      ],
    );

class _TaskCardShell extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? extraLine;
  final Widget? trailing;

  const _TaskCardShell({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.extraLine,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _taskCardDecoration(),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 60, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Center(child: Icon(icon, size: 22, color: color)),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.labelLg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (extraLine != null) ...[
                        const SizedBox(height: 2),
                        Text(extraLine!,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: color),
          ),
        ],
      ),
    );
  }
}

String _daysWordUk(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'днів';
  if (mod10 == 1) return 'день';
  if (mod10 >= 2 && mod10 <= 4) return 'дні';
  return 'днів';
}

// ─── Med card ─────────────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final Medication med;
  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(med.color) ?? AppColors.primary;
    return _TaskCardShell(
      color: color,
      icon: medFormIcon(med.form),
      title: med.name,
      subtitle: '${_doseStr(med)} · ${_repeatStr(med)}',
      extraLine: _daysLeftStr(med),
      trailing: med.totalCount > 0
          ? _PillBadge(remaining: med.remainingCount, total: med.totalCount)
          : null,
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

  String _daysLeftStr(Medication m) {
    if (m.endDate == null) return 'постійний курс';
    final diff = m.endDate!.difference(DateTime.now()).inDays + 1;
    if (diff <= 0) return 'курс завершено';
    return '$diff ${_daysWordUk(diff)} курсу';
  }
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
    final color = colorFromHex(activity.color) ?? AppColors.primary;
    return _TaskCardShell(
      color: color,
      icon: _typeIcon(activity.type),
      title: activity.name,
      subtitle: '${activity.durationMin} хв · ${_daysStr(activity.repeatDays)}',
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
    final color = colorFromHex(appointment.color) ?? AppColors.primary;
    final fmt = DateFormat('d MMM', 'uk');
    final hh = appointment.scheduledAt.hour.toString().padLeft(2, '0');
    final mm = appointment.scheduledAt.minute.toString().padLeft(2, '0');
    final hasLocation =
        appointment.location != null && appointment.location!.isNotEmpty;
    return _TaskCardShell(
      color: color,
      icon: Icons.medical_services_rounded,
      title: appointment.doctorType,
      subtitle: hasLocation ? appointment.location! : 'Без місця проведення',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(fmt.format(appointment.scheduledAt),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textSub)),
          Text('$hh:$mm',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.textMuted, fontSize: 10)),
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
    final color = colorFromHex(schedule.color) ?? AppColors.primary;

    return _TaskCardShell(
      color: color,
      icon: Icons.favorite_rounded,
      title: freqStr,
      subtitle: timesStr,
    );
  }
}

// ─── Member switcher pill ─────────────────────────────────────────────────────

class _MemberSwitcherPill extends StatelessWidget {
  final List<Member> members;
  final Member selected;
  final void Function(int) onSelect;

  const _MemberSwitcherPill({
    required this.members,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _MemberPickerSheet(
          members: members,
          selectedId: selected.id,
          onSelect: onSelect,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarImage(index: selected.avatarIndex, size: 20),
            const SizedBox(width: 6),
            Text(selected.name, style: AppTextStyles.labelMd),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerSheet extends StatelessWidget {
  final List<Member> members;
  final int selectedId;
  final void Function(int) onSelect;

  const _MemberPickerSheet({
    required this.members,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SectionLabel('Оберіть профіль'),
            ),
            ...members.map((m) {
              final sel = m.id == selectedId;
              return ListTile(
                onTap: () {
                  onSelect(m.id);
                  Navigator.pop(context);
                },
                leading: AvatarImage(index: m.avatarIndex, size: 36),
                title: Text(m.name,
                    style: AppTextStyles.bodyMd.copyWith(
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400)),
                trailing: sel
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
              );
            }),
          ],
        ),
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
