import 'package:shared_preferences/shared_preferences.dart';

/// Ліміт безкоштовних викликів хмарних AI-функцій (Free-план): скан рецепта
/// за фото і голосові команди рахуються окремо. Лічильники — назавжди
/// (не скидаються щомісяця), зберігаються тільки локально. Платні плани
/// (`AppPlan.care`/`family`) не викликають ці перевірки — обмеження
/// застосовується лише з боку виклику (див. `AddMedicationScreen._ScanCta`).
class AiUsageService {
  static const _photoScansKey = 'ai_usage_photo_scans';
  static const _voiceCommandsKey = 'ai_usage_voice_commands';

  static const photoScanLimit = 3;
  static const voiceCommandLimit = 5;

  static Future<int> getPhotoScansUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_photoScansKey) ?? 0;
  }

  static Future<bool> canPhotoScan() async =>
      (await getPhotoScansUsed()) < photoScanLimit;

  static Future<void> recordPhotoScan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_photoScansKey, (await getPhotoScansUsed()) + 1);
  }

  static Future<int> getVoiceCommandsUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_voiceCommandsKey) ?? 0;
  }

  static Future<bool> canUseVoiceCommand() async =>
      (await getVoiceCommandsUsed()) < voiceCommandLimit;

  static Future<void> recordVoiceCommand() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _voiceCommandsKey, (await getVoiceCommandsUsed()) + 1);
  }
}
