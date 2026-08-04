import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/member_switcher_pill.dart';
import '../../shared/widgets/peer_section_closed_card.dart';
import '../../shared/widgets/plan_upgrade_banner.dart';
import '../../shared/widgets/switch_profile_banner.dart';
import '../appointments/appointments_history_screen.dart';
import '../family/peer_view_providers.dart';
import '../plans/elly_denied_screen.dart';
import '../today/providers/today_providers.dart';
import '../wellbeing/wellbeing_history_screen.dart';
import 'add_medcard_section_screen.dart';
import 'medcard_section_screen.dart';
import 'medication_archive_screen.dart';

final _medcardSectionsProvider =
    StreamProvider.family<List<MedcardSection>, int>((ref, memberId) {
  return ref.watch(medcardSectionsRepositoryProvider).watchByMember(memberId);
});

class MedCardScreen extends ConsumerStatefulWidget {
  const MedCardScreen({super.key});

  @override
  ConsumerState<MedCardScreen> createState() => _MedCardScreenState();
}

class _MedCardScreenState extends ConsumerState<MedCardScreen> {
  int? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    // Якщо десь у застосунку активовано перегляд "від імені" іншого члена
    // сім'ї — Архів теж підхоплює цей вибір (доки користувач сам не
    // перемкне когось локально через пілюлю), той самий патерн, що й у
    // Розкладі.
    ref.listen<int?>(activeMemberIdProvider, (prev, next) {
      if (next != prev) setState(() => _selectedMemberId = next);
    });
    final activeId = ref.watch(activeMemberIdProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final membersAsync = ref.watch(allMembersProvider);
    // Крок 4.3.4 плану: той самий глобальний стан, що вже вмикає перегляд
    // піра на Сьогодні/Розкладі.
    final peer = ref.watch(activePeerProvider);
    final peers = ref.watch(allFamilyPeersProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
          data: (defaultMember) {
            if (defaultMember == null) return const SizedBox.shrink();
            final members = membersAsync.valueOrNull ?? [defaultMember];
            final selected = members.firstWhere(
              (m) => m.id == (_selectedMemberId ?? defaultMember.id),
              orElse: () => defaultMember,
            );
            final showBanner = peer != null || shouldShowSwitchBanner(activeId, selected.role);
            return _MedCardBody(
              memberId: selected.id,
              memberName: peer?.name ?? selected.name,
              showSwitchBanner: showBanner,
              members: members,
              selected: selected,
              onMemberChanged: (id) {
                ref.read(activePeerProvider.notifier).state = null;
                setState(() => _selectedMemberId = id);
                // Пишемо і в глобальний activeMemberIdProvider — інакше вибір
                // діє лише на цьому екрані й злітає при переході на інші
                // вкладки (Сьогодні/Розклад). Вибір власного профілю в пікері
                // рівнозначний натисканню "Повернутись".
                ref.read(activeMemberIdProvider.notifier).state =
                    id == defaultMember.id ? null : id;
              },
              peer: peer,
              peers: peers,
              onSelectPeer: (p) {
                ref.read(activeMemberIdProvider.notifier).state = null;
                ref.read(activePeerProvider.notifier).state = p;
              },
            );
          },
        ),
      ),
    );
  }
}

class _MedCardBody extends ConsumerWidget {
  final int memberId;
  final String memberName;
  final bool showSwitchBanner;
  final List<Member> members;
  final Member selected;
  final void Function(int) onMemberChanged;
  final PeerSubject? peer;
  final List<FamilyPeer> peers;
  final void Function(PeerSubject)? onSelectPeer;
  const _MedCardBody({
    required this.memberId,
    required this.memberName,
    required this.showSwitchBanner,
    required this.members,
    required this.selected,
    required this.onMemberChanged,
    this.peer,
    this.peers = const [],
    this.onSelectPeer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readOnly = peer != null;
    // Крок 4.3.4 плану: для піра розділи (Полички) читаються через
    // перекладач, а не з локальної бази (той пір фізично не має тут
    // жодного Members-рядка).
    final AsyncValue<List<MedcardSection>> sectionsAsync = peer != null
        ? AsyncValue.data(ref.watch(peerMedcardSectionsProvider(peer!.personUuid)))
        : ref.watch(_medcardSectionsProvider(memberId));
    // Крок 4.3.6 плану: якщо суб'єкт закрив Полички — розділи взагалі не
    // потрапляють у кеш піра, тож замість тихо порожнього списку показуємо,
    // чому саме (той самий принцип, що на Сьогодні/Розкладі).
    final grants = ref.watch(activePeerGrantsProvider);
    final shelvesClosed = peer != null && grants != null && !grants.viewShelvesGranted;
    final limits = ref.watch(planProvider).limits;
    final sectionsCount = sectionsAsync.valueOrNull?.length ?? 0;
    final sectionsLimitReached = limits.maxMedcardSections != 0 &&
        sectionsCount >= limits.maxMedcardSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSwitchBanner) SwitchProfileBanner(name: memberName),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            AppDimensions.lg,
            AppDimensions.screenPadding,
            AppDimensions.md,
          ),
          child: Row(
            children: [
              Expanded(child: Text(context.l10n.medCardTitle, style: AppTextStyles.h2)),
              if (members.length > 1 || peers.isNotEmpty)
                MemberSwitcherPill(
                  members: members,
                  selected: selected,
                  onSelect: onMemberChanged,
                  peers: peers,
                  selectedPeer: peer,
                  onSelectPeer: onSelectPeer,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              0,
              AppDimensions.screenPadding,
              48,
            ),
            children: [
              _MedCardTile(
                icon: Icons.inventory_2_rounded,
                iconWidget: const AssetIcon('box', size: 22),
                iconColor: AppColors.primary,
                title: context.l10n.medCardArchiveTitle,
                subtitle: context.l10n.medCardArchiveSubtitle,
                // MedicationArchiveScreen/AppointmentsHistoryScreen/
                // WellbeingHistoryScreen поки не адаптовані під чужі дані
                // (Крок 4.3.5 плану) — ховаємо тап для піра.
                onTap: readOnly
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicationArchiveScreen(memberId: memberId),
                          ),
                        ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.event_note_rounded,
                iconWidget: const AssetIcon('task_reminder', size: 22),
                iconColor: AppColors.primary,
                title: context.l10n.medCardAppointmentsTitle,
                subtitle: context.l10n.medCardAppointmentsSubtitle,
                onTap: readOnly
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentsHistoryScreen(memberId: memberId),
                          ),
                        ),
              ),
              const SizedBox(height: AppDimensions.sm),
              _MedCardTile(
                icon: Icons.mood_rounded,
                iconWidget: const AssetIcon('task_wellbeing', size: 22),
                iconColor: AppColors.primary,
                title: context.l10n.medCardWellbeingHistoryTitle,
                subtitle: context.l10n.medCardWellbeingHistorySubtitle,
                onTap: readOnly
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WellbeingHistoryScreen(memberId: memberId),
                          ),
                        ),
              ),

              if (shelvesClosed)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.lg),
                  child: PeerSectionClosedCard(
                    peerName: peer!.name,
                    sectionLabel: context.l10n.familySectionShelvesLabel,
                  ),
                ),

              // ── Довільні розділи, створені користувачем ──
              sectionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (sections) {
                  if (sections.isEmpty) return const SizedBox.shrink();
                  // Автостворений розділ "Нотатки" завжди вгорі, поза
                  // драг-н-дропом — решта (реальний sortOrder із
                  // watchByMember) перетягується вільно.
                  MedcardSection? defaultSection;
                  final draggable = <MedcardSection>[];
                  for (final s in sections) {
                    if (s.isDefaultNotes && defaultSection == null) {
                      defaultSection = s;
                    } else {
                      draggable.add(s);
                    }
                  }
                  return Column(
                    children: [
                      const SizedBox(height: AppDimensions.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.customSectionsHeader,
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      if (defaultSection != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                          child: _MedCardTile(
                            icon: Icons.folder_rounded,
                            iconWidget: MedcardIcon(defaultSection.iconKey, size: 24),
                            iconColor: colorFromHex(defaultSection.color) ?? AppColors.primary,
                            title: defaultSection.name,
                            subtitle: defaultSection.comment,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedcardSectionScreen(
                                  section: defaultSection!,
                                  peer: peer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      _DraggableSections(sections: draggable, peer: peer, readOnly: readOnly),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppDimensions.lg),
              if (!readOnly && limits.maxMedcardSections != 0) ...[
                PlanUpgradeBanner(
                  badgeIcon: Icons.folder_rounded,
                  badge: context.l10n.medcardSectionsLimitBadge,
                  title: context.l10n.medcardSectionsLimitTitle,
                  subtitle: context.l10n.medcardSectionsLimitSubtitle(
                      sectionsCount, limits.maxMedcardSections),
                  illustrationAsset: 'assets/illustrations/elly-docs.png',
                ),
                const SizedBox(height: AppDimensions.md),
              ],
              if (!readOnly)
              GestureDetector(
                onTap: () {
                  if (sectionsLimitReached) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EllyDeniedScreen(
                          title: context.l10n.medcardSectionsLimitDeniedTitle,
                          subtitle:
                              context.l10n.medcardSectionsLimitDeniedSubtitle,
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMedcardSectionScreen(memberId: memberId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.addSectionAction,
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Довільні розділи: драг-н-дроп ────────────────────────────────────────────

class _DraggableSections extends ConsumerStatefulWidget {
  final List<MedcardSection> sections;
  final PeerSubject? peer;
  final bool readOnly;
  const _DraggableSections({required this.sections, this.peer, this.readOnly = false});

  @override
  ConsumerState<_DraggableSections> createState() => _DraggableSectionsState();
}

class _DraggableSectionsState extends ConsumerState<_DraggableSections> {
  late List<MedcardSection> _local;
  // Поки триває збереження нового порядку — не підміняти _local вхідними
  // widget.sections: той список ще зі старим sortOrder (потік watchByMember
  // емітить оновлення лише ПІСЛЯ завершення запису), інакше щойно
  // перетягнутий елемент на мить "відскочив" би назад.
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _local = widget.sections;
  }

  @override
  void didUpdateWidget(covariant _DraggableSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reordering) _local = widget.sections;
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    setState(() {
      _reordering = true;
      final item = _local.removeAt(oldIndex);
      _local.insert(newIndex, item);
    });
    await ref
        .read(medcardSectionsRepositoryProvider)
        .reorder(_local.map((s) => s.id).toList());
    if (mounted) setState(() => _reordering = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_local.isEmpty) return const SizedBox.shrink();
    // Для піра — звичайний список, без драг-н-дропу (перетягувати чужий
    // порядок розділів немає сенсу — Крок 4.3.4 плану).
    if (widget.readOnly) {
      return Column(
        children: _local
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                  child: _MedCardTile(
                    icon: Icons.folder_rounded,
                    iconWidget: MedcardIcon(s.iconKey, size: 24),
                    iconColor: colorFromHex(s.color) ?? AppColors.primary,
                    title: s.name,
                    subtitle: s.comment,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedcardSectionScreen(section: s, peer: widget.peer),
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _local.length,
      onReorderItem: _handleReorder,
      itemBuilder: (context, index) {
        final s = _local[index];
        return Padding(
          key: ValueKey(s.id),
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: _MedCardTile(
            icon: Icons.folder_rounded,
            iconWidget: MedcardIcon(s.iconKey, size: 24),
            iconColor: colorFromHex(s.color) ?? AppColors.primary,
            title: s.name,
            subtitle: s.comment,
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_handle_rounded,
                color: AppColors.textMuted,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedcardSectionScreen(section: s),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MedCardTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? iconWidget;
  final Widget? leading;

  const _MedCardTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconWidget,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppDimensions.sm),
              ],
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: iconWidget ?? Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLg),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!disabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
