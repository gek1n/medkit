import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/avatars.dart';
import '../../../data/db/app_database.dart';
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
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (_, i) => _MemberChip(
          member: members[i],
          isCurrent: members[i].id == currentMemberId,
          ref: ref,
          onTap: () => ref.read(activeMemberIdProvider.notifier).state =
              members[i].id,
        ),
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
    final intakesAsync = ref.watch(todayIntakesProvider(member.id));

    return intakesAsync.when(
      loading: () => _chip(0, 0),
      error: (_, _) => _chip(0, 0),
      data: (intakes) {
        final taken = intakes.where((i) => i.status == 'taken').length;
        final total = intakes.length;
        return _chip(taken, total);
      },
    );
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
