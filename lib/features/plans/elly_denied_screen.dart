import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_button.dart';
import 'plans_screen.dart';

/// Показується замість форми додавання, коли в акаунті вже більше
/// профілів (локальних чи автономних), ніж дозволяє поточний план —
/// напр. після завершення платної підписки, або при спробі приєднати ще
/// одного автономного учасника понад ліміт. Перегляд лишається
/// доступним, редагування/додавання — ні, поки не оновити план.
class EllyDeniedScreen extends StatelessWidget {
  final String? title;
  final String? subtitle;
  const EllyDeniedScreen({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? context.l10n.tooManyProfilesForPlanTitle;
    final effectiveSubtitle = subtitle ?? context.l10n.upgradeToEditSubtitle;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEEE2), AppColors.bg],
            stops: [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.md,
                  AppDimensions.screenPadding,
                  0,
                ),
                child: Row(
                  children: [
                    MkBackButton(onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/illustrations/elly-denied.png',
                            height: 220),
                        const SizedBox(height: AppDimensions.lg),
                        Text(effectiveTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h2),
                        const SizedBox(height: 8),
                        Text(
                          effectiveSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  0,
                  AppDimensions.screenPadding,
                  AppDimensions.lg,
                ),
                child: MkButton(
                  label: context.l10n.viewPlansAction,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PlansScreen()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
