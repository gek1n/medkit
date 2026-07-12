import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP-клієнт до `/subscription/*`
/// (medkit-backend/medkit_private/src/Modules/Billing/SubscriptionController.php).
/// Той самий "account_id + recovery_key_hash доводить володіння" паттерн,
/// що й AccountApiClient — сервер НІКОЛИ не отримує поняття про "сім'ї"/
/// "слоти"/"учасників" (лишається виключно на клієнті), лише "чи активна
/// підписка акаунта X, до якого числа".
class SubscriptionApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const SubscriptionApiClient();

  /// POST /subscription/verify — після успішної покупки (StoreKit 2/Play
  /// Billing). [receipt] — originalTransactionId (iOS) чи purchase token
  /// (Android).
  Future<SubscriptionStatusResult> verify({
    required String accountId,
    required String recoveryKeyHash,
    required String platform,
    required String productId,
    required String receipt,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/subscription/verify'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'account_id': accountId,
            'recovery_key_hash': recoveryKeyHash,
            'platform': platform,
            'product_id': productId,
            'receipt': receipt,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw SubscriptionApiException(response.statusCode, _tryDecodeError(response.body));
    }
    return SubscriptionStatusResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /subscription/status — дешевий lookup із серверної БД (без походу
  /// до Apple/Google), для частих перевірок при кожному відкритті/resume.
  Future<SubscriptionStatusResult> status({
    required String accountId,
    required String recoveryKeyHash,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/subscription/status'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'account_id': accountId, 'recovery_key_hash': recoveryKeyHash}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SubscriptionApiException(response.statusCode, _tryDecodeError(response.body));
    }
    return SubscriptionStatusResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /subscription/verify-test — той самий ефект, що й [verify], але
  /// БЕЗ походу до Apple/Google (лише для тестування на кількох реальних
  /// пристроях; сервер вимикає маршрут (404), якщо BILLING_TEST_MODE/
  /// BILLING_TEST_SECRET не налаштовані в його .env).
  Future<SubscriptionStatusResult> verifyTest({
    required String accountId,
    required String recoveryKeyHash,
    required String platform,
    required String productId,
    required String testSecret,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/subscription/verify-test'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'account_id': accountId,
            'recovery_key_hash': recoveryKeyHash,
            'platform': platform,
            'product_id': productId,
            'test_secret': testSecret,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SubscriptionApiException(response.statusCode, _tryDecodeError(response.body));
    }
    return SubscriptionStatusResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POST /subscription/cancel-test — тестовий аналог миттєвого розриву,
  /// той самий захист, що й [verifyTest].
  Future<void> cancelTest({
    required String accountId,
    required String recoveryKeyHash,
    required String testSecret,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/subscription/cancel-test'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'account_id': accountId,
            'recovery_key_hash': recoveryKeyHash,
            'test_secret': testSecret,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw SubscriptionApiException(response.statusCode, _tryDecodeError(response.body));
    }
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

/// [status] — 'none' (підписки немає) | 'active' | 'grace' | 'expired' | 'cancelled'.
class SubscriptionStatusResult {
  final String status;
  final String? productId;
  final DateTime? expiresAt;

  const SubscriptionStatusResult({required this.status, this.productId, this.expiresAt});

  factory SubscriptionStatusResult.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResult(
      status: json['status'] as String? ?? 'none',
      productId: json['product_id'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
    );
  }
}

class SubscriptionApiException implements Exception {
  final int statusCode;
  final String message;

  const SubscriptionApiException(this.statusCode, this.message);

  @override
  String toString() => 'SubscriptionApiException($statusCode): $message';
}
