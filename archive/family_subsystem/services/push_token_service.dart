import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import 'app_logger.dart';

/// Отримання FCM push-токена цього пристрою — потрібен лише для реєстрації
/// в relay-каналі (`RelayApiClient.register`), щоб сервер знав, куди слати
/// "розбуди" пуш. Firebase тут використовується лише заради FCM — жодних
/// Firestore/Firebase Auth.
class PushTokenService {
  static const _nativeChannel = MethodChannel('com.ellyapp.medkit/apns_debug');
  static bool _nativeDiagnosticsInstalled = false;

  /// Слухає підтвердження від AppDelegate.swift, що ОС реально викликала
  /// `didRegisterForRemoteNotificationsWithDeviceToken` — незалежно від
  /// того, чи вдалось Firebase-плагіну підхопити цей токен зі свого боку.
  /// Дозволяє відрізнити в логах "ОС взагалі не видає токен" від "ОС видає,
  /// але Dart-сторона (getAPNSToken) його не бачить". Викликати раз при
  /// старті застосунку, після Firebase.initializeApp().
  static void installNativeDiagnostics() {
    if (!Platform.isIOS || _nativeDiagnosticsInstalled) return;
    _nativeDiagnosticsInstalled = true;
    _nativeChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'nativeApnsTokenRegistered':
          final hex = call.arguments as String? ?? '';
          final fingerprint = hex.length >= 8 ? hex.substring(0, 8) : hex;
          AppLogger.log(
              'AppDelegate(native): didRegisterForRemoteNotificationsWithDeviceToken FIRED, len=${hex.length} fingerprint=$fingerprint');
          break;
        case 'nativeApnsTokenFailed':
          AppLogger.log(
              'AppDelegate(native): didFailToRegisterForRemoteNotificationsWithError: ${call.arguments}');
          break;
      }
    });
  }

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
        AppLogger.log(
            'PushTokenService.getToken: APNs token OBTAINED after $attempts retries, len=${apnsToken.length}');
      }
      final fcmToken = await FirebaseMessaging.instance.getToken();
      AppLogger.log(
          'PushTokenService.getToken: FCM token ${fcmToken == null ? "NULL" : "obtained, len=${fcmToken.length}"}');
      return fcmToken;
    } catch (e, st) {
      AppLogger.logError('PushTokenService.getToken', e, st);
      return null;
    }
  }
}
