import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Криптографія для пейрингу пристроїв (Фаза 1 бекенду: /pairing/create,
/// /pairing/redeem). Ключ шифрування ніколи не залишає пристрій і ніколи не
/// передається на сервер — сервер отримує лише sha256(код) для пошуку.
///
/// Формат: code (людський, 8 символів) + salt (випадкові 16 байт, зберігається
/// разом із зашифрованим blob'ом, не секрет) --Argon2id--> AES-256 ключ.
class PairingCryptoService {
  static const _codeAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static final _cipher = AesGcm.with256bits();

  /// Код для ручного введення на другому пристрої. Без 0/O, 1/I/L та інших
  /// пар, які легко переплутати. ~40 біт ентропії при 8 символах.
  static String generateCode({int length = 8}) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)],
    ).join();
  }

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static String codeHash(String code) {
    // sha256 — лише ключ пошуку на сервері, не сам ключ шифрування.
    return sha256Hex(utf8.encode(code));
  }

  static Future<SecretKey> _deriveKey(String code, List<int> salt) async {
    final argon2 = Argon2id(
      memory: 19456, // ~19 МБ — рекомендація OWASP для Argon2id
      iterations: 2,
      parallelism: 1,
      hashLength: 32,
    );
    return argon2.deriveKeyFromPassword(password: code, nonce: salt);
  }

  /// Шифрує payload кодом, який ще й буде людяно введений на другому
  /// пристрої. Повертає все, що потрібно відправити на /pairing/create.
  static Future<PairingEncryptResult> encrypt(String code, List<int> plainBytes) async {
    final salt = generateSalt();
    final key = await _deriveKey(code, salt);
    final nonce = _cipher.newNonce();
    final box = await _cipher.encrypt(plainBytes, secretKey: key, nonce: nonce);

    return PairingEncryptResult(
      codeHash: codeHash(code),
      salt: salt,
      nonce: Uint8List.fromList(nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
  }

  /// Обернена операція — те, що приходить із /pairing/redeem, плюс код,
  /// який ввела людина. Кидає виняток, якщо код невірний (тег не збігається).
  static Future<Uint8List> decrypt(
    String code, {
    required List<int> salt,
    required List<int> nonce,
    required List<int> cipherTextAndMac,
  }) async {
    final key = await _deriveKey(code, salt);
    const macLength = 16;
    if (cipherTextAndMac.length < macLength) {
      throw const FormatException('Пошкоджений пейринг-blob');
    }
    final cipherText = cipherTextAndMac.sublist(0, cipherTextAndMac.length - macLength);
    final mac = cipherTextAndMac.sublist(cipherTextAndMac.length - macLength);

    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plain = await _cipher.decrypt(box, secretKey: key);
    return Uint8List.fromList(plain);
  }
}

class PairingEncryptResult {
  final String codeHash;
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List ciphertext;

  const PairingEncryptResult({
    required this.codeHash,
    required this.salt,
    required this.nonce,
    required this.ciphertext,
  });
}

/// Невеликий helper для sha256-хешу без окремої залежності — cryptography
/// вже в проєкті. Sha256() сам по собі не має hashSync (тільки асинхронний
/// hash()), тому синхронна версія береться через toSync() -> DartSha256.
String sha256Hex(List<int> bytes) {
  final digest = Sha256().toSync().hashSync(bytes);
  return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
