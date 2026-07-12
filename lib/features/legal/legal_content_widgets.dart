import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Спільні будівельні блоки для нативних правових документів (Політика
/// конфіденційності, Умови використання) — щоб не дублювати ту саму
/// розмітку "секція з іконкою / абзац / буліти / callout / рядок мітка-
/// значення" в кожному екрані окремо.

class LegalSection {
  final IconData icon;
  final String title;
  final List<Widget> body;
  const LegalSection(this.icon, this.title, this.body);
}

class LegalSectionWidget extends StatelessWidget {
  final LegalSection section;
  const LegalSectionWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(section.title, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 10),
          ...section.body,
        ],
      ),
    );
  }
}

Widget legalP(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
    );

Widget legalBullets(List<String> items) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
                      Expanded(
                          child: Text(t,
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

Widget legalCallout(String text, {required Color bg, required Color border, required Color fg}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: border),
      ),
      child: Text(text, style: AppTextStyles.bodyMd.copyWith(color: fg)),
    );

/// Рядок "мітка — значення" — заміна HTML-таблиці для мобільного екрана.
Widget legalRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.textMain)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
        ],
      ),
    );
