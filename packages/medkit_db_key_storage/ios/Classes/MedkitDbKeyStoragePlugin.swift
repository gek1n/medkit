import Flutter
import Foundation
import Security

/// Прямий, мінімальний Keychain-враппер для невеликої, наперед відомої
/// кількості секретів (ключ шифрування локальної БД, ключ шифрування вкладень
/// — `account` розрізняє їх один від одного). На відміну від generic-пакетів
/// (flutter_secure_storage), тут для КОЖНОГО окремого `account` ЗАВЖДИ
/// використовується один і той самий, раз і назавжди фіксований набір
/// атрибутів запиту — kSecAttrService/kSecAttrAccessible/kSecAttrSynchronizable
/// НІКОЛИ не варіюються між викликами read/write/delete для одного й того ж
/// `account`. Це структурно унеможливлює клас багів, з яким ми зіткнулись у
/// flutter_secure_storage: коли write() з одним набором атрибутів не знаходить
/// (і тому не оновлює) запис, залишений іншим набором, і в Keychain
/// накопичуються дублікати з непередбачуваним порядком читання.
///
/// kSecAttrService — окремий, унікальний рядок (не той, що використовує
/// flutter_secure_storage за замовчуванням) — гарантує, що ці записи живуть у
/// повністю ізольованому "просторі імен" Keychain, без жодного перетину зі
/// старими записами.
public class MedkitDbKeyStoragePlugin: NSObject, FlutterPlugin {
  private static let service = "com.ellyapp.medkit.dbkeystorage"
  private static let defaultAccount = "db_encryption_key"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "medkit.dev/db_key_storage",
      binaryMessenger: registrar.messenger()
    )
    let instance = MedkitDbKeyStoragePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // Один фіксований набір атрибутів на кожен account — використовується і для
  // write (add/update), і для read, і для delete. Жодних інших варіантів ніде
  // в цьому файлі. `account` — єдине, що відрізняє один секрет від іншого.
  private static func baseQuery(account: String) -> [CFString: Any] {
    return [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecAttrSynchronizable: false,
    ]
  }

  private static func account(from call: FlutterMethodCall) -> String {
    guard let args = call.arguments as? [String: Any],
      let account = args["account"] as? String, !account.isEmpty
    else {
      return defaultAccount
    }
    return account
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let account = MedkitDbKeyStoragePlugin.account(from: call)
    switch call.method {
    case "read":
      result(readValue(account: account))
    case "write":
      guard let args = call.arguments as? [String: Any],
        let value = args["value"] as? String
      else {
        result(FlutterError(code: "invalid_args", message: "value missing", details: nil))
        return
      }
      result(writeValue(value, account: account))
    case "delete":
      result(deleteValue(account: account))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func readValue(account: String) -> Any {
    var query = MedkitDbKeyStoragePlugin.baseQuery(account: account)
    query[kSecReturnData] = true
    query[kSecMatchLimit] = kSecMatchLimitOne

    var item: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound {
      // Значення ще нема — цілком нормальний стан (перший запуск на цьому
      // пристрої), а не помилка: звичайний успішний результат nil, без
      // FlutterError, щоб виклик-сторона не мусила ловити виняток на
      // абсолютно очікуваному шляху.
      return NSNull()
    }
    if status == errSecInteractionNotAllowed {
      // Пристрій не розблоковували з моменту перезавантаження — Keychain
      // фізично на місці, але зараз недосяжний. НЕ "ключа нема" — код
      // навмисно відрізняється від not_found, щоб Dart-сторона (
      // DbEncryptionService) могла показати "розблокуйте пристрій", а не
      // деструктивний скид БД.
      return FlutterError(
        code: "keychain_locked",
        message: "Device not unlocked since boot",
        details: Int(status)
      )
    }
    guard status == errSecSuccess, let data = item as? Data,
      let value = String(data: data, encoding: .utf8)
    else {
      return FlutterError(code: "read_failed", message: nil, details: Int(status))
    }
    return value
  }

  private func writeValue(_ value: String, account: String) -> Any? {
    guard let data = value.data(using: .utf8) else {
      return FlutterError(code: "invalid_args", message: "value not UTF-8", details: nil)
    }

    let query = MedkitDbKeyStoragePlugin.baseQuery(account: account)
    let updateStatus = SecItemUpdate(
      query as CFDictionary,
      [kSecValueData: data] as CFDictionary
    )
    if updateStatus == errSecSuccess {
      return nil
    }
    if updateStatus != errSecItemNotFound {
      return FlutterError(code: "write_failed", message: nil, details: Int(updateStatus))
    }

    // Запису ще нема (перший запис на цьому пристрої) — додаємо новий,
    // з тим самим фіксованим набором атрибутів + сам вміст.
    var addQuery = query
    addQuery[kSecValueData] = data
    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    if addStatus != errSecSuccess {
      return FlutterError(code: "write_failed", message: nil, details: Int(addStatus))
    }
    return nil
  }

  private func deleteValue(account: String) -> Any? {
    let status = SecItemDelete(MedkitDbKeyStoragePlugin.baseQuery(account: account) as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound {
      return FlutterError(code: "delete_failed", message: nil, details: Int(status))
    }
    return nil
  }
}
