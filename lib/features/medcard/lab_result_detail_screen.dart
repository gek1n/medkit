import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/l10n_ext.dart';
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
            MkFormHeader(title: context.l10n.labResultTitle, onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                children: [
                  MkDetailRow(
                    label: context.l10n.fieldName,
                    value: Text(
                      result.testName?.isNotEmpty == true ? result.testName! : result.specialty,
                      style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  MkDetailRow(label: context.l10n.fieldSpecialty, value: Text(result.specialty, style: AppTextStyles.bodyMd)),
                  MkDetailRow(
                    label: context.l10n.fieldDate,
                    value: Text(MKDateUtils.formatDate(context, result.takenAt), style: AppTextStyles.bodyMd),
                  ),
                  if (result.notes?.isNotEmpty ?? false)
                    MkDetailRow(label: context.l10n.fieldNotes, value: Text(result.notes!, style: AppTextStyles.bodyMd)),
                  DocumentsSection(paths: docs, onChanged: (_) {}, readOnly: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: MkSaveButton(
                isSaving: false,
                label: context.l10n.editAction,
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
