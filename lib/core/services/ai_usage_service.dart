import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../providers/database_provider.dart';

/// Ліміт безкоштовних викликів хмарних AI-функцій (Free-план): скан рецепта
/// за фото і голосові команди рахуються окремо. Лічильники — назавжди
/// (не скидаються щомісяця). Живуть у самій БД (один рядок, id=0), а не в
/// SharedPreferences — навмисно: SharedPreferences НЕ потрапляє в резервну
/// копію, тож видалення застосунку + відновлення бекапу мовчки давало б
/// безкоштовні спроби заново, хоча решта даних відновлювалась би коректно.
/// Платні плани (`AppPlan.plus`/`family`) не викликають ці перевірки —
/// обмеження застосовується лише з боку виклику (див. `AddMedicationScreen`).
class AiUsageService {
  final AppDatabase _db;
  AiUsageService(this._db);

  static const photoScanLimit = 3;
  static const voiceCommandLimit = 5;

  static const _rowId = 0;

  Future<AiUsageData> _row() async {
    final row = await (_db.select(_db.aiUsage)..where((t) => t.id.equals(_rowId)))
        .getSingleOrNull();
    return row ??
        AiUsageData(id: _rowId, photoScansUsed: 0, voiceCommandsUsed: 0);
  }

  Future<int> getPhotoScansUsed() async => (await _row()).photoScansUsed;

  Future<bool> canPhotoScan() async =>
      (await getPhotoScansUsed()) < photoScanLimit;

  Future<void> recordPhotoScan() async {
    final row = await _row();
    await _db.into(_db.aiUsage).insertOnConflictUpdate(AiUsageCompanion(
          id: const Value(_rowId),
          photoScansUsed: Value(row.photoScansUsed + 1),
          voiceCommandsUsed: Value(row.voiceCommandsUsed),
        ));
  }

  Future<int> getVoiceCommandsUsed() async => (await _row()).voiceCommandsUsed;

  Future<bool> canUseVoiceCommand() async =>
      (await getVoiceCommandsUsed()) < voiceCommandLimit;

  Future<void> recordVoiceCommand() async {
    final row = await _row();
    await _db.into(_db.aiUsage).insertOnConflictUpdate(AiUsageCompanion(
          id: const Value(_rowId),
          photoScansUsed: Value(row.photoScansUsed),
          voiceCommandsUsed: Value(row.voiceCommandsUsed + 1),
        ));
  }
}

final aiUsageServiceProvider = Provider<AiUsageService>((ref) {
  return AiUsageService(ref.watch(databaseProvider));
});
