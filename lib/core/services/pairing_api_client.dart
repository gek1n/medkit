import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP-клієнт до relay-бекенду (`medkit-backend/medkit_private/src/Modules/Relay/`).
/// Сервер бачить лише sha256(код) + зашифрований blob — сам код і вміст
/// ніколи не покидають пристрій у відкритому вигляді. Дані навмисно на
/// власному MySQL-сервері (не Firestore) — без пооперационного білінгу,
/// власна БД не має ризику впертись у чужі денні квоти при великому
/// навантаженні.
class PairingApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const PairingApiClient();

  /// POST /pairing/create — завантажує зашифрований blob під code_hash,
  /// TTL 30 хв на сервері.
  Future<void> create({
    required String codeHash,
    required List<int> salt,
    required List<int> nonce,
    required List<int> ciphertext,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/pairing/create'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'code_hash': codeHash,
            'salt': base64Encode(salt),
            'nonce': base64Encode(nonce),
            'ciphertext': base64Encode(ciphertext),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 201) {
      throw PairingApiException(response.statusCode, _tryDecodeError(response.body));
    }
  }

  /// POST /pairing/redeem — забирає blob по code_hash. Сервер видаляє
  /// запис одразу після успішного читання (one-time use).
  Future<PairingBlob> redeem({required String codeHash}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/pairing/redeem'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'code_hash': codeHash}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw const PairingCodeExpiredException();
    }
    if (response.statusCode != 200) {
      throw PairingApiException(response.statusCode, _tryDecodeError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PairingBlob(
      salt: base64Decode(json['salt'] as String),
      nonce: base64Decode(json['nonce'] as String),
      ciphertext: base64Decode(json['ciphertext'] as String),
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

class PairingBlob {
  final List<int> salt;
  final List<int> nonce;
  final List<int> ciphertext;

  const PairingBlob({required this.salt, required this.nonce, required this.ciphertext});
}

class PairingApiException implements Exception {
  final int statusCode;
  final String message;

  const PairingApiException(this.statusCode, this.message);

  @override
  String toString() => 'PairingApiException($statusCode): $message';
}

/// code_hash не знайдено на сервері — код або невірний, або прострочений
/// (TTL 30 хв), або вже був використаний (one-time).
class PairingCodeExpiredException implements Exception {
  const PairingCodeExpiredException();

  @override
  String toString() => 'Код недійсний, прострочений або вже використаний';
}
