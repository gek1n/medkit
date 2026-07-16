import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Показує recovery key користувачу з поясненням і обов'язковим explicit
/// підтвердженням "Я зберіг(ла) код" — ЄДИНИЙ спосіб отримати доступ до
/// синхронізованих даних з іншого пристрою, сервер сам ключ ніколи не бачить.
/// Використовується і при ручній активації синку (SyncSettingsScreen), і
/// одразу після покупки Plus/Family, якщо вона сама auto-створила
/// sync-акаунт (SubscriptionService, docs/multifamily_billing_plan.md,
/// розділ 4 — НІКОЛИ тихо).
Future<bool?> showRecoveryKeyDialog(BuildContext context, String recoveryKey) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.recoveryKeyDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.recoveryKeyDialogBody),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: recoveryKey));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.copiedSnackbar)),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLighter, width: 2),
              ),
              child: Text(
                recoveryKey,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(color: AppColors.primary, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.actionCancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.recoveryKeySavedConfirmAction),
        ),
      ],
    ),
  );
}
