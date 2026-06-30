enum AppTier { free, pro }

abstract final class AppConfig {
  // Переключить на AppTier.pro для разблокировки всех функций
  static const AppTier tier = AppTier.free;

  static const int freeMedsLimit = 3;
  static const int freeFamilyLimit = 1;

  // Feature gates
  static bool get isPro => tier == AppTier.pro;
  static bool get canAddUnlimitedMeds => isPro;
  static bool get canAddFamilyMembers => isPro;
  static bool get canSetReminders => isPro;
  static bool get canExportData => isPro;
  static bool get canViewAnalytics => isPro;
}
