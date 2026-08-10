import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/avatars.dart';
import '../../../data/db/app_database.dart';
import '../../family/peer_view_providers.dart';
import '../providers/today_providers.dart';

class FamilyStatusStrip extends StatelessWidget {
  final List<Member> members;
  final int currentMemberId;
  final WidgetRef ref;

  const FamilyStatusStrip({
    super.key,
    required this.members,
    required this.currentMemberId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Крок 4.3.2 плану: той самий перемикач тепер показує і автономних
    // членів сім'ї (окремий пристрій), не лише локальні профілі — вибір
    // одного скидає інший (activePeerProvider/activeMemberIdProvider
    // взаємовиключні, див. peer_view_providers.dart).
    final peerList = ref.watch(allFamilyPeersProvider).valueOrNull ?? const <FamilyPeer>[];
    final activePeer = ref.watch(activePeerProvider);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length + peerList.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (_, i) {
          if (i < members.length) {
            return _MemberChip(
              member: members[i],
              isCurrent: activePeer == null && members[i].id == currentMemberId,
              ref: ref,
              onTap: () {
                ref.read(activePeerProvider.notifier).state = null;
                ref.read(activeMemberIdProvider.notifier).state = members[i].id;
              },
            );
          }
          final peer = peerList[i - members.length];
          return _PeerChip(
            peer: peer,
            isCurrent: activePeer?.personUuid == peer.personUuid,
            ref: ref,
            onTap: () {
              ref.read(activeMemberIdProvider.notifier).state = null;
              ref.read(activePeerProvider.notifier).state = PeerSubject(
                personUuid: peer.personUuid,
                channelId: peer.channelId,
                name: peer.name,
                avatarIndex: peer.avatarIndex,
              );
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
    return _chip(progress.done, progress.total);
  }

  Widget _chip(int taken, int total) {
    // wrapped in GestureDetector below
    final allDone = total > 0 && taken == total;
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
              AvatarImage(index: member.avatarIndex, size: 40),
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
            member.name,
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            total > 0 ? '$taken/$total' : '—',
            style: AppTextStyles.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
    );
  }
}

class _PeerChip extends StatelessWidget {
  final FamilyPeer peer;
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
    final allDone = progress.total > 0 && progress.done == progress.total;
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
                AvatarImage(index: peer.avatarIndex, size: 40),
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
              peer.name,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              progress.total > 0 ? '${progress.done}/${progress.total}' : '—',
              style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
