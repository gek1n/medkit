import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/members_repository.dart';
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
  Future<void> acceptInvite(GroupInvitePreview preview) async {
    final membersRepo = MembersRepository(_db);
    final owner = await membersRepo.getOwner();
    if (owner == null) throw const GroupJoinException('Немає власного профілю');

    if (owner.familyId != null && owner.familyId != preview.familyId) {
      throw const GroupJoinException(
        'Ваш профіль уже належить до іншої сімейної групи. Спершу вийдіть із неї.',
      );
    }

    await membersRepo.update(
      MembersCompanion(id: Value(owner.id), familyId: Value(preview.familyId)),
    );

    await SharedChannelKeyStorage.store(preview.channelId, preview.syncKey);
    await FamilyPeersRepository(_db).upsert(
      FamilyPeersCompanion.insert(
        personUuid: preview.inviterPersonUuid,
        familyId: preview.familyId,
        name: preview.inviterName,
        avatarIndex: Value(preview.inviterAvatarIndex),
        channelId: preview.channelId,
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
        ));
        await repo.removePendingInvite(invite.channelId);
      } catch (_) {
        // Ще ніхто не відповів або тимчасово немає мережі — спробуємо ще
        // раз на наступному тригері.
      }
    }
  }
}
