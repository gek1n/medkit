import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backup_crypto_service.dart';
import 'google_drive_backup_service.dart';
import 'icloud_backup_service.dart';

enum BackupTarget { googleDrive, iCloud }

/// Оркеструє повний цикл бекапу: пакує вже зашифровані на диску файли
/// (medkit.db + med_photos/) у zip, окремо загортає ключі шифрування паролем
/// бекапу (`BackupCryptoService`), і завантажує обидва blob'и у Google
/// Drive/iCloud. Хмара ніколи не бачить нічого нешифрованого — ні саму БД
/// (вже SQLCipher), ні фото (вже AES-GCM), ні самі ключі шифрування
/// (обгорнуті окремо паролем, який хмарі теж не відомий).
class BackupService {
  final _drive = GoogleDriveBackupService();
  final _icloud = ICloudBackupService();

  Future<void> createBackup({required BackupTarget target, required String passphrase}) async {
    final zipBytes = await _buildZip();
    final keysBlob = await BackupCryptoService.wrapKeys(passphrase);

    switch (target) {
      case BackupTarget.googleDrive:
        await _drive.uploadBackup(zipBytes: zipBytes, keysBlob: keysBlob);
      case BackupTarget.iCloud:
        await _icloud.uploadBackup(zipBytes: zipBytes, keysBlob: keysBlob);
    }
  }

  /// Відновлює ключі шифрування і файли з хмари. Після виклику застосунок
  /// потрібно перезапустити, щоб Drift переоткрив БД з відновленим ключем.
  Future<void> restoreBackup({required BackupTarget target, required String passphrase}) async {
    final (:zipBytes, :keysBlob) = switch (target) {
      BackupTarget.googleDrive => await _drive.downloadBackup(),
      BackupTarget.iCloud => await _icloud.downloadBackup(),
    };

    // Розшифровується паролем ПЕРЕД записом файлів — якщо пароль невірний,
    // виняток вилетить тут і жоден локальний файл не буде зачеплено.
    await BackupCryptoService.unwrapAndInstallKeys(keysBlob, passphrase);
    await _extractZip(zipBytes);
  }

  Future<Uint8List> _buildZip() async {
    final docs = await getApplicationDocumentsDirectory();
    final archive = Archive();

    // Drift/SQLCipher працює в WAL-режимі за замовчуванням — окрім
    // medkit.db, останні незакеймічені зміни можуть лежати в medkit.db-wal
    // (+ medkit.db-shm, спільна пам'ять-індекс до неї). Пакувати ЛИШЕ
    // головний файл означало б (а) губити найсвіжіші записи, яких ще не
    // було checkpoint, і (б) головне — якщо на пристрої з якоїсь причини
    // вже лежить ОСИРОТІЛА wal від іншої генерації бази, наступний
    // extractZip() змішав би її з відновленим головним файлом і дав ту
    // саму SqliteException(26) "file is not a database", яку відновлення
    // з бекапу якраз мало виправити. Пакуємо всі наявні файли-супутники
    // разом, як єдиний узгоджений знімок.
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File('${p.join(docs.path, 'medkit.db')}$suffix');
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        archive.addFile(ArchiveFile('medkit.db$suffix', bytes.length, bytes));
      }
    }

    final photosDir = Directory(p.join(docs.path, 'med_photos'));
    if (await photosDir.exists()) {
      await for (final entity in photosDir.list(recursive: true)) {
        if (entity is File) {
          final relative = p.join('med_photos', p.relative(entity.path, from: photosDir.path));
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relative, bytes.length, bytes));
        }
      }
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  Future<void> _extractZip(Uint8List zipBytes) async {
    final docs = await getApplicationDocumentsDirectory();

    // Прибираємо БУДЬ-ЯКІ наявні на пристрої medkit.db(-wal/-shm) ДО
    // розпакування — інакше стара, вже на диску WAL-супутня від
    // попередньої (можливо іншої) генерації бази могла б лишитись поруч із
    // щойно відновленим головним файлом і дати salt-розсинхрон при
    // наступному відкритті (та сама причина, що й у
    // DbEncryptionService.resetCorruptedDatabase — див. коментар там).
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File('${p.join(docs.path, 'medkit.db')}$suffix');
      if (await f.exists()) {
        await f.delete();
      }
    }

    final archive = ZipDecoder().decodeBytes(zipBytes);

    for (final file in archive) {
      if (!file.isFile) continue;
      final outFile = File(p.join(docs.path, file.name));
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }
}
