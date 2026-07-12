import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
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
          Text('Не вдалось списати оплату', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            timeLeft > Duration.zero
                ? 'Залишилось ${_formatTimeLeftUk(timeLeft)}, щоб оновити спосіб оплати — доки що все працює без обмежень, і для вас, і для всіх учасників вашої сімейної групи.'
                : 'Оновіть спосіб оплати негайно, інакше сімейна група розірветься.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Пізніше')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PlansScreen()));
          },
          child: const Text('Оновити оплату'),
        ),
      ],
    ),
  );
}

String _formatTimeLeftUk(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} ${_wordUk(d.inDays, 'день', 'дні', 'днів')}';
  if (d.inHours >= 1) return '${d.inHours} ${_wordUk(d.inHours, 'годину', 'години', 'годин')}';
  final minutes = d.inMinutes < 1 ? 1 : d.inMinutes;
  return '$minutes ${_wordUk(minutes, 'хвилину', 'хвилини', 'хвилин')}';
}

String _wordUk(int n, String one, String few, String many) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return few;
  return many;
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
          Text('Доступ змінився', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(reason, textAlign: TextAlign.center, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
          const SizedBox(height: AppDimensions.lg),
          MkButton(
            label: 'Змінити план',
            isFullWidth: true,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PlansScreen()));
            },
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    ),
  );
}
