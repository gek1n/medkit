import 'package:permission_handler/permission_handler.dart';

/// Android після "не питати знову" і iOS після першої відмови більше не
/// показують системний діалог дозволу на камеру — повторний запит буде
/// миттєво (і мовчки) відхилений ОС. У цьому випадку єдиний робочий шлях —
/// відкрити системні налаштування застосунку, де користувач вмикає камеру
/// вручну (`openAppSettings()` сам показує правильний екран для Android/iOS).
class CameraPermissionService {
  /// Для екранів, що самі керують запитом дозволу (напр. `image_picker`) —
  /// перевіряє і за потреби відкриває налаштування, інакше просить дозвіл сам.
  static Future<bool> ensureGranted() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return false;
    }
    final result = await Permission.camera.request();
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return result.isGranted;
  }

  /// Для екранів, де запит дозволу робить сам нативний віджет (напр.
  /// `MobileScanner` при монтуванні) — лише перевіряє, чи є сенс взагалі
  /// пробувати, і за потреби одразу відкриває налаштування замість marної
  /// спроби, яку ОС однаково мовчки відхилить.
  static Future<bool> openSettingsIfPermanentlyDenied() async {
    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return true;
    }
    return false;
  }
}
