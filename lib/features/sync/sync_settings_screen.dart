import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/account_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';
import '../../shared/widgets/recovery_key_dialog.dart';

/// Опційна зашифрована синхронізація з сервером — окремо від "Резервної
/// копії" (Google Drive/iCloud). Тут дані ще й лишаються на нашому сервері
/// (зашифровані ключем, який сервер ніколи не бачить) — потрібно для
/// зберігання фото з медкартки та GDPR-виправлення "видати/видалити мої
/// дані на вимогу". Три режими: лише локально (за замовчуванням, нічого не
/// міняється), хмара без акаунта (recovery key) і хмара з акаунтом
/// (Google/Apple Sign-In — заплановано).
class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  final _accountService = AccountService();
  SyncMode _mode = SyncMode.local;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await _accountService.currentMode();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _loading = false;
    });
  }

  Future<void> _enableNoAccountSync() async {
    final recoveryKey = AccountService.generateRecoveryKey();
    final saved = await showRecoveryKeyDialog(context, recoveryKey);
    if (saved != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _accountService.enableNoAccountSync(recoveryKey);
      await SyncService(ref.read(databaseProvider)).pushChanges();
      if (!mounted) return;
      setState(() => _mode = SyncMode.noAccount);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Синхронізацію увімкнено, дані залиті на сервер')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enableAccountSync() async {
    final provider = await _askProvider();
    if (provider == null || !mounted) return;

    final recoveryKey = AccountService.generateRecoveryKey();
    final saved = await showRecoveryKeyDialog(context, recoveryKey);
    if (saved != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _accountService.enableAccountSync(provider: provider, recoveryKeyDisplay: recoveryKey);
      await SyncService(ref.read(databaseProvider)).pushChanges();
      if (!mounted) return;
      setState(() => _mode = SyncMode.account);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Синхронізацію увімкнено, дані залиті на сервер')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Вхід через Google/Apple на новому пристрої — знаходить свій account_id
  /// без ручного пошуку, але ключ шифрування все одно виводиться з recovery
  /// key (якщо secure storage цього пристрою вже не отримав його сам через
  /// iCloud Keychain — тоді після входу нижче просто нічого не зміниться).
  Future<void> _restoreViaOAuth() async {
    final provider = await _askProvider();
    if (provider == null || !mounted) return;

    setState(() => _busy = true);
    String accountId;
    try {
      accountId = await _accountService.findAccountViaOAuth(provider);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не вдалося увійти: $e')),
        );
      }
      return;
    }
    setState(() => _busy = false);
    if (!mounted) return;

    final recoveryKey = await _askRecoveryKey(
      title: 'Recovery key',
      subtitle: 'Вхід підтверджено. Введіть recovery key, щоб відновити ключ шифрування на цьому пристрої.',
    );
    if (recoveryKey == null || !mounted) return;

    final confirmed = await _confirmOverwrite();
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _accountService.attachRecoveryKey(accountId: accountId, recoveryKeyDisplay: recoveryKey);
      await SyncService(ref.read(databaseProvider)).pullChanges(fullRestore: true);
      if (!mounted) return;
      setState(() => _mode = SyncMode.account);
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
        const SnackBar(content: Text('Не вдалося відновити: невірний recovery key')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askProvider() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Увійти через'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.g_mobiledata_rounded, size: 32),
              title: const Text('Google'),
              onTap: () => Navigator.of(context).pop('google'),
            ),
            ListTile(
              leading: const Icon(Icons.apple_rounded),
              title: const Text('Apple'),
              onTap: () => Navigator.of(context).pop('apple'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Скасувати')),
        ],
      ),
    );
  }

  Future<void> _restoreOnThisDevice() async {
    final recoveryKey = await _askRecoveryKey(
      title: 'Відновлення',
      subtitle: 'Введіть recovery key, який ви зберегли раніше.',
    );
    if (recoveryKey == null || !mounted) return;

    final confirmed = await _confirmOverwrite();
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _accountService.restoreFromRecoveryKey(recoveryKey);
      await SyncService(ref.read(databaseProvider)).pullChanges(fullRestore: true);
      if (!mounted) return;
      setState(() => _mode = SyncMode.noAccount);
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
        const SnackBar(content: Text('Не вдалося відновити: невірний recovery key')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disableSync() async {
    await _accountService.disableSync();
    if (!mounted) return;
    setState(() => _mode = SyncMode.local);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Синхронізацію вимкнено (локальні дані не зачеплено)')),
    );
  }

  Future<void> _deleteAccountEverywhere() async {
    final recoveryKey = await _askRecoveryKey(
      title: 'Видалити акаунт і дані на сервері',
      subtitle: 'Введіть recovery key ще раз для підтвердження. Цю дію не можна скасувати.',
    );
    if (recoveryKey == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await _accountService.deleteAccountEverywhere(recoveryKey);
      if (!mounted) return;
      setState(() => _mode = SyncMode.local);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Акаунт і всі дані на сервері видалено')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askRecoveryKey({required String title, required String subtitle}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
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

  Future<bool?> _confirmOverwrite() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Замінити локальні дані?'),
        content: const Text(
          'Поточні дані на цьому пристрої буде замінено даними з сервера. Цю дію не можна скасувати.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Скасувати')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Відновити')),
        ],
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
            const MkScreenHeader(title: 'Синхронізація та акаунт'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _busy
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding:
                              const EdgeInsets.all(AppDimensions.screenPadding),
                          children: [
                      Text(
                        'За замовчуванням усі дані лишаються тільки на пристрої. '
                        'Синхронізація — опційна: дані шифруються ще на пристрої, '
                        'сервер бачить лише зашифровані байти.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      _ModeCard(
                        icon: Icons.phonelink_off_rounded,
                        title: 'Тільки локально',
                        subtitle: 'Дані лишаються лише на цьому пристрої (за замовчуванням)',
                        selected: _mode == SyncMode.local,
                        onTap: _mode == SyncMode.local ? null : _disableSync,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _ModeCard(
                        icon: Icons.cloud_rounded,
                        title: 'Хмара без акаунта',
                        subtitle: 'Recovery key замість email/пароля — його ніхто, крім вас, не знає',
                        selected: _mode == SyncMode.noAccount,
                        onTap: _mode == SyncMode.noAccount ? null : _enableNoAccountSync,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _ModeCard(
                        icon: Icons.person_rounded,
                        title: 'Хмара з акаунтом (Google/Apple)',
                        subtitle: 'Вхід без пароля — на iPhone ключ підхоплюється сам через iCloud',
                        selected: _mode == SyncMode.account,
                        onTap: _mode == SyncMode.account ? null : _enableAccountSync,
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      OutlinedButton.icon(
                        onPressed: _restoreOnThisDevice,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Відновити за recovery key'),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      OutlinedButton.icon(
                        onPressed: _restoreViaOAuth,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Відновити через Google/Apple'),
                      ),
                      if (_mode != SyncMode.local) ...[
                        const SizedBox(height: AppDimensions.md),
                        OutlinedButton.icon(
                          onPressed: _deleteAccountEverywhere,
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Видалити акаунт і дані на сервері'),
                        ),
                      ],
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
