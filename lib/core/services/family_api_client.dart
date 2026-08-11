import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// HTTP-клієнт до `/family/*`
/// (medkit-backend/medkit_private/src/Modules/Family/{FamilyController,FamilySyncV2Controller}.php)
/// — Крок 11, замінює архівний `FamilySyncApiClient`/`RelayApiClient`/
/// `PairingApiClient` (anonymous `channel_id`, без server-side ACL). Той
/// самий "account_id + recovery_key_hash доводить володіння" паттерн, що й
/// [SubscriptionApiClient]/[AccountApiClient] — сервер тут РЕАЛЬНО перевіряє
/// власника, а не лише формат channel_id.
///
/// `channel_id` — один спільний секрет на пару акаунтів (обидві сторони
/// пушать свої дані в один і той самий канал; сервер не розрізняє
/// "власника"/"глядача" на рівні каналу). Хто саме дозволив бачити що —
/// окреме, напрямлене питання ([grantsPush]/[grantsPull]).
///
/// Уточнення (11.08): channel_id НЕ передається клієнтом і не потребує
/// окремої реєстрації — кожен учасник публікує X25519 [FamilyKeyService]
/// public_key (не секрет), сервер сам матеріалізує попарні канали при
/// [join]/[create] проти всіх активних учасників, а обидві сторони
/// НЕЗАЛЕЖНО обчислюють той самий channel_id+симетричний ключ через ECDH
/// (`family_server_sync_service.dart::deterministicChannelId`+
/// `FamilyKeyService.sharedChannelKey`) — без relay-"представлення".
class FamilyApiClient {
  static const _baseUrl = 'https://api.elly-medkit.com';

  const FamilyApiClient();

  /// POST /family/create — idempotent: якщо в мене вже є сім'я, сервер
  /// повертає її ж family_id замість створення нової. [publicKeyHex] —
  /// `FamilyKeyService.publicKeyHex()`.
  Future<String> create({
    required String accountId,
    required String recoveryKeyHash,
    required String personUuid,
    required String name,
    required int avatarIndex,
    required String publicKeyHex,
  }) async {
    final json = await _post('/family/create', {
      'account_id': accountId,
      'recovery_key_hash': recoveryKeyHash,
      'person_uuid': personUuid,
      'name': name,
      'avatar_index': avatarIndex,
      'public_key': publicKeyHex,
    });
    return json['family_id'] as String;
  }

  /// POST /family/join — після розшифровки pairing-конверта (QR/6-значний
  /// код, той самий механізм, що й раніше, несе лише family_id +
  /// inviter_account_id + ім'я/аватар інвайтера для preview-екрана — БЕЗ
  /// жодного ключа шифрування, сервер його не бачить). [publicKeyHex] —
  /// `FamilyKeyService.publicKeyHex()`; сервер сам матеріалізує канали з
  /// усіма вже активними учасниками.
  Future<void> join({
    required String accountId,
    required String recoveryKeyHash,
    required String familyId,
    required String personUuid,
    required String name,
    required int avatarIndex,
    required String inviterAccountId,
    required String publicKeyHex,
  }) {
    return _post('/family/join', {
      'account_id': accountId,
      'recovery_key_hash': recoveryKeyHash,
      'family_id': familyId,
      'person_uuid': personUuid,
      'name': name,
      'avatar_index': avatarIndex,
      'inviter_account_id': inviterAccountId,
      'public_key': publicKeyHex,
    });
  }

  Future<void> leave({
    required String accountId,
    required String recoveryKeyHash,
    required String familyId,
  }) {
    return _post('/family/leave', {
      'account_id': accountId,
      'recovery_key_hash': recoveryKeyHash,
      'family_id': familyId,
    });
  }

  /// Лише адміністратор (owner) сім'ї може виключати учасників — сервер
  /// сам перевіряє це і поверне 403, якщо викликати не від імені owner.
  Future<void> kick({
    required String accountId,
    required String recoveryKeyHash,
    required String familyId,
    required String targetAccountId,
  }) {
    return _post('/family/kick', {
      'account_id': accountId,
      'recovery_key_hash': recoveryKeyHash,
      'family_id': familyId,
      'target_account_id': targetAccountId,
    });
  }

  /// POST /family/status — повний стан усіх моїх сімей одним запитом:
  /// роль, статус підписки-власника, активні учасники, мої канали, гранти
  /// в обидва боки. Викликається на кожному тригері синку (resume/
  /// cold-start/pull-to-refresh) — замінює старе "просочування" через пірів.
  Future<FamilyStatusResult> status({
    required String accountId,
    required String recoveryKeyHash,
  }) async {
    final json = await _post('/family/status', {
      'account_id': accountId,
      'recovery_key_hash': recoveryKeyHash,
    });
    return FamilyStatusResult.fromJson(json);
  }

  Future<void> push({
    required String accountId,
    required String channelId,
    List<Map<String, dynamic>> entities = const [],
    List<Map<String, dynamic>> photos = const [],
  }) {
    return _post('/family/push', {
      'account_id': accountId,
      'channel_id': channelId,
      'entities': entities,
      'photos': photos,
    });
  }

  /// POST /family/sync — на відміну від старого /family-sync/pull (один
  /// channel_id за раз), тут одразу ВСІ мої канали одним запитом. Фото
  /// повертаються лише як метадані (без байтів) — самі байти через [photo].
  Future<FamilySyncPullResult> sync({
    required String accountId,
    DateTime? since,
  }) async {
    final json = await _post('/family/sync', {
      'account_id': accountId,
      if (since != null) 'since': since.toIso8601String(),
    });
    return FamilySyncPullResult(
      entities: (json['entities'] as List)
          .map((e) => FamilySyncEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: (json['photos'] as List? ?? [])
          .map((e) => FamilySyncPhotoMeta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /family/photo — байти одного фото/вкладення на вимогу (лише коли
  /// користувач реально відкриває конкретний запис).
  Future<Uint8List> photo({
    required String accountId,
    required String channelId,
    required String photoId,
  }) async {
    final json = await _post('/family/photo', {
      'account_id': accountId,
      'channel_id': channelId,
      'photo_id': photoId,
    });
    return base64Decode(json['bytes'] as String);
  }

  Future<void> grantsPush({
    required String accountId,
    required List<Map<String, dynamic>> grants,
  }) {
    return _post('/family/grants/push', {
      'account_id': accountId,
      'grants': grants,
    });
  }

  Future<List<FamilyGrantEntry>> grantsPull({required String accountId}) async {
    final json = await _post('/family/grants/pull', {'account_id': accountId});
    return (json['grants'] as List)
        .map((g) => FamilyGrantEntry.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerPush({
    required String accountId,
    required String pushToken,
    required String platform,
  }) {
    return _post('/family/register-push', {
      'account_id': accountId,
      'push_token': pushToken,
      'platform': platform,
    });
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw FamilyApiException(response.statusCode, _tryDecodeError(response.body));
    }
    if (response.body.isEmpty) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
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

class FamilySyncEntity {
  final String channelId;
  final String type;
  final String uuid;
  final Uint8List ciphertext;
  final bool deleted;
  final String updatedAt;

  const FamilySyncEntity({
    required this.channelId,
    required this.type,
    required this.uuid,
    required this.ciphertext,
    required this.deleted,
    required this.updatedAt,
  });

  factory FamilySyncEntity.fromJson(Map<String, dynamic> json) => FamilySyncEntity(
        channelId: json['channel_id'] as String,
        type: json['type'] as String,
        uuid: json['uuid'] as String,
        ciphertext: base64Decode(json['ciphertext'] as String),
        deleted: json['deleted'] as bool,
        updatedAt: json['updated_at'] as String,
      );
}

/// Лише метадані фото з /family/sync — самі байти підвантажуються окремо
/// через [FamilyApiClient.photo], коли користувач реально відкриває запис.
class FamilySyncPhotoMeta {
  final String channelId;
  final String photoId;
  final bool deleted;
  final String updatedAt;

  const FamilySyncPhotoMeta({
    required this.channelId,
    required this.photoId,
    required this.deleted,
    required this.updatedAt,
  });

  factory FamilySyncPhotoMeta.fromJson(Map<String, dynamic> json) => FamilySyncPhotoMeta(
        channelId: json['channel_id'] as String,
        photoId: json['photo_id'] as String,
        deleted: json['deleted'] as bool,
        updatedAt: json['updated_at'] as String,
      );
}

class FamilySyncPullResult {
  final List<FamilySyncEntity> entities;
  final List<FamilySyncPhotoMeta> photos;

  const FamilySyncPullResult({required this.entities, required this.photos});
}

class FamilyPlanInfo {
  final bool active;
  final String status;
  final String? productId;
  final DateTime? expiresAt;

  const FamilyPlanInfo({required this.active, required this.status, this.productId, this.expiresAt});

  factory FamilyPlanInfo.fromJson(Map<String, dynamic> json) => FamilyPlanInfo(
        active: json['active'] as bool? ?? false,
        status: json['status'] as String? ?? 'none',
        productId: json['product_id'] as String?,
        expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'active': active,
        'status': status,
        'product_id': productId,
        'expires_at': expiresAt?.toIso8601String(),
      };
}

class FamilyMemberEntry {
  final String accountId;
  final String personUuid;
  final String name;
  final int avatarIndex;
  final String publicKeyHex;
  final String status;

  const FamilyMemberEntry({
    required this.accountId,
    required this.personUuid,
    required this.name,
    required this.avatarIndex,
    required this.publicKeyHex,
    required this.status,
  });

  factory FamilyMemberEntry.fromJson(Map<String, dynamic> json) => FamilyMemberEntry(
        accountId: json['account_id'] as String,
        personUuid: json['person_uuid'] as String,
        name: json['name'] as String,
        avatarIndex: json['avatar_index'] as int? ?? 0,
        publicKeyHex: json['public_key'] as String? ?? '',
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'account_id': accountId,
        'person_uuid': personUuid,
        'name': name,
        'avatar_index': avatarIndex,
        'public_key': publicKeyHex,
        'status': status,
      };
}

class FamilyChannelEntry {
  final String channelId;
  final String counterpartAccountId;

  const FamilyChannelEntry({required this.channelId, required this.counterpartAccountId});

  factory FamilyChannelEntry.fromJson(Map<String, dynamic> json) => FamilyChannelEntry(
        channelId: json['channel_id'] as String,
        counterpartAccountId: json['counterpart_account_id'] as String,
      );

  Map<String, dynamic> toJson() => {
        'channel_id': channelId,
        'counterpart_account_id': counterpartAccountId,
      };
}

/// 'schedule' | 'medcard' | 'shelves'.
class FamilyGrantEntry {
  final String? ownerAccountId;
  final String subjectPersonUuid;
  final String? viewerAccountId;
  final String section;
  final bool canView;
  final bool canEdit;
  final bool notify;

  const FamilyGrantEntry({
    this.ownerAccountId,
    required this.subjectPersonUuid,
    this.viewerAccountId,
    required this.section,
    required this.canView,
    required this.canEdit,
    required this.notify,
  });

  factory FamilyGrantEntry.fromJson(Map<String, dynamic> json) => FamilyGrantEntry(
        ownerAccountId: json['owner_account_id'] as String?,
        subjectPersonUuid: json['subject_person_uuid'] as String,
        viewerAccountId: json['viewer_account_id'] as String?,
        section: json['section'] as String,
        canView: json['can_view'] as bool? ?? false,
        canEdit: json['can_edit'] as bool? ?? false,
        notify: json['notify'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'owner_account_id': ownerAccountId,
        'subject_person_uuid': subjectPersonUuid,
        'viewer_account_id': viewerAccountId,
        'section': section,
        'can_view': canView,
        'can_edit': canEdit,
        'notify': notify,
      };
}

class FamilyEntry {
  final String familyId;
  final String role; // 'admin' | 'member'
  final FamilyPlanInfo plan;
  final List<FamilyMemberEntry> members;
  final List<FamilyChannelEntry> channels;

  const FamilyEntry({
    required this.familyId,
    required this.role,
    required this.plan,
    required this.members,
    required this.channels,
  });

  factory FamilyEntry.fromJson(Map<String, dynamic> json) => FamilyEntry(
        familyId: json['family_id'] as String,
        role: json['role'] as String,
        plan: FamilyPlanInfo.fromJson(json['plan'] as Map<String, dynamic>),
        members: (json['members'] as List)
            .map((m) => FamilyMemberEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
        channels: (json['channels'] as List)
            .map((c) => FamilyChannelEntry.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'role': role,
        'plan': plan.toJson(),
        'members': members.map((m) => m.toJson()).toList(),
        'channels': channels.map((c) => c.toJson()).toList(),
      };
}

class FamilyStatusResult {
  final List<FamilyEntry> families;
  final List<FamilyGrantEntry> grantsFromMe;
  final List<FamilyGrantEntry> grantsToMe;

  const FamilyStatusResult({
    required this.families,
    required this.grantsFromMe,
    required this.grantsToMe,
  });

  factory FamilyStatusResult.fromJson(Map<String, dynamic> json) => FamilyStatusResult(
        families: (json['families'] as List)
            .map((f) => FamilyEntry.fromJson(f as Map<String, dynamic>))
            .toList(),
        grantsFromMe: (json['grants_from_me'] as List)
            .map((g) => FamilyGrantEntry.fromJson(g as Map<String, dynamic>))
            .toList(),
        grantsToMe: (json['grants_to_me'] as List)
            .map((g) => FamilyGrantEntry.fromJson(g as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'families': families.map((f) => f.toJson()).toList(),
        'grants_from_me': grantsFromMe.map((g) => g.toJson()).toList(),
        'grants_to_me': grantsToMe.map((g) => g.toJson()).toList(),
      };
}

class FamilyApiException implements Exception {
  final int statusCode;
  final String message;

  const FamilyApiException(this.statusCode, this.message);

  @override
  String toString() => 'FamilyApiException($statusCode): $message';
}
