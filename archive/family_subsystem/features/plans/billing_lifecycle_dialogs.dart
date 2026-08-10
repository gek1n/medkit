import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_button.dart';
import 'plans_screen.dart';

/// Модалки грейс-періоду/розпаду (docs/multifamily_billing_plan.md, розділ
/// 4, пункти 1 і 5). Підключені: [main.dart] викликає [showGracePeriodPopup]
/// на `GraceCheckResult.graceStarted`/`graceOngoing`, [showAccessChangedModal]
/// на `disbanded` (лише у ПЛАТЯЩОГО — гості дізнаються реактивно, при своєму
/// наступному синку, без проактивних сповіщень).

/// "Залишилось N днів/хвилин" — показувати при КОЖНОМУ вході в застосунок,
/// поки триває грейс-період. Все працює без обмежень весь цей час. Формат
/// [timeLeft] залежить від того, що зараз [BillingLifecycleService.gracePeriod]
/// — дні для реального 5-денного грейсу, хвилини для тимчасового тестового.
Future<void> showGracePeriodPopup(BuildContext context, {required Duration timeLeft}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/illustrations/elly-thinking-2.png', height: 120),
          const SizedBox(height: AppDimensions.md),
          Text(context.l10n.paymentFailedTitle, style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            timeLeft > Duration.zero
                ? context.l10n.gracePeriodRemainingBody(_formatTimeLeftUk(context, timeLeft))
                : context.l10n.gracePeriodExpiredBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.laterAction)),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PlansScreen()));
          },
          child: Text(context.l10n.updatePaymentAction),
        ),
      ],
    ),
  );
}

String _formatTimeLeftUk(BuildContext context, Duration d) {
  if (d.inDays >= 1) return context.l10n.daysLeftLabel(d.inDays);
  if (d.inHours >= 1) return context.l10n.hoursLeftLabel(d.inHours);
  final minutes = d.inMinutes < 1 ? 1 : d.inMinutes;
  return context.l10n.minutesLeftLabel(minutes);
}

/// "Що змінилось і чому" — показувати ОДИН РАЗ при першому вході після
/// зміни (і в платящого при добровільній зміні тарифу, і в гостя після
/// розриву/заморозки), навіть якщо застосунок уже був відкритий у момент
/// зміни (не лише на холодному старті).
Future<void> showAccessChangedModal(
  BuildContext context, {
  required String reason,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/illustrations/elly-thinking-2.png', height: 120),
          const SizedBox(height: AppDimensions.md),
          Text(context.l10n.accessChangedTitle, style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(reason, textAlign: TextAlign.center, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
          const SizedBox(height: AppDimensions.lg),
          MkButton(
            label: context.l10n.changePlanAction,
            isFullWidth: true,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PlansScreen()));
            },
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.okAction)),
        ],
      ),
    ),
  );
}
