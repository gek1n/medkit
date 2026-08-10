import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FamilySyncEntity {
  final String type;
  final String uuid;
  final Uint8List ciphertext;
  final bool deleted;
  final String updatedAt;

  const FamilySyncEntity({
    required this.type,
    required this.uuid,
    required this.ciphertext,
    required this.deleted,
    required this.updatedAt,
  });

  factory FamilySyncEntity.fromJson(Map<String, dynamic> json) => FamilySyncEntity(
        type: json['type'] as String,
        uuid: json['uuid'] as String,
        ciphertext: base64Decode(json['ciphertext'] as String),
        deleted: json['deleted'] as bool,
        updatedAt: json['updated_at'] as String,
      );
}

class FamilySyncPhoto {
  final String photoId;
  final Uint8List bytes;
  final bool deleted;
  final String updatedAt;

  const FamilySyncPhoto({
    required this.photoId,
    required this.bytes,
    required this.deleted,
    required this.updatedAt,
  });

  factory FamilySyncPhoto.fromJson(Map<String, dynamic> json) => FamilySyncPhoto(
        photoId: json['photo_id'] as String,
        bytes: base64Decode(json['bytes'] as String),
        deleted: json['deleted'] as bool,
        updatedAt: json['updated_at'] as String,
      );
}

class FamilySyncPullResult {
  final List<FamilySyncEntity> entities;
  final List<FamilySyncPhoto> photos;

  const FamilySyncPullResult({required this.entities, required this.photos});
}

/// HTTP-клієнт до `/family-sync/push` і `/family-sync/pull`
/// (medkit-backend/medkit_private/src/Modules/Relay/FamilySyncController.php).
/// На відміну від `SyncApiClient` (account-sync, `accountId`+`localId` int),
/// тут область видимості — `channelId` (той самий, що і в пейрингу/relay), а
/// ідентифікатор рядка — `uuid` (string), бо обидва пристрої живі одночасно.
class FamilySyncApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const FamilySyncApiClient();

  Future<void> push({
    required String channelId,
    List<Map<String, dynamic>> entities = const [],
    List<Map<String, dynamic>> photos = const [],
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/family-sync/push'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'channel_id': channelId, 'entities': entities, 'photos': photos}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw FamilySyncApiException(response.statusCode, _tryDecodeError(response.body));
    }
  }

  Future<FamilySyncPullResult> pull({required String channelId, DateTime? since}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/family-sync/pull'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'channel_id': channelId,
            if (since != null) 'since': since.toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw FamilySyncApiException(response.statusCode, _tryDecodeError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return FamilySyncPullResult(
      entities: (json['entities'] as List)
          .map((e) => FamilySyncEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: (json['photos'] as List? ?? [])
          .map((e) => FamilySyncPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String _tryDecodeError(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return j['error'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}

class FamilySyncApiException implements Exception {
  final int statusCode;
  final String message;

  const FamilySyncApiException(this.statusCode, this.message);

  @override
  String toString() => 'FamilySyncApiException($statusCode): $message';
}
