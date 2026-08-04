import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class FamilyPeersRepository {
  final AppDatabase _db;
  FamilyPeersRepository(this._db);

  // sortOrder — драг-н-дроп на екрані Сім'я; addedAt — стабільний tiebreak
  // для тих, хто ще на дефолтних 0 (порядок приєднання, той самий, що й до
  // появи sortOrder).
  Stream<List<FamilyPeer>> watchAll() => (_db.select(_db.familyPeers)
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.addedAt),
        ]))
      .watch();

  Future<List<FamilyPeer>> allPeers() => _db.select(_db.familyPeers).get();

  /// Викликати з нового порядку personUuid-ів після реордеру на екрані
  /// Сім'я (той самий принцип, що й MembersRepository.reorder — тут з 0,
  /// бо піри завжди рендеряться власним блоком ПІСЛЯ локальних членів,
  /// колізії sortOrder-просторів немає).
  Future<void> reorder(List<String> orderedPersonUuids) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedPersonUuids.length; i++) {
        await (_db.update(_db.familyPeers)..where((t) => t.personUuid.equals(orderedPersonUuids[i])))
            .write(FamilyPeersCompanion(sortOrder: Value(i)));
      }
    });
  }

  Future<FamilyPeer?> getByUuid(String personUuid) =>
      (_db.select(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid))).getSingleOrNull();

  // Крок 3.2 плану: одного інвайтера ловить getByUuid, але цього не
  // достатньо — та сама сімейна група (familyId) могла вже "прийти" через
  // ІНШОГО її учасника (автопредставлення чи попереднє пряме приєднання).
  Future<List<FamilyPeer>> getByFamilyId(String familyId) =>
      (_db.select(_db.familyPeers)..where((t) => t.familyId.equals(familyId))).get();

  Future<void> upsert(FamilyPeersCompanion peer) =>
      _db.into(_db.familyPeers).insertOnConflictUpdate(peer);

  Future<void> updateLastSynced(String personUuid, DateTime at) =>
      (_db.update(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid)))
          .write(FamilyPeersCompanion(lastSyncedAt: Value(at)));

  /// Ті, кого я прийняв (invitedMe=true), але моя картка-відповідь ще не
  /// підтверджено пішла — див. коментар при introductionSent у таблиці.
  Future<List<FamilyPeer>> peersNeedingIntroduction() =>
      (_db.select(_db.familyPeers)
            ..where((t) => t.invitedMe.equals(true) & t.introductionSent.equals(false)))
          .get();

  Future<void> markIntroductionSent(String personUuid) =>
      (_db.update(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid)))
          .write(const FamilyPeersCompanion(introductionSent: Value(true)));

  /// Що САМ цей пір дозволив мені (+ чи активна його Family-підписка, якщо
  /// саме він мій прямий інвайтер) — прилітає через grants_summary при
  /// кожному синку (FamilyGrants живе лише на пристрої субʼєкта).
  Future<void> updateGrantedToMe(
    String personUuid, {
    required bool notify,
    required bool view,
    required bool edit,
    required bool viewSchedule,
    required bool editSchedule,
    required bool viewMedcard,
    required bool editMedcard,
    required bool viewShelves,
    required bool editShelves,
    required bool payerPlanActive,
  }) =>
      (_db.update(_db.familyPeers)..where((t) => t.personUuid.equals(personUuid))).write(
        FamilyPeersCompanion(
          notifyGranted: Value(notify),
          viewGranted: Value(view),
          editGranted: Value(edit),
          viewScheduleGranted: Value(viewSchedule),
          editScheduleGranted: Value(editSchedule),
          viewMedcardGranted: Value(viewMedcard),
          editMedcardGranted: Value(editMedcard),
          viewShelvesGranted: Value(viewShelves),
          editShelvesGranted: Value(editShelves),
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
