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
      }
    } catch (_) {
      // Не критично для самого запрошення — просто не буде push-пробудження.
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
      }
    } catch (_) {
      // Не критично для самого запрошення.
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
      ),
    );

    String? token;
    try {
      token = await PushTokenService.getToken();
      if (token != null) {
        await _relayApi.register(channelId: preview.channelId, pushToken: token, platform: _platform);
      }
    } catch (_) {
      // Не критично — токен можна зареєструвати пізніше.
    }

    // Одразу надсилаємо СВОЮ картку у відповідь, щоб інвайтер дізнався про
    // нового учасника — той самий канал і ключ, лише в інший бік.
    if (token != null) {
      try {
        final key = SecretKey(preview.syncKey);
        final myCard = {
          'v': 3,
          'familyId': preview.familyId,
          'personUuid': owner.personUuid,
          'name': owner.name,
          'avatarIndex': owner.avatarIndex,
        };
        final encrypted = await SyncCryptoService.encryptEntity(key, myCard);
        await _relayApi.send(
          channelId: preview.channelId,
          senderToken: token,
          encryptedPayloadBase64: base64Encode(encrypted),
        );
      } catch (_) {
        // Інвайтер підхопить картку при наступному відкритті застосунку —
        // relay/state не залежить від миттєвої доставки пушу.
      }
    }
  }

  /// Викликати на тих самих тригерах, що й `FamilySyncService.syncAll()`
  /// (відкриття/resume/FCM) — перевіряє, чи хтось відповів на запрошення,
  /// що очікують відповіді.
  Future<void> refreshPeers() async {
    final repo = FamilyPeersRepository(_db);

    for (final invite in await repo.pendingInvites()) {
      try {
        final keyBytes = await SharedChannelKeyStorage.read(invite.channelId);
        if (keyBytes == null) continue;
        final state = await _relayApi.fetchState(channelId: invite.channelId);
        final key = SecretKey(keyBytes);
        final card = await SyncCryptoService.decryptEntity(key, base64Decode(state.encryptedPayloadBase64));
        if (card['v'] != 3) continue;
        await repo.upsert(FamilyPeersCompanion.insert(
          personUuid: card['personUuid'] as String,
          familyId: card['familyId'] as String,
          name: card['name'] as String? ?? 'Учасник родини',
          avatarIndex: Value(card['avatarIndex'] as int? ?? 0),
          channelId: invite.channelId,
          // Це відповідь на МОЄ запрошення (звичайне чи конверсія) — я його
          // не запрошував, я запросив ЙОГО, тому invitedMe=false (за
          // замовчуванням), витрачає мій ліміт слотів.
        ));

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
  }
}
