import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account_api_client.dart';

enum SyncMode { local, noAccount, account }

/// Керує "акаунтом синхронізації" — і в режимі без OAuth (recovery key), і
/// в режимі з Google/Apple Sign-In. Ключ шифрування синхронізації і хеш для
/// пошуку на сервері — обидва похідні одного секрету (recovery key), але
/// різними односторонніми функціями: сервер бачить лише sha256(key), а
/// AES-ключ (HMAC-SHA256 з іншим info-рядком) сюди ніколи не потрапляє.
/// Recovery key — вже високоентропійний (~119 біт), тому Argon2id тут не
/// потрібен (на відміну від пейринг-коду, який людина могла б вгадати) —
/// просто HMAC для розділення призначень.
///
/// Google/Apple Sign-In НІКОЛИ не бере участі в цій KDF — OAuth тут лише
/// ідентифікація (щоб знайти свій account_id, не вводячи recovery key
/// вручну щоразу). Ключ шифрування завжди йде з recovery key, збереженого
/// через `flutter_secure_storage` з увімкненою iCloud-синхронізацією на
/// iOS (`IOSOptions(synchronizable: true)`) — на новому iPhone з тим самим
/// Apple ID ключ підтягнеться сам, без ручного введення recovery key.
class AccountService {
  static const _secureStorage = FlutterSecureStorage();
  static const _syncedIOSOptions = IOSOptions(synchronizable: true);
  static const _syncModeKey = 'sync_mode';
  static const _accountIdKey = 'sync_account_id';
  static const _syncKeyKey = 'sync_encryption_key';
  static const _recoveryKeyHashKey = 'sync_recovery_key_hash';
  // На відміну від recovery key (ніколи не зберігається як є) — це
  // одностороння похідна (sha256), кешувати безпечно: сама по собі не дає
  // доступу до розшифровки нічого, лише дозволяє серверу підтвердити "цей
  // пристрій знає ключ від акаунта X" для API, що не потребують такого
  // самого рівня захисту, як видалення акаунта (напр. SubscriptionService —
  // /subscription/status/verify викликаються часто, повторно просити ввести
  // recovery key щоразу було б неможливим UX).

  static const _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const _groups = 6;
  static const _groupLength = 4;

  static const _hkdfKeyInfo = 'medkit-sync-encryption-key-v1';

  // Те саме значення має бути в GOOGLE_CLIENT_ID на бекенді
  // (DEPLOY.md, крок 11) — інакше сервер не зможе перевірити підпис
  // id_token, підписаного Google під цю ж audience.
  static const _googleServerClientId =
      '964528755773-n4lo22v5npjjk8nlon0eertoaap8d2qp.apps.googleusercontent.com';

  final _apiClient = const AccountApiClient();
  final _googleSignIn = GoogleSignIn(serverClientId: _googleServerClientId);

  /// Генерує новий recovery key для показу користувачеві, у форматі
  /// "XXXX-XXXX-XXXX-XXXX-XXXX-XXXX" (~119 біт ентропії).
  static String generateRecoveryKey() {
    final random = Random.secure();
    final groups = List.generate(
      _groups,
      (_) => List.generate(_groupLength, (_) => _alphabet[random.nextInt(_alphabet.length)]).join(),
    );
    return groups.join('-');
  }

  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String _recoveryKeyHash(String normalizedKey) {
    final digest = Sha256().toSync().hashSync(utf8.encode(normalizedKey));
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<SecretKey> _deriveSyncKey(String normalizedKey) async {
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(_hkdfKeyInfo),
      secretKey: SecretKey(utf8.encode(normalizedKey)),
    );
    return SecretKey(mac.bytes);
  }

  Future<void> _persist({
    required SyncMode mode,
    required String accountId,
    required SecretKey syncKey,
    required String recoveryKeyHash,
  }) async {
    await _secureStorage.write(key: _syncModeKey, value: mode.name);
    await _secureStorage.write(key: _accountIdKey, value: accountId, iOptions: _syncedIOSOptions);
    await _secureStorage.write(
      key: _syncKeyKey,
      value: base64Encode(await syncKey.extractBytes()),
      iOptions: _syncedIOSOptions,
    );
    await _secureStorage.write(key: _recoveryKeyHashKey, value: recoveryKeyHash, iOptions: _syncedIOSOptions);
  }

  /// Створює новий акаунт синхронізації з щойно згенерованим recovery key.
  Future<void> enableNoAccountSync(String recoveryKeyDisplay) async {
    final normalized = normalize(recoveryKeyDisplay);
    final hash = _recoveryKeyHash(normalized);
    final accountId = await _apiClient.create(recoveryKeyHash: hash);
    final syncKey = await _deriveSyncKey(normalized);
    await _persist(mode: SyncMode.noAccount, accountId: accountId, syncKey: syncKey, recoveryKeyHash: hash);
  }

  /// Відновлює доступ до акаунта на новому пристрої за вже наявним recovery key.
  Future<void> restoreFromRecoveryKey(String recoveryKeyDisplay) async {
    final normalized = normalize(recoveryKeyDisplay);
    final hash = _recoveryKeyHash(normalized);
    final accountId = await _apiClient.login(recoveryKeyHash: hash);
    final syncKey = await _deriveSyncKey(normalized);
    await _persist(mode: SyncMode.noAccount, accountId: accountId, syncKey: syncKey, recoveryKeyHash: hash);
  }

  /// Google Sign-In — повертає ID-токен для перевірки на сервері. Просить
  /// лише ідентифікацію, без Drive-доступу (той — окремий, у `GoogleDriveBackupService`).
  Future<String> _googleIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Вхід через Google скасовано');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw StateError('Google не повернув ID-токен');
    }
    return idToken;
  }

  /// Sign in with Apple — повертає identity-токен для перевірки на сервері.
  /// Без email/fullName scopes — вони нам не потрібні, ми взагалі не
  /// зберігаємо жодних персональних даних користувача.
  Future<String> _appleIdentityToken() async {
    final credential = await SignInWithApple.getAppleIDCredential(scopes: const []);
    final token = credential.identityToken;
    if (token == null) {
      throw StateError('Apple не повернув identity-токен');
    }
    return token;
  }

  Future<String> _oauthToken(String provider) => switch (provider) {
        'google' => _googleIdToken(),
        'apple' => _appleIdentityToken(),
        _ => throw ArgumentError('Невідомий провайдер: $provider'),
      };

  /// Створює акаунт синхронізації, прив'язаний і до Google/Apple (для
  /// зручного входу), і до recovery key (єдине реальне джерело ключа
  /// шифрування — токен у KDF не бере участі).
  Future<void> enableAccountSync({
    required String provider,
    required String recoveryKeyDisplay,
  }) async {
    final token = await _oauthToken(provider);
    final normalized = normalize(recoveryKeyDisplay);
    final hash = _recoveryKeyHash(normalized);
    final accountId = await _apiClient.create(
      recoveryKeyHash: hash,
      authProvider: provider,
      authToken: token,
    );
    final syncKey = await _deriveSyncKey(normalized);
    await _persist(mode: SyncMode.account, accountId: accountId, syncKey: syncKey, recoveryKeyHash: hash);
  }

  /// Крок 1 відновлення через акаунт: знаходить account_id за Google/Apple
  /// ID. Ключ шифрування після цього все одно береться окремо —
  /// або з secure storage (якщо це той самий пристрій/iCloud-синк вже
  /// підтягнув його сам), або через [attachRecoveryKey] нижче.
  Future<String> findAccountViaOAuth(String provider) async {
    final token = await _oauthToken(provider);
    return _apiClient.loginOAuth(authProvider: provider, authToken: token);
  }

  /// Крок 2 (якщо secure storage ще не має ключа на цьому пристрої) —
  /// довести recovery key, щоб вивести й зберегти ключ шифрування локально.
  Future<void> attachRecoveryKey({required String accountId, required String recoveryKeyDisplay}) async {
    final normalized = normalize(recoveryKeyDisplay);
    final hash = _recoveryKeyHash(normalized);
    final syncKey = await _deriveSyncKey(normalized);
    await _persist(mode: SyncMode.account, accountId: accountId, syncKey: syncKey, recoveryKeyHash: hash);
  }

  /// Вимикає синхронізацію — локальні дані не чіпає, лише прибирає локальні
  /// облікові дані про акаунт синхронізації.
  Future<void> disableSync() async {
    await _secureStorage.delete(key: _syncModeKey);
    await _secureStorage.delete(key: _accountIdKey, iOptions: _syncedIOSOptions);
    await _secureStorage.delete(key: _syncKeyKey, iOptions: _syncedIOSOptions);
    await _secureStorage.delete(key: _recoveryKeyHashKey, iOptions: _syncedIOSOptions);
  }

  /// GDPR — остаточно видаляє акаунт і всі дані на сервері, потім вимикає
  /// синхронізацію локально. Потребує ще раз ввести recovery key (щоб ніхто
  /// сторонній не міг стерти акаунт, лише маючи розблокований пристрій).
  Future<void> deleteAccountEverywhere(String recoveryKeyDisplay) async {
    final normalized = normalize(recoveryKeyDisplay);
    final hash = _recoveryKeyHash(normalized);
    final accountId = await _secureStorage.read(key: _accountIdKey, iOptions: _syncedIOSOptions);
    if (accountId == null) {
      throw StateError('Синхронізація не увімкнена на цьому пристрої');
    }
    await _apiClient.delete(accountId: accountId, recoveryKeyHash: hash);
    await disableSync();
  }

  Future<SyncMode> currentMode() async {
    final raw = await _secureStorage.read(key: _syncModeKey);
    return SyncMode.values.firstWhere((m) => m.name == raw, orElse: () => SyncMode.local);
  }

  Future<String?> currentAccountId() async {
    return _secureStorage.read(key: _accountIdKey, iOptions: _syncedIOSOptions);
  }

  Future<String?> currentRecoveryKeyHash() async {
    return _secureStorage.read(key: _recoveryKeyHashKey, iOptions: _syncedIOSOptions);
  }

  Future<SecretKey?> currentSyncKey() async {
    final b64 = await _secureStorage.read(key: _syncKeyKey, iOptions: _syncedIOSOptions);
    if (b64 == null) return null;
    return SecretKey(base64Decode(b64));
  }
}
