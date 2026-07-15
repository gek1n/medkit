import 'dart:convert';
import 'package:http/http.dart' as http;

class NluResult {
  // Голосове ADD підтримує рівно 3 дії: add_med | add_activity |
  // add_appointment. Усе інше (mark_taken, самопочуття тощо) — unknown.
  final String action;
  final String? drugName;
  final double? doseAmount;
  final String? doseUnit;
  final List<String>? scheduleTimes; // morning | evening | afternoon | night
  final String? foodRelation; // before | after | any
  final String? activityName;
  final String? appointmentType;
  final String transcript;

  const NluResult({
    required this.action,
    required this.transcript,
    this.drugName,
    this.doseAmount,
    this.doseUnit,
    this.scheduleTimes,
    this.foodRelation,
    this.activityName,
    this.appointmentType,
  });

  factory NluResult.unknown(String transcript) =>
      NluResult(action: 'unknown', transcript: transcript);
}

/// Проксі до Claude API для розпізнавання голосових команд. Приймає лише
/// структуровані дії (прийом ліків, розклад, запис до лікаря) — вільний
/// текстовий опис самопочуття/симптомів сюди НЕ надсилається (лишається
/// тільки локальне текстове поле на екрані самопочуття), щоб такий контент
/// ніколи не залишав пристрій.
class NluService {
  static const _proxyUrl = 'https://api.elly-medkit.com/voice/parse';

  NluService();

  Future<NluResult> parse(String transcript) async {
    final response = await http
        .post(
          Uri.parse(_proxyUrl),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'transcript': transcript}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = _tryDecodeError(response.body);
      throw Exception('Proxy error ${response.statusCode}: $body');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return NluResult(
      action: json['action'] as String? ?? 'unknown',
      transcript: transcript,
      drugName: json['drugName'] as String?,
      doseAmount: (json['doseAmount'] as num?)?.toDouble(),
      doseUnit: json['doseUnit'] as String?,
      scheduleTimes: (json['scheduleTimes'] as List?)
          ?.map((e) => e as String)
          .toList(),
      foodRelation: json['foodRelation'] as String?,
      activityName: json['activityName'] as String?,
      appointmentType: json['appointmentType'] as String?,
    );
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
