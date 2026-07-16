import 'package:flutter/material.dart';
import '../../core/services/symptom_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';

/// Локалізована назва симптому за ключем зі SymptomLibraryService.common
/// (для власних `custom_...` симптомів — сам текст після префіксу, він
/// уже введений користувачем і локалізації не потребує). Винесено сюди
/// (а не в SymptomLibraryService, який не має доступу до BuildContext),
/// щоб symptom_picker_sheet.dart, wellbeing_check_screen.dart та
/// wellbeing_history_screen.dart показували однакові локалізовані назви.
String symptomLabelFor(BuildContext context, String key) {
  if (key.startsWith('custom_')) return key.substring(7);
  final l10n = context.l10n;
  switch (key) {
    case 'headache': return l10n.symptomHeadache;
    case 'nausea': return l10n.symptomNausea;
    case 'dizziness': return l10n.symptomDizziness;
    case 'weakness': return l10n.symptomWeakness;
    case 'shortness_of_breath': return l10n.symptomShortnessOfBreath;
    case 'rash': return l10n.symptomRash;
    case 'pain': return l10n.symptomPain;
    case 'fever': return l10n.symptomFever;
    case 'cough': return l10n.symptomCough;
    case 'sore_throat': return l10n.symptomSoreThroat;
    case 'runny_nose': return l10n.symptomRunnyNose;
    case 'stuffy_nose': return l10n.symptomStuffyNose;
    case 'sneezing': return l10n.symptomSneezing;
    case 'vomiting': return l10n.symptomVomiting;
    case 'diarrhea': return l10n.symptomDiarrhea;
    case 'constipation': return l10n.symptomConstipation;
    case 'bloating': return l10n.symptomBloating;
    case 'heartburn': return l10n.symptomHeartburn;
    case 'stomach_pain': return l10n.symptomStomachPain;
    case 'loss_of_appetite': return l10n.symptomLossOfAppetite;
    case 'increased_appetite': return l10n.symptomIncreasedAppetite;
    case 'insomnia': return l10n.symptomInsomnia;
    case 'drowsiness': return l10n.symptomDrowsiness;
    case 'fatigue': return l10n.symptomFatigue;
    case 'chest_pain': return l10n.symptomChestPain;
    case 'palpitations': return l10n.symptomPalpitations;
    case 'high_blood_pressure': return l10n.symptomHighBloodPressure;
    case 'low_blood_pressure': return l10n.symptomLowBloodPressure;
    case 'back_pain': return l10n.symptomBackPain;
    case 'joint_pain': return l10n.symptomJointPain;
    case 'muscle_pain': return l10n.symptomMusclePain;
    case 'cramps': return l10n.symptomCramps;
    case 'swelling': return l10n.symptomSwelling;
    case 'itching': return l10n.symptomItching;
    case 'dry_skin': return l10n.symptomDrySkin;
    case 'bruising': return l10n.symptomBruising;
    case 'dry_mouth': return l10n.symptomDryMouth;
    case 'excessive_sweating': return l10n.symptomExcessiveSweating;
    case 'chills': return l10n.symptomChills;
    case 'blurred_vision': return l10n.symptomBlurredVision;
    case 'ringing_in_ears': return l10n.symptomRingingInEars;
    case 'numbness': return l10n.symptomNumbness;
    case 'tremor': return l10n.symptomTremor;
    case 'memory_issues': return l10n.symptomMemoryIssues;
    case 'concentration_issues': return l10n.symptomConcentrationIssues;
    case 'anxiety': return l10n.symptomAnxiety;
    case 'irritability': return l10n.symptomIrritability;
    case 'mood_swings': return l10n.symptomMoodSwings;
    case 'weight_loss': return l10n.symptomWeightLoss;
    case 'weight_gain': return l10n.symptomWeightGain;
    default: return SymptomLibraryService.labelFor(key);
  }
}

/// Список ~50 поширених симптомів + власні (збережені раніше через
/// SymptomLibraryService) з пошуком та можливістю додати нове — на заміну
/// колишньому Wrap із 8 чипів. Повертає оновлений набір ключів через
/// Navigator.pop, або null якщо закрито без підтвердження.
class SymptomPickerSheet extends StatefulWidget {
  final Set<String> initialSelected;
  const SymptomPickerSheet({super.key, required this.initialSelected});

  @override
  State<SymptomPickerSheet> createState() => _SymptomPickerSheetState();
}

class _SymptomPickerSheetState extends State<SymptomPickerSheet> {
  late final Set<String> _selected = {...widget.initialSelected};
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<String> _customKeys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custom = await SymptomLibraryService.getCustom();
    // Раніше додані custom_-симптоми, яких ще нема у збереженому списку
    // (створені до появи персистентності), теж показуємо — інакше вибрані
    // раніше зникнуть із переліку.
    final legacySelected = _selected
        .where((s) => s.startsWith('custom_'))
        .map((s) => s.substring(7))
        .where((label) => !custom.contains(label));
    if (mounted) {
      setState(() {
        _customKeys = [...custom, ...legacySelected];
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCustom(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    await SymptomLibraryService.addCustom(trimmed);
    setState(() {
      if (!_customKeys.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
        _customKeys.add(trimmed);
      }
      _selected.add('custom_$trimmed');
      _searchCtrl.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final commonFiltered = SymptomLibraryService.common
        .map((s) => (s.$1, symptomLabelFor(context, s.$1)))
        .where((s) => q.isEmpty || s.$2.toLowerCase().contains(q))
        .toList();
    final customFiltered = _customKeys
        .where((c) => q.isEmpty || c.toLowerCase().contains(q))
        .toList();
    final exactMatchExists = q.isNotEmpty &&
        (commonFiltered.any((s) => s.$2.toLowerCase() == q) ||
            customFiltered.any((c) => c.toLowerCase() == q));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding, AppDimensions.md, AppDimensions.screenPadding, 0),
                child: Row(
                  children: [
                    Expanded(child: Text(context.l10n.symptomsTitle, style: AppTextStyles.h3)),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text(context.l10n.doneTitle),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: context.l10n.symptomSearchHint,
                      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.screenPadding, vertical: 4),
                        children: [
                          if (q.isNotEmpty && !exactMatchExists)
                            _AddCustomRow(query: _searchCtrl.text.trim(), onTap: () => _addCustom(_searchCtrl.text)),
                          for (final c in customFiltered)
                            _SymptomRow(
                              label: c,
                              selected: _selected.contains('custom_$c'),
                              onTap: () => setState(() {
                                final key = 'custom_$c';
                                if (_selected.contains(key)) {
                                  _selected.remove(key);
                                } else {
                                  _selected.add(key);
                                }
                              }),
                            ),
                          for (final s in commonFiltered)
                            _SymptomRow(
                              label: s.$2,
                              selected: _selected.contains(s.$1),
                              onTap: () => setState(() {
                                if (_selected.contains(s.$1)) {
                                  _selected.remove(s.$1);
                                } else {
                                  _selected.add(s.$1);
                                }
                              }),
                            ),
                          if (commonFiltered.isEmpty && customFiltered.isEmpty && q.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(context.l10n.symptomListEmptyLabel, style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SymptomRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.border,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: selected ? AppColors.textMain : AppColors.textSub,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomRow extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  const _AddCustomRow({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.add_circle_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.addCustomSymptomLabel(query),
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
