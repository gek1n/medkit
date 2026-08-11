import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// X25519-ідентичність пристрою для сімейних каналів (Крок 11, уточнення
/// 11.08) — замінює всю relay-based "представлення" механіку архівної
/// системи (`FamilyGroupService.introduceNewPeer`/`known_member`/
/// `request_introduction`/`introduction`). Публічний ключ НЕ секрет —
/// публікується на сервері разом із профілем у сім'ї (`FamilyApiClient.
/// create`/`join`, повертається всім у `/family/status`). Приватний ключ
/// ніколи нікуди не передається.
///
/// Будь-які два активні учасники сім'ї, знаючи account_id+public_key одне
/// одного (обидва вже безкоштовно приходять у status()), НЕЗАЛЕЖНО
/// обчислюють ОДИН і той самий канал (`deterministicChannelId` у
/// `family_server_sync_service.dart`) і ОДИН і той самий симетричний ключ
/// шифрування (через ECDH, [sharedChannelKey] нижче) — без жодного
/// релею/запиту-відповіді. Це прибирає весь клас багів 04.08/10.08
/// (star-topology hub-relay "представлення" одне одному).
class FamilyKeyService {
  static const _storage = FlutterSecureStorage();
  static const _syncedIOSOptions = IOSOptions(synchronizable: true);
  static const _privateKeyKey = 'family_x25519_private_key';
  static const _publicKeyKey = 'family_x25519_public_key';
  static final _algorithm = X25519();

  /// Ідемпотентно — генерує пару лише якщо на цьому пристрої (чи, на iOS,
  /// у Keychain, синхронізованому через той самий Apple ID) її ще немає.
  /// Стабільна ідентичність необхідна: якби пара змінювалась між
  /// сесіями, channel_id/ключ, обчислені іншою стороною раніше, перестали
  /// б збігатися з тим, що обчислює цей пристрій зараз.
  static Future<SimpleKeyPair> _ensureKeyPair() async {
    final existingPrivB64 = await _storage.read(key: _privateKeyKey, iOptions: _syncedIOSOptions);
    if (existingPrivB64 != null) {
      final privBytes = base64Decode(existingPrivB64);
      return _algorithm.newKeyPairFromSeed(privBytes);
    }
    final keyPair = await _algorithm.newKeyPair();
    final privBytes = await keyPair.extractPrivateKeyBytes();
    final pubKey = await keyPair.extractPublicKey();
    await _storage.write(key: _privateKeyKey, value: base64Encode(privBytes), iOptions: _syncedIOSOptions);
    await _storage.write(key: _publicKeyKey, value: _toHex(pubKey.bytes), iOptions: _syncedIOSOptions);
    return keyPair;
  }

  /// Публічний ключ, hex-кодований (64 символи) — саме це поле передається
  /// в `FamilyApiClient.create`/`join` як `public_key`.
  static Future<String> publicKeyHex() async {
    final cached = await _storage.read(key: _publicKeyKey, iOptions: _syncedIOSOptions);
    if (cached != null) return cached;
    final keyPair = await _ensureKeyPair();
    final pub = await keyPair.extractPublicKey();
    final hexStr = _toHex(pub.bytes);
    await _storage.write(key: _publicKeyKey, value: hexStr, iOptions: _syncedIOSOptions);
    return hexStr;
  }

  /// ECDH: спільний симетричний ключ із конкретним іншим учасником —
  /// детермінований, обчислюється наживо щоразу (не кешується локально —
  /// дешевше й безпечніше, ніж зберігати ключ на кожен канал окремо, як
  /// робив архівний `SharedChannelKeyStorage`).
  static Future<SecretKey> sharedChannelKey(String counterpartPublicKeyHex) async {
    final keyPair = await _ensureKeyPair();
    final counterpartPublicKey = SimplePublicKey(_fromHex(counterpartPublicKeyHex), type: KeyPairType.x25519);
    return _algorithm.sharedSecretKey(keyPair: keyPair, remotePublicKey: counterpartPublicKey);
  }

  static String _toHex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _fromHex(String hexStr) {
    final result = <int>[];
    for (var i = 0; i < hexStr.length; i += 2) {
      result.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
