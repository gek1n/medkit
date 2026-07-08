import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/account_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../today/providers/today_providers.dart';

/// Онбординг-варіант "Відновити акаунт" — вхід через Google/Apple, щоб
/// знайти вже наявний акаунт синхронізації (`AccountService.findAccountViaOAuth`),
/// а тоді повне відновлення даних (`SyncService.pullChanges(fullRestore: true)`).
/// Recovery key просимо, лише якщо ключ шифрування ще не підхопився сам через
/// iCloud Keychain (secure storage) — на новому Android чи новому Apple ID
/// його доведеться ввести вручну.
class RestoreAccountScreen extends ConsumerStatefulWidget {
  const RestoreAccountScreen({super.key});

  @override
  ConsumerState<RestoreAccountScreen> createState() => _RestoreAccountScreenState();
}

class _RestoreAccountScreenState extends ConsumerState<RestoreAccountScreen> {
  final _accountService = AccountService();
  bool _busy = false;
  String? _error;

  Future<void> _restore(String provider) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final accountId = await _accountService.findAccountViaOAuth(provider);

      final existingKey = await _accountService.currentSyncKey();
      if (existingKey == null) {
        if (!mounted) return;
        final recoveryKey = await _askRecoveryKey();
        if (recoveryKey == null) {
          if (mounted) setState(() => _busy = false);
          return;
        }
        await _accountService.attachRecoveryKey(accountId: accountId, recoveryKeyDisplay: recoveryKey);
      }

      final db = ref.read(databaseProvider);
      await SyncService(db).pullChanges(fullRestore: true);

      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      container.invalidate(generateTodayIntakesProvider);
      container.invalidate(tomorrowIntakesProvider);
      container.invalidate(generateTodayActivityLogsProvider);
      container.invalidate(tomorrowActivityLogsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не вдалося увійти: перевірте зʼєднання та спробуйте ще раз';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askRecoveryKey() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovery key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вхід підтверджено. Введіть recovery key, щоб відновити ключ шифрування на цьому пристрої.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Скасувати')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Продовжити'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MkBackButton(
                  onTap: _busy ? null : () => Navigator.of(context).pop()),
              const SizedBox(height: 20),
              Text('Відновити акаунт', style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                'Увійдіть, щоб відновити ваші дані з попереднього пристрою',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 32),
              if (_busy)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
              else ...[
                _AuthButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Продовжити з Google',
                  onTap: () => _restore('google'),
                ),
                const SizedBox(height: 12),
                _AuthButton(
                  icon: Icons.apple_rounded,
                  label: 'Продовжити з Apple',
                  onTap: () => _restore('apple'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AuthButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        ),
        icon: Icon(icon, color: AppColors.textMain),
        label: Text(label, style: AppTextStyles.labelLg.copyWith(color: AppColors.textMain)),
      ),
    );
  }
}
