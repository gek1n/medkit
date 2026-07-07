import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Пакує ключі шифрування БД і файлів у один маленький blob, захищений
/// паролем бекапу (Argon2id -> AES-256-GCM, той самий підхід, що і в
/// `pairing_crypto_service.dart`). Сам бекап (medkit.db + med_photos/) вже
/// зашифрований цими ключами на диску — хмара (Google Drive/iCloud) ніколи
/// не бачить plaintext, а без пароля бекапу ключі з архіву не витягнути,
/// навіть маючи повний доступ до хмарного сховища.
class BackupCryptoService {
  static const _secureStorage = FlutterSecureStorage();
  static const _dbKeyStorageKey = 'db_encryption_key';
  static const _fileKeyStorageKey = 'file_encryption_key';
  static final _cipher = AesGcm.with256bits();

  static Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final argon2 = Argon2id(
      memory: 19456,
      iterations: 2,
      parallelism: 1,
      hashLength: 32,
    );
    return argon2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  /// Читає обидва ключі з secure storage поточного пристрою і шифрує їх
  /// паролем бекапу. Повертає готовий до запису у файл blob:
  /// [salt(16)][nonce(12)][ciphertext][mac(16)].
  static Future<Uint8List> wrapKeys(String passphrase) async {
    final dbKey = await _secureStorage.read(key: _dbKeyStorageKey);
    final fileKey = await _secureStorage.read(key: _fileKeyStorageKey);
    if (dbKey == null || fileKey == null) {
      throw StateError('Ключі шифрування не знайдено на цьому пристрої');
    }

    final envelope = utf8.encode(jsonEncode({'dbKey': dbKey, 'fileKey': fileKey}));

    final salt = _generateSalt();
    final key = await _deriveKey(passphrase, salt);
    final nonce = _cipher.newNonce();
    final box = await _cipher.encrypt(envelope, secretKey: key, nonce: nonce);

    return Uint8List.fromList([
      ...salt,
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// Обернена операція — розшифровує blob паролем бекапу і записує обидва
  /// ключі в secure storage ЦЬОГО пристрою (перезаписуючи наявні, якщо є —
  /// виклик відновлення завжди має бути свідомим рішенням користувача).
  /// Кидає виняток, якщо пароль невірний.
  static Future<void> unwrapAndInstallKeys(Uint8List blob, String passphrase) async {
    const saltLength = 16;
    const nonceLength = 12;
    const macLength = 16;
    if (blob.length < saltLength + nonceLength + macLength) {
      throw const FormatException('Файл резервної копії пошкоджений');
    }

    final salt = blob.sublist(0, saltLength);
    final nonce = blob.sublist(saltLength, saltLength + nonceLength);
    final mac = blob.sublist(blob.length - macLength);
    final cipherText = blob.sublist(saltLength + nonceLength, blob.length - macLength);

    final key = await _deriveKey(passphrase, salt);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plain = await _cipher.decrypt(box, secretKey: key);

    final envelope = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    await _secureStorage.write(key: _dbKeyStorageKey, value: envelope['dbKey'] as String);
    await _secureStorage.write(key: _fileKeyStorageKey, value: envelope['fileKey'] as String);
  }
}
