import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medkit/core/services/sync_crypto_service.dart';

void main() {
  test('encryptEntity then decryptEntity round-trips a JSON map', () async {
    final key = await AesGcm.with256bits().newSecretKey();
    final original = {'name': 'Парацетамол', 'doseAmount': 1.5, 'active': true};

    final blob = await SyncCryptoService.encryptEntity(key, original);
    final decrypted = await SyncCryptoService.decryptEntity(key, blob);

    expect(decrypted, equals(original));
  });

  test('decrypting with the wrong key throws', () async {
    final key1 = await AesGcm.with256bits().newSecretKey();
    final key2 = await AesGcm.with256bits().newSecretKey();
    final blob = await SyncCryptoService.encryptEntity(key1, {'a': 1});

    expect(() => SyncCryptoService.decryptEntity(key2, blob), throwsA(anything));
  });
}
