import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/allergy_severity.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_form_fields.dart';
import 'add_allergy_screen.dart';

/// Перегляд уже створеного запису — не редагування напряму. Кнопка
/// "Редагувати" внизу веде на [AddAllergyScreen] у режимі редагування.
class AllergyDetailScreen extends StatelessWidget {
  final Allergy allergy;
  const AllergyDetailScreen({super.key, required this.allergy});

  @override
  Widget build(BuildContext context) {
    final severity = AllergySeverity.fromDb(allergy.severity);
    final docs = List<String>.from(jsonDecode(allergy.documentPaths) as List);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(title: 'Алергія', onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                children: [
                  MkDetailRow(
                    label: 'Алерген',
                    value: Text(allergy.allergen, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  MkDetailRow(
                    label: 'Тяжкість',
                    value: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: severity.bgColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(severity.label,
                          style: AppTextStyles.bodySm.copyWith(color: severity.color, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (allergy.reaction?.isNotEmpty ?? false)
                    MkDetailRow(label: 'Реакція', value: Text(allergy.reaction!, style: AppTextStyles.bodyMd)),
                  if (allergy.notes?.isNotEmpty ?? false)
                    MkDetailRow(label: 'Нотатки', value: Text(allergy.notes!, style: AppTextStyles.bodyMd)),
                  DocumentsSection(
                    paths: docs,
                    onChanged: (_) {},
                    readOnly: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: MkSaveButton(
                isSaving: false,
                label: 'Редагувати',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AddAllergyScreen(memberId: allergy.memberId, existing: allergy)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
