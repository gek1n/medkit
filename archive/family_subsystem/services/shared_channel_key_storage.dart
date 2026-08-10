import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ключ шифрування family_sync для одного каналу пейрингу — генерується
/// інвайтером при створенні запрошення, передається всередині вже
/// зашифрованого pairing-envelope (`PairingCryptoService`), і зберігається
/// тут окремо на кожному пристрої. Сервер його ніколи не бачить.
class SharedChannelKeyStorage {
  static const _storage = FlutterSecureStorage();

  static String _keyName(String channelId) => 'shared_sync_key_$channelId';

  static Future<void> store(String channelId, List<int> keyBytes) =>
      _storage.write(key: _keyName(channelId), value: base64Encode(keyBytes));

  static Future<List<int>?> read(String channelId) async {
    final b64 = await _storage.read(key: _keyName(channelId));
    if (b64 == null) return null;
    return base64Decode(b64);
  }

  static Future<void> delete(String channelId) => _storage.delete(key: _keyName(channelId));
}
