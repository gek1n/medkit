import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medkit_db_key_storage/medkit_db_key_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db_encryption_service.dart';
import 'file_encryption_service.dart';

/// Пакує ВЕСЬ secure storage пристрою (не лише ключі шифрування БД/файлів,
/// а й обліковий запис синхронізації з AccountService, і per-канальні ключі
/// SharedChannelKeyStorage для сімейної синхронізації) в один маленький blob,
/// захищений паролем бекапу (Argon2id -> AES-256-GCM, той самий підхід, що і
/// в `pairing_crypto_service.dart`). Сам бекап (medkit.db + med_photos/) вже
/// зашифрований ключами звідси на диску — хмара (Google Drive/iCloud) ніколи
/// не бачить plaintext, а без пароля бекапу нічого з архіву не витягнути,
/// навіть маючи повний доступ до хмарного сховища.
///
/// Здебільшого readAll(), а не список конкретних ключів — так відновлення
/// лишається повним автоматично і для розділів, доданих ПІСЛЯ написання
/// цього файлу (будь-що нове, що зберігається через flutter_secure_storage,
/// саме потрапить у бекап без окремої правки тут). Виняток — ключ шифрування
/// БД (`DbEncryptionService`): він живе в ОКРЕМОМУ нативному сховищі
/// (medkit_db_key_storage), яке readAll() фізично не бачить, тож для нього —
/// явний виклик `DbEncryptionService.currentKeyForBackup()` (див.
/// `_nativeDbKeyEnvelopeKey` нижче).
///
/// Додатково (з `_backedUpPrefsKeys`) пакує explicit allowlist рядкових
/// значень із SharedPreferences — власноруч додані елементи "спільний
/// список + свої варіанти" (напр. `SymptomLibraryService`,
/// `LabTestLibraryService`), які інакше губляться при відновленні бекапу:
/// старі записи в БД, де такий варіант уже використаний, лишаються
/// читабельними (БД відновлюється окремо, через zip), але сам варіант
/// зникає зі списку вибору для НОВИХ записів, бо SharedPreferences не
/// зачіпають ні цей клас, ні `BackupService._buildZip()`. На відміну від
/// secure storage — тут НЕ readAll(): SharedPreferences містить і суто
/// локальні налаштування пристрою (мова, тема), які не повинні "переїжджати"
/// між пристроями при відновленні.
class BackupCryptoService {
  static const _secureStorage = FlutterSecureStorage();
  static const _syncedIOSOptions = IOSOptions(synchronizable: true);
  // Ключі AccountService навмисно пишуться з synchronizable:true (iCloud
  // Keychain) — readAll() з дефолтними опціями на iOS їх не бачить, тож
  // читаємо/пишемо і цю групу окремо, щоб жодного значення не загубити.
  static const _syncedKeyNames = {
    'sync_mode',
    'sync_account_id',
    'sync_encryption_key',
    'sync_recovery_key_hash',
  };

  // "Спільний+власний" списки (типова назва аналізу, симптому тощо), де
  // власноруч додані користувачем варіанти зберігаються в SharedPreferences,
  // а не в БД чи secure storage — жоден з тих двох механізмів backup їх не
  // зачіпає. Без цього списку розсинхрон резервної копії від
  // SharedPreferences (реальний звіт: після відновлення бекапу власноруч
  // додані симптоми зникали зі списку вибору, хоча старі записи в БД, де
  // вони вже використані, лишались читабельними — самі назви просто більше
  // не пропонувались для нового вибору). На відміну від secure storage,
  // тут НЕ можна просто "прочитати все" — SharedPreferences містить і суто
  // локальні налаштування пристрою (мова, тема), які НЕ мають переїжджати
  // між пристроями при відновленні бекапу, тож явний allowlist навмисний.
  // Додавайте сюди кожен новий `_customKey` за тим самим патерном
  // ("спільний список + свої варіанти, збережені в SharedPreferences").
  static const _backedUpPrefsKeys = {
    'wellbeing_custom_symptoms', // SymptomLibraryService
    'lab_test_custom_names', // LabTestLibraryService
  };
  static const _prefsKeyPrefix = 'prefs:';

  // Ключ шифрування локальної БД (DbEncryptionService) з версії, коли
  // перейшли на власний нативний плагін medkit_db_key_storage, більше НЕ
  // видно через readAll() нижче — той дивиться лише в flutter_secure_storage,
  // а наше сховище тепер повністю окреме (Keychain/Keystore напряму, без
  // цього пакета). Реальний наслідок ДО цього виправлення: ключ БД, судячи з
  // усього, взагалі не потрапляв у хмарний бекап на iOS (readAll() з
  // дефолтним accessibility "unlocked" не бачив запис із
  // "first_unlock_this_device" — різні accessibility-рівні Keychain
  // фактично ізольовані одне від одного), тож відновлення з бекапу могло
  // розпакувати файл medkit.db, але без ключа до нього. Читаємо/пишемо
  // явно, окремим ключем у конверті.
  static const _nativeDbKeyEnvelopeKey = 'native:db_encryption_key';

  // Той самий випадок, що й вище, для ключа шифрування вкладень
  // (FileEncryptionService) після його переходу на те саме нативне сховище —
  // readAll() теж більше його не бачить.
  static const _nativeFileKeyEnvelopeKey = 'native:file_encryption_key';

  static final _cipher = AesGcm.with256bits();

  static Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final argon2 = Argon2id(
      memory: 19456,
      iterations: 2,
      parallelism: 1,
      hashLength: 32,
    );
    return argon2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  /// Читає УВЕСЬ secure storage поточного пристрою (ключі шифрування БД/
  /// файлів, обліковий запис синхронізації, канальні ключі сімейної
  /// синхронізації — і будь-що додане пізніше) і шифрує паролем бекапу.
  /// Повертає готовий до запису у файл blob: [salt(16)][nonce(12)][ciphertext][mac(16)].
  static Future<Uint8List> wrapKeys(String passphrase) async {
    final prefs = await SharedPreferences.getInstance();
    final dbKey = await DbEncryptionService.currentKeyForBackup();
    final fileKey = await FileEncryptionService.currentKeyForBackup();
    final entries = <String, String>{
      ...await _secureStorage.readAll(),
      ...await _secureStorage.readAll(iOptions: _syncedIOSOptions),
      if (dbKey != null) _nativeDbKeyEnvelopeKey: dbKey,
      if (fileKey != null) _nativeFileKeyEnvelopeKey: fileKey,
      for (final prefsKey in _backedUpPrefsKeys)
        if (prefs.getString(prefsKey) != null)
          '$_prefsKeyPrefix$prefsKey': prefs.getString(prefsKey)!,
    };
    if (entries.isEmpty) {
      throw StateError('Ключі шифрування не знайдено на цьому пристрої');
    }

    final envelope = utf8.encode(jsonEncode(entries));

    final salt = _generateSalt();
    final key = await _deriveKey(passphrase, salt);
    final nonce = _cipher.newNonce();
    final box = await _cipher.encrypt(envelope, secretKey: key, nonce: nonce);

    return Uint8List.fromList([
      ...salt,
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// Обернена операція — розшифровує blob паролем бекапу і записує усі
  /// значення в secure storage ЦЬОГО пристрою (перезаписуючи наявні, якщо є —
  /// виклик відновлення завжди має бути свідомим рішенням користувача).
  /// Кидає виняток, якщо пароль невірний.
  static Future<void> unwrapAndInstallKeys(Uint8List blob, String passphrase) async {
    const saltLength = 16;
    const nonceLength = 12;
    const macLength = 16;
    if (blob.length < saltLength + nonceLength + macLength) {
      throw const FormatException('Файл резервної копії пошкоджений');
    }

    final salt = blob.sublist(0, saltLength);
    final nonce = blob.sublist(saltLength, saltLength + nonceLength);
    final mac = blob.sublist(blob.length - macLength);
    final cipherText = blob.sublist(saltLength + nonceLength, blob.length - macLength);

    final key = await _deriveKey(passphrase, salt);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final plain = await _cipher.decrypt(box, secretKey: key);

    final envelope = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in envelope.entries) {
      if (entry.key.startsWith(_prefsKeyPrefix)) {
        await prefs.setString(
          entry.key.substring(_prefsKeyPrefix.length),
          entry.value as String,
        );
        continue;
      }
      if (entry.key == _nativeDbKeyEnvelopeKey) {
        await MedkitDbKeyStorage.write(entry.value as String);
        continue;
      }
      if (entry.key == _nativeFileKeyEnvelopeKey) {
        await MedkitDbKeyStorage.write(
          entry.value as String,
          account: 'file_encryption_key',
        );
        continue;
      }
      final synced = _syncedKeyNames.contains(entry.key);
      await _secureStorage.write(
        key: entry.key,
        value: entry.value as String,
        iOptions: synced ? _syncedIOSOptions : const IOSOptions(),
      );
    }
  }
}
