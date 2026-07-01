import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../today/providers/today_providers.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _memberMedsProvider = StreamProvider.family<List<Medication>, int>(
  (ref, memberId) =>
      ref.watch(medicationsRepositoryProvider).watchByMember(memberId),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: membersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) => _FamilyBody(members: members),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _FamilyBody extends StatelessWidget {
  final List<Member> members;
  const _FamilyBody({required this.members});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _FamilyHeader(count: members.length)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppDimensions.lg),
              ...members.map((m) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.md),
                    child: _MemberCard(member: m),
                  )),
              _AddMemberTile(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FamilyHeader extends StatelessWidget {
  final int count;
  const _FamilyHeader({required this.count});

  @override
  Widget build(BuildContext context) {
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
                    Text('Сімʼя', style: AppTextStyles.h2),
                    Text(
                      '$count ${_membersLabel(count)}',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAddMemberSheet(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.primaryLighter, width: 1.5),
                  ),
                  child: const Icon(Icons.add,
                      color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _membersLabel(int n) {
    if (n == 1) return 'член';
    if (n < 5) return 'члени';
    return 'членів';
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────

class _MemberCard extends ConsumerWidget {
  final Member member;
  const _MemberCard({required this.member});

  static const _avatars = ['🧑', '👩', '👨', '👧', '👦', '👴', '👵', '🧒'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));
    final medsAsync = ref.watch(_memberMedsProvider(member.id));

    final intakes = intakesAsync.valueOrNull ?? [];
    final meds = medsAsync.valueOrNull ?? [];

    final taken = intakes.where((i) => i.status == 'taken').length;
    final total = intakes.length;
    final missed =
        intakes.where((i) => i.status == 'skipped').length;

    _MemberStatus status;
    if (total == 0) {
      status = _MemberStatus.idle;
    } else if (missed > 0) {
      status = _MemberStatus.warn;
    } else if (taken == total) {
      status = _MemberStatus.ok;
    } else {
      status = _MemberStatus.idle;
    }

    final ringColor = switch (status) {
      _MemberStatus.ok => const Color(0xFF22C55E),
      _MemberStatus.warn => const Color(0xFFEF4444),
      _MemberStatus.idle => AppColors.border,
    };

    final statusText = switch (status) {
      _MemberStatus.ok => '✓ Всі прийнято',
      _MemberStatus.warn => '⚠ Є пропуски',
      _MemberStatus.idle =>
        total > 0 ? '$taken/$total прийнято' : 'Немає ліків на сьогодні',
    };

    final statusColor = switch (status) {
      _MemberStatus.ok => const Color(0xFF22C55E),
      _MemberStatus.warn => const Color(0xFFEF4444),
      _MemberStatus.idle => AppColors.textMuted,
    };

    final emoji = _avatars[member.avatarIndex % _avatars.length];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Member header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                // Avatar with status ring
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(member.name, style: AppTextStyles.labelLg),
                          if (member.role == 'owner') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('я',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(statusText,
                          style: AppTextStyles.bodySm
                              .copyWith(color: statusColor)),
                      if (total > 0)
                        Text(
                          '$taken з $total прийомів',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Remind / OK button
                if (status == _MemberStatus.warn)
                  _RemindBtn(
                    label: 'Нагадати',
                    color: const Color(0xFFEF4444),
                    bg: const Color(0xFFFEF2F2),
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Нагадування для ${member.name} відправлено')),
                    ),
                  )
                else if (status == _MemberStatus.ok)
                  _RemindBtn(
                    label: '✓ Добре',
                    color: const Color(0xFF22C55E),
                    bg: const Color(0xFFF0FDF4),
                    onTap: null,
                  ),
              ],
            ),
          ),

          // ── Medication chips ──
          if (meds.isNotEmpty) ...[
            const Divider(color: AppColors.borderLight, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: meds.map((med) {
                  // Find today's intakes for this med
                  final medIntakes = intakes
                      .where((i) => i.medicationId == med.id)
                      .toList();
                  final medTaken =
                      medIntakes.where((i) => i.status == 'taken').length;
                  final medTotal = medIntakes.length;
                  final medMissed =
                      medIntakes.where((i) => i.status == 'skipped').length;

                  Color dotColor = AppColors.textMuted;
                  if (medTotal > 0 && medTaken == medTotal) {
                    dotColor = AppColors.success;
                  } else if (medMissed > 0) {
                    dotColor = AppColors.danger;
                  } else if (medTaken > 0) {
                    dotColor = AppColors.warning;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          med.name,
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain),
                        ),
                        if (medTotal > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$medTaken/$medTotal',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _MemberStatus { ok, warn, idle }

class _RemindBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  const _RemindBtn({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Add member tile ───────────────────────────────────────────────────────────

class _AddMemberTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddMemberSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
              width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Додати члена сімʼї',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('Батьки, діти, партнер…',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add member bottom sheet ───────────────────────────────────────────────────

void _showAddMemberSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddMemberSheet(),
  );
}

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet();

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  final _nameCtrl = TextEditingController();
  int _avatarIndex = 1;
  bool _saving = false;

  static const _avatars = ['🧑', '👩', '👨', '👧', '👦', '👴', '👵', '🧒'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(membersRepositoryProvider).insert(
          MembersCompanion.insert(
            name: name,
            avatarIndex: Value(_avatarIndex),
            role: const Value('member'),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Додати члена сімʼї', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Вкажіть імʼя та оберіть аватар',
              style: AppTextStyles.bodySm),
          const SizedBox(height: 20),

          // Avatar picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_avatars.length, (i) {
                final sel = i == _avatarIndex;
                return GestureDetector(
                  onTap: () => setState(() => _avatarIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(right: 10),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            sel ? AppColors.primary : AppColors.border,
                        width: sel ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(_avatars[i],
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),

          // Name field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Мама, Тато, Бабуся…',
                hintStyle: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
              ),
              style: AppTextStyles.bodyMd,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _saving ? 'Зберігаємо...' : 'Додати',
                style: AppTextStyles.labelLg.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
