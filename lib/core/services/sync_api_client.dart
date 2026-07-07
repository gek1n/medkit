import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SyncEntity {
  final String type;
  final int localId;
  final Uint8List ciphertext;
  final bool deleted;
  final String updatedAt;

  const SyncEntity({
    required this.type,
    required this.localId,
    required this.ciphertext,
    required this.deleted,
    required this.updatedAt,
  });

  factory SyncEntity.fromJson(Map<String, dynamic> json) => SyncEntity(
        type: json['type'] as String,
        localId: json['local_id'] as int,
        ciphertext: base64Decode(json['ciphertext'] as String),
        deleted: json['deleted'] as bool,
        updatedAt: json['updated_at'] as String,
      );
}

class SyncPhoto {
  final String photoId;
  final Uint8List bytes;
  final bool deleted;
  final String updatedAt;

  const SyncPhoto({
    required this.photoId,
    required this.bytes,
    required this.deleted,
    required this.updatedAt,
  });

  factory SyncPhoto.fromJson(Map<String, dynamic> json) => SyncPhoto(
        photoId: json['photo_id'] as String,
        bytes: base64Decode(json['bytes'] as String),
        deleted: json['deleted'] as bool,
        updatedAt: json['updated_at'] as String,
      );
}

class SyncPullResult {
  final List<SyncEntity> entities;
  final List<SyncPhoto> photos;

  const SyncPullResult({required this.entities, required this.photos});
}

/// HTTP-клієнт до `/sync/push` і `/sync/pull`
/// (medkit-backend/medkit_private/src/Modules/Sync/SyncController.php).
class SyncApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const SyncApiClient();

  Future<void> push({
    required String accountId,
    List<Map<String, dynamic>> entities = const [],
    List<Map<String, dynamic>> photos = const [],
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/sync/push'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'account_id': accountId, 'entities': entities, 'photos': photos}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw SyncApiException(response.statusCode, _tryDecodeError(response.body));
    }
  }

  Future<SyncPullResult> pull({required String accountId, DateTime? since}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/sync/pull'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'account_id': accountId,
            if (since != null) 'since': since.toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw SyncApiException(response.statusCode, _tryDecodeError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SyncPullResult(
      entities: (json['entities'] as List)
          .map((e) => SyncEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: (json['photos'] as List? ?? [])
          .map((e) => SyncPhoto.fromJson(e as Map<String, dynamic>))
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

class SyncApiException implements Exception {
  final int statusCode;
  final String message;

  const SyncApiException(this.statusCode, this.message);

  @override
  String toString() => 'SyncApiException($statusCode): $message';
}
