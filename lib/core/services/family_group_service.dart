import 'dart:convert';

import '../../data/db/app_database.dart';
import '../../data/repositories/members_repository.dart';
import 'family_account.dart';
import 'family_api_client.dart';
import 'family_key_service.dart';
import 'pairing_api_client.dart';
import 'pairing_crypto_service.dart';

/// Крок 11 C6: запрошення/приєднання/вихід із сімейної групи — нова,
/// значно менша заміна архівного `FamilyGroupService` (котрий ніс
/// channelId+syncKey у самому конверті й вимагав ручного relay-обміну
/// "візитівкою"). Тепер конверт несе лише `family_id`+`inviter_account_id`
/// (+ ім'я/аватар інвайтера для preview-екрана) — жодного ключа шифрування
/// в конверті: канал і симетричний ключ обидві сторони обчислюють
/// НЕЗАЛЕЖНО через ECDH (`FamilyKeyService`), щойно бачать одне одного в
/// `/family/status`. QR/6-значний код + Argon2id-конверт
/// (`PairingCryptoService`/`PairingApiClient`, /pairing/create,/pairing/redeem)
/// лишаються буквально тим самим кодом, що й до Кроку 11.
class GroupInvitePreview {
  final String familyId;
  final String inviterAccountId;
  final String inviterName;
  final int inviterAvatarIndex;
  const GroupInvitePreview({
    required this.familyId,
    required this.inviterAccountId,
    required this.inviterName,
    required this.inviterAvatarIndex,
  });
}

class GroupJoinException implements Exception {
  final String message;
  const GroupJoinException(this.message);
  @override
  String toString() => message;
}

class FamilyGroupService {
  final AppDatabase _db;
  final _api = const FamilyApiClient();
  final _pairingApi = const PairingApiClient();

  FamilyGroupService(this._db);

  Future<Member> _requireOwner() async {
    final owner = await MembersRepository(_db).getOwner();
    if (owner == null || owner.personUuid == null) {
      throw const GroupJoinException('Немає власного профілю на цьому пристрої');
    }
    return owner;
  }

  /// Створює запрошення від імені власного профілю. `/family/create` —
  /// idempotent: якщо я вже адміністратор якоїсь сім'ї, повертає її ж
  /// family_id замість створення нової, тож повторний виклик безпечний.
  Future<String> createInvite() async {
    final owner = await _requireOwner();
    final account = await ensureFamilyAccount();
    final publicKeyHex = await FamilyKeyService.publicKeyHex();
    final familyId = await _api.create(
      accountId: account.accountId,
      recoveryKeyHash: account.recoveryKeyHash,
      personUuid: owner.personUuid!,
      name: owner.name,
      avatarIndex: owner.avatarIndex,
      publicKeyHex: publicKeyHex,
    );

    final code = PairingCryptoService.generateCode();
    final envelope = jsonEncode({
      'family_id': familyId,
      'inviter_account_id': account.accountId,
      'inviter_name': owner.name,
      'inviter_avatar_index': owner.avatarIndex,
    });
    final enc = await PairingCryptoService.encrypt(code, utf8.encode(envelope));
    await _pairingApi.create(
      codeHash: enc.codeHash,
      salt: enc.salt,
      nonce: enc.nonce,
      ciphertext: enc.ciphertext,
    );
    return code;
  }

  /// Розшифровує код — не мутує стан, лише готує preview для екрана згоди.
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
    return GroupInvitePreview(
      familyId: envelope['family_id'] as String,
      inviterAccountId: envelope['inviter_account_id'] as String,
      inviterName: envelope['inviter_name'] as String? ?? '',
      inviterAvatarIndex: envelope['inviter_avatar_index'] as int? ?? 0,
    );
  }

  /// `/family/join` — сервер сам матеріалізує канали проти всіх активних
  /// учасників (не лише інвайтера) й перевіряє, що інвайтер і досі активний.
  Future<void> acceptInvite(GroupInvitePreview preview) async {
    final owner = await _requireOwner();
    final account = await ensureFamilyAccount();
    final publicKeyHex = await FamilyKeyService.publicKeyHex();
    await _api.join(
      accountId: account.accountId,
      recoveryKeyHash: account.recoveryKeyHash,
      familyId: preview.familyId,
      personUuid: owner.personUuid!,
      name: owner.name,
      avatarIndex: owner.avatarIndex,
      inviterAccountId: preview.inviterAccountId,
      publicKeyHex: publicKeyHex,
    );
  }

  Future<void> leaveGroup(String familyId) async {
    final account = await ensureFamilyAccount();
    await _api.leave(
      accountId: account.accountId,
      recoveryKeyHash: account.recoveryKeyHash,
      familyId: familyId,
    );
  }

  /// Лише адміністратор може викликати успішно — сервер сам перевіряє й
  /// поверне 403 інакше.
  Future<void> kick(String familyId, String targetAccountId) async {
    final account = await ensureFamilyAccount();
    await _api.kick(
      accountId: account.accountId,
      recoveryKeyHash: account.recoveryKeyHash,
      familyId: familyId,
      targetAccountId: targetAccountId,
    );
  }
}
