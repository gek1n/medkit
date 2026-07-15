import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/backup_settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/mk_screen_header.dart';
import '../today/providers/today_providers.dart';

/// Єдиний розділ "Резервна копія" — заміняє собою колишні окремі "Резервна
/// копія" і "Синхронізація". Три варіанти: лише на пристрої (з попередженням
/// про втрату даних при перевстановленні), Google Drive (iOS+Android) і
/// iCloud (лише iOS). Для хмарних режимів — частота автобекапу (раз на день/
/// тиждень), який фактично запускається на resume застосунку (`_Shell` у
/// main.dart), а не через нативний background scheduler.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _backupService = BackupService();
  bool _loading = true;
  bool _busy = false;
  BackupMode _mode = BackupMode.local;
  BackupFrequency _frequency = BackupFrequency.daily;
  DateTime? _lastBackupAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await BackupSettingsService.currentMode();
    final frequency = await BackupSettingsService.currentFrequency();
    final lastAt = await BackupSettingsService.lastBackupAt();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _frequency = frequency;
      _lastBackupAt = lastAt;
      _loading = false;
    });
  }

  BackupTarget? get _target => switch (_mode) {
        BackupMode.local => null,
        BackupMode.googleDrive => BackupTarget.googleDrive,
        BackupMode.iCloud => BackupTarget.iCloud,
      };

  // ⚠️ Навмисно НЕ питає пароль і НЕ створює бекап одразу при виборі хмарного
  // режиму — на щойно встановленому застосунку тут ще нема з чим порівняти
  // "новий пароль" від "пароль наявної копії в хмарі", а негайний
  // silent-бекап перезаписав би саме ту копію, яку користувач, можливо,
  // прийшов сюди відновити. Вибір режиму лише вмикає автобекап на майбутнє —
  // перший реальний бекап чи відновлення завжди явна дія користувача нижче
  // ("Створити зараз" / "Відновити з резервної копії").
  Future<void> _selectMode(BackupMode mode) async {
    if (mode == _mode) return;
    await BackupSettingsService.setMode(mode);
    if (!mounted) return;
    setState(() => _mode = mode);
  }

  Future<void> _selectFrequency(BackupFrequency frequency) async {
    if (frequency == _frequency) return;
    await BackupSettingsService.setFrequency(frequency);
    if (!mounted) return;
    setState(() => _frequency = frequency);
  }

  Future<void> _createBackup() async {
    final target = _target;
    if (target == null) return;

    var passphrase = await BackupSettingsService.savedPassphrase();
    if (passphrase == null) {
      final entered = await _askPassphrase(
        title: 'Пароль для резервної копії',
        subtitle: 'Придумайте пароль. Без нього відновити дані буде неможливо — навіть нам.',
        confirmRequired: true,
      );
      if (entered == null) return;
      passphrase = entered;
      await BackupSettingsService.savePassphrase(passphrase);
    }

    setState(() => _busy = true);
    try {
      await _backupService.createBackup(target: target, passphrase: passphrase);
      await BackupSettingsService.markBackedUpNow();
      if (!mounted) return;
      setState(() => _lastBackupAt = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Резервну копію збережено у $_targetName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final target = _target;
    if (target == null) return;

    final confirmed = await _confirmRestore();
    if (confirmed != true) return;

    final passphrase = await _askPassphrase(
      title: 'Пароль резервної копії',
      subtitle: 'Введіть пароль, який ви вказали при створенні копії.',
      confirmRequired: false,
    );
    if (passphrase == null || !mounted) return;

    // Captured before invalidate() нижче — щойно БД перепідключиться,
    // ProviderScope-дерево вище може перебудуватись.
    final container = ProviderScope.containerOf(context, listen: false);

    setState(() => _busy = true);
    try {
      // Закриваємо активне з'єднання ДО підміни файлу/ключа — інакше
      // фонова ізолят-БД лишається живою поверх файлу, який змінюється в
      // неї "під ногами" (гонка, здатна лишити ключ і вміст файлу
      // неузгодженими — SqliteException(26) "file is not a database" при
      // наступному відкритті).
      await container.read(databaseProvider).close();

      await _backupService.restoreBackup(target: target, passphrase: passphrase);
      await BackupSettingsService.savePassphrase(passphrase);

      // ⚠️ restoreBackup() підмінює файл БД і ключ шифрування в secure
      // storage — без цього invalidate застосунок і далі мовчки показував
      // би стару БД, поки користувач не перезапустить його вручну.
      container.invalidate(databaseProvider);
      container.invalidate(currentMemberProvider);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Готово'),
          content: const Text('Дані відновлено.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Гаразд')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося відновити: невірний пароль або копія відсутня')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Пароль лишається лише локально (secure storage) — самого старого пароля
  // тут ніде не звіряємо, бо нема з чим: BackupCryptoService шифрує ключі
  // симетрично, без окремого відновлення "забутого" пароля. Тому зміна
  // пароля — це просто новий пароль ЗАРАЗ + одразу свіжий бекап під нього,
  // щоб копія в хмарі не лишилась назавжди прив'язаною до старого пароля,
  // який більше ніде не збережений.
  Future<void> _changePassphrase() async {
    final target = _target;
    if (target == null) return;

    final newPassphrase = await _askPassphrase(
      title: 'Новий пароль резервної копії',
      subtitle: 'Одразу після зміни буде створено нову резервну копію з цим паролем — '
          'запам\'ятайте його, стару резервну копію під старим паролем більше не '
          'можна буде використати.',
      confirmRequired: true,
    );
    if (newPassphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await BackupSettingsService.savePassphrase(newPassphrase);
      await _backupService.createBackup(target: target, passphrase: newPassphrase);
      await BackupSettingsService.markBackedUpNow();
      if (!mounted) return;
      setState(() => _lastBackupAt = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль змінено, нову резервну копію збережено')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _targetName => switch (_mode) {
        BackupMode.googleDrive => 'Google Drive',
        BackupMode.iCloud => 'iCloud',
        BackupMode.local => '',
      };

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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(AppDimensions.screenPadding),
                      children: [
                        Text(
                          'Ліки, розклад, медкартка (фото/PDF) і всі інші дані — обирайте, '
                          'де зберігати резервну копію.',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                        _ModeCard(
                          icon: Icons.phonelink_off_rounded,
                          title: 'Тільки на пристрої',
                          subtitle: 'При перевстановленні застосунку всі дані буде втрачено',
                          selected: _mode == BackupMode.local,
                          warning: _mode == BackupMode.local,
                          onTap: _busy ? null : () => _selectMode(BackupMode.local),
                        ),
                        const SizedBox(height: AppDimensions.md),
                        _ModeCard(
                          icon: Icons.cloud_rounded,
                          title: 'Google Drive',
                          subtitle: 'Зашифровано на пристрої — Elly і Google не бачать ваші дані',
                          selected: _mode == BackupMode.googleDrive,
                          onTap: _busy ? null : () => _selectMode(BackupMode.googleDrive),
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(height: AppDimensions.md),
                          _ModeCard(
                            icon: Icons.cloud_queue_rounded,
                            title: 'iCloud',
                            subtitle: 'Зашифровано на пристрої — Elly і Apple не бачать ваші дані',
                            selected: _mode == BackupMode.iCloud,
                            onTap: _busy ? null : () => _selectMode(BackupMode.iCloud),
                          ),
                        ],
                        if (_mode != BackupMode.local) ...[
                          const SizedBox(height: AppDimensions.xl),
                          Text('ЧАСТОТА АВТОБЕКАПУ', style: AppTextStyles.labelSm),
                          const SizedBox(height: AppDimensions.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _FrequencyChip(
                                  label: 'Раз на день',
                                  selected: _frequency == BackupFrequency.daily,
                                  onTap: _busy
                                      ? null
                                      : () => _selectFrequency(BackupFrequency.daily),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(
                                child: _FrequencyChip(
                                  label: 'Раз на тиждень',
                                  selected: _frequency == BackupFrequency.weekly,
                                  onTap: _busy
                                      ? null
                                      : () => _selectFrequency(BackupFrequency.weekly),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          Text(
                            'Спрацьовує, коли ви відкриваєте застосунок чи повертаєтесь у '
                            'нього — це не справжній фоновий розклад. Якщо не відкривати '
                            'Elly довше обраної частоти, бекап зробиться одразу при '
                            'наступному відкритті.',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Text(
                            _lastBackupAt == null
                                ? 'Резервної копії ще не було'
                                : 'Останній бекап: ${_formatDate(_lastBackupAt!)}',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppDimensions.lg),
                          if (_busy)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            FilledButton.icon(
                              onPressed: () => _createBackup(),
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: const Text('Створити резервну копію зараз'),
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            OutlinedButton.icon(
                              onPressed: _restoreBackup,
                              icon: const Icon(Icons.cloud_download_outlined),
                              label: const Text('Відновити з резервної копії'),
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            TextButton.icon(
                              onPressed: _changePassphrase,
                              icon: const Icon(Icons.key_rounded, size: 18),
                              label: const Text('Змінити пароль резервної копії'),
                            ),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool warning;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.warning = false,
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
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: warning ? AppColors.warning : AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(
                      color: warning ? AppColors.warning : AppColors.textMuted,
                    ),
                  ),
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

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _FrequencyChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.primary : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}
