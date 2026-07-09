import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/services/privacy_consent_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../legal/privacy_policy_screen.dart';

/// Останній крок будь-якого з трьох онбординг-флоу (створення акаунта,
/// підключення до сім'ї, відновлення акаунта) — обов'язкова згода з
/// Політикою конфіденційності. Без чекбокса кнопка неактивна: на відміну
/// від `AiConsentService` (згода на окрему хмарну функцію, можна
/// відмовитись і користуватись рештою застосунку), ця згода — умова
/// використання застосунку взагалі.
class PrivacyGateStep extends StatefulWidget {
  final bool isBusy;
  final bool hasMedications;
  final Future<void> Function() onConfirm;

  const PrivacyGateStep({
    super.key,
    required this.onConfirm,
    this.isBusy = false,
    this.hasMedications = false,
  });

  @override
  State<PrivacyGateStep> createState() => _PrivacyGateStepState();
}

class _PrivacyGateStepState extends State<PrivacyGateStep> {
  bool _checked = false;
  bool _submitting = false;
  late final TapGestureRecognizer _policyLinkRecognizer;

  bool get _busy => widget.isBusy || _submitting;

  @override
  void initState() {
    super.initState();
    _policyLinkRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          );
  }

  @override
  void dispose() {
    _policyLinkRecognizer.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_checked || _busy) return;
    setState(() => _submitting = true);
    await PrivacyConsentService.recordAcceptance();
    await widget.onConfirm();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Image.asset('assets/illustrations/done-hero.png', height: 180),
          const SizedBox(height: 16),
          Text('Готово!', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Все налаштовано. Відкрийте дашборд і почніть стежити за здоров\'ям.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hasMedications
                            ? 'Перше нагадування — сьогодні'
                            : 'Нагадувань поки немає',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        widget.hasMedications
                            ? 'Нагадування прийде за розкладом, який ви щойно додали'
                            : 'Налаштуйте ліки щоб активувати нагадування',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _checked = !_checked),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _checked ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _checked ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: _checked
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain),
                      children: [
                        const TextSpan(text: 'Я ознайомлений(-а) і згоден(-а) з '),
                        TextSpan(
                          text: 'Політикою конфіденційності',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _policyLinkRecognizer,
                        ),
                        const TextSpan(text: ' застосунку'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checked ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                elevation: 0,
              ),
              child: Text(
                'Відкрити дашборд →',
                style: AppTextStyles.labelLg.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Обгортка `PrivacyGateStep` у власний Scaffold — для флоу "Підключення до
/// сім'ї" й "Відновлення акаунта", які пушаться окремим route поверх
/// онбордингу (а не є кроком у його PageView). Назад повернутись не можна:
/// дані вже застосовано (профіль створено/дані відновлено), як і в інших
/// фінальних екранах цих флоу.
class PrivacyGateScreen extends StatefulWidget {
  final bool hasMedications;

  const PrivacyGateScreen({super.key, this.hasMedications = true});

  @override
  State<PrivacyGateScreen> createState() => _PrivacyGateScreenState();
}

class _PrivacyGateScreenState extends State<PrivacyGateScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: PrivacyGateStep(
            hasMedications: widget.hasMedications,
            onConfirm: () async {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      ),
    );
  }
}
