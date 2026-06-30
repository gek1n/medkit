import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/family_member.dart';

class FamilyStatusStrip extends StatelessWidget {
  final List<FamilyMember> members;

  const FamilyStatusStrip({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (context2, index2) =>
            const SizedBox(width: AppDimensions.md),
        itemBuilder: (_, i) => _MemberChip(member: members[i]),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final FamilyMember member;

  const _MemberChip({required this.member});

  @override
  Widget build(BuildContext context) {
    final pct = member.adherence;
    final color = pct >= 1
        ? AppColors.success
        : pct > 0
            ? AppColors.warning
            : AppColors.textMuted;

    return Container(
      width: 72,
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Text(member.avatar,
                  style: const TextStyle(fontSize: 26)),
              if (member.adherence >= 1)
                const Text('✅',
                    style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            member.name,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${member.takenToday}/${member.totalToday}',
            style:
                AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
