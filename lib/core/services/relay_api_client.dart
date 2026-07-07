import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP-клієнт до relay-каналу (`medkit-backend/medkit_private/src/Modules/Relay/RelayController.php`),
/// який використовується ПІСЛЯ пейрингу для доставки зашифрованих оновлень
/// (нові ліки, зміна розкладу, фото). Сервер бачить лише channel_id і
/// push-токени — вміст payload завжди зашифрований на клієнті спільним
/// ключем, встановленим під час пейрингу.
///
/// На сервері `/relay/send` перезаписує один рядок "поточний стан каналу"
/// (не зростаючу чергу) — тому пристрій, що пропустив push (був вимкнений/
/// офлайн), може забрати актуальний стан через [state] одразу при
/// наступному відкритті застосунку, без окремого механізму повторів.
class RelayApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const RelayApiClient();

  /// POST /relay/register — прив'язує push-токен цього пристрою до каналу.
  Future<void> register({
    required String channelId,
    required String pushToken,
    required String platform,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/relay/register'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'channel_id': channelId,
            'push_token': pushToken,
            'platform': platform,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 201) {
      throw RelayApiException(response.statusCode, _tryDecodeError(response.body));
    }
  }

  /// POST /relay/send — перезаписує поточний стан каналу і будить інші
  /// пристрої пушем.
  Future<RelaySendResult> send({
    required String channelId,
    required String senderToken,
    required String encryptedPayloadBase64,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/relay/send'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'channel_id': channelId,
            'sender_token': senderToken,
            'encrypted_payload': encryptedPayloadBase64,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw RelayApiException(response.statusCode, _tryDecodeError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RelaySendResult(
      recipients: json['recipients'] as int? ?? 0,
      deliveredImmediately: json['delivered_immediately'] as int? ?? 0,
    );
  }

  /// POST /relay/state — забирає поточний стан каналу (для пристрою, що
  /// відкрився після пропущеного push, чи одразу після пейрингу).
  Future<RelayState> fetchState({required String channelId}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/relay/state'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'channel_id': channelId}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw const RelayStateNotFoundException();
    }
    if (response.statusCode != 200) {
      throw RelayApiException(response.statusCode, _tryDecodeError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return RelayState(
      encryptedPayloadBase64: json['encrypted_payload'] as String,
      senderToken: json['sender_token'] as String,
      updatedAt: json['updated_at'] as String,
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

class RelaySendResult {
  final int recipients;
  final int deliveredImmediately;

  const RelaySendResult({required this.recipients, required this.deliveredImmediately});
}

class RelayState {
  final String encryptedPayloadBase64;
  final String senderToken;
  final String updatedAt;

  const RelayState({
    required this.encryptedPayloadBase64,
    required this.senderToken,
    required this.updatedAt,
  });
}

class RelayApiException implements Exception {
  final int statusCode;
  final String message;

  const RelayApiException(this.statusCode, this.message);

  @override
  String toString() => 'RelayApiException($statusCode): $message';
}

class RelayStateNotFoundException implements Exception {
  const RelayStateNotFoundException();

  @override
  String toString() => 'Для цього каналу ще немає стану';
}
