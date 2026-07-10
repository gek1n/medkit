import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class FamilyPeersRepository {
  final AppDatabase _db;
  FamilyPeersRepository(this._db);

  Stream<List<FamilyPeer>> watchAll() => _db.select(_db.familyPeers).watch();

  Future<List<FamilyPeer>> allPeers() => _db.select(_db.familyPeers).get();

  Future<FamilyPeer?> getByUuid(String personUuid) =>
      (_db.select(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid))).getSingleOrNull();

  Future<void> upsert(FamilyPeersCompanion peer) =>
      _db.into(_db.familyPeers).insertOnConflictUpdate(peer);

  Future<void> updateLastSynced(String personUuid, DateTime at) =>
      (_db.update(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid)))
          .write(FamilyPeersCompanion(lastSyncedAt: Value(at)));

  Future<void> delete(String personUuid) =>
      (_db.delete(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid))).go();

  Future<void> addPendingInvite(PendingGroupInvitesCompanion invite) =>
      _db.into(_db.pendingGroupInvites).insert(invite);

  Future<List<PendingGroupInvite>> pendingInvites() => _db.select(_db.pendingGroupInvites).get();

  Future<void> removePendingInvite(String channelId) =>
      (_db.delete(_db.pendingGroupInvites)..where((t) => t.channelId.equals(channelId))).go();

  // ── Дані, отримані від пірів (Фаза 4, read-only) ────────────────────────

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
  /// [FamilyPeerSyncService.syncAllPeers]), тож безпечно й потрібно чистити
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
