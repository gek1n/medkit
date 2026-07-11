import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Шифрує вкладення (фото ліків, у майбутньому — фото/PDF медкартки, войс-
/// нотатки) окремим ключем від БД, щоб на диску ніколи не лежав plaintext.
/// AES-256-GCM: свіжий nonce на кожен файл, тег автентичності перевіряє
/// цілісність при розшифровці.
class FileEncryptionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'file_encryption_key';
  static final _algorithm = AesGcm.with256bits();

  static Future<SecretKey> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }

    final key = await _algorithm.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(key: _keyStorageKey, value: base64Encode(bytes));
    return key;
  }

  /// [plainBytes] -> [nonce (12 байт)][ciphertext][mac (16 байт)] одним blob'ом,
  /// готовим для запису у файл.
  static Future<Uint8List> encryptBytes(List<int> plainBytes) async {
    final key = await _getOrCreateKey();
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(plainBytes, secretKey: key, nonce: nonce);
    return Uint8List.fromList([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Обернена операція до [encryptBytes]. Кидає виняток, якщо blob
  /// пошкоджений або зашифрований іншим ключем (тег не збігається).
  static Future<Uint8List> decryptBytes(List<int> blob) async {
    final key = await _getOrCreateKey();
    const nonceLength = 12;
    const macLength = 16;
    if (blob.length < nonceLength + macLength) {
      throw const FormatException('Зашифрований файл пошкоджений (замалий розмір)');
    }

    final nonce = blob.sublist(0, nonceLength);
    final mac = blob.sublist(blob.length - macLength);
    final cipherText = blob.sublist(nonceLength, blob.length - macLength);

    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plain = await _algorithm.decrypt(box, secretKey: key);
    return Uint8List.fromList(plain);
  }

  // ── Синхронізація ключа між пристроями ОДНОГО акаунта ──────────────────
  // На відміну від пейрингу з іншою людиною (FamilySyncService), тут це
  // той самий власник даних на іншому своєму пристрої — тож, коли на новому
  // пристрої локального ключа ще нема, безпечно (і потрібно) прийняти той,
  // що вже використовувався для наявних файлів, а не мовчки згенерувати
  // свій — інакше відновлені фото/PDF назавжди лишились би нечитаемыми.

  static Future<bool> hasLocalKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    return existing != null && existing.isNotEmpty;
  }

  static Future<Uint8List> exportKeyBytes() async {
    final key = await _getOrCreateKey();
    return Uint8List.fromList(await key.extractBytes());
  }

  /// Встановлює ключ з сервера ЛИШЕ якщо на цьому пристрої ще нема свого —
  /// інакше вже наявні тут локальні файли (зашифровані старим ключем)
  /// стали б нечитаемыми назавжди.
  static Future<void> installKeyIfAbsent(Uint8List keyBytes) async {
    if (await hasLocalKey()) return;
    await _secureStorage.write(key: _keyStorageKey, value: base64Encode(keyBytes));
  }
}
