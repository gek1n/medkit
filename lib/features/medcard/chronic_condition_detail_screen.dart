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
import 'add_chronic_condition_screen.dart';

class ChronicConditionDetailScreen extends StatelessWidget {
  final ChronicCondition condition;
  const ChronicConditionDetailScreen({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    final docs = List<String>.from(jsonDecode(condition.documentPaths) as List);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkFormHeader(title: context.l10n.chronicConditionTitle, onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                children: [
                  MkDetailRow(
                    label: context.l10n.fieldDiagnosis,
                    value: Text(condition.name, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (condition.specialty?.isNotEmpty ?? false)
                    MkDetailRow(label: context.l10n.fieldSpecialty, value: Text(condition.specialty!, style: AppTextStyles.bodyMd)),
                  if (condition.diagnosedAt != null)
                    MkDetailRow(
                      label: context.l10n.fieldDiagnosisDate,
                      value: Text(MKDateUtils.formatDate(context, condition.diagnosedAt!), style: AppTextStyles.bodyMd),
                    ),
                  if (condition.notes?.isNotEmpty ?? false)
                    MkDetailRow(label: context.l10n.fieldNotes, value: Text(condition.notes!, style: AppTextStyles.bodyMd)),
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
                    builder: (_) => AddChronicConditionScreen(memberId: condition.memberId, existing: condition),
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
