import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPlan { free, care, family }

class PlanLimits {
  final int maxMembers;
  final int maxHistoryDays; // 0 = unlimited
  final bool voiceCommands;
  final bool aiInsights;

  const PlanLimits({
    required this.maxMembers,
    required this.maxHistoryDays,
    required this.voiceCommands,
    required this.aiInsights,
  });
}

const planLimits = {
  AppPlan.free: PlanLimits(
    maxMembers: 1,
    maxHistoryDays: 7,
    voiceCommands: false,
    aiInsights: false,
  ),
  AppPlan.care: PlanLimits(
    maxMembers: 1,
    maxHistoryDays: 0,
    voiceCommands: true,
    aiInsights: true,
  ),
  AppPlan.family: PlanLimits(
    maxMembers: 10,
    maxHistoryDays: 0,
    voiceCommands: true,
    aiInsights: true,
  ),
};

extension AppPlanExt on AppPlan {
  PlanLimits get limits => planLimits[this]!;

  String get displayName => switch (this) {
        AppPlan.free => 'Безкоштовний',
        AppPlan.care => 'Турбота',
        AppPlan.family => 'Сімʼя',
      };

  String get badge => switch (this) {
        AppPlan.free => '⭐ Безкоштовний план',
        AppPlan.care => '💜 Турбота',
        AppPlan.family => '👑 Сімʼя',
      };

  bool get isPaid => this != AppPlan.free;
}

final planProvider = StateProvider<AppPlan>((_) => AppPlan.free);
