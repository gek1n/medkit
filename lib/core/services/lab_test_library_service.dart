import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/l10n_ext.dart';

/// Список поширених назв аналізів (~50) + власні, додані користувачем —
/// та сама ідея, що й [SymptomLibraryService]: щоб не вводити ту саму
/// назву вручну щоразу і щоб однакові аналізи можна було надійно збирати
/// в один список за назвою в майбутньому (напр. графік показників у часі).
class LabTestLibraryService {
  static const _customKey = 'lab_test_custom_names';

  static List<String> common(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.labTestCbc,
      l10n.labTestUrinalysis,
      l10n.labTestBloodChemistry,
      l10n.labTestBloodGlucose,
      l10n.labTestLipidProfile,
      l10n.labTestTsh,
      l10n.labTestFreeT3,
      l10n.labTestFreeT4,
      l10n.labTestLiverEnzymes,
      l10n.labTestBilirubin,
      l10n.labTestCreatinine,
      l10n.labTestUrea,
      l10n.labTestUricAcid,
      l10n.labTestSerumIron,
      l10n.labTestFerritin,
      l10n.labTestVitaminD,
      l10n.labTestVitaminB12,
      l10n.labTestFolicAcid,
      l10n.labTestCoagulogram,
      l10n.labTestBloodType,
      l10n.labTestCrp,
      l10n.labTestEsr,
      l10n.labTestEstrogenProgesterone,
      l10n.labTestTestosterone,
      l10n.labTestProlactin,
      l10n.labTestInsulin,
      l10n.labTestHba1c,
      l10n.labTestPcr,
      l10n.labTestAllergens,
      l10n.labTestCoprogram,
      l10n.labTestOccultBlood,
      l10n.labTestFloraSwab,
      l10n.labTestUrineCulture,
      l10n.labTestHepatitis,
      l10n.labTestHiv,
      l10n.labTestSyphilis,
      l10n.labTestCalcium,
      l10n.labTestMagnesium,
      l10n.labTestElectrolytesKNaCl,
      l10n.labTestAmylase,
      l10n.labTestLipase,
      l10n.labTestPsa,
      l10n.labTestTumorMarkers,
      l10n.labTestParasites,
      l10n.labTestCortisol,
      l10n.labTestImmunogram,
      l10n.labTestSpermogram,
      l10n.labTestBloodElectrolytes,
      l10n.labTestTotalProtein,
      l10n.labTestDDimer,
    ];
  }

  static Future<List<String>> getCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  static Future<void> addCustom(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await getCustom();
    if (existing.any((e) => e.toLowerCase() == trimmed.toLowerCase())) return;
    existing.add(trimmed);
    await prefs.setString(_customKey, jsonEncode(existing));
  }
}
