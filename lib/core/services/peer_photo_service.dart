import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'family_account.dart';
import 'family_api_client.dart';
import 'family_key_service.dart';
import 'sync_crypto_service.dart';

/// photo_id — детермінований, обчислюється НЕЗАЛЕЖНО і суб'єктом (при
/// пуші), і глядачем (при перегляді), з того самого відносного шляху, що
/// вже й так приходить у синхронізованому photoPaths/documentPaths —
/// жодного нового поля/міграції не потрібно. SHA-256 (не String.hashCode —
/// той не гарантовано стабільний між платформами/версіями Dart, а тут
/// обидва пристрої мусять порахувати ОДНАКОВЕ значення).
Future<String> photoIdFor(String relativePath) async {
  final hash = await Sha256().hash(utf8.encode(relativePath));
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Розшифровані байти ОДНОГО фото/вкладення піра — на вимогу, лише коли
/// користувач реально відкриває перегляд (той самий принцип, що описаний у
/// докблоці FamilyServerSyncService: "Фото — пряме GET-подібне /family/photo
/// на вимогу"). Кешується в пам'яті за photo_id — байти вкладення ніколи не
/// змінюються "на місці" (нове фото = новий шлях = новий photo_id), тож
/// повторний перегляд безпечно повертає закешоване.
class PeerPhotoService {
  static final _cache = <String, Uint8List>{};
  static const _api = FamilyApiClient();

  static Future<Uint8List> fetch({
    required String channelId,
    required String publicKeyHex,
    required String relativePath,
  }) async {
    final photoId = await photoIdFor(relativePath);
    final cached = _cache[photoId];
    if (cached != null) return cached;

    final account = await ensureFamilyAccount();
    final encrypted = await _api.photo(
      accountId: account.accountId,
      channelId: channelId,
      photoId: photoId,
    );
    final key = await FamilyKeyService.sharedChannelKey(publicKeyHex);
    final bytes = await SyncCryptoService.decryptBytes(key, encrypted);
    _cache[photoId] = bytes;
    return bytes;
  }
}
