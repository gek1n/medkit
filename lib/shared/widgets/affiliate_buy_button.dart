import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/affiliate_config_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Кнопка "Купити" на партнерське посилання (affiliate) — рендерить сама
/// себе, лише коли для країни користувача й розділу [section] у
/// [AffiliateConfigService] є посилання; інакше — нічого (порожній
/// SizedBox), тож викликачу не треба окремо перевіряти видимість.
///
/// Позначку "Реклама" показуємо завжди, коли кнопка видима — незалежно від
/// того, чи це варіант поруч зі стеженням за залишком, чи самостійний блок
/// без нього: це оплачене партнерство в обох випадках, а не наша власна
/// пропозиція купити щось конкретне.
class AffiliateBuyButton extends StatelessWidget {
  final AffiliateSection section;
  const AffiliateBuyButton({super.key, required this.section});

  Future<void> _open(String link) =>
      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AffiliateConfigService.revision,
      builder: (context, _, _) {
        final link = AffiliateConfigService.linkFor(section);
        if (link == null) return const SizedBox.shrink();
        return _buildButton(context, link);
      },
    );
  }

  Widget _buildButton(BuildContext context, String link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _open(link),
            icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
            label: Text(context.l10n.buyAction, style: AppTextStyles.labelMd.copyWith(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.affiliateDisclaimerLabel,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
