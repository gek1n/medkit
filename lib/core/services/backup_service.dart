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

    final dbFile = File(p.join(docs.path, 'medkit.db'));
    if (await dbFile.exists()) {
      final bytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('medkit.db', bytes.length, bytes));
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
    final archive = ZipDecoder().decodeBytes(zipBytes);

    for (final file in archive) {
      if (!file.isFile) continue;
      final outFile = File(p.join(docs.path, file.name));
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }
}
