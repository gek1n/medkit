import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/backup_settings_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../today/providers/today_providers.dart';

/// Онбординг-варіант "Відновити акаунт" — підключення до Google Drive/iCloud
/// (той самий сховок, куди складено "Резервну копію" в Профілі) і пароль
/// бекапу. Відновлює ПОВНІСТЮ: БД, фото/PDF медкартки, обліковий запис
/// синхронізації (а отже й сімейні зв'язки) і план підписки — все, що було
/// в blob'і ключів ([BackupCryptoService]) та архіві на момент створення
/// копії. `SubscriptionService.restorePurchases()` викликається додатково —
/// best-effort підтвердження активної покупки в App Store/Google Play, якщо
/// обліковий запис синхронізації з якоїсь причини не підхопився.
class RestoreAccountScreen extends ConsumerStatefulWidget {
  const RestoreAccountScreen({super.key});

  @override
  ConsumerState<RestoreAccountScreen> createState() => _RestoreAccountScreenState();
}

class _RestoreAccountScreenState extends ConsumerState<RestoreAccountScreen> {
  final _backupService = BackupService();
  bool _busy = false;
  String? _error;

  Future<void> _restore(BackupTarget target, BackupMode mode) async {
    final passphrase = await _askPassphrase();
    if (passphrase == null || !mounted) return;

    // Captured тут, ще ДО restoreBackup() — щойно нижче перепідключиться
    // БД, currentMemberProvider побачить відновленого власника і
    // _RootRouter замінить OnboardingScreen на _Shell, розаттачивши цей
    // State (а з ним і `context`).
    final container = ProviderScope.containerOf(context, listen: false);

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Закриваємо поточне (порожнє, щойно створене онбордингом) з'єднання
      // ДО того, як restoreBackup() підмінить сам файл medkit.db і ключ у
      // secure storage — інакше фонова ізолят-БД лишається живою поверх
      // файлу, який міняється в неї "під ногами", а це гонка, здатна
      // лишити диск у стані, де ключ і вміст файлу не відповідають один
      // одному (SqliteException(26) "file is not a database" при
      // наступному відкритті).
      await container.read(databaseProvider).close();

      await _backupService.restoreBackup(target: target, passphrase: passphrase);
      await BackupSettingsService.savePassphrase(passphrase);
      await BackupSettingsService.setMode(mode);
      await BackupSettingsService.markBackedUpNow();

      try {
        await SubscriptionService.restorePurchases();
      } catch (_) {
        // Best-effort — обліковий запис синхронізації, відновлений вище,
        // вже несе актуальний статус підписки з сервера.
      }

      // ⚠️ restoreBackup() підмінює і сам файл БД, і ключ шифрування в
      // secure storage "під ногами" у вже відкритого Drift-з'єднання — без
      // цього invalidate воно продовжило б мовчки працювати зі старою
      // (щойно створеною онбордингом, порожньою) базою, currentMemberProvider
      // й далі бачив би null, і онбординг замість переходу на Сьогодні
      // просто лишався б на кроці "Як почнемо?".
      container.invalidate(databaseProvider);
      container.invalidate(currentMemberProvider);

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.restoreErrorBody;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassphrase() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.backupPasswordDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.backupPasswordDialogBody,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(labelText: context.l10n.passwordFieldLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.actionCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.continueAction),
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
              MkBackButton(onTap: _busy ? null : () => Navigator.of(context).pop()),
              const SizedBox(height: 20),
              Text(context.l10n.restoreAccountTitle, style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                context.l10n.restoreAccountSubtitle,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 32),
              if (_busy)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
              else ...[
                _SourceButton(
                  icon: Icons.cloud_rounded,
                  label: context.l10n.googleDriveLabel,
                  onTap: () => _restore(BackupTarget.googleDrive, BackupMode.googleDrive),
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  _SourceButton(
                    icon: Icons.cloud_queue_rounded,
                    label: context.l10n.iCloudLabel,
                    onTap: () => _restore(BackupTarget.iCloud, BackupMode.iCloud),
                  ),
                ],
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

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

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
