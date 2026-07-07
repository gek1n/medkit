import 'package:firebase_messaging/firebase_messaging.dart';

/// Отримання FCM push-токена цього пристрою — потрібен лише для реєстрації
/// в relay-каналі (`RelayApiClient.register`), щоб сервер знав, куди слати
/// "розбуди" пуш. Firebase тут використовується лише заради FCM — жодних
/// Firestore/Firebase Auth.
class PushTokenService {
  /// Повертає токен або null, якщо користувач не дав дозвіл (типово на iOS
  /// до першого запиту) чи Firebase не налаштований на цьому білді.
  static Future<String?> getToken() async {
    try {
      // На iOS getToken() поверне null, поки не дано дозвіл — на Android
      // цей виклик просто ні на що не впливає.
      await FirebaseMessaging.instance.requestPermission(alert: false, badge: false, sound: false);
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
