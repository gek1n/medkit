import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/section_label.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  int? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_allMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: membersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) {
          if (members.isEmpty) {
            return const _EmptyMembers();
          }
          final currentMemberId =
              _selectedMemberId ?? members.first.id;
          return _MedicationsBody(
            members: members,
            selectedMemberId: currentMemberId,
            onMemberChanged: (id) =>
                setState(() => _selectedMemberId = id),
          );
        },
      ),
    );
  }
}

final _allMembersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(membersRepositoryProvider).watchAll();
});

// ─── Body ────────────────────────────────────────────────────────────────────

class _MedicationsBody extends ConsumerWidget {
  final List<Member> members;
  final int selectedMemberId;
  final void Function(int) onMemberChanged;

  const _MedicationsBody({
    required this.members,
    required this.selectedMemberId,
    required this.onMemberChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync =
        ref.watch(_medicationsByMemberProvider(selectedMemberId));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        if (members.length > 1)
          SliverToBoxAdapter(
            child: _MemberFilterStrip(
              members: members,
              selectedId: selectedMemberId,
              onSelect: onMemberChanged,
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          sliver: medsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
            data: (meds) {
              final active = meds.where((m) => m.isActive).toList();
              final inactive = meds.where((m) => !m.isActive).toList();

              if (meds.isEmpty) {
                return SliverToBoxAdapter(child: _EmptyMeds(memberId: selectedMemberId));
              }

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (active.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.xl),
                    SectionLabel('Активні (${active.length})'),
                    const SizedBox(height: AppDimensions.md),
                    ...active.map((m) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimensions.sm),
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
                  ],
                  if (inactive.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.xl),
                    SectionLabel('Завершені (${inactive.length})'),
                    const SizedBox(height: AppDimensions.md),
                    ...inactive.map((m) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimensions.sm),
                          child: _MedCard(med: m, dimmed: true),
                        )),
                  ],
                  const SizedBox(height: 100),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final member = members.firstWhere(
      (m) => m.id == selectedMemberId,
      orElse: () => members.first,
    );
    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ліки', style: AppTextStyles.h2),
                    Text(
                      member.name,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      AddMedicationScreen(memberId: selectedMemberId),
                )),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _medicationsByMemberProvider =
    StreamProvider.family<List<Medication>, int>((ref, memberId) {
  return ref.watch(medicationsRepositoryProvider).watchByMember(memberId);
});

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
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPadding),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = members[i];
          final selected = m.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

// ─── Med card ─────────────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final Medication med;
  final bool dimmed;

  const _MedCard({required this.med, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final opacity = dimmed ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: MkCard(
        color: AppColors.surface,
        borderColor: AppColors.border,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: dimmed ? AppColors.bgPage : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Center(
                child: Text(
                  _formEmoji(med.form),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(
                    '${_doseStr(med)} · ${_repeatStr(med)}',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            if (med.totalCount > 0)
              _PillBadge(
                  remaining: med.remainingCount, total: med.totalCount),
            const SizedBox(width: AppDimensions.sm),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
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
      child: Text(
        '$remaining',
        style: AppTextStyles.labelSm.copyWith(color: color),
      ),
    );
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyMeds extends StatelessWidget {
  final int memberId;
  const _EmptyMeds({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('💊', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Ліків ще немає', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Натисніть + щоб додати перше лікарство',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddMedicationScreen(memberId: memberId),
            )),
            icon: const Icon(Icons.add),
            label: const Text('Додати лікарство'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
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
          const Text('👤', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Профіль не знайдено', style: AppTextStyles.h3),
        ],
      ),
    );
  }
}
