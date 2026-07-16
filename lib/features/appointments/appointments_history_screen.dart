import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/doctor_appointments_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/specialty_picker.dart';
import '../today/providers/today_providers.dart';
import 'add_appointment_screen.dart';

// ────────────────────────────── provider ──────────────────────────────

final _allAppointmentsProvider =
    StreamProvider<List<DoctorAppointment>>((ref) {
  return ref.watch(doctorAppointmentsRepositoryProvider).watchAll();
});

// ────────────────────────────── screen ──────────────────────────────

class AppointmentsHistoryScreen extends ConsumerStatefulWidget {
  // Якщо задано (напр. з Медкартки, де вже обраний конкретний профіль) —
  // показує візити лише цього члена сім'ї. Без нього — усі візити родини,
  // як і раніше (той самий шлях, яким Сім'я/Профіль можуть показати
  // спільний календар).
  final int? memberId;
  const AppointmentsHistoryScreen({super.key, this.memberId});

  @override
  ConsumerState<AppointmentsHistoryScreen> createState() =>
      _AppointmentsHistoryScreenState();
}

class _AppointmentsHistoryScreenState
    extends ConsumerState<AppointmentsHistoryScreen> {
  String? _specialty;

  Future<void> _pickSpecialty() async {
    final picked = await showSpecialtyPicker(context, current: _specialty);
    if (picked != null) setState(() => _specialty = picked);
  }

  @override
  Widget build(BuildContext context) {
    final aptsAsync = ref.watch(_allAppointmentsProvider);
    final membersAsync = ref.watch(allMembersProvider);
    final currentMemberAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () {
          final targetId = widget.memberId ?? currentMemberAsync.valueOrNull?.id;
          if (targetId == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddAppointmentScreen(memberId: targetId)),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SpecialtyFilterChip(
                  specialty: _specialty,
                  onTap: _pickSpecialty,
                  onClear: () => setState(() => _specialty = null),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Expanded(
              child: aptsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) =>
                    Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                data: (allApts) {
                  final members = membersAsync.valueOrNull ?? [];
                  final apts = allApts
                      .where((a) => widget.memberId == null || a.memberId == widget.memberId)
                      .where((a) => _specialty == null || a.doctorType == _specialty)
                      .toList();
                  final hasFilter = _specialty != null;
                  return _AppointmentsList(
                      apts: apts, members: members, filtered: hasFilter);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── header ──────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(context.l10n.appointmentsHistoryTitle, style: AppTextStyles.h3)),
        ],
      ),
    );
  }
}

// ────────────────────────────── specialty filter chip ─────────────────────

class _SpecialtyFilterChip extends StatelessWidget {
  final String? specialty;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _SpecialtyFilterChip({
    required this.specialty,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final active = specialty != null;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              specialty ?? context.l10n.allSpecialtiesFilter,
              style: AppTextStyles.labelMd.copyWith(
                color: active ? AppColors.primary : AppColors.textSub,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── list ──────────────────────────────

class _AppointmentsList extends StatelessWidget {
  final List<DoctorAppointment> apts;
  final List<Member> members;
  final bool filtered;

  const _AppointmentsList(
      {required this.apts, required this.members, this.filtered = false});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming =
        apts.where((a) => a.scheduledAt.isAfter(now)).toList();
    final past = apts
        .where((a) => !a.scheduledAt.isAfter(now))
        .toList()
        .reversed
        .toList(); // newest past first

    if (apts.isEmpty) return _EmptyState(filtered: filtered);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.md,
        AppDimensions.screenPadding,
        48,
      ),
      children: [
        if (upcoming.isNotEmpty) ...[
          SectionLabel(context.l10n.sectionFuture),
          const SizedBox(height: AppDimensions.md),
          ...upcoming.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(
                    bottom: AppDimensions.sm),
                child: _AppointmentCard(
                  apt: e.value,
                  members: members,
                  isNext: e.key == 0,
                  isPast: false,
                ),
              )),
          const SizedBox(height: AppDimensions.lg),
        ],
        if (past.isNotEmpty) ...[
          SectionLabel(context.l10n.sectionPast),
          const SizedBox(height: AppDimensions.md),
          ...past.map((a) => Padding(
                padding: const EdgeInsets.only(
                    bottom: AppDimensions.sm),
                child: _AppointmentCard(
                  apt: a,
                  members: members,
                  isNext: false,
                  isPast: true,
                ),
              )),
        ],
      ],
    );
  }
}

// ────────────────────────────── appointment card ──────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointment apt;
  final List<Member> members;
  final bool isNext;
  final bool isPast;

  const _AppointmentCard({
    required this.apt,
    required this.members,
    required this.isNext,
    required this.isPast,
  });

  List<String> _monthsShort(BuildContext context) {
    final l10n = context.l10n;
    return [
      '',
      l10n.monthAbbrJan,
      l10n.monthAbbrFeb,
      l10n.monthAbbrMar,
      l10n.monthAbbrApr,
      l10n.monthAbbrMay,
      l10n.monthAbbrJun,
      l10n.monthAbbrJul,
      l10n.monthAbbrAug,
      l10n.monthAbbrSep,
      l10n.monthAbbrOct,
      l10n.monthAbbrNov,
      l10n.monthAbbrDec,
    ];
  }

  Member? get _member =>
      members.cast<Member?>().firstWhere(
            (m) => m?.id == apt.memberId,
            orElse: () => null,
          );

  Color get _badgeBg {
    if (isPast) return AppColors.successLight;
    if (isNext) return AppColors.primary;
    return const Color(0xFFF1F5F9);
  }

  Color get _badgeText {
    if (isPast) return AppColors.success;
    if (isNext) return Colors.white;
    return AppColors.textSub;
  }

  @override
  Widget build(BuildContext context) {
    final member = _member;
    final memberName =
        member?.role == 'owner' ? context.l10n.meCapsLabel : (member?.name ?? '');

    final hh = apt.scheduledAt.hour.toString().padLeft(2, '0');
    final mm = apt.scheduledAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hh:$mm';

    return Opacity(
      opacity: isPast ? 0.72 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isNext ? AppColors.primaryLight : AppColors.bg,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isNext
                ? AppColors.primary
                : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _badgeBg,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${apt.scheduledAt.day}',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _badgeText,
                      height: 1,
                    ),
                  ),
                  Text(
                    _monthsShort(context)[apt.scheduledAt.month],
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _badgeText.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apt.doctorType,
                    style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    apt.location != null && apt.location!.isNotEmpty
                        ? '$timeStr · ${apt.location}'
                        : timeStr,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      member != null
                          ? AvatarImage(index: member.avatarIndex, size: 14)
                          : const Icon(Icons.person_rounded,
                              size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        memberName,
                        style: AppTextStyles.bodySm.copyWith(
                          color: isNext
                              ? AppColors.primary
                              : AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Trailing
            isPast
                ? Text(
                    context.l10n.visitPassedLabel,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    context.l10n.arrowRightLabel,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.textMuted),
                  ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── empty ──────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({this.filtered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(filtered ? context.l10n.noAppointmentsForSpecialty : context.l10n.noRecordsYetTitle,
              style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            filtered
                ? context.l10n.tryDifferentSpecialtyHint
                : context.l10n.tapToAddFirstHint,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
