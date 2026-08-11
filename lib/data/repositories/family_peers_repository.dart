import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

/// Крок 11: цей репозиторій тепер обслуговує лише "чужий кеш" (SharedSubjects/
/// SharedEntities) і FamilyGrants-повʼязані видалення — вся бухгалтерія
/// каналів/запрошень старої relay-моделі (FamilyPeers/PendingGroupInvites/
/// KnownFamilyMembers-специфічні методи) з архівної версії свідомо НЕ
/// перенесена: `FamilyServerSyncService` більше не тримає локальний
/// per-peer Drift-рядок для бухгалтерії синку (курсор — один глобальний
/// SharedPreferences-ключ), а членство/канали читаються наживо з
/// `/family/status`. Самі таблиці (FamilyPeers тощо) лишаються в схемі
/// незайманими (Крок 10 рішення не займати міграції) — просто без
/// репозиторних методів під них тут, поки не з'явиться реальна потреба
/// (напр. локальний UI-кеш "Сім'я" екрана, Крок 11 C5).
class FamilyPeersRepository {
  final AppDatabase _db;
  FamilyPeersRepository(this._db);

  // ── Дані, отримані від інших учасників сім'ї (read-only кеш) ────────────

  Stream<List<SharedSubject>> watchSharedSubjects() => _db.select(_db.sharedSubjects).watch();

  Future<void> upsertSharedSubject(SharedSubjectsCompanion subject) =>
      _db.into(_db.sharedSubjects).insertOnConflictUpdate(subject);

  Future<void> deleteSharedSubjectsForChannel(String channelId) =>
      (_db.delete(_db.sharedSubjects)..where((t) => t.peerChannelId.equals(channelId))).go();

  Stream<List<SharedEntity>> watchSharedEntities(String subjectPersonUuid) =>
      (_db.select(_db.sharedEntities)..where((t) => t.subjectPersonUuid.equals(subjectPersonUuid))).watch();

  Future<void> upsertSharedEntity(SharedEntitiesCompanion entity) =>
      _db.into(_db.sharedEntities).insertOnConflictUpdate(entity);

  Future<void> deleteSharedEntity(String uuid) =>
      (_db.delete(_db.sharedEntities)..where((t) => t.uuid.equals(uuid))).go();

  Future<void> deleteSharedEntitiesForSubjects(List<String> subjectPersonUuids) =>
      (_db.delete(_db.sharedEntities)..where((t) => t.subjectPersonUuid.isIn(subjectPersonUuids))).go();

  /// Викликати на холодному старті ДО першого синку — SharedSubjects/
  /// SharedEntities це чистий похідний кеш (перевипускається кожним раундом
  /// [FamilyServerSyncService.syncAll]), тож безпечно й потрібно чистити
  /// його щоразу: інакше застаріла версія (напр. з відновленого бекапу,
  /// зробленого до того, як хтось відкликав доступ) могла б пережити
  /// відновлення й показувати вже недійсні "чужі" дані аж до наступного
  /// вдалого раунду синку.
  Future<void> clearSharedCache() async {
    await _db.delete(_db.sharedSubjects).go();
    await _db.delete(_db.sharedEntities).go();
  }
}

final familyPeersRepositoryProvider = Provider<FamilyPeersRepository>((ref) {
  return FamilyPeersRepository(ref.watch(databaseProvider));
});
