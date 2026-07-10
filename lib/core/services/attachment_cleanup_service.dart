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
  static Future<void> deleteAllForMember(AppDatabase db, int memberId) async {
    final medications = await (db.select(db.medications)..where((t) => t.memberId.equals(memberId))).get();
    for (final m in medications) {
      await deletePaths(m.photoPaths);
    }
    final appointments =
        await (db.select(db.doctorAppointments)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in appointments) {
      await deletePaths(a.documentPaths);
    }
    final labResults = await (db.select(db.labResults)..where((t) => t.memberId.equals(memberId))).get();
    for (final l in labResults) {
      await deletePaths(l.documentPaths);
    }
    final allergies = await (db.select(db.allergies)..where((t) => t.memberId.equals(memberId))).get();
    for (final a in allergies) {
      await deletePaths(a.documentPaths);
    }
    final conditions = await (db.select(db.chronicConditions)..where((t) => t.memberId.equals(memberId))).get();
    for (final c in conditions) {
      await deletePaths(c.documentPaths);
    }
    final vaccinations = await (db.select(db.vaccinations)..where((t) => t.memberId.equals(memberId))).get();
    for (final v in vaccinations) {
      await deletePaths(v.documentPaths);
    }
    final surgeries = await (db.select(db.surgeries)..where((t) => t.memberId.equals(memberId))).get();
    for (final s in surgeries) {
      await deletePaths(s.documentPaths);
    }
  }
}
