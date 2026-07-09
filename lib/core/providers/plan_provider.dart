import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPlan { free, plus, family }

class PlanLimits {
  /// 0 = необмежено.
  final int maxLocalMembers;
  /// 0 = автономні профілі недоступні на цьому плані.
  final int maxAutonomousMembers;
  /// null = необмежено.
  final int? photoScanLimit;
  /// null = необмежено.
  final int? voiceCommandLimit;
  final bool serverSync;
  final double price;

  const PlanLimits({
    required this.maxLocalMembers,
    required this.maxAutonomousMembers,
    required this.photoScanLimit,
    required this.voiceCommandLimit,
    required this.serverSync,
    required this.price,
  });
}

const planLimits = {
  AppPlan.free: PlanLimits(
    maxLocalMembers: 1,
    maxAutonomousMembers: 0,
    photoScanLimit: 3,
    voiceCommandLimit: 5,
    serverSync: false,
    price: 0,
  ),
  AppPlan.plus: PlanLimits(
    maxLocalMembers: 0,
    maxAutonomousMembers: 0,
    photoScanLimit: null,
    voiceCommandLimit: null,
    serverSync: true,
    price: 2.99,
  ),
  AppPlan.family: PlanLimits(
    maxLocalMembers: 0,
    maxAutonomousMembers: 8,
    photoScanLimit: null,
    voiceCommandLimit: null,
    serverSync: true,
    price: 5.99,
  ),
};

extension AppPlanExt on AppPlan {
  PlanLimits get limits => planLimits[this]!;

  String get displayName => switch (this) {
        AppPlan.free => 'Безкоштовний',
        AppPlan.plus => 'Elly Plus',
        AppPlan.family => 'Elly Family',
      };

  bool get isPaid => this != AppPlan.free;
}

final planProvider = StateProvider<AppPlan>((_) => AppPlan.free);
