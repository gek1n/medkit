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

  /// Що САМ цей пір дозволив мені (+ чи активна його Family-підписка, якщо
  /// саме він мій прямий інвайтер) — прилітає через grants_summary при
  /// кожному синку (FamilyGrants живе лише на пристрої субʼєкта).
  Future<void> updateGrantedToMe(
    String personUuid, {
    required bool notify,
    required bool view,
    required bool edit,
    required bool payerPlanActive,
  }) =>
      (_db.update(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid))).write(
        FamilyPeersCompanion(
          notifyGranted: Value(notify),
          viewGranted: Value(view),
          editGranted: Value(edit),
          payerPlanActive: Value(payerPlanActive),
        ),
      );

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

  // ── Автопредставлення: "візитівки" без каналу (Фаза 5) ──────────────────

  Stream<List<KnownFamilyMember>> watchKnownMembers() =>
      _db.select(_db.knownFamilyMembers).watch();

  Future<KnownFamilyMember?> getKnownMember(String personUuid) =>
      (_db.select(_db.knownFamilyMembers)..where((t) => t.personUuid.equals(personUuid)))
          .getSingleOrNull();

  /// Не перезаписує, якщо для цього personUuid вже є справжній [FamilyPeers]
  /// канал — реальні дані завжди старші за просту візитівку.
  Future<void> upsertKnownMember(KnownFamilyMembersCompanion member) async {
    final personUuid = member.personUuid.value;
    if (await getByUuid(personUuid) != null) return;
    await _db.into(_db.knownFamilyMembers).insertOnConflictUpdate(member);
  }

  Future<void> removeKnownMember(String personUuid) =>
      (_db.delete(_db.knownFamilyMembers)..where((t) => t.personUuid.equals(personUuid))).go();

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
