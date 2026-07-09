import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_back_button.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _isYearly = false;

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
                          'Тарифи',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLg
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Text('Обери план', style: AppTextStyles.h2),
                const SizedBox(height: 6),
                Text(
                  "Турбота про здоров'я всієї сім'ї",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                ),
                const SizedBox(height: AppDimensions.lg),
                _PeriodToggle(
                  isYearly: _isYearly,
                  onChanged: (v) => setState(() => _isYearly = v),
                ),
                Padding(
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
                        period: 'назавжди',
                        illustration: 'assets/illustrations/elly-tablet.png',
                        features: const [
                          'Всі розділи без обмежень',
                          'Необмежено ліків і медкарток',
                          '3 сканування фото рецепта',
                          '5 голосових команд',
                          'Локально + копія в Google Drive/iCloud',
                        ],
                        isCurrent: currentPlan == AppPlan.free,
                        selectLabel: 'Обрати Безкоштовний',
                        onSelect: () =>
                            ref.read(planProvider.notifier).state = AppPlan.free,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _PlanCard(
                        title: 'Elly Plus',
                        isPaid: true,
                        price: _isYearly ? '\$2.39' : '\$2.99',
                        period: _isYearly ? 'на місяць (рік)' : 'щомісяця',
                        illustration: 'assets/illustrations/elly-hospital.png',
                        features: const [
                          'Все з безкоштовного',
                          'Необмежені сканування фото',
                          'Необмежені голосові команди',
                          'Синхронізація з сервером (зашифровано)',
                          'Необмежена кількість локальних профілів',
                        ],
                        isCurrent: currentPlan == AppPlan.plus,
                        selectLabel: 'Обрати Plus',
                        onSelect: () =>
                            ref.read(planProvider.notifier).state = AppPlan.plus,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _PlanCard(
                        title: 'Elly Family',
                        isPaid: true,
                        price: _isYearly ? '\$4.79' : '\$5.99',
                        period: _isYearly ? 'на місяць (рік)' : 'щомісяця',
                        illustration: 'assets/illustrations/family.png',
                        features: const [
                          'Все з Elly Plus',
                          'Автономні профілі — до 8 осіб',
                          'Кожен керує своїм профілем сам',
                        ],
                        isCurrent: currentPlan == AppPlan.family,
                        selectLabel: 'Обрати Family',
                        onSelect: () =>
                            ref.read(planProvider.notifier).state = AppPlan.family,
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      Text(
                        'Скасувати можна будь-коли\nОплата через App Store · Google Play',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 48),
                    ],
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
          _ToggleChip(label: 'Місяць', selected: !isYearly, onTap: () => onChanged(false)),
          _ToggleChip(label: 'Рік −20%', selected: isYearly, onTap: () => onChanged(true)),
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
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
                      child: Text(title,
                          style: AppTextStyles.h3, overflow: TextOverflow.ellipsis),
                    ),
                    if (isPaid) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Center(
                          child: Icon(Icons.workspace_premium_rounded,
                              size: 15, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price,
                      style:
                          AppTextStyles.h2.copyWith(color: AppColors.textMain)),
                  Text(period,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textMuted)),
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
                  children: [
                    for (final f in features) _FeatureLine(text: f),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: isCurrent ? null : onSelect,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.bgPage : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Text(
                  isCurrent ? 'Поточний' : selectLabel,
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
