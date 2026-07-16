import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/providers/real_plan_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/marketing_topics_service.dart';
import '../../core/services/review_prompt_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/recovery_key_dialog.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_use_screen.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _isYearly = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // "Покинутий кошик" — відкрила екран тарифів, але поки не купила.
    // Прибирається одразу після успішної покупки, [_selectPaid].
    MarketingTopicsService.markViewedPlansNoPurchase();
  }

  /// Свідома зміна тарифу ГЕТЬ від Family (не невдала оплата — окремий
  /// сценарій грейс-періоду, `BillingLifecycleService`) — попереджаємо ДО
  /// зміни, бо зв'язки з родиною розірвуться миттєво, без грейс-періоду
  /// (він уже попереджений тут-і-зараз). Повертає true, якщо можна
  /// продовжувати зміну плану (попередження не потрібне або підтверджене).
  ///
  /// Працює вже зараз поверх декоративного `planProvider` — навмисно: так
  /// можна протестувати весь грейс/розпад-флоу, не чекаючи підключення
  /// реальної покупки (docs/multifamily_billing_plan.md, розділ 6).
  Future<bool> _confirmDowngradeFromFamily(AppPlan currentPlan) async {
    if (currentPlan != AppPlan.family) return true;
    final db = ref.read(databaseProvider);
    final owner = await MembersRepository(db).getOwner();
    final ownerFamilyId = owner?.familyId;
    if (ownerFamilyId == null) return true;
    final peers = await FamilyPeersRepository(db).allPeers();
    final hasInvitedAnyone = peers.any(
      (p) => p.familyId == ownerFamilyId && !p.invitedMe,
    );
    if (!hasInvitedAnyone) return true;

    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/illustrations/elly-thinking-2.png',
              height: 120,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              context.l10n.familyTiesBrokenTitle,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.familyTiesBrokenBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.breakAndChangePlanAction),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await FamilyPeerSyncService(db).leaveGroup(ownerFamilyId);
    return true;
  }

  /// Тестовий режим біллінгу — реальний sync-акаунт + реальний сервер (інші
  /// пристрої на тому ж акаунті побачать зміну), але БЕЗ реального
  /// in_app_purchase/App Store/Google Play (docs/multifamily_billing_plan.md,
  /// "Тестовий режим біллінгу"). Кнопки лишаються на цьому шляху, поки
  /// користувач явно не попросить фінальне переключення на [SubscriptionService.buy].
  Future<void> _selectPaid(AppPlan plan, AppPlan currentPlan) async {
    if (_busy) return;
    if (!await _confirmDowngradeFromFamily(currentPlan)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final outcome = await SubscriptionService.buyTest(
        plan,
        yearly: _isYearly,
      );
      ref.read(planProvider.notifier).state = plan;
      ref.invalidate(realPlanProvider);
      unawaited(MarketingTopicsService.clearPurchaseIntentTopics());
      unawaited(ReviewPromptService.recordPurchase(plan));
      if (!mounted) return;
      if (outcome.newRecoveryKeyDisplay != null) {
        await showRecoveryKeyDialog(context, outcome.newRecoveryKeyDisplay!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.planActivatedTestSnackbar(plan.displayName(context)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.actionFailedError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectFree(AppPlan currentPlan) async {
    if (_busy) return;
    if (!await _confirmDowngradeFromFamily(currentPlan)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await SubscriptionService.cancelTest();
      ref.read(planProvider.notifier).state = AppPlan.free;
      ref.invalidate(realPlanProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.actionFailedError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = ref.watch(planProvider);

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
          child: SingleChildScrollView(
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
                      Expanded(
                        child: Text(
                          context.l10n.plansLabel,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Text(context.l10n.choosePlanTitle, style: AppTextStyles.h2),
                const SizedBox(height: 6),
                Text(
                  context.l10n.choosePlanSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                _PeriodToggle(
                  isYearly: _isYearly,
                  onChanged: (v) => setState(() => _isYearly = v),
                ),
                if (_busy)
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    minHeight: 2,
                  ),
                AbsorbPointer(
                  absorbing: _busy,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _busy ? 0.5 : 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding,
                        AppDimensions.lg,
                        AppDimensions.screenPadding,
                        0,
                      ),
                      child: Column(
                        children: [
                          _PlanCard(
                            title: 'Elly',
                            isPaid: false,
                            price: '\$0',
                            period: context.l10n.planForeverPeriod,
                            illustration:
                                'assets/illustrations/elly-tablet.png',
                            features: [
                              context.l10n.freeFeatureAllSections,
                              context.l10n.freeFeatureUnlimitedMeds,
                              context.l10n.freeFeatureScanLimit,
                              context.l10n.freeFeatureVoiceLimit,
                              context.l10n.freeFeatureLocalBackup,
                            ],
                            isCurrent: currentPlan == AppPlan.free,
                            selectLabel: context.l10n.selectFreeAction,
                            onSelect: () => _selectFree(currentPlan),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          _PlanCard(
                            title: 'Elly Plus',
                            isPaid: true,
                            price: _isYearly ? '\$2.39' : '\$2.99',
                            period: _isYearly
                                ? context.l10n.planPerMonthYearlyPeriod
                                : context.l10n.planPerMonthPeriod,
                            illustration:
                                'assets/illustrations/elly-hospital.png',
                            features: [
                              context.l10n.plusFeatureAllFree,
                              context.l10n.plusFeatureUnlimitedScans,
                              context.l10n.plusFeatureUnlimitedVoice,
                              context.l10n.plusFeatureServerSync,
                              context.l10n.plusFeatureUnlimitedProfiles,
                            ],
                            isCurrent: currentPlan == AppPlan.plus,
                            selectLabel: context.l10n.selectPlusAction,
                            onSelect: () =>
                                _selectPaid(AppPlan.plus, currentPlan),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          _PlanCard(
                            title: 'Elly Family',
                            isPaid: true,
                            price: _isYearly ? '\$4.79' : '\$5.99',
                            period: _isYearly
                                ? context.l10n.planPerMonthYearlyPeriod
                                : context.l10n.planPerMonthPeriod,
                            illustration: 'assets/illustrations/family.png',
                            features: [
                              context.l10n.familyFeatureAllPlus,
                              context.l10n.familyFeatureAutonomousProfiles,
                              context.l10n.familyFeatureSelfManaged,
                            ],
                            isCurrent: currentPlan == AppPlan.family,
                            selectLabel: context.l10n.selectFamilyAction,
                            onSelect: () =>
                                _selectPaid(AppPlan.family, currentPlan),
                            comingSoon: true,
                          ),
                          const SizedBox(height: AppDimensions.xl),
                          Text(
                            context.l10n.billingTermsDisclaimer,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _LegalLink(
                                label: context.l10n.privacyPolicyLinkLabel,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyScreen(),
                                  ),
                                ),
                              ),
                              Text(
                                '  ·  ',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              _LegalLink(
                                label: context.l10n.termsOfUseLinkLabel,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsOfUseScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────── period toggle ──────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onChanged;
  const _PeriodToggle({required this.isYearly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: context.l10n.monthToggleLabel,
            selected: !isYearly,
            onTap: () => onChanged(false),
          ),
          _ToggleChip(
            label: context.l10n.yearToggleDiscountLabel,
            selected: isYearly,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────── plan card ──────────────────────────────

class _PlanCard extends StatelessWidget {
  final String title;
  final bool isPaid;
  final String price;
  final String period;
  final String illustration;
  final List<String> features;
  final bool isCurrent;
  final String selectLabel;
  final VoidCallback onSelect;
  final bool comingSoon;

  const _PlanCard({
    required this.title,
    required this.isPaid,
    required this.price,
    required this.period,
    required this.illustration,
    required this.features,
    required this.isCurrent,
    required this.selectLabel,
    required this.onSelect,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: comingSoon ? 0.5 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: isCurrent ? AppColors.primary : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppTextStyles.h3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPaid) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: AppTextStyles.h2.copyWith(color: AppColors.textMain),
                        ),
                        Text(
                          period,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(illustration, height: 108),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final f in features) _FeatureLine(text: f)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: (isCurrent || comingSoon) ? null : onSelect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.bgPage : AppColors.primary,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        isCurrent ? context.l10n.currentPlanLabel : selectLabel,
                        style: AppTextStyles.labelMd.copyWith(
                          color: isCurrent ? AppColors.textMuted : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (comingSoon)
          Positioned(
            top: AppDimensions.lg,
            right: AppDimensions.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                context.l10n.comingSoon,
                style: AppTextStyles.labelSm.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;
  const _FeatureLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}
