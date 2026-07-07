import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP-клієнт до `/account/*` (medkit-backend/medkit_private/src/Modules/Sync/AccountController.php).
/// Сервер бачить лише sha256(recovery key) — сам recovery key і ключ
/// шифрування синхронізації ніколи не покидають пристрій.
class AccountApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const AccountApiClient();

  /// POST /account/create — реєструє новий акаунт синхронізації.
  /// [authProvider]/[authToken] — опційно, для режиму "хмара з акаунтом"
  /// (лише ідентифікація, ключ шифрування як і раніше йде з recovery key).
  Future<String> create({
    required String recoveryKeyHash,
    String? authProvider,
    String? authToken,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/account/create'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'recovery_key_hash': recoveryKeyHash,
            'auth_provider': ?authProvider,
            'auth_token': ?authToken,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 201) {
      throw AccountApiException(response.statusCode, _tryDecodeError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['account_id'] as String;
  }

  /// POST /account/login-oauth — знаходить account_id за вже верифікованим
  /// Google/Apple ID, без recovery key (зручність входу). Ключ шифрування
  /// після цього все одно треба або з secure storage (iCloud-синк на iOS),
  /// або повторно ввівши recovery key.
  Future<String> loginOAuth({required String authProvider, required String authToken}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/account/login-oauth'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'auth_provider': authProvider, 'auth_token': authToken}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw const AccountNotFoundException();
    }
    if (response.statusCode != 200) {
      throw AccountApiException(response.statusCode, _tryDecodeError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['account_id'] as String;
  }

  /// POST /account/login — знаходить існуючий акаунт за recovery key
  /// (відновлення на новому пристрої).
  Future<String> login({required String recoveryKeyHash}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/account/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'recovery_key_hash': recoveryKeyHash}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw const AccountNotFoundException();
    }
    if (response.statusCode != 200) {
      throw AccountApiException(response.statusCode, _tryDecodeError(response.body));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['account_id'] as String;
  }

  /// POST /account/delete — GDPR: остаточно видаляє акаунт і всі його дані
  /// на сервері (каскадом). Локальні дані на пристрої це не зачіпає.
  Future<void> delete({required String accountId, required String recoveryKeyHash}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/account/delete'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'account_id': accountId, 'recovery_key_hash': recoveryKeyHash}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw AccountApiException(response.statusCode, _tryDecodeError(response.body));
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

class AccountApiException implements Exception {
  final int statusCode;
  final String message;

  const AccountApiException(this.statusCode, this.message);

  @override
  String toString() => 'AccountApiException($statusCode): $message';
}

class AccountNotFoundException implements Exception {
  const AccountNotFoundException();

  @override
  String toString() => 'Акаунт не знайдено — перевірте recovery key';
}
