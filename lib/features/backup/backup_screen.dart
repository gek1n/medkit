import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/backup_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';

/// На Android — Google Drive (appDataFolder), на iOS — iCloud. Обидва
/// зберігають лише вже зашифровані на пристрої дані (SQLCipher БД +
/// AES-GCM фото) плюс окремо зашифрований паролем бекапу конверт із ключами
/// шифрування. Без цього пароля відновити дані з хмари неможливо навіть
/// маючи повний доступ до самого Drive/iCloud акаунта.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupService = BackupService();
  bool _busy = false;

  BackupTarget get _target => Platform.isIOS ? BackupTarget.iCloud : BackupTarget.googleDrive;
  String get _targetName => Platform.isIOS ? 'iCloud' : 'Google Drive';

  Future<void> _createBackup() async {
    final passphrase = await _askPassphrase(
      title: 'Пароль для резервної копії',
      subtitle: 'Придумайте пароль. Без нього відновити дані буде неможливо — навіть нам.',
      confirmRequired: true,
    );
    if (passphrase == null) return;

    setState(() => _busy = true);
    try {
      await _backupService.createBackup(target: _target, passphrase: passphrase);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Резервну копію збережено у $_targetName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await _confirmRestore();
    if (confirmed != true) return;

    final passphrase = await _askPassphrase(
      title: 'Пароль резервної копії',
      subtitle: 'Введіть пароль, який ви вказали при створенні копії.',
      confirmRequired: false,
    );
    if (passphrase == null) return;

    setState(() => _busy = true);
    try {
      await _backupService.restoreBackup(target: _target, passphrase: passphrase);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Готово'),
          content: const Text('Дані відновлено. Перезапустіть застосунок, щоб зміни набули дії.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Гаразд')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося відновити: невірний пароль або копія відсутня')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmRestore() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Відновити з резервної копії?'),
        content: const Text(
          'Поточні дані на цьому пристрої буде замінено даними з резервної копії. Цю дію не можна скасувати.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Відновити')),
        ],
      ),
    );
  }

  Future<String?> _askPassphrase({
    required String title,
    required String subtitle,
    required bool confirmRequired,
  }) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
              ),
              if (confirmRequired) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Повторіть пароль'),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text;
                if (value.length < 6) {
                  setDialogState(() => error = 'Пароль має бути не коротшим за 6 символів');
                  return;
                }
                if (confirmRequired && value != confirmController.text) {
                  setDialogState(() => error = 'Паролі не збігаються');
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Продовжити'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Резервна копія'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.backup_rounded,
                              size: 48, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text('Резервна копія в $_targetName',
                              style: AppTextStyles.h2),
                          const SizedBox(height: 8),
                          Text(
                            'Ліки, розклад і фото зберігаються у вашому особистому '
                            '$_targetName вже зашифрованими. Elly і хмара не бачать '
                            'ваші дані — розшифрувати їх можна лише паролем, який '
                            'знаєте тільки ви.',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSub),
                          ),
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            onPressed: _createBackup,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Створити резервну копію'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _restoreBackup,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('Відновити з резервної копії'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
