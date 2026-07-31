import 'dart:convert';

import '../../data/db/app_database.dart';
import 'photo_service.dart';

/// Централізоване видалення прикріплених файлів (фото/PDF) — щоб видалення
/// запису медкартки чи цілого профілю не лишало осиротілі зашифровані файли
/// в `med_photos/` назавжди. Раніше жоден `_delete()` цього не робив: рядок
/// зникав з БД, а файл на диску лишався невидимим ні для UI, ні для GDPR
/// "право на забуття".
abstract final class AttachmentCleanupService {
  /// Видалити всі файли з JSON-списку documentPaths/photoPaths одного
  /// запису. Викликати ДО видалення самого рядка з БД.
  static Future<void> deletePaths(String pathsJson) async {
    List<String> paths;
    try {
      paths = List<String>.from(jsonDecode(pathsJson) as List);
    } catch (_) {
      return; // пошкоджений/порожній JSON — нічого видаляти
    }
    for (final path in paths) {
      try {
        await PhotoService.delete(path);
      } catch (_) {
        // Файл міг вже бути видалений раніше — не блокуємо видалення запису.
      }
    }
  }

  /// Викликати ДО видалення члена сім'ї (MembersRepository.delete) — FK
  /// каскад видаляє всі його рядки одразу після цього, тож шляхи до файлів
  /// треба зібрати, поки рядки ще існують.
  ///
  /// ⚠️ НЕ звертатись тут до labResults/allergies/chronicConditions/
  /// vaccinations/surgeries — ці таблиці фізично дропнуті (onCreate і
  /// міграція 30, див. app_database.dart) для АБСОЛЮТНО всіх пристроїв,
  /// і нових, і оновлених. Запит до неіснуючої таблиці кидав SqliteException
  /// ще до реального видалення профілю — саме тому видалення члена сім'ї
  /// не працювало взагалі ні для кого.
  static Future<void> deleteAllForMember(AppDatabase db, int memberId) async {
    final medications = await (db.select(db.medications)..where((t) => t.memberId.equals(memberId))).get();
    for (final m in medications) {
      await deletePaths(m.photoPaths);
    }
    final appointments =
        await (db.select(db.reminders)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in appointments) {
      await deletePaths(a.documentPaths);
    }
    final entries = await (db.select(db.medcardEntries)..where((t) => t.memberId.equals(memberId))).get();
    for (final e in entries) {
      await deletePaths(e.documentPaths);
    }
  }
}
