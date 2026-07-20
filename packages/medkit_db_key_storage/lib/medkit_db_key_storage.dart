import 'package:flutter/services.dart';

/// Мінімальний нативний сховище невеликої, наперед відомої кількості
/// секретів — див. опис у pubspec.yaml цього пакету. [account] розрізняє
/// один секрет від іншого (напр. ключ шифрування БД проти ключа шифрування
/// вкладень) — за замовчуванням лишається початковий `db_encryption_key` для
/// зворотної сумісності з усіма наявними викликами. Кожен метод — один
/// прямий виклик платформного каналу, без жодної логіки ретраїв чи варіацій
/// параметрів на боці Dart: уся визначеність — у тому, що нативний код по
/// обидва боки завжди використовує ОДИН і той самий, раз і назавжди
/// фіксований набір атрибутів сховища для кожного окремого [account].
class MedkitDbKeyStorage {
  MedkitDbKeyStorage._();

  static const MethodChannel _channel =
      MethodChannel('medkit.dev/db_key_storage');
  static const _defaultAccount = 'db_encryption_key';

  /// Повертає збережене значення, або null, якщо його ще нема.
  static Future<String?> read({String account = _defaultAccount}) async {
    return _channel.invokeMethod<String>('read', {'account': account});
  }

  static Future<void> write(
    String value, {
    String account = _defaultAccount,
  }) async {
    await _channel
        .invokeMethod<void>('write', {'value': value, 'account': account});
  }

  static Future<void> delete({String account = _defaultAccount}) async {
    await _channel.invokeMethod<void>('delete', {'account': account});
  }
}
