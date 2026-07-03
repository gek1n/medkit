import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class PhotoService {
  static const _dir = 'med_photos';
  static const _uuid = Uuid();

  // Абсолютний шлях з відносного
  static Future<String> absolutePath(String relative) async {
    final base = await getApplicationDocumentsDirectory();
    return p.join(base.path, relative);
  }

  // Відносний шлях зберігаємо в БД
  static Future<String?> pickAndSave(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return null;

    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _dir));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path)
        : '.jpg';
    final filename = '${_uuid.v4()}$ext';
    final dest = p.join(dir.path, filename);

    await File(picked.path).copy(dest);
    return '$_dir/$filename'; // відносний шлях
  }

  static Future<void> delete(String relative) async {
    final abs = await absolutePath(relative);
    final f = File(abs);
    if (f.existsSync()) f.deleteSync();
  }

  // Показати діалог: камера або галерея
  static Future<String?> showPickerDialog(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
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
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Вибрати з галереї'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return pickAndSave(source);
  }
}
