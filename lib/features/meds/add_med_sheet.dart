import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/models/medication.dart';
import '../../shared/widgets/mk_button.dart';

class AddMedSheet extends StatefulWidget {
  final void Function(Medication) onSave;

  const AddMedSheet({super.key, required this.onSave});

  @override
  State<AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<AddMedSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '30');
  final _instrCtrl = TextEditingController();

  MedForm _form = MedForm.tablet;
  FoodRelation _food = FoodRelation.any;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _totalCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final total = int.tryParse(_totalCtrl.text) ?? 30;
    widget.onSave(
      Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        form: _form,
        dose: _doseCtrl.text.trim(),
        foodRelation: _food,
        instructions:
            _instrCtrl.text.trim().isEmpty ? null : _instrCtrl.text.trim(),
        totalCount: total,
        remainingCount: total,
        createdAt: DateTime.now(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.md),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                  vertical: AppDimensions.lg),
              child: Row(
                children: [
                  Text(l10n.addMedTitle, style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding),
                  children: [
                    _FieldLabel(l10n.addMedName),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          InputDecoration(hintText: l10n.addMedNameHint),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.errorRequired
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _FieldLabel(l10n.addMedDose),
                    TextFormField(
                      controller: _doseCtrl,
                      decoration:
                          InputDecoration(hintText: l10n.addMedDoseHint),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.errorRequired
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _FieldLabel(l10n.addMedForm),
                    _FormPicker(
                      value: _form,
                      onChanged: (v) => setState(() => _form = v),
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _FieldLabel(l10n.addMedFood),
                    _FoodPicker(
                      value: _food,
                      onChanged: (v) => setState(() => _food = v),
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _FieldLabel(l10n.addMedTotal),
                    TextFormField(
                      controller: _totalCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: '30'),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    _FieldLabel(l10n.addMedInstructions),
                    TextFormField(
                      controller: _instrCtrl,
                      decoration: InputDecoration(
                          hintText: l10n.addMedInstructionsHint),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppDimensions.xxl),
                    MkButton(label: l10n.actionSave, onTap: _submit),
                    const SizedBox(height: AppDimensions.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Text(text, style: AppTextStyles.labelSm),
    );
  }
}

class _FormPicker extends StatelessWidget {
  final MedForm value;
  final ValueChanged<MedForm> onChanged;
  final AppLocalizations l10n;

  const _FormPicker(
      {required this.value, required this.onChanged, required this.l10n});

  String _label(MedForm f) => switch (f) {
        MedForm.tablet => l10n.medFormTablet,
        MedForm.capsule => l10n.medFormCapsule,
        MedForm.syrup => l10n.medFormSyrup,
        MedForm.drops => l10n.medFormDrops,
        MedForm.cream => l10n.medFormCream,
        MedForm.inhaler => l10n.medFormInhaler,
        MedForm.injection => l10n.medFormInjection,
        MedForm.other => l10n.medFormOther,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: MedForm.values.map((f) {
        final selected = f == value;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              '${f.emoji} ${_label(f)}',
              style: AppTextStyles.bodyMd.copyWith(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSub,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FoodPicker extends StatelessWidget {
  final FoodRelation value;
  final ValueChanged<FoodRelation> onChanged;
  final AppLocalizations l10n;

  const _FoodPicker(
      {required this.value, required this.onChanged, required this.l10n});

  String _label(FoodRelation f) => switch (f) {
        FoodRelation.before => l10n.foodBefore,
        FoodRelation.after => l10n.foodAfter,
        FoodRelation.with_ => l10n.foodWith,
        FoodRelation.any => l10n.foodAny,
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: FoodRelation.values.map((f) {
        final selected = f == value;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accentLight
                  : AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              _label(f),
              style: AppTextStyles.bodyMd.copyWith(
                color: selected
                    ? AppColors.accent
                    : AppColors.textSub,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
