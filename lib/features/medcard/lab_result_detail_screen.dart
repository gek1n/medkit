import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/documents_section.dart';
import '../../shared/widgets/mk_form_fields.dart';
import 'add_lab_result_screen.dart';

class LabResultDetailScreen extends StatelessWidget {
  final LabResult result;
  const LabResultDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final docs = List<String>.from(jsonDecode(result.documentPaths) as List);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(title: 'Аналіз', onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                children: [
                  MkDetailRow(
                    label: 'Назва',
                    value: Text(
                      result.testName?.isNotEmpty == true ? result.testName! : result.specialty,
                      style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  MkDetailRow(label: 'Напрямок', value: Text(result.specialty, style: AppTextStyles.bodyMd)),
                  MkDetailRow(
                    label: 'Дата',
                    value: Text(MKDateUtils.formatDate(result.takenAt), style: AppTextStyles.bodyMd),
                  ),
                  if (result.notes?.isNotEmpty ?? false)
                    MkDetailRow(label: 'Нотатки', value: Text(result.notes!, style: AppTextStyles.bodyMd)),
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
                    builder: (_) => AddLabResultScreen(memberId: result.memberId, existing: result),
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
