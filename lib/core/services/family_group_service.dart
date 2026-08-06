import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/shared_channels_repository.dart';
import 'app_logger.dart';
import 'attachment_cleanup_service.dart';
import 'family_peer_sync_service.dart';
import 'family_sync_service.dart';
import 'pairing_api_client.dart';
import 'pairing_crypto_service.dart';
import 'push_token_service.dart';
import 'relay_api_client.dart';
import 'shared_channel_key_storage.dart';
import 'sync_crypto_service.dart';

/// Дані з розшифрованого запрошення до сімейної групи — проміжний стан між
/// скануванням коду і явним підтвердженням користувача. Приєднання вже
/// заповненого акаунта завжди вимагає explicit consent-екран (на відміну
/// від онбордингового `JoinFamilyScreen`, де приєднується порожній
/// пристрій) — тому розшифровка і застосування розділені на два кроки.
class GroupInvitePreview {
  final String channelId;
  final String familyId;
  final String inviterPersonUuid;
  final String inviterName;
  final int inviterAvatarIndex;
  final List<int> syncKey;

  const GroupInvitePreview({
    required this.channelId,
    required this.familyId,
    required this.inviterPersonUuid,
    required this.inviterName,
    required this.inviterAvatarIndex,
    required this.syncKey,
  });
}

class GroupJoinException implements Exception {
  final String message;
  const GroupJoinException(this.message);
  @override
  String toString() => message;
}

/// Запрошення й приєднання до сімейної групи. На відміну від
/// `FamilySyncService` (дзеркалить дані ОДНОГО профілю між двома
/// пристроями тієї самої людини), тут ідеться про легкий обмін
/// "візитівками" (ім'я/аватар/personUuid) між НЕЗАЛЕЖНИМИ учасниками —
/// кожен лишається на своєму пристрої зі своїми даними. Сама медична
/// видимість між учасниками групи — окреме питання (Фаза 3/4), тут лише
/// встановлюється факт членства.
class FamilyGroupService {
  static const _uuid = Uuid();
  final AppDatabase _db;
  final _pairingApi = const PairingApiClient();
  final _relayApi = const RelayApiClient();

  FamilyGroupService(this._db);

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Створює запрошення від імені власного "головного" профілю. Якщо
  /// профіль ще ні в якій групі — генерує нову familyId; якщо вже в групі —
  /// запрошує до неї ж, тож приєднатись можна через будь-кого з учасників.
  Future<String> createInvite() async {
    final membersRepo = MembersRepository(_db);
    final owner = await membersRepo.getOwner();
    if (owner == null) throw const GroupJoinException('Немає власного профілю');

    var familyId = owner.familyId;
    if (familyId == null) {
      familyId = _uuid.v4();
      await membersRepo.update(MembersCompanion(id: Value(owner.id), familyId: Value(familyId)));
    }

    final code = PairingCryptoService.generateCode();
    final channelId = _uuid.v4();
    final syncKey = _randomBytes(32);

    final envelope = utf8.encode(jsonEncode({
      'v': 3,
      'familyId': familyId,
      'personUuid': owner.personUuid,
      'name': owner.name,
      'avatarIndex': owner.avatarIndex,
      'channelId': channelId,
      'syncKey': base64Encode(syncKey),
    }));

    final result = await PairingCryptoService.encrypt(code, envelope);
    await _pairingApi.create(
      codeHash: result.codeHash,
      salt: result.salt,
      nonce: result.nonce,
      ciphertext: result.ciphertext,
    );

    await SharedChannelKeyStorage.store(channelId, syncKey);
    await FamilyPeersRepository(_db).addPendingInvite(
      PendingGroupInvitesCompanion.insert(channelId: channelId, familyId: familyId),
    );

    try {
      final token = await PushTokenService.getToken();
      if (token != null) {
        await _relayApi.register(channelId: channelId, pushToken: token, platform: _platform);
        AppLogger.log(
            'FamilyGroupService.createInvite: registered on relay with real push token channelId=$channelId');
      } else {
        // Той самий "тихий" випадок, що й у _sendMyCard — без логу тут
        // неможливо відрізнити "запрошення взагалі не реєструвалось на
        // relay" від "усе працює, просто ніхто ще не відповів".
        AppLogger.log(
            'FamilyGroupService.createInvite: SKIPPED register (push token null) channelId=$channelId');
      }
    } catch (e, st) {
      // Не критично для самого запрошення — просто не буде push-пробудження,
      // але лишаємо слід у логах, а не проковтуємо мовчки.
      AppLogger.logError('FamilyGroupService.createInvite.register(channelId=$channelId)', e, st);
    }

    return code;
  }

  /// "Локальний → Автономний": на відміну від [createInvite] (запрошуєш
  /// когось приєднатись зі СВОЇМ вже наявним акаунтом), тут запрошуєш
  /// ЛОКАЛЬНИЙ профіль [dependent], яким сам керуєш, стати незалежним. Той,
  /// хто відсканує код, отримає на новому пристрої власний акаунт із повною
  /// історією [dependent] як стартовими даними — далі керує ним сам.
  ///
  /// Технічно: одноразова передача історії йде через ту саму інфраструктуру,
  /// що й старий 1:1-пейринг ([FamilySyncService]/[SharedChannelsRepository]),
  /// але лише ОДИН раз — щойно приєднання підтверджено, канал видаляється
  /// ([refreshPeers]) і надалі відносини між двома вже незалежними людьми
  /// живуть через звичайні FamilyPeers/FamilyGrants.
  Future<String> createConversionInvite(Member dependent) async {
    // Крок 1.2 плану: почати НОВУ конвертацію заборонено — конвертація
    // розкриває багато проблем на приймаючому боці. UI вже ховає кнопку для
    // цього випадку; це defense-in-depth на рівні сервісу. Регенерація коду
    // для ВЖЕ розпочатої конвертації (є рядок PendingGroupInvites з цим
    // convertingMemberId) лишається дозволеною, щоб не зламати завершення
    // вже показаного користувачу запрошення.
    final hasPendingConversion = await (_db.select(_db.pendingGroupInvites)
          ..where((t) => t.convertingMemberId.equals(dependent.id)))
        .get()
        .then((rows) => rows.isNotEmpty);
    if (!hasPendingConversion) {
      throw const GroupJoinException(
          'Перетворення локального профілю на автономний тимчасово недоступне');
    }

    final membersRepo = MembersRepository(_db);
    final owner = await membersRepo.getOwner();
    if (owner == null) throw const GroupJoinException('Немає власного профілю');

    var familyId = owner.familyId;
    if (familyId == null) {
      familyId = _uuid.v4();
      await membersRepo.update(MembersCompanion(id: Value(owner.id), familyId: Value(familyId)));
    }

    final code = PairingCryptoService.generateCode();
    final channelId = _uuid.v4();
    final syncKey = _randomBytes(32);

    final envelope = utf8.encode(jsonEncode({
      'v': 4,
      'familyId': familyId,
      'inviterPersonUuid': owner.personUuid,
      'inviterName': owner.name,
      'inviterAvatarIndex': owner.avatarIndex,
      'channelId': channelId,
      'syncKey': base64Encode(syncKey),
      'profileName': dependent.name,
      'profileAvatarIndex': dependent.avatarIndex,
    }));

    final result = await PairingCryptoService.encrypt(code, envelope);
    await _pairingApi.create(
      codeHash: result.codeHash,
      salt: result.salt,
      nonce: result.nonce,
      ciphertext: result.ciphertext,
    );

    await SharedChannelKeyStorage.store(channelId, syncKey);
    // Той самий канал одноразово несе повну історію dependent-профілю — тим
    // самим шляхом, що й старий 1:1-пейринг (SharedChannels), лише без
    // подальшої постійної синхронізації.
    await SharedChannelsRepository(_db).bind(channelId: channelId, memberId: dependent.id);
    await FamilyPeersRepository(_db).addPendingInvite(
      PendingGroupInvitesCompanion.insert(
        channelId: channelId,
        familyId: familyId,
        convertingMemberId: Value(dependent.id),
      ),
    );

    try {
      final token = await PushTokenService.getToken();
      if (token != null) {
        await _relayApi.register(channelId: channelId, pushToken: token, platform: _platform);
        AppLogger.log(
            'FamilyGroupService.createConversionInvite: registered on relay with real push token channelId=$channelId');
      } else {
        AppLogger.log(
            'FamilyGroupService.createConversionInvite: SKIPPED register (push token null) channelId=$channelId');
      }
    } catch (e, st) {
      AppLogger.logError('FamilyGroupService.createConversionInvite.register(channelId=$channelId)', e, st);
    }

    // Штовхаємо історію на сервер одразу, не чекаючи наступного звичайного
    // тригера синку — код може бути відсканований за лічені секунди.
    try {
      await FamilySyncService(_db).syncChannelForMember(dependent.id);
    } catch (_) {
      // Спробуємо ще раз при наступному звичайному тригері (resume/FCM) —
      // той самий компроміс, що й у решті FamilySyncService.
    }

    return code;
  }

  /// Розшифровує код і повертає preview — БЕЗ жодних локальних записів.
  /// Екран згоди показується саме за цими даними, до [acceptInvite].
  Future<GroupInvitePreview> decodeInvite(String code) async {
    final codeHash = PairingCryptoService.codeHash(code);
    final blob = await _pairingApi.redeem(codeHash: codeHash);
    final plain = await PairingCryptoService.decrypt(
      code,
      salt: blob.salt,
      nonce: blob.nonce,
      cipherTextAndMac: blob.ciphertext,
    );
    final envelope = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    if (envelope['v'] != 3) {
      throw const GroupJoinException('Це запрошення не для сімейної групи');
    }
    return GroupInvitePreview(
      channelId: envelope['channelId'] as String,
      familyId: envelope['familyId'] as String,
      inviterPersonUuid: envelope['personUuid'] as String,
      inviterName: envelope['name'] as String? ?? 'Учасник родини',
      inviterAvatarIndex: envelope['avatarIndex'] as int? ?? 0,
      syncKey: base64Decode(envelope['syncKey'] as String),
    );
  }

  /// Викликати лише після явного підтвердження користувача на екрані згоди.
  ///
  /// `owner.familyId` НІКОЛИ не чіпається тут — це поле означає лише "сім'я,
  /// яку я створив і за яку плачу", а не "у яких сімʼях я гість". Те, що я
  /// приєднався до чужої групи, відстежується виключно через новий запис
  /// `FamilyPeers` нижче (мультисемейність: можна одночасно платити за свою
  /// сім'ю і бути гостем у довільній кількості чужих).
  Future<void> acceptInvite(GroupInvitePreview preview) async {
    final membersRepo = MembersRepository(_db);
    final owner = await membersRepo.getOwner();
    if (owner == null) throw const GroupJoinException('Немає власного профілю');

    await SharedChannelKeyStorage.store(preview.channelId, preview.syncKey);
    await FamilyPeersRepository(_db).upsert(
      FamilyPeersCompanion.insert(
        personUuid: preview.inviterPersonUuid,
        familyId: preview.familyId,
        name: preview.inviterName,
        avatarIndex: Value(preview.inviterAvatarIndex),
        channelId: preview.channelId,
        // Я скановував ЙОГО код — це він мене запросив, не витрачає мій ліміт.
        invitedMe: const Value(true),
        // Реальний баг у продакшені (04.08): картка нижче раніше надсилалась
        // РІВНО ОДИН раз, тут-таки. Якщо push-токен ще не готовий (типово на
        // iOS одразу після приєднання, поки дозвіл не надано) — інвайтер
        // навіки лишався без сліду, що запрошення прийняли. false — ще
        // спробувати при наступних sync-раундах (retryPendingIntroductions).
        introductionSent: const Value(false),
      ),
    );

    final sent = await _sendMyCard(
      channelId: preview.channelId,
      syncKey: preview.syncKey,
      familyId: preview.familyId,
      owner: owner,
    );
    if (sent) {
      await FamilyPeersRepository(_db).markIntroductionSent(preview.inviterPersonUuid);
    }
  }

  /// Надсилає мою "візитівку" у відповідь каналом [channelId] — той самий
  /// крок, що й наприкінці acceptInvite(), винесений окремо, щоб
  /// [retryPendingIntroductions] міг повторювати його для пірів, чия перша
  /// спроба не пройшла. Повертає true лише якщо реально дійшло до relay.
  Future<bool> _sendMyCard({
    required String channelId,
    required List<int> syncKey,
    required String familyId,
    required Member owner,
  }) async {
    // Push-токен потрібен лише для миттєвого "розбудити" іншу сторону —
    // сама відправка картки (нижче) НЕ має від нього залежати: channel_state
    // на сервері однаково читається звичайним polling'ом на кожному
    // відкритті застосунку будь-якою стороною (FamilyGroupService.refreshPeers),
    // а senderToken серверу не потрібен як справжній push-токен — це лише
    // службова позначка "хто востаннє писав", не автентифікація (перевірено
    // в RelayController.php: жодної звірки з реальними токенами). Раніше
    // null-токен (типово нестабільна APNs-реєстрація на iOS) повністю
    // скасовував відправку — і саме це, а не сам push, було справжньою
    // причиною того, що інвайтер ніколи не бачив піра.
    final token = await PushTokenService.getToken();
    if (token == null) {
      AppLogger.log(
          'FamilyGroupService._sendMyCard: no push token, sending without push wake-up channelId=$channelId personUuid=${owner.personUuid}');
    } else {
      try {
        await _relayApi.register(channelId: channelId, pushToken: token, platform: _platform);
        AppLogger.log(
            'FamilyGroupService._sendMyCard: registered on relay with real push token channelId=$channelId');
      } catch (e, st) {
        AppLogger.logError('FamilyGroupService._sendMyCard.register(channelId=$channelId)', e, st);
      }
    }

    try {
      final key = SecretKey(syncKey);
      final myCard = {
        'v': 3,
        'familyId': familyId,
        'personUuid': owner.personUuid,
        'name': owner.name,
        'avatarIndex': owner.avatarIndex,
      };
      final encrypted = await SyncCryptoService.encryptEntity(key, myCard);
      await _relayApi.send(
        channelId: channelId,
        senderToken: token ?? 'no-token-${DateTime.now().microsecondsSinceEpoch}',
        encryptedPayloadBase64: base64Encode(encrypted),
      );
      // Симетрична до логу невдачі нижче — без цього немає жодного сліду в
      // логах, що клієнт реально відправив картку (лише мовчазна відсутність
      // помилки), тож "надіслав, а інвайтер так і не побачив" неможливо
      // відрізнити від "взагалі не намагався" при діагностиці за логами.
      AppLogger.log(
          'FamilyGroupService._sendMyCard: sent OK channelId=$channelId personUuid=${owner.personUuid}');
      return true;
    } catch (e, st) {
      AppLogger.logError('FamilyGroupService._sendMyCard.send(channelId=$channelId)', e, st);
      return false;
    }
  }

  /// Викликати на тих самих тригерах, що й refreshPeers()/syncAllPeers() —
  /// повторює надсилання моєї картки для пірів, чия перша спроба (в
  /// acceptInvite()) не дійшла до relay (типово: push-токен ще не був
  /// готовий у момент приєднання). Без цього такий пір назавжди лишається
  /// невидимим на пристрої того, хто мене запросив, попри те, що я сам вже
  /// бачу його в себе — саме це й сталось у реальному репорті користувача.
  Future<void> retryPendingIntroductions() async {
    final repo = FamilyPeersRepository(_db);
    final membersRepo = MembersRepository(_db);
    final owner = await membersRepo.getOwner();
    if (owner == null) return;

    for (final peer in await repo.peersNeedingIntroduction()) {
      final syncKey = await SharedChannelKeyStorage.read(peer.channelId);
      if (syncKey == null) continue;
      final sent = await _sendMyCard(
        channelId: peer.channelId,
        syncKey: syncKey,
        familyId: peer.familyId,
        owner: owner,
      );
      if (sent) {
        await repo.markIntroductionSent(peer.personUuid);
      }
    }
  }

  /// Викликати на тих самих тригерах, що й `FamilySyncService.syncAll()`
  /// (відкриття/resume/FCM) — перевіряє, чи хтось відповів на запрошення,
  /// що очікують відповіді.
  // Крок 3.1 плану: код запрошення на сервері мертвий вже через 30 хвилин
  // (одноразовий pairing-blob, див. inviteCodeExpiryNotice) — тож перевіряти
  // мережею запрошення, старіше за це, гарантовано марно. Даємо запас на
  // повільну мережу/розсинхронізований годинник і однаково прибираємо
  // застарілий рядок локально, а не лишаємо його рости в списку назавжди.
  static const _pendingInviteTtl = Duration(hours: 2);

  /// Повертає щойно виявлених нових пірів (тих, хто відповів на МОЄ
  /// запрошення саме в цьому виклику) — [main.dart] використовує це, щоб
  /// показати одноразовий поп-ап "додався новий член сім'ї" (family_join_popup.dart).
  Future<List<FamilyPeer>> refreshPeers() async {
    final repo = FamilyPeersRepository(_db);
    final newlyAdded = <FamilyPeer>[];

    final pending = await repo.pendingInvites();
    // Тимчасове діагностичне логування — щоб бачити, чи взагалі є цей канал
    // у списку очікуваних запрошень на момент виклику (а не лише результат).
    AppLogger.log(
        'FamilyGroupService.refreshPeers: checking ${pending.length} pending invite(s): ${pending.map((i) => i.channelId).join(", ")}');
    for (final invite in pending) {
      if (DateTime.now().difference(invite.createdAt) > _pendingInviteTtl) {
        await repo.removePendingInvite(invite.channelId);
        // Конверсія, яку так ніхто й не завершив, — прибираємо одноразовий
        // канал передачі історії; сам локальний профіль лишається як є (він
        // ніколи не переставав бути локальним, конверсія просто не сталась).
        final convertingId = invite.convertingMemberId;
        if (convertingId != null) {
          await SharedChannelsRepository(_db).unbind(convertingId);
        }
        await SharedChannelKeyStorage.delete(invite.channelId);
        continue;
      }
      try {
        final keyBytes = await SharedChannelKeyStorage.read(invite.channelId);
        if (keyBytes == null) continue;
        final state = await _relayApi.fetchState(channelId: invite.channelId);
        final key = SecretKey(keyBytes);
        final card = await SyncCryptoService.decryptEntity(key, base64Decode(state.encryptedPayloadBase64));
        if (card['v'] != 3) continue;
        final joinedPersonUuid = card['personUuid'] as String;
        await repo.upsert(FamilyPeersCompanion.insert(
          personUuid: joinedPersonUuid,
          familyId: card['familyId'] as String,
          name: card['name'] as String? ?? 'Учасник родини',
          avatarIndex: Value(card['avatarIndex'] as int? ?? 0),
          channelId: invite.channelId,
          // Це відповідь на МОЄ запрошення (звичайне чи конверсія) — я його
          // не запрошував, я запросив ЙОГО, тому invitedMe=false (за
          // замовчуванням), витрачає мій ліміт слотів.
        ));
        final savedPeer = await repo.getByUuid(joinedPersonUuid);
        if (savedPeer != null) newlyAdded.add(savedPeer);
        // Тимчасове діагностичне логування (баг: інвайтер не бачить піра
        // навіть коли channel_state на сервері вже підтверджено має дані) —
        // refreshPeers() досі не мав жодного логу на успішній гілці, лише
        // на помилці, тож неможливо було відрізнити "ще не відповів" від
        // "відповів, зберіг, але це не показалось" за самими логами.
        AppLogger.log(
            'FamilyGroupService.refreshPeers: SAVED peer channelId=${invite.channelId} personUuid=$joinedPersonUuid familyId=${card['familyId']} savedPeerIsNull=${savedPeer == null}');

        // Я (хаб цієї сім'ї) знайомлю нового учасника з усіма, хто вже в
        // групі, і навпаки — обміном візитівок (Фаза 5, автопредставлення).
        try {
          await FamilyPeerSyncService(_db).introduceNewPeer(card['personUuid'] as String);
        } catch (_) {
          // Best-effort — підхопиться наступним новим учасником чи synk-раундом.
        }
        await repo.removePendingInvite(invite.channelId);

        // "Локальний → Автономний" підтверджено: людина, якою я щойно
        // керував локально, тепер сама відповідає за свої дані на власному
        // пристрої. Прибираю її локальний профіль (з усім, що до нього
        // прив'язано) і одноразовий канал передачі історії — далі це
        // звичайний FamilyPeer, як і будь-хто інший.
        final convertingId = invite.convertingMemberId;
        if (convertingId != null) {
          await SharedChannelsRepository(_db).unbind(convertingId);
          await AttachmentCleanupService.deleteAllForMember(_db, convertingId);
          await MembersRepository(_db).delete(convertingId);
        }
      } catch (e, st) {
        // Ще ніхто не відповів або тимчасово немає мережі — спробуємо ще
        // раз на наступному тригері. Логуємо, а не проковтуємо мовчки —
        // інакше "запрошення прийняте, а статус на пристрої запрошувача
        // так і лишився Локальний" виглядає як загадка без жодного сліду
        // в логах для діагностики.
        AppLogger.logError(
          'FamilyGroupService.refreshPeers(channelId=${invite.channelId})',
          e,
          st,
        );
      }
    }
    return newlyAdded;
  }
}
