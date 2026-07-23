import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ScannedMedication {
  final String name;
  final String? form; // tablet | capsule | suppository | vial | syrup | drops | cream | inhaler | injection
  final double? doseAmount;
  final String? doseUnit;
  final List<String>? scheduleTimes; // morning | afternoon | evening | night
  final int? durationDays;
  // Користувач обирає це САМ на екрані перегляду результатів сканування
  // (food_relation_picker) — сервер більше не намагається вгадати це за
  // назвою препарату (Apple App Review guideline 1.4.1).
  final String? foodRelation; // before | after | any

  const ScannedMedication({
    required this.name,
    this.form,
    this.doseAmount,
    this.doseUnit,
    this.scheduleTimes,
    this.durationDays,
    this.foodRelation,
  });

  factory ScannedMedication.fromJson(Map<String, dynamic> json) => ScannedMedication(
        name: json['name'] as String,
        form: json['form'] as String?,
        doseAmount: (json['doseAmount'] as num?)?.toDouble(),
        doseUnit: json['doseUnit'] as String?,
        scheduleTimes: (json['scheduleTimes'] as List?)?.map((e) => e as String).toList(),
        durationDays: (json['durationDays'] as num?)?.toInt(),
      );
}

/// Проксі до `/scan/prescription` — фото рецепта чи упаковок ліків
/// (одне чи кілька) розпізнаються Claude (vision) на сервері. Фото
/// передається лише для розпізнавання і ніде на сервері не зберігається.
class PrescriptionScanService {
  static const _proxyUrl = 'https://api.elly-medkit.com/scan/prescription';

  Future<List<ScannedMedication>> scan(List<File> imageFiles) async {
    final images = await Future.wait(imageFiles.map((f) async {
      final bytes = await f.readAsBytes();
      return {
        'mediaType': _mediaType(f.path),
        'base64': base64Encode(bytes),
      };
    }));

    final response = await http
        .post(
          Uri.parse(_proxyUrl),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'images': images}),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Proxy error ${response.statusCode}: ${_tryDecodeError(response.body)}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['medications'] as List)
        .map((e) => ScannedMedication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _mediaType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _tryDecodeError(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return j['error'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}
