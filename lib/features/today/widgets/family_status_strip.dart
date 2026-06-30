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
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
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
    final allDone = member.totalToday > 0 && member.takenToday == member.totalToday;
    final color = allDone ? AppColors.success : AppColors.primary;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm, horizontal: AppDimensions.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: allDone ? AppColors.success.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(member.avatar, style: const TextStyle(fontSize: 20))),
              ),
              if (allDone)
                Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(member.name, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${member.takenToday}/${member.totalToday}', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
