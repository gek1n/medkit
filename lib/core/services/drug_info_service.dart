import 'dart:convert';
import 'package:http/http.dart' as http;

class DrugReference {
  final String name;
  final String? foodRelation; // before | after | any
  final List<String>? sideEffects;

  const DrugReference({required this.name, this.foodRelation, this.sideEffects});

  factory DrugReference.fromJson(Map<String, dynamic> json) => DrugReference(
        name: json['name'] as String,
        foodRelation: json['foodRelation'] as String?,
        sideEffects: (json['sideEffects'] as List?)?.map((e) => e as String).toList(),
      );

  bool get hasInfo => foodRelation != null || (sideEffects != null && sideEffects!.isNotEmpty);
}

/// Проксі до `/drug/info` — довідкова інформація про ліки (їжа/побічні
/// ефекти) за назвою. Той самий бекенд-виклик, що і всередині сканування
/// рецепта, але окремо для збагачення вже розпізнаного голосом препарату.
/// Дані НЕ з перевіреного каталогу ліків — загальні знання моделі, тому UI
/// має показувати застереження поруч з цією інформацією.
class DrugInfoService {
  static const _proxyUrl = 'https://api.elly-medkit.com/drug/info';

  Future<List<DrugReference>> lookup(List<String> names) async {
    if (names.isEmpty) return [];

    final response = await http
        .post(
          Uri.parse(_proxyUrl),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'names': names}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Proxy error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['items'] as List)
        .map((e) => DrugReference.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
