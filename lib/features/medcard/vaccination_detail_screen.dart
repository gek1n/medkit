import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_form_fields.dart';
import 'add_vaccination_screen.dart';

class VaccinationDetailScreen extends StatelessWidget {
  final Vaccination vaccination;
  const VaccinationDetailScreen({super.key, required this.vaccination});

  @override
  Widget build(BuildContext context) {
    final docs = List<String>.from(jsonDecode(vaccination.documentPaths) as List);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(title: 'Щеплення', onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                children: [
                  MkDetailRow(
                    label: 'Назва',
                    value: Text(vaccination.name, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  MkDetailRow(
                    label: 'Дата введення',
                    value: Text(MKDateUtils.formatDate(vaccination.givenAt), style: AppTextStyles.bodyMd),
                  ),
                  if (vaccination.nextDoseAt != null)
                    MkDetailRow(
                      label: 'Наступна ревакцинація',
                      value: Text(MKDateUtils.formatDate(vaccination.nextDoseAt!), style: AppTextStyles.bodyMd),
                    ),
                  if (vaccination.notes?.isNotEmpty ?? false)
                    MkDetailRow(label: 'Нотатки', value: Text(vaccination.notes!, style: AppTextStyles.bodyMd)),
                  DocumentsSection(paths: docs, onChanged: (_) {}, readOnly: true),
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
                  MaterialPageRoute(
                    builder: (_) => AddVaccinationScreen(memberId: vaccination.memberId, existing: vaccination),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
