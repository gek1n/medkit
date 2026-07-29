import 'package:flutter/material.dart';
import '../../core/utils/l10n_ext.dart';

/// Мапа старих значень поля "форма" (тепер вільний текст, [Medication.form])
/// на локалізовані підписи — потрібна лише для показу людяної назви
/// збережених раніше записів (Архів інвентарю), нові записи зберігають
/// довільний текст напряму.
Map<String, String> medFormLabels(BuildContext context) {
  final l10n = context.l10n;
  return {
    'tablet': l10n.medFormTablet,
    'capsule': l10n.medFormCapsule,
    'suppository': l10n.medFormSuppository,
    'vial': l10n.medFormVial,
    'syrup': l10n.medFormSyrup,
    'drops': l10n.medFormDrops,
    'cream': l10n.medFormCream,
    'inhaler': l10n.medFormInhaler,
    'injection': l10n.medFormInjection,
  };
}
