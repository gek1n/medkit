import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/wellbeing_repository.dart';
import '../../shared/widgets/member_switcher_pill.dart';
import '../../shared/widgets/peer_section_closed_card.dart';
import '../../shared/widgets/plan_upgrade_banner.dart';
import '../../shared/widgets/section_label.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../add/add_activity_screen.dart';
import '../add/add_task_screen.dart';
import '../add/routine_view_screen.dart';
import '../appointments/add_appointment_screen.dart';
import '../appointments/reminder_view_screen.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import '../medications/add_medication_screen.dart';
import '../plans/elly_denied_screen.dart';
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

// Всі АКТИВНІ нагадування учасника — не лише "майбутні" за scheduledAt, бо
// для щоденних/щотижневих/щорічних (repeatType != 'none') це поле лише
// "якір", не реальна наступна дата спрацювання (та обчислюється нативно ОС).
// watchActiveByMember (а не watchByMember) ховає одноразові нагадування, що
// вже позначені виконаними/пропущеними — повторювані ж лишаються видимими,
// доки серія не видалена цілком (їхній status завжди 'pending').
final _scheduleAppointmentsProvider =
    StreamProvider.family<List<Reminder>, int>((ref, memberId) {
  return ref.watch(remindersRepositoryProvider).watchActiveByMember(memberId);
});

final _scheduleWellbeingScheduleProvider =
    StreamProvider.family<WellbeingSchedule?, int>((ref, memberId) {
  return ref.watch(wellbeingRepositoryProvider).watchScheduleByMember(memberId);
});

// ─── Category ────────────────────────────────────────────────────────────────

// 4 типізовані категорії (той самий порядок, що й у пікері створення
// завдання) + "Всі". Нагадування — об'єднана форма (заміна Зустрічі/Спорт/
// Прості завдання), завжди з таблиці Reminders. Рутинні справи — окремо,
// це Activities зі службовим (прихованим від юзера) type == 'routine'.
enum _ScheduleCategory { all, meds, reminders, routine, wellbeing }

const _kActivityTypeRoutine = 'routine';

extension on _ScheduleCategory {
  IconData get icon => switch (this) {
        _ScheduleCategory.all => Icons.grid_view_rounded,
        _ScheduleCategory.meds => Icons.medication_rounded,
        _ScheduleCategory.reminders => Icons.notifications_rounded,
        _ScheduleCategory.routine => Icons.home_repair_service_rounded,
        _ScheduleCategory.wellbeing => Icons.favorite_rounded,
      };

  // "Всі" не має власного task_*-асета (це не окремий тип, а перемикач
  // показу всіх одразу) — лишається на Material-іконці.
  String? get assetKey => switch (this) {
        _ScheduleCategory.all => null,
        _ScheduleCategory.meds => 'box',
        _ScheduleCategory.reminders => 'task_reminder',
        _ScheduleCategory.routine => 'task_routine',
        _ScheduleCategory.wellbeing => 'task_wellbeing',
      };

  String label(BuildContext context) => switch (this) {
        _ScheduleCategory.all => context.l10n.categoryAll,
        _ScheduleCategory.meds => context.l10n.categoryMeds,
        _ScheduleCategory.reminders => context.l10n.reminderCategoryTitle,
        _ScheduleCategory.routine => context.l10n.taskTypeRoutine,
        _ScheduleCategory.wellbeing => context.l10n.categoryWellbeing,
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
    // Крок 4.3.3 плану: те саме, але для автономного піра — глобальний
    // стан (той самий, що й Сьогодні), тож перемикання деінде теж
    // одразу відображається тут.
    final peer = ref.watch(activePeerProvider);
    final peers = ref.watch(allFamilyPeersProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: peer != null
          ? null
          : FloatingActionButton(
              onPressed: () => openAddTaskScreen(context, memberId: _selectedMemberId),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: membersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(context.l10n.errorGeneric('$e'))),
        data: (members) {
          if (members.isEmpty) {
            return const _EmptyMembers();
          }
          final memberId = _selectedMemberId ?? activeId ?? members.first.id;
          final owner = members.firstWhere((m) => m.role == 'owner',
              orElse: () => members.first);
          return _ScheduleBody(
            members: members,
            selectedMemberId: memberId,
            onMemberChanged: (id) {
              ref.read(activePeerProvider.notifier).state = null;
              setState(() => _selectedMemberId = id);
              // Пишемо і в глобальний activeMemberIdProvider — інакше вибір
              // діє лише на цьому екрані й злітає при переході на інші
              // вкладки (Сьогодні/Медкартка). Вибір власного профілю в
              // пікері рівнозначний натисканню "Повернутись".
              ref.read(activeMemberIdProvider.notifier).state =
                  id == owner.id ? null : id;
            },
            category: _category,
            onCategoryChanged: (c) => setState(() => _category = c),
            search: _search,
            onSearchChanged: (s) => setState(() => _search = s),
            peer: peer,
            peers: peers,
            onSelectPeer: (p) {
              ref.read(activeMemberIdProvider.notifier).state = null;
              ref.read(activePeerProvider.notifier).state = p;
            },
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
  final PeerSubject? peer;
  final List<FamilyPeer> peers;
  final void Function(PeerSubject)? onSelectPeer;

  const _ScheduleBody({
    required this.members,
    required this.selectedMemberId,
    required this.onMemberChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.search,
    required this.onSearchChanged,
    this.peer,
    this.peers = const [],
    this.onSelectPeer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readOnly = peer != null;
    // Крок 4.3.6 плану: той самий принцип, що на Сьогодні — коли суб'єкт
    // закрив розділ, дані взагалі не потрапляють у кеш піра, тож замість
    // тихо порожньої вкладки показуємо, чому саме.
    final grants = ref.watch(activePeerGrantsProvider);
    final scheduleClosed = peer != null && grants != null && !grants.viewScheduleGranted;
    final medcardClosed = peer != null && grants != null && !grants.viewMedcardGranted;
    // Крок 4.3.3 плану: коли обрано автономного піра, читаємо не з
    // локальної бази (той пір фізично не має тут Members-рядка), а з
    // перекладача (peer_view_providers.dart), той самий підхід, що й на
    // Сьогодні (today_screen.dart _TodayContent).
    final AsyncValue<List<Medication>> medsAsync;
    final AsyncValue<List<Activity>> activitiesAsync;
    final AsyncValue<List<Reminder>> appointmentsAsync;
    final AsyncValue<WellbeingSchedule?> wellbeingScheduleAsync;
    if (peer != null) {
      final uuid = peer!.personUuid;
      medsAsync = AsyncValue.data(ref.watch(peerMedicationsProvider(uuid)));
      activitiesAsync = AsyncValue.data(ref.watch(peerActivitiesProvider(uuid)));
      appointmentsAsync = AsyncValue.data(ref.watch(peerRemindersProvider(uuid)));
      final schedules = ref.watch(peerWellbeingSchedulesProvider(uuid));
      wellbeingScheduleAsync = AsyncValue.data(
        schedules.isEmpty
            ? null
            : schedules.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b),
      );
    } else {
      medsAsync = ref.watch(_scheduleMedsProvider(selectedMemberId));
      activitiesAsync = ref.watch(_scheduleActivitiesProvider(selectedMemberId));
      appointmentsAsync = ref.watch(_scheduleAppointmentsProvider(selectedMemberId));
      wellbeingScheduleAsync = ref.watch(_scheduleWellbeingScheduleProvider(selectedMemberId));
    }
    final limits = ref.watch(planProvider).limits;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final routineCount = activitiesAsync.valueOrNull?.length ?? 0;
    final routineLimitReached =
        limits.maxRoutineTasks != 0 && routineCount >= limits.maxRoutineTasks;
    // Крок 4.4.4 плану: якщо суб'єкт дозволив редагування відповідного
    // розділу саме цьому глядачеві — кнопки "додати" лишаються доступними
    // і для піра, лише замість прямого запису шлють record_proposal
    // (Крок 4.4.1). Ліки/рутини — Розклад; нагадування — Медкартка
    // (Візити/Самопочуття), той самий бар'єр, що й у
    // FamilyPeerSyncService._push.
    final canEditSchedulePeer =
        peer != null && grants != null && grants.viewScheduleGranted && grants.editScheduleGranted;
    final canEditMedcardPeer =
        peer != null && grants != null && grants.viewMedcardGranted && grants.editMedcardGranted;

    void openAddRoutine() {
      if (peer != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddActivityScreen(
              hideTypePicker: true,
              forcedType: _kActivityTypeRoutine,
              compactMode: true,
              onDraftCreated: (draft) => submitActivityProposal(ref, peer!, draft),
            ),
          ),
        );
        return;
      }
      if (routineLimitReached) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EllyDeniedScreen(
              title: context.l10n.routineTasksLimitDeniedTitle,
              subtitle: context.l10n.routineTasksLimitDeniedSubtitle,
            ),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddActivityScreen(
            memberId: selectedMemberId,
            hideTypePicker: true,
            forcedType: _kActivityTypeRoutine,
            compactMode: true,
          ),
        ),
      );
    }

    void openAddMedication() {
      if (peer != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedicationScreen(
              onDraftCreated: (draft) => submitMedicationProposal(ref, peer!, draft),
            ),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddMedicationScreen(memberId: selectedMemberId),
        ),
      );
    }

    void openAddAppointment() {
      if (peer != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddAppointmentScreen(
              onDraftCreated: (draft, slotTimes) => submitReminderProposal(
                ref,
                peer!,
                draft,
                slotTimes: slotTimes,
              ),
            ),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddAppointmentScreen(memberId: selectedMemberId),
        ),
      );
    }

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
        if (peer != null || (owner != null && member.id != owner.id))
          SliverToBoxAdapter(
            child: SwitchProfileBanner(
              name: peer?.name ?? member.name,
              onReturn: () {
                // Скидаємо і глобальний activeMemberIdProvider — інакше при
                // поверненні на цей екран (наприклад, через нижню навігацію)
                // _selectedMemberId знову підхопить старе глобальне значення
                // через ref.listen вище, і кнопка виглядатиме так, ніби
                // нічого не робить.
                ref.read(activePeerProvider.notifier).state = null;
                ref.read(activeMemberIdProvider.notifier).state = null;
                if (owner != null) onMemberChanged(owner.id);
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
                      child: Text(context.l10n.scheduleTitle, style: AppTextStyles.h2),
                    ),
                    if (members.length > 1 || peers.isNotEmpty)
                      MemberSwitcherPill(
                        members: members,
                        selected: member,
                        onSelect: onMemberChanged,
                        peers: peers,
                        selectedPeer: peer,
                        onSelectPeer: onSelectPeer,
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
              hint: context.l10n.searchAllSections,
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

              if (scheduleClosed &&
                  (category == _ScheduleCategory.all ||
                      category == _ScheduleCategory.meds ||
                      category == _ScheduleCategory.routine))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: PeerSectionClosedCard(
                    peerName: peer!.name,
                    sectionLabel: context.l10n.familySectionScheduleLabel,
                  ),
                ),
              if (medcardClosed &&
                  (category == _ScheduleCategory.all ||
                      category == _ScheduleCategory.reminders ||
                      category == _ScheduleCategory.wellbeing))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: PeerSectionClosedCard(
                    peerName: peer!.name,
                    sectionLabel: context.l10n.familySectionVisitsWellbeingLabel,
                  ),
                ),

              if (q.isEmpty) ...[
                if (category == _ScheduleCategory.all ||
                    category == _ScheduleCategory.meds) ...[
                  _SectionHeader(
                    icon: Icons.medication_rounded,
                    iconWidget: const AssetIcon('box', size: 22),
                    title: context.l10n.sectionMeds,
                    onAdd: (peer == null || canEditSchedulePeer) ? openAddMedication : null,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  medsAsync.when(
                    loading: () => const _SectionLoading(),
                    error: (e, _) => Text(context.l10n.errorGeneric('$e')),
                    data: (allMeds) {
                      // Курс, що вже завершився (endDate у минулому), не
                      // потребує дії й лише захаращує Розклад — лишається
                      // видимим в Архіві ліків зі статусом "завершено".
                      final meds = allMeds
                          .where((m) =>
                              m.endDate == null ||
                              !m.endDate!.isBefore(startOfToday))
                          .toList();
                      if (meds.isEmpty) {
                        return _EmptySection(
                          hint: context.l10n.noActiveMeds,
                          onAdd: (peer == null || canEditSchedulePeer) ? openAddMedication : null,
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
                                          memberId: m.memberId,
                                          peer: peer,
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
                    category == _ScheduleCategory.reminders) ...[
                  _SectionHeader(
                    icon: Icons.notifications_rounded,
                    iconWidget: const AssetIcon('task_reminder', size: 22),
                    title: context.l10n.reminderCategoryTitle,
                    onAdd: (peer == null || canEditMedcardPeer) ? openAddAppointment : null,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  appointmentsAsync.when(
                    loading: () => const _SectionLoading(),
                    error: (e, _) => Text(context.l10n.errorGeneric('$e')),
                    data: (allAppointments) {
                      // Розове нагадування (repeatType=='none'), що вже
                      // минуло й ніколи не позначене відвіданим/пропущеним
                      // (лишається status=='pending' назавжди — див.
                      // watchActiveByMember) — не потребує дії й лише
                      // захаращує Розклад, ховаємо. Повторювані завжди
                      // лишаються видимими (їм властивий той самий 'pending'
                      // status незалежно від дати).
                      final appointments = allAppointments
                          .where((a) =>
                              a.repeatType != 'none' ||
                              !a.scheduledAt.isBefore(startOfToday))
                          .toList();
                      if (appointments.isEmpty) {
                        return _EmptySection(
                          hint: context.l10n.noScheduledAppointments,
                          onAdd: (peer == null || canEditMedcardPeer) ? openAddAppointment : null,
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
                                        builder: (_) => ReminderViewScreen(
                                          reminderId: a.id,
                                          peer: peer,
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
                    category == _ScheduleCategory.routine) ...[
                  _SectionHeader(
                    icon: Icons.home_repair_service_rounded,
                    iconWidget: const AssetIcon('task_routine', size: 22),
                    title: context.l10n.taskTypeRoutine,
                    onAdd: (peer == null || canEditSchedulePeer) ? openAddRoutine : null,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  activitiesAsync.when(
                    loading: () => const _SectionLoading(),
                    error: (e, _) => Text(context.l10n.errorGeneric('$e')),
                    data: (activities) {
                      // Усі isActive-активності — не лише type=='routine'.
                      // Старі записи Спорту/Простих завдань (типи
                      // general_sport/simple_task, створені до об'єднання
                      // пікера) досі можуть існувати в БД — без цього вони
                      // "губились" би: не мають власної секції жодного
                      // категорійного фільтра, тож ставали невидимими в
                      // Розкладі попри isActive=true.
                      final routine = activities;
                      if (routine.isEmpty) {
                        return _EmptySection(
                          hint: context.l10n.noRoutineTasksHint,
                          onAdd: (peer == null || canEditSchedulePeer) ? openAddRoutine : null,
                        );
                      }
                      return Column(
                        children: routine
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RoutineViewScreen(
                                          activityId: a.id,
                                          peer: peer,
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
                  if (limits.maxRoutineTasks != 0) ...[
                    const SizedBox(height: AppDimensions.md),
                    PlanUpgradeBanner(
                      badgeIcon: Icons.home_repair_service_rounded,
                      badge: context.l10n.routineTasksLimitBadge,
                      title: context.l10n.routineTasksLimitTitle,
                      subtitle: context.l10n.routineTasksLimitSubtitle(
                          routineCount, limits.maxRoutineTasks),
                      illustrationAsset: 'assets/illustrations/elly-calendar.png',
                    ),
                  ],
                  const SizedBox(height: AppDimensions.xl),
                ],

                if (category == _ScheduleCategory.all ||
                    category == _ScheduleCategory.wellbeing) ...[
                  _SectionHeader(
                    icon: Icons.favorite_rounded,
                    iconWidget: const AssetIcon('task_wellbeing', size: 22),
                    title: context.l10n.sectionWellbeing,
                    onAdd: readOnly
                        ? null
                        : () => Navigator.push(
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
                    error: (e, _) => Text(context.l10n.errorGeneric('$e')),
                    data: (schedule) {
                      if (schedule == null || !schedule.isActive) {
                        return _EmptySection(
                          hint: context.l10n.wellbeingScheduleNotSet,
                          onAdd: readOnly
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddWellbeingScheduleScreen(memberId: selectedMemberId),
                                    ),
                                  ),
                        );
                      }
                      return GestureDetector(
                        // AddWellbeingScheduleScreen тут виступає і як
                        // редактор — ховаємо тап для піра (Крок 4.3.5).
                        onTap: readOnly
                            ? null
                            : () => Navigator.push(
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
                    return _EmptySection(hint: context.l10n.nothingFound);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meds.isNotEmpty) ...[
                        _SectionHeader(
                          icon: Icons.medication_rounded,
                          iconWidget: const AssetIcon('box', size: 22),
                          title: context.l10n.sectionMeds,
                        ),
                        const SizedBox(height: AppDimensions.md),
                        ...meds.map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicationDetailScreen(
                                      medicationId: m.id,
                                      memberId: m.memberId,
                                      peer: peer,
                                    ),
                                  ),
                                ),
                                child: _MedCard(med: m),
                              ),
                            )),
                        const SizedBox(height: AppDimensions.xl),
                      ],
                      if (activities.isNotEmpty) ...[
                        _SectionHeader(
                          icon: Icons.home_repair_service_rounded,
                          iconWidget: const AssetIcon('task_routine', size: 22),
                          title: context.l10n.sectionActivities,
                        ),
                        const SizedBox(height: AppDimensions.md),
                        ...activities.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoutineViewScreen(
                                      activityId: a.id,
                                      peer: peer,
                                    ),
                                  ),
                                ),
                                child: _ActivityCard(activity: a),
                              ),
                            )),
                        const SizedBox(height: AppDimensions.xl),
                      ],
                      if (appointments.isNotEmpty) ...[
                        _SectionHeader(
                          icon: Icons.notifications_rounded,
                          iconWidget: const AssetIcon('task_reminder', size: 22),
                          title: context.l10n.sectionAppointments,
                        ),
                        const SizedBox(height: AppDimensions.md),
                        ...appointments.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReminderViewScreen(
                                      reminderId: a.id,
                                      peer: peer,
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
                  c.assetKey != null
                      ? AssetIcon(c.assetKey!, size: 20)
                      : Icon(c.icon,
                          size: 16,
                          color: active ? Colors.white : AppColors.textSub),
                  const SizedBox(width: 6),
                  Text(
                    c.label(context),
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
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
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
  final Widget? iconWidget;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.onAdd,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget ?? Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: SectionLabel(title)),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
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
  final Widget? iconWidget;

  const _TaskCardShell({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.extraLine,
    this.trailing,
    this.iconWidget,
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
                  child: Center(child: iconWidget ?? Icon(icon, size: 22, color: color)),
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

// ─── Med card ─────────────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final Medication med;
  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(med.color) ?? AppColors.primary;
    return _TaskCardShell(
      color: color,
      icon: Icons.inventory_2_rounded,
      iconWidget: MedcardIcon(med.iconKey ?? 'form_cream', size: 26),
      title: med.name,
      subtitle: '${_doseStr(med)} · ${_repeatStr(context, med)}',
      extraLine: _daysLeftStr(context, med),
      trailing: med.totalCount > 0
          ? _PillBadge(remaining: med.remainingCount, total: med.totalCount)
          : null,
    );
  }

  String _doseStr(Medication m) =>
      '${m.doseAmount.toStringAsFixed(m.doseAmount == m.doseAmount.roundToDouble() ? 0 : 1)} ${m.doseUnit}';

  String _repeatStr(BuildContext context, Medication m) => switch (m.repeatType) {
        'daily' => context.l10n.repeatDaily,
        'alternate' => context.l10n.repeatAlternate,
        'weekdays' => context.l10n.repeatWeekdays,
        'every_n' => context.l10n.repeatEveryN,
        'cycle' => context.l10n.repeatCycle,
        _ => '',
      };

  String _daysLeftStr(BuildContext context, Medication m) {
    if (m.endDate == null) return context.l10n.courseOngoing;
    final diff = m.endDate!.difference(DateTime.now()).inDays + 1;
    if (diff <= 0) return context.l10n.courseFinished;
    return context.l10n.courseDaysLeft(diff);
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
      iconWidget: activity.type == _kActivityTypeRoutine
          ? const AssetIcon('task_routine', size: 26)
          : null,
      title: activity.name,
      subtitle:
          '${context.l10n.durationMinutes(activity.durationMin)} · ${_daysStr(context, activity.repeatDays)}',
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'walk' => Icons.directions_walk_rounded,
        'workout' => Icons.fitness_center_rounded,
        'yoga' => Icons.self_improvement_rounded,
        'cycling' => Icons.directions_bike_rounded,
        _kActivityTypeRoutine => Icons.home_repair_service_rounded,
        _ => Icons.bolt_rounded,
      };

  String _daysStr(BuildContext context, String repeatDaysJson) {
    try {
      final raw = repeatDaysJson.replaceAll('[', '').replaceAll(']', '');
      final days = raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (days.length == 7) return context.l10n.repeatDaily;
      final names = [
        context.l10n.dayMon,
        context.l10n.dayTue,
        context.l10n.dayWed,
        context.l10n.dayThu,
        context.l10n.dayFri,
        context.l10n.daySat,
        context.l10n.daySun,
      ];
      return days.where((d) => d >= 1 && d <= 7).map((d) => names[d - 1]).join(', ');
    } catch (_) {
      return '';
    }
  }
}

// ─── Appointment card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Reminder appointment;
  const _AppointmentCard({required this.appointment});

  static String _dayLabel(BuildContext context, int weekday) {
    final l10n = context.l10n;
    return switch (weekday) {
      1 => l10n.dayMon,
      2 => l10n.dayTue,
      3 => l10n.dayWed,
      4 => l10n.dayThu,
      5 => l10n.dayFri,
      6 => l10n.daySat,
      _ => l10n.daySun,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(appointment.color) ?? AppColors.primary;
    final fmt = DateFormat('d MMM', Localizations.localeOf(context).languageCode);
    final hh = appointment.scheduledAt.hour.toString().padLeft(2, '0');
    final mm = appointment.scheduledAt.minute.toString().padLeft(2, '0');
    final hasLocation =
        appointment.location != null && appointment.location!.isNotEmpty;

    // scheduledAt — лише "якір" для daily/weekly/yearly (реальний час(и)
    // спрацювання беруться нативно ОС), тож для них показуємо тип повтору
    // замість дати, а для yearly — день+місяць (без року).
    Widget trailingContent;
    switch (appointment.repeatType) {
      case 'daily':
        trailingContent = Text(context.l10n.repeatDaily,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSub));
        break;
      case 'weekly':
        var weekdayLabels = '—';
        try {
          final cfg =
              jsonDecode(appointment.repeatConfig) as Map<String, dynamic>;
          final days = List<int>.from(cfg['days'] as List);
          weekdayLabels =
              days.map((d) => _dayLabel(context, d)).join(', ');
        } catch (_) {}
        trailingContent = Text(weekdayLabels,
            textAlign: TextAlign.end,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSub));
        break;
      case 'monthly':
        // scheduledAt.month зафіксовано на січні при збереженні (див.
        // AddAppointmentScreen._save) — важливий лише .day.
        trailingContent = Text(
            '${context.l10n.reminderMonthlyDayFieldLabel} ${appointment.scheduledAt.day}',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSub));
        break;
      case 'yearly':
        final dfmt =
            DateFormat('d MMM', Localizations.localeOf(context).languageCode);
        trailingContent = Text(dfmt.format(appointment.scheduledAt),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSub));
        break;
      default:
        trailingContent = Text(fmt.format(appointment.scheduledAt),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSub));
    }

    return _TaskCardShell(
      color: color,
      icon: Icons.notifications_rounded,
      iconWidget: MedcardIcon(appointment.iconKey, size: 26),
      title: appointment.doctorType,
      subtitle: hasLocation ? appointment.location! : context.l10n.noLocation,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          trailingContent,
          if (appointment.repeatType == 'none' ||
              appointment.repeatType == 'monthly' ||
              appointment.repeatType == 'yearly')
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
    final freqStr = context.l10n.timesPerDayLabel(schedule.timesPerDay);
    final color = colorFromHex(schedule.color) ?? AppColors.primary;

    return _TaskCardShell(
      color: color,
      icon: Icons.favorite_rounded,
      iconWidget: const AssetIcon('task_wellbeing', size: 26),
      title: freqStr,
      subtitle: timesStr,
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
                context.l10n.addAction,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_rounded, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(context.l10n.profileNotFound),
        ],
      ),
    );
  }
}
