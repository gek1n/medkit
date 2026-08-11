import 'account_service.dart';

/// Крок 11: сімейне членство використовує ТОЙ САМИЙ account_id/recovery key,
/// що вже створений для Subscription/Sync (`AccountService`) — не мінтиться
/// окремий "сімейний" ідентифікатор. Це дзеркало приватного
/// `SubscriptionService._ensureAccount()`, винесене окремо, щоб не
/// прив'язувати family-код до внутрішньої реалізації білінгу; обидва
/// врешті створюють/читають один і той самий акаунт через [AccountService].
///
/// SyncMode.local → перший виклик (створення сім'ї чи приєднання) автоматично
/// вмикає sync-акаунт. НІКОЛИ тихо — [FamilyAccountInfo.newRecoveryKeyDisplay]
/// заповнюється, коли акаунт щойно створено, UI-шар одразу показує екран
/// "збережіть recovery key" (той самий контракт, що й для покупки підписки).
Future<FamilyAccountInfo> ensureFamilyAccount() async {
  final account = AccountService();
  String? newRecoveryKeyDisplay;
  var accountId = await account.currentAccountId();
  var hash = await account.currentRecoveryKeyHash();
  if (accountId == null || hash == null) {
    newRecoveryKeyDisplay = AccountService.generateRecoveryKey();
    await account.enableNoAccountSync(newRecoveryKeyDisplay);
    accountId = await account.currentAccountId();
    hash = await account.currentRecoveryKeyHash();
  }
  if (accountId == null || hash == null) {
    throw StateError('Не вдалося створити sync-акаунт для сімейних функцій');
  }
  return FamilyAccountInfo(
    accountId: accountId,
    recoveryKeyHash: hash,
    newRecoveryKeyDisplay: newRecoveryKeyDisplay,
  );
}

class FamilyAccountInfo {
  final String accountId;
  final String recoveryKeyHash;
  /// Заповнено лише якщо акаунт щойно створено цим викликом — UI-шар має
  /// одразу показати екран збереження recovery key.
  final String? newRecoveryKeyDisplay;

  const FamilyAccountInfo({
    required this.accountId,
    required this.recoveryKeyHash,
    this.newRecoveryKeyDisplay,
  });
}
