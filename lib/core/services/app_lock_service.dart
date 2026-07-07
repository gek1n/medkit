import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Розблокування застосунку біометрією/паролем пристрою — додатковий шар
/// захисту над ключем шифрування БД (сам ключ і так у Keychain/Keystore,
/// це саме про "не дати відкрити застосунок з розблокованого телефону,
/// залишеного на столі").
class AppLockService {
  static final _auth = LocalAuthentication();

  /// true — або користувач успішно підтвердив особу, або на пристрої взагалі
  /// не налаштовано жодного способу автентифікації (немає біометрії й не
  /// заданий PIN/патерн/пароль) — у такому разі блокувати нічим, і застосунок
  /// не повинен назавжди замикати користувача поза собою.
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Підтвердіть, що це ви, щоб відкрити MedKit',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
