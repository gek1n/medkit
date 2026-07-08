import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

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
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroHeader(
              isYearly: _isYearly,
              onToggle: (v) => setState(() => _isYearly = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.xl,
                AppDimensions.screenPadding,
                0,
              ),
              child: Column(
                children: [
                  _FreeCard(
                    isCurrent: currentPlan == AppPlan.free,
                    onSelect: () => ref.read(planProvider.notifier).state = AppPlan.free,
                  ),
                  const SizedBox(height: 10),
                  _CareCard(
                    isYearly: _isYearly,
                    isCurrent: currentPlan == AppPlan.care,
                    onSelect: () => ref.read(planProvider.notifier).state = AppPlan.care,
                  ),
                  const SizedBox(height: 10),
                  _FamilyCard(
                    isYearly: _isYearly,
                    isCurrent: currentPlan == AppPlan.family,
                    onSelect: () => ref.read(planProvider.notifier).state = AppPlan.family,
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
    );
  }
}

// ────────────────────────────── hero header ──────────────────────────────

class _HeroHeader extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onToggle;

  const _HeroHeader(
      {required this.isYearly, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4C9A6A), Color(0xFF3B82F6)],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 20,
            20,
            32,
          ),
          child: Column(
            children: [
              Text(
                'Вибери план',
                style: AppTextStyles.bodySm
                    .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 6),
              Text(
                "Турбота про здоров’я\nвсієї сім’ї",
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleChip(
                      label: 'Місяць',
                      selected: !isYearly,
                      onTap: () => onToggle(false),
                    ),
                    _ToggleChip(
                      label: 'Рік −20%',
                      selected: isYearly,
                      onTap: () => onToggle(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
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
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w600,
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────── feature row ──────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String text;
  final Color checkColor;
  final bool bold;

  const _FeatureRow({
    required this.text,
    required this.checkColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✓ ',
              style: TextStyle(
                  color: checkColor, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                color: const Color(0xFF374151),
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRowDark extends StatelessWidget {
  final String text;
  final Color checkColor;
  final bool bold;

  const _FeatureRowDark({
    required this.text,
    required this.checkColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✓ ',
              style: TextStyle(
                  color: checkColor, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── free card ──────────────────────────────

class _FreeCard extends StatelessWidget {
  final bool isCurrent;
  final VoidCallback onSelect;
  const _FreeCard({required this.isCurrent, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Безкоштовно', style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text('Назавжди',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSub)),
                  ],
                ),
              ),
              Text('\$0', style: AppTextStyles.h1.copyWith(fontSize: 26)),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const _FeatureRow(text: '1 профіль', checkColor: AppColors.success),
          const _FeatureRow(text: 'Необмежено ліків', checkColor: AppColors.success),
          const _FeatureRow(text: 'Push та Telegram сповіщення', checkColor: AppColors.success),
          const _FeatureRow(text: 'Активність та самопочуття (7 днів)', checkColor: AppColors.success),
          const _FeatureRow(text: '3 скани рецептів', checkColor: AppColors.success),
          const SizedBox(height: AppDimensions.md),
          GestureDetector(
            onTap: isCurrent ? null : onSelect,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                isCurrent ? '✓ Поточний план' : 'Перейти на Безкоштовний',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMd.copyWith(
                  color: isCurrent ? AppColors.primary : AppColors.textSub,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── care card ──────────────────────────────

class _CareCard extends StatelessWidget {
  final bool isYearly;
  final bool isCurrent;
  final VoidCallback onSelect;
  const _CareCard({required this.isYearly, required this.isCurrent, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? '\$2.4' : '\$3';
    final sub = isYearly ? 'на місяць (оплата щорічно)' : 'в місяць';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg, 20, AppDimensions.lg, AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLg),
            border:
                Border.all(color: AppColors.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4FD8).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Турбота',
                            style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        Text('Для себе, максимум користі',
                            style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.textSub)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price,
                          style: AppTextStyles.h1.copyWith(
                              fontSize: 26,
                              color: AppColors.primary)),
                      Text(sub,
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSub)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              const _FeatureRow(
                  text: 'Всe з безкоштовного',
                  checkColor: AppColors.success),
              _FeatureRow(
                  text: '10 сканів рецептів на місяць',
                  checkColor: AppColors.primary,
                  bold: true),
              _FeatureRow(
                  text: 'AI-інсайти та кореляції',
                  checkColor: AppColors.primary),
              _FeatureRow(
                  text: 'PDF-звіт для лікаря',
                  checkColor: AppColors.primary),
              const SizedBox(height: AppDimensions.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrent ? null : onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? AppColors.primaryLight : AppColors.primary,
                    foregroundColor: isCurrent ? AppColors.primary : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  child: Text(
                    isCurrent ? '✓ Поточний план' : 'Спробувати 7 днів безкоштовно',
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -11,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusFull),
              ),
              child: Text(
                'ПОПУЛЯРНИЙ',
                style: AppTextStyles.labelSm
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────── family card ──────────────────────────────

class _FamilyCard extends StatelessWidget {
  final bool isYearly;
  final bool isCurrent;
  final VoidCallback onSelect;
  const _FamilyCard({required this.isYearly, required this.isCurrent, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? '\$8' : '\$10';
    final sub = isYearly ? 'на місяць (оплата щорічно)' : 'в місяць';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сімʼя',
                        style: AppTextStyles.h3
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('До 10 профілів',
                        style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white
                                .withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price,
                      style: AppTextStyles.h1.copyWith(
                          fontSize: 26, color: Colors.white)),
                  Text(sub,
                      style: AppTextStyles.bodySm.copyWith(
                          color:
                              Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const _FeatureRowDark(
              text: 'Всe з «Турботи»',
              checkColor: AppColors.success),
          _FeatureRowDark(
              text: '50 сканів на всю сімʼю',
              checkColor: const Color(0xFFFBBF24),
              bold: true),
          const _FeatureRowDark(
              text: 'Сімейний дашборд',
              checkColor: Color(0xFFFBBF24)),
          const _FeatureRowDark(
              text: 'AI-інсайти по всій сімʼї',
              checkColor: Color(0xFFFBBF24)),
          const _FeatureRowDark(
              text: 'Пріоритетна підтримка',
              checkColor: Color(0xFFFBBF24)),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent
                    ? const Color(0xFFFBBF24).withValues(alpha: 0.3)
                    : const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                isCurrent ? '✓ Поточний план' : "Обрати «Сімʼя»",
                style: AppTextStyles.bodyMd
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
