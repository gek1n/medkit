import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medkit/core/services/pairing_crypto_service.dart';

void main() {
  test('encrypt then decrypt with the correct code returns original bytes', () async {
    final plain = utf8.encode('{"deviceName":"iPhone","memberId":"abc-123"}');
    final code = PairingCryptoService.generateCode();

    final result = await PairingCryptoService.encrypt(code, plain);
    final decrypted = await PairingCryptoService.decrypt(
      code,
      salt: result.salt,
      nonce: result.nonce,
      cipherTextAndMac: result.ciphertext,
    );

    expect(decrypted, equals(plain));
  });

  test('decrypt with the wrong code throws', () async {
    final plain = utf8.encode('secret payload');
    final code = PairingCryptoService.generateCode();
    final result = await PairingCryptoService.encrypt(code, plain);

    expect(
      () => PairingCryptoService.decrypt(
        PairingCryptoService.generateCode(),
        salt: result.salt,
        nonce: result.nonce,
        cipherTextAndMac: result.ciphertext,
      ),
      throwsA(anything),
    );
  });

  test('codeHash is deterministic for the same code', () {
    final code = PairingCryptoService.generateCode();
    expect(PairingCryptoService.codeHash(code), equals(PairingCryptoService.codeHash(code)));
  });
}
