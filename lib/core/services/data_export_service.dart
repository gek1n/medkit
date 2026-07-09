import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/db/app_database.dart';

/// GDPR-експорт (право на доступ/портативність, ст. 15/20) — на відміну від
/// "Резервної копії" (`BackupService`, зашифрований blob, читається лише
/// самим MedKit), тут дані виходять у читабельному JSON, який користувач
/// може відкрити будь-де і передати кому завгодно.
///
/// ⚠️ Свідоме обмеження: фото ліків НЕ включені (вони зашифровані окремим
/// ключем на диску й роздули б файл) — лише структуровані дані з БД. Якщо
/// колись знадобиться — фото вже є в "Резервній копії".
/// `SharedChannels` теж не включена — це внутрішній технічний стан
/// пейрингу/синку (id каналів), а не дані користувача про себе чи сім'ю.
class DataExportService {
  final AppDatabase _db;

  DataExportService(this._db);

  Future<Map<String, dynamic>> _collectAll() async {
    Future<List<Map<String, dynamic>>> dump<T extends Table, D>(
      TableInfo<T, D> table,
      Map<String, dynamic> Function(D) toJsonOf,
    ) async {
      final rows = await _db.select(table).get();
      return rows.map(toJsonOf).toList();
    }

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'members': await dump(_db.members, (r) => r.toJson()),
      'medications': await dump(_db.medications, (r) => r.toJson()),
      'schedules': await dump(_db.schedules, (r) => r.toJson()),
      'intakes': await dump(_db.intakes, (r) => r.toJson()),
      'symptoms': await dump(_db.symptoms, (r) => r.toJson()),
      'wellbeingLogs': await dump(_db.wellbeingLogs, (r) => r.toJson()),
      'wellbeingSchedules': await dump(_db.wellbeingSchedules, (r) => r.toJson()),
      'activities': await dump(_db.activities, (r) => r.toJson()),
      'activitySlots': await dump(_db.activitySlots, (r) => r.toJson()),
      'activityLogs': await dump(_db.activityLogs, (r) => r.toJson()),
      'doctorAppointments': await dump(_db.doctorAppointments, (r) => r.toJson()),
    };
  }

  /// Будує JSON-файл у тимчасовій директорії і повертає шлях до нього —
  /// готовий для `Share.shareXFiles`.
  Future<File> buildExportFile() async {
    final data = await _collectAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File(p.join(dir.path, 'medkit_export_$stamp.json'));
    return file.writeAsString(json);
  }
}
