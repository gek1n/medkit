import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Пакує ВЕСЬ secure storage пристрою (не лише ключі шифрування БД/файлів,
/// а й обліковий запис синхронізації з AccountService, і per-канальні ключі
/// SharedChannelKeyStorage для сімейної синхронізації) в один маленький blob,
/// захищений паролем бекапу (Argon2id -> AES-256-GCM, той самий підхід, що і
/// в `pairing_crypto_service.dart`). Сам бекап (medkit.db + med_photos/) вже
/// зашифрований ключами звідси на диску — хмара (Google Drive/iCloud) ніколи
/// не бачить plaintext, а без пароля бекапу нічого з архіву не витягнути,
/// навіть маючи повний доступ до хмарного сховища.
///
/// Навмисно readAll(), а не список конкретних ключів — так відновлення
/// лишається повним автоматично і для розділів, доданих ПІСЛЯ написання
/// цього файлу (будь-що нове, що зберігається через secure storage, саме
/// потрапить у бекап без окремої правки тут).
class BackupCryptoService {
  static const _secureStorage = FlutterSecureStorage();
  static const _syncedIOSOptions = IOSOptions(synchronizable: true);
  // Ключі AccountService навмисно пишуться з synchronizable:true (iCloud
  // Keychain) — readAll() з дефолтними опціями на iOS їх не бачить, тож
  // читаємо/пишемо і цю групу окремо, щоб жодного значення не загубити.
  static const _syncedKeyNames = {
    'sync_mode',
    'sync_account_id',
    'sync_encryption_key',
    'sync_recovery_key_hash',
  };
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

  /// Читає УВЕСЬ secure storage поточного пристрою (ключі шифрування БД/
  /// файлів, обліковий запис синхронізації, канальні ключі сімейної
  /// синхронізації — і будь-що додане пізніше) і шифрує паролем бекапу.
  /// Повертає готовий до запису у файл blob: [salt(16)][nonce(12)][ciphertext][mac(16)].
  static Future<Uint8List> wrapKeys(String passphrase) async {
    final entries = <String, String>{
      ...await _secureStorage.readAll(),
      ...await _secureStorage.readAll(iOptions: _syncedIOSOptions),
    };
    if (entries.isEmpty) {
      throw StateError('Ключі шифрування не знайдено на цьому пристрої');
    }

    final envelope = utf8.encode(jsonEncode(entries));

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

  /// Обернена операція — розшифровує blob паролем бекапу і записує усі
  /// значення в secure storage ЦЬОГО пристрою (перезаписуючи наявні, якщо є —
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
    for (final entry in envelope.entries) {
      final synced = _syncedKeyNames.contains(entry.key);
      await _secureStorage.write(
        key: entry.key,
        value: entry.value as String,
        iOptions: synced ? _syncedIOSOptions : const IOSOptions(),
      );
    }
  }
}
