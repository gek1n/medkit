import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Список поширених назв аналізів (~50) + власні, додані користувачем —
/// та сама ідея, що й [SymptomLibraryService]: щоб не вводити ту саму
/// назву вручну щоразу і щоб однакові аналізи можна було надійно збирати
/// в один список за назвою в майбутньому (напр. графік показників у часі).
class LabTestLibraryService {
  static const _customKey = 'lab_test_custom_names';

  static const List<String> common = [
    'Загальний аналіз крові',
    'Загальний аналіз сечі',
    'Біохімічний аналіз крові',
    'Глюкоза крові',
    'Ліпідний профіль (холестерин)',
    'Гормони щитоподібної залози (ТТГ)',
    'Т3 вільний',
    'Т4 вільний',
    'Печінкові проби (АЛТ, АСТ)',
    'Білірубін',
    'Креатинін',
    'Сечовина',
    'Сечова кислота',
    'Залізо сироватки',
    'Феритин',
    'Вітамін D',
    'Вітамін B12',
    'Фолієва кислота',
    'Коагулограма',
    'Група крові та резус-фактор',
    'С-реактивний білок (СРБ)',
    'Швидкість осідання еритроцитів (ШОЕ)',
    'Естроген, прогестерон',
    'Тестостерон',
    'Пролактин',
    'Інсулін',
    'Глікований гемоглобін (HbA1c)',
    'ПЛР-тест',
    'Аналіз на алергени',
    'Копрограма',
    'Аналіз калу на приховану кров',
    'Мазок на флору',
    'Посів сечі на стерильність',
    'Аналіз на гепатити (B, C)',
    'ВІЛ-тест',
    'RW (сифіліс)',
    'Кальцій',
    'Магній',
    'Калій, натрій, хлор',
    'Амілаза',
    'Ліпаза',
    'ПСА (простатоспецифічний антиген)',
    'Онкомаркери (СА-125)',
    'Аналіз на паразитів (яйця гельмінтів)',
    'Кортизол',
    'Імунограма',
    'Спермограма',
    'Електроліти крові',
    'Загальний білок',
    'Д-димер',
  ];

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
