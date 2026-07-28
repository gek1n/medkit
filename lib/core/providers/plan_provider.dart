import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/l10n_ext.dart';

enum AppPlan { free, plus, family }

class PlanLimits {
  /// 0 = необмежено.
  final int maxLocalMembers;
  /// 0 = автономні профілі недоступні на цьому плані.
  final int maxAutonomousMembers;
  final bool serverSync;
  final double price;
  /// 0 = необмежено. Рутинні справи (Activities, type=='routine') на профіль.
  final int maxRoutineTasks;
  /// 0 = необмежено. Розділи Простору (MedcardSections) на профіль.
  final int maxMedcardSections;

  const PlanLimits({
    required this.maxLocalMembers,
    required this.maxAutonomousMembers,
    required this.serverSync,
    required this.price,
    required this.maxRoutineTasks,
    required this.maxMedcardSections,
  });
}

const planLimits = {
  AppPlan.free: PlanLimits(
    maxLocalMembers: 1,
    maxAutonomousMembers: 0,
    serverSync: false,
    price: 0,
    maxRoutineTasks: 1,
    maxMedcardSections: 3,
  ),
  AppPlan.plus: PlanLimits(
    maxLocalMembers: 0,
    maxAutonomousMembers: 0,
    serverSync: true,
    price: 2.99,
    maxRoutineTasks: 0,
    maxMedcardSections: 0,
  ),
  AppPlan.family: PlanLimits(
    maxLocalMembers: 0,
    maxAutonomousMembers: 8,
    serverSync: true,
    price: 5.99,
    maxRoutineTasks: 0,
    maxMedcardSections: 0,
  ),
};

extension AppPlanExt on AppPlan {
  PlanLimits get limits => planLimits[this]!;

  String displayName(BuildContext context) => switch (this) {
        AppPlan.free => context.l10n.planFreeShortLabel,
        AppPlan.plus => context.l10n.planPlusLabel,
        AppPlan.family => context.l10n.planFamilyLabel,
      };

  bool get isPaid => this != AppPlan.free;
}

final planProvider = StateProvider<AppPlan>((_) => AppPlan.free);
