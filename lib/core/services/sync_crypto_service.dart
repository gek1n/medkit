import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Шифрування/розшифровка окремих рядків (member/medication/...) для
/// синхронізації з сервером. Той самий підхід, що і в
/// `file_encryption_service.dart` (AES-256-GCM, свіжий nonce на кожен блок):
/// [nonce(12)][ciphertext][mac(16)]. Ключ сюди передається ззовні
/// (`AccountService` відповідає за те, де і як він зберігається) — цей
/// сервіс лише шифрує/розшифровує, без побічної відповідальності за ключі.
class SyncCryptoService {
  static final _algorithm = AesGcm.with256bits();

  /// [entityJson] — звичайна Map, яку зазвичай отримують із
  /// `Medication.toJson()`/`Member.toJson()`/тощо (через Drift-генерований
  /// `toJson()` на рядку таблиці).
  static Future<Uint8List> encryptEntity(SecretKey key, Map<String, dynamic> entityJson) async {
    final plainBytes = utf8.encode(jsonEncode(entityJson));
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(plainBytes, secretKey: key, nonce: nonce);
    return Uint8List.fromList([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  static Future<Map<String, dynamic>> decryptEntity(SecretKey key, List<int> blob) async {
    const nonceLength = 12;
    const macLength = 16;
    if (blob.length < nonceLength + macLength) {
      throw const FormatException('Зашифрована сутність пошкоджена (замалий розмір)');
    }

    final nonce = blob.sublist(0, nonceLength);
    final mac = blob.sublist(blob.length - macLength);
    final cipherText = blob.sublist(nonceLength, blob.length - macLength);

    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plain = await _algorithm.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }
}
