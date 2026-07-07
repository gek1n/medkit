import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medkit/core/services/account_service.dart';

void main() {
  test('generateRecoveryKey produces expected format', () {
    final key = AccountService.generateRecoveryKey();
    final groups = key.split('-');
    expect(groups.length, 6);
    for (final g in groups) {
      expect(g.length, 4);
    }
  });

  test('normalize strips separators and uppercases', () {
    expect(AccountService.normalize('abcd-1234-efgh'), 'ABCD1234EFGH');
    expect(AccountService.normalize('  abCD 1234 '), 'ABCD1234');
  });

  test('two different recovery keys derive different HMAC-based sync keys', () async {
    Future<List<int>> deriveKey(String normalized) async {
      final mac = await Hmac.sha256().calculateMac(
        utf8.encode('medkit-sync-encryption-key-v1'),
        secretKey: SecretKey(utf8.encode(normalized)),
      );
      return mac.bytes;
    }

    final keyA = await deriveKey(AccountService.normalize(AccountService.generateRecoveryKey()));
    final keyB = await deriveKey(AccountService.normalize(AccountService.generateRecoveryKey()));

    expect(keyA.length, 32);
    expect(keyA, isNot(equals(keyB)));
  });

  test('same recovery key derives the same sync key deterministically', () async {
    Future<List<int>> deriveKey(String normalized) async {
      final mac = await Hmac.sha256().calculateMac(
        utf8.encode('medkit-sync-encryption-key-v1'),
        secretKey: SecretKey(utf8.encode(normalized)),
      );
      return mac.bytes;
    }

    final normalized = AccountService.normalize('WXYZ-1234-ABCD-5678-EFGH-9999');
    final key1 = await deriveKey(normalized);
    final key2 = await deriveKey(normalized);
    expect(key1, equals(key2));
  });
}
