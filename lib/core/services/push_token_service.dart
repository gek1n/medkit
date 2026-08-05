import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_logger.dart';

/// Отримання FCM push-токена цього пристрою — потрібен лише для реєстрації
/// в relay-каналі (`RelayApiClient.register`), щоб сервер знав, куди слати
/// "розбуди" пуш. Firebase тут використовується лише заради FCM — жодних
/// Firestore/Firebase Auth.
class PushTokenService {
  /// Повертає токен або null, якщо користувач не дав дозвіл (типово на iOS
  /// до першого запиту) чи Firebase не налаштований на цьому білді.
  static Future<String?> getToken() async {
    try {
      final settings = await FirebaseMessaging.instance
          .requestPermission(alert: false, badge: false, sound: false);
      // Тимчасове діагностичне логування (баг: APNs token лишається null
      // навіть після entitlements/capability фіксів, підтверджених у
      // Xcode/Apple Developer Portal) — без кабелю немає доступу до живого
      // Console.app/apsd-логів пристрою, тож перевіряємо тут єдине, що
      // могло б пояснити стабільний null БЕЗ жодного стосунку до
      // entitlements: чи authorizationStatus взагалі authorized (не
      // notDetermined/provisional) — якщо дозвіл фактично не наданий, iOS
      // ніколи не видасть APNs-токен, скільки не чекай.
      AppLogger.log(
          'PushTokenService.getToken: authorizationStatus=${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.log('PushTokenService.getToken: SKIPPED (permission denied)');
        return null;
      }
      if (Platform.isIOS) {
        // На iOS FCM getToken() кидає "apns-token-not-set", якщо звернутись
        // до нього до того, як ОС встигла видати APNs-токен Firebase'у — це
        // відбувається з невеликою затримкою після requestPermission(),
        // не миттєво. Без цього очікування getToken() на iOS падає майже
        // щоразу при першому запуску, і catch нижче тихо перетворював це на
        // null — реальні дані з relay_channels підтвердили: реєстрації
        // приходили ЛИШЕ з Android, жодної з iOS.
        var apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        var attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          attempts++;
        }
        if (apnsToken == null) {
          AppLogger.log('PushTokenService.getToken: APNs token still null after retries');
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e, st) {
      AppLogger.logError('PushTokenService.getToken', e, st);
      return null;
    }
  }
}
