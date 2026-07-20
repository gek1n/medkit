import 'package:flutter/services.dart';

/// Мінімальний нативний сховище рівно одного секрету (ключа шифрування
/// локальної БД) — див. опис у pubspec.yaml цього пакету. Кожен метод —
/// один прямий виклик платформного каналу, без жодної логіки ретраїв чи
/// варіацій параметрів на боці Dart: уся визначеність — у тому, що нативний
/// код по обидва боки завжди використовує ОДИН і той самий, раз і назавжди
/// фіксований набір атрибутів сховища.
class MedkitDbKeyStorage {
  MedkitDbKeyStorage._();

  static const MethodChannel _channel =
      MethodChannel('medkit.dev/db_key_storage');

  /// Повертає збережене значення, або null, якщо його ще нема.
  static Future<String?> read() async {
    return _channel.invokeMethod<String>('read');
  }

  static Future<void> write(String value) async {
    await _channel.invokeMethod<void>('write', {'value': value});
  }

  static Future<void> delete() async {
    await _channel.invokeMethod<void>('delete');
  }
}
