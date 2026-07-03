import 'dart:convert';
import 'package:http/http.dart' as http;

class NluResult {
  final String action; // mark_taken | add_med | add_wellbeing | add_appointment | unknown
  final String? drugName;
  final double? doseAmount;
  final String? doseUnit;
  final List<String>? scheduleTimes; // morning | evening | afternoon | night
  final String? foodRelation; // before | after | any
  final int? wellbeingMood; // 1-5
  final List<String>? symptoms;
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
    this.wellbeingMood,
    this.symptoms,
    this.appointmentType,
  });

  factory NluResult.unknown(String transcript) =>
      NluResult(action: 'unknown', transcript: transcript);
}

class NluService {
  // Replace with your actual server URL after deploying nlu_proxy.php
  static const _proxyUrl = 'https://YOUR_DOMAIN/medkit/nlu.php';

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
      wellbeingMood: json['wellbeingMood'] as int?,
      symptoms:
          (json['symptoms'] as List?)?.map((e) => e as String).toList(),
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
