import 'dart:io';
import 'dart:typed_data';

import 'package:icloud_storage/icloud_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Бекап у контейнер iCloud Drive застосунку (не Key-Value Store — там ліміт
/// 1МБ, а фото можуть бути більшими). Файли й тут вже зашифровані на диску
/// (SQLCipher + AES-256-GCM), iCloud бачить лише зашифровані байти.
///
/// ⚠️ Потребує ввімкненого iCloud capability в Xcode (Signing & Capabilities
/// -> iCloud -> CloudKit/iCloud Documents) з тим самим containerId, що і
/// нижче — це робиться на Mac, окремо від Dart-коду, потребує Apple
/// Developer акаунта. Без цього `gather`/`upload`/`download` кинуть виняток
/// про відсутній контейнер.
class ICloudBackupService {
  static const _containerId = 'iCloud.com.ellyapp.medkit';
  static const _backupFileName = 'medkit_backup.zip';
  static const _keysFileName = 'medkit_backup_keys.bin';

  Future<void> uploadBackup({required Uint8List zipBytes, required Uint8List keysBlob}) async {
    final tmp = await getTemporaryDirectory();
    final zipPath = p.join(tmp.path, _backupFileName);
    final keysPath = p.join(tmp.path, _keysFileName);
    await File(zipPath).writeAsBytes(zipBytes);
    await File(keysPath).writeAsBytes(keysBlob);

    await ICloudStorage.upload(
      containerId: _containerId,
      filePath: zipPath,
      destinationRelativePath: _backupFileName,
    );
    await ICloudStorage.upload(
      containerId: _containerId,
      filePath: keysPath,
      destinationRelativePath: _keysFileName,
    );
  }

  Future<({Uint8List zipBytes, Uint8List keysBlob})> downloadBackup() async {
    final files = await ICloudStorage.gather(containerId: _containerId);
    final hasBackup = files.any((f) => f.relativePath == _backupFileName);
    final hasKeys = files.any((f) => f.relativePath == _keysFileName);
    if (!hasBackup || !hasKeys) {
      throw StateError('Резервну копію в iCloud не знайдено');
    }

    final tmp = await getTemporaryDirectory();
    final zipPath = p.join(tmp.path, 'restore_$_backupFileName');
    final keysPath = p.join(tmp.path, 'restore_$_keysFileName');

    await ICloudStorage.download(
      containerId: _containerId,
      relativePath: _backupFileName,
      destinationFilePath: zipPath,
    );
    await ICloudStorage.download(
      containerId: _containerId,
      relativePath: _keysFileName,
      destinationFilePath: keysPath,
    );

    return (
      zipBytes: await File(zipPath).readAsBytes(),
      keysBlob: await File(keysPath).readAsBytes(),
    );
  }
}
