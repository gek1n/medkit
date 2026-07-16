/// Компіляційний (не рантайм!) прапорець, що відрізняє тестову/QA-збірку
/// (TestFlight-збірка для команди, внутрішній Android APK) від справжньої
/// продакшн-збірки, яка йде в App Store/Google Play.
///
/// ⚠️ МУСИТЬ лишатись `bool.fromEnvironment` (const, вирішується під час
/// компіляції) — НЕ SharedPreferences/рантайм-перемикач. Це гарантує, що:
/// (1) нічого всередині вже встановленого застосунку не може сам себе
/// переключити в тестовий режим; (2) забутий прапорець за замовчуванням
/// дає БЕЗПЕЧНУ (продакшн) поведінку, а не випадково протікає тестовий
/// білінг/логування в реліз-збірку.
///
/// Використання:
///   flutter run --dart-define=APP_TEST_BUILD=true
///   flutter build ipa --release --dart-define=APP_TEST_BUILD=true      # TestFlight
///   flutter build apk --release --dart-define=APP_TEST_BUILD=true      # внутрішній тест APK
///   flutter build ipa --release                                        # App Store — БЕЗ прапорця
///   flutter build appbundle --release                                  # Google Play — БЕЗ прапорця
class AppEnv {
  AppEnv._();

  static const bool isTestBuild =
      bool.fromEnvironment('APP_TEST_BUILD', defaultValue: false);
}
