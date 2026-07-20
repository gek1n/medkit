import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medkit_db_key_storage/medkit_db_key_storage.dart';

/// Шифрує вкладення (фото ліків, у майбутньому — фото/PDF медкартки, войс-
/// нотатки) окремим ключем від БД, щоб на диску ніколи не лежав plaintext.
/// AES-256-GCM: свіжий nonce на кожен файл, тег автентичності перевіряє
/// цілісність при розшифровці.
///
/// Ключ живе в тому самому нативному сховищі (`medkit_db_key_storage`), що й
/// ключ шифрування БД (`DbEncryptionService`) — під окремим `account`, щоб не
/// перетнутись. Спочатку цей ключ жив лише у flutter_secure_storage, як і
/// ключ БД до свого переходу — той самий клас багів (дублікати записів у
/// Keychain через розсинхрон атрибутів між write-викликами різних
/// версій/збірок застосунку) теоретично міг зачепити і цей ключ так само,
/// навіть якщо жодного підтвердженого інциденту саме з фото ще не було.
/// `_legacySecureStorage` лишається ЛИШЕ як одноразове джерело міграції для
/// пристроїв, де ключ ще лежить у старому місці — нових записів туди більше
/// ніколи не робимо.
class FileEncryptionService {
  static const _legacySecureStorage = FlutterSecureStorage();
  static const _legacyKeyStorageKey = 'file_encryption_key';
  static const _nativeAccount = 'file_encryption_key';
  static final _algorithm = AesGcm.with256bits();

  static Future<SecretKey> _getOrCreateKey() async {
    final fromNative = await MedkitDbKeyStorage.read(account: _nativeAccount);
    if (fromNative != null && fromNative.isNotEmpty) {
      return SecretKey(base64Decode(fromNative));
    }

    final fromLegacy =
        await _legacySecureStorage.read(key: _legacyKeyStorageKey);
    if (fromLegacy != null && fromLegacy.isNotEmpty) {
      // Одноразова міграція — наступний виклик уже піде через гілку
      // fromNative вище. Стару копію навмисно не видаляємо (та сама логіка,
      // що й у DbEncryptionService._migrateLegacyKey — аварійний запасний
      // варіант, дублювання нешкідливе).
      await MedkitDbKeyStorage.write(fromLegacy, account: _nativeAccount);
      return SecretKey(base64Decode(fromLegacy));
    }

    final key = await _algorithm.newSecretKey();
    final bytes = await key.extractBytes();
    await MedkitDbKeyStorage.write(base64Encode(bytes), account: _nativeAccount);
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
    final fromNative = await MedkitDbKeyStorage.read(account: _nativeAccount);
    if (fromNative != null && fromNative.isNotEmpty) return true;
    final fromLegacy =
        await _legacySecureStorage.read(key: _legacyKeyStorageKey);
    return fromLegacy != null && fromLegacy.isNotEmpty;
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
    await MedkitDbKeyStorage.write(
      base64Encode(keyBytes),
      account: _nativeAccount,
    );
  }

  /// Read-only доступ до поточного ключа для `BackupCryptoService.wrapKeys()`
  /// — той самий трюк, що і `DbEncryptionService.currentKeyForBackup()`:
  /// readAll() у BackupCryptoService бачить лише flutter_secure_storage, а
  /// це сховище тепер нативне й повністю окреме, тож без явного виклику тут
  /// ключ шифрування фото мовчки випав би з резервної копії.
  static Future<String?> currentKeyForBackup() async {
    final fromNative = await MedkitDbKeyStorage.read(account: _nativeAccount);
    if (fromNative != null && fromNative.isNotEmpty) return fromNative;
    final fromLegacy =
        await _legacySecureStorage.read(key: _legacyKeyStorageKey);
    return (fromLegacy != null && fromLegacy.isNotEmpty) ? fromLegacy : null;
  }
}
