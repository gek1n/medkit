import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/avatars.dart';
import '../../../data/db/app_database.dart';
import '../../family/peer_view_providers.dart';
import '../providers/today_providers.dart';

// Горизонтальна стрічка "Сім'я" під hero-блоком на Сьогодні — той самий
// перемикач "хто зараз обраний", що й MemberSwitcherPill (Розклад/Медкартка),
// але у вигляді картки з прогресом, а не пігулки. Відновлено з
// archive/family_subsystem/features/today/widgets/family_status_strip.dart
// (Крок 10 карантинував увесь функціонал сім'ї разом із цим блоком; Крок 11
// повернув сім'ю через сервер, але цей конкретний блок на Today так і не
// перевідновили — замінили MemberSwitcherPill-пігулкою у шапці, залишивши
// Today без свого "1. Сім'я" розділу).
class FamilyStatusStrip extends StatelessWidget {
  final List<Member> members;
  final List<PeerSubject> peers;
  final int currentMemberId;
  final WidgetRef ref;

  const FamilyStatusStrip({
    super.key,
    required this.members,
    required this.peers,
    required this.currentMemberId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final activePeer = ref.watch(activePeerProvider);
    final owner = members.where((m) => m.role == 'owner').firstOrNull;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length + peers.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (_, i) {
          if (i < members.length) {
            final m = members[i];
            return _MemberChip(
              member: m,
              isCurrent: activePeer == null && m.id == currentMemberId,
              ref: ref,
              onTap: () {
                ref.read(activePeerProvider.notifier).state = null;
                ref.read(activeMemberIdProvider.notifier).state =
                    owner != null && m.id == owner.id ? null : m.id;
              },
            );
          }
          final peer = peers[i - members.length];
          return _PeerChip(
            peer: peer,
            isCurrent: activePeer == peer,
            ref: ref,
            onTap: () {
              ref.read(activeMemberIdProvider.notifier).state = null;
              ref.read(activePeerProvider.notifier).state = peer;
            },
          );
        },
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final Member member;
  final bool isCurrent;
  final WidgetRef ref;
  final VoidCallback onTap;

  const _MemberChip({
    required this.member,
    required this.isCurrent,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(familyMemberTodayProgressProvider(member.id));
    return _StatusChip(
      avatarIndex: member.avatarIndex,
      name: member.name,
      done: progress.done,
      total: progress.total,
      isCurrent: isCurrent,
      onTap: onTap,
    );
  }
}

class _PeerChip extends StatelessWidget {
  final PeerSubject peer;
  final bool isCurrent;
  final WidgetRef ref;
  final VoidCallback onTap;

  const _PeerChip({
    required this.peer,
    required this.isCurrent,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(peerTodayProgressProvider(peer.personUuid));
    return _StatusChip(
      avatarIndex: peer.avatarIndex,
      name: peer.name,
      done: progress.done,
      total: progress.total,
      isCurrent: isCurrent,
      onTap: onTap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final int avatarIndex;
  final String name;
  final int done;
  final int total;
  final bool isCurrent;
  final VoidCallback onTap;

  const _StatusChip({
    required this.avatarIndex,
    required this.name,
    required this.done,
    required this.total,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && done == total;
    final color = allDone ? AppColors.success : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.sm, horizontal: AppDimensions.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: allDone
                ? AppColors.success.withValues(alpha: 0.4)
                : isCurrent
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
            width: isCurrent ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                AvatarImage(index: avatarIndex, size: 40),
                if (allDone)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 10),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              total > 0 ? '$done/$total' : '—',
              style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
