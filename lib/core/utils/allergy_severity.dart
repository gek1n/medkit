import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'l10n_ext.dart';

/// Тяжкість алергічної реакції — контрольований словник (не вільний текст),
/// щоб можна було надійно сортувати/виділяти тяжкі алергії візуально.
/// Це саме та інформація, яку варто побачити з першого погляду при виборі
/// ліків чи на прийомі в лікаря.
enum AllergySeverity {
  mild,
  moderate,
  severe;

  static AllergySeverity fromDb(String value) => AllergySeverity.values.firstWhere(
        (s) => s.name == value,
        orElse: () => AllergySeverity.mild,
      );

  String label(BuildContext context) => switch (this) {
        AllergySeverity.mild => context.l10n.severityMild,
        AllergySeverity.moderate => context.l10n.severityModerate,
        AllergySeverity.severe => context.l10n.severitySevere,
      };

  Color get color => switch (this) {
        AllergySeverity.mild => AppColors.textSub,
        AllergySeverity.moderate => AppColors.warning,
        AllergySeverity.severe => AppColors.danger,
      };

  Color get bgColor => switch (this) {
        AllergySeverity.mild => AppColors.border,
        AllergySeverity.moderate => AppColors.warningLight,
        AllergySeverity.severe => AppColors.dangerLight,
      };

  // mild=0 … severe=2 — для сортування "найтяжче зверху"
  int get weight => index;
}
