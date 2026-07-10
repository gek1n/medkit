import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'file_encryption_service.dart';
import 'photo_sync_queue.dart';

enum _PickKind { camera, gallery, pdf }

class PhotoService {
  static const _dir = 'med_photos';
  static const _uuid = Uuid();

  // Абсолютний шлях з відносного (файл на диску зашифрований — для
  // відображення використовуйте decryptedBytes, а не Image.file напряму).
  static Future<String> absolutePath(String relative) async {
    final base = await getApplicationDocumentsDirectory();
    return p.join(base.path, relative);
  }

  /// Розшифровані байти вкладення (фото чи PDF) — готові для Image.memory()
  /// або запису у тимчасовий файл для перегляду/шерингу.
  static Future<Uint8List> decryptedBytes(String relative) async {
    final abs = await absolutePath(relative);
    final blob = await File(abs).readAsBytes();
    return FileEncryptionService.decryptBytes(blob);
  }

  /// true, якщо вкладення за розширенням — PDF, а не зображення (для UI:
  /// показувати іконку файлу замість Image.memory-прев'ю).
  static bool isPdf(String relative) => relative.toLowerCase().endsWith('.pdf');

  // ⚠️ Усі вкладення (фото ліків, фото/PDF документи медкартки) свідомо
  // йдуть в одну й ту саму `med_photos/` — `BackupService._buildZip()`
  // хардкодить саме цю директорію при пакуванні бекапу, окрема тека
  // мовчки випала б з резервної копії.
  static Future<String> _saveBytes(Uint8List plainBytes, String ext) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _dir));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final filename = '${_uuid.v4()}$ext';
    final dest = p.join(dir.path, filename);

    final encrypted = await FileEncryptionService.encryptBytes(plainBytes);
    await File(dest).writeAsBytes(encrypted);

    final relative = '$_dir/$filename';
    // Не блокує збереження, якщо сама позначка в чергу з якоїсь причини не
    // вдалась — синхронізація опційна, файл вже безпечно на диску.
    unawaited(PhotoSyncQueue.markPendingUpload(relative));
    return relative;
  }

  // Відносний шлях зберігаємо в БД. Сам файл на диску — вже зашифрований,
  // plaintext-копію в своїй директорії ми ніколи не пишемо.
  static Future<String?> pickAndSave(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return null;

    final ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path)
        : '.jpg';
    final plainBytes = await File(picked.path).readAsBytes();
    return _saveBytes(plainBytes, ext);
  }

  /// Вибір PDF-файлу з файлової системи пристрою (не через ImagePicker —
  /// той працює лише з фото).
  static Future<String?> pickAndSavePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final plainBytes = await File(path).readAsBytes();
    return _saveBytes(plainBytes, '.pdf');
  }

  static Future<void> delete(String relative) async {
    final abs = await absolutePath(relative);
    final f = File(abs);
    if (f.existsSync()) f.deleteSync();
    unawaited(PhotoSyncQueue.markPendingDelete(relative));
  }

  // Показати діалог: камера, галерея або PDF-файл
  static Future<String?> showPickerDialog(BuildContext context) async {
    final choice = await showModalBottomSheet<_PickKind>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Зробити фото'),
              onTap: () => Navigator.pop(context, _PickKind.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Вибрати з галереї'),
              onTap: () => Navigator.pop(context, _PickKind.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Обрати PDF-файл'),
              onTap: () => Navigator.pop(context, _PickKind.pdf),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (choice) {
      case _PickKind.camera:
        return pickAndSave(ImageSource.camera);
      case _PickKind.gallery:
        return pickAndSave(ImageSource.gallery);
      case _PickKind.pdf:
        return pickAndSavePdf();
      case null:
        return null;
    }
  }
}
