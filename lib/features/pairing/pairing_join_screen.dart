import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/camera_permission_service.dart';
import '../../core/services/pairing_api_client.dart';
import '../../core/services/pairing_crypto_service.dart';
import '../../core/services/push_token_service.dart';
import '../../core/services/relay_api_client.dart';
import '../../core/services/shared_channel_key_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/shared_channels_repository.dart';
import '../../shared/widgets/mk_button.dart';
import '../../shared/widgets/mk_screen_header.dart';
import '../today/providers/today_providers.dart';

class PairingResult {
  final String channelId;
  final String name;

  const PairingResult({required this.channelId, required this.name});
}

/// Приймає код (скановий QR або введений вручну), забирає envelope через
/// `/pairing/redeem` і розшифровує локально. Код одноразовий — сервер
/// видаляє запис одразу після успішного читання. Якщо envelope несе
/// `syncKey` (v2 — запрошення, привʼязане до профілю), після розшифровки
/// просимо користувача обрати, до якого ЙОГО ЛОКАЛЬНОГО профілю привʼязати
/// це підключення, і зберігаємо ключ family_sync.
class PairingJoinScreen extends ConsumerStatefulWidget {
  const PairingJoinScreen({super.key});

  @override
  ConsumerState<PairingJoinScreen> createState() => _PairingJoinScreenState();
}

class _PairingJoinScreenState extends ConsumerState<PairingJoinScreen> {
  final _pairingApi = const PairingApiClient();
  final _relayApi = const RelayApiClient();
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController();

  bool _submitting = false;
  String? _error;
  bool _handledScan = false;
  bool _scannerStarted = false;

  // Якщо дозвіл вже перманентно відхилений — новий запит до ОС однаково
  // нічого не покаже, тож одразу ведемо в системні налаштування замість
  // марної спроби змонтувати камеру.
  Future<void> _startScanner() async {
    if (await CameraPermissionService.openSettingsIfPermanentlyDenied()) return;
    setState(() => _scannerStarted = true);
  }

  // Виклик під час першого монтування MobileScanner робить autoStart сам,
  // але коли попередня спроба впала через відмову в дозволі — камера вже
  // змонтована й повторний запит треба ініціювати вручну. Той самий нюанс з
  // перманентною відмовою, що і в _startScanner().
  Future<void> _retryScanner() async {
    if (await CameraPermissionService.openSettingsIfPermanentlyDenied()) return;
    await _scannerController.start();
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _redeem(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final codeHash = PairingCryptoService.codeHash(trimmed);
      final blob = await _pairingApi.redeem(codeHash: codeHash);
      final plain = await PairingCryptoService.decrypt(
        trimmed,
        salt: blob.salt,
        nonce: blob.nonce,
        cipherTextAndMac: blob.ciphertext,
      );
      final envelope = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final result = PairingResult(
        channelId: envelope['channelId'] as String,
        name: envelope['name'] as String? ?? '',
      );
      final syncKeyB64 = envelope['syncKey'] as String?;

      try {
        final token = await PushTokenService.getToken();
        if (token != null) {
          await _relayApi.register(
            channelId: result.channelId,
            pushToken: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
        }
      } catch (_) {
        // Не критично — пейринг уже успішний, реєстрацію можна повторити пізніше.
      }

      if (syncKeyB64 != null) {
        if (!mounted) return;
        final memberId = await _pickMemberToBind(result.name);
        if (memberId != null) {
          await ref
              .read(sharedChannelsRepositoryProvider)
              .bind(channelId: result.channelId, memberId: memberId);
          await SharedChannelKeyStorage.store(result.channelId, base64Decode(syncKeyB64));
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не вдалося приєднатись: невірний або прострочений код';
        _submitting = false;
        _handledScan = false;
      });
    }
  }

  /// Обирає, до якого ЛОКАЛЬНОГО профілю привʼязати щойно прийняте
  /// запрошення. Якщо є рівно один профіль з роллю 'owner' — вибирається
  /// автоматично (типовий випадок: людина приєднується власним телефоном).
  /// Інакше — просимо вибрати вручну.
  Future<int?> _pickMemberToBind(String inviterName) async {
    final members = await ref.read(allMembersProvider.future);
    if (members.isEmpty) return null;

    final owners = members.where((m) => m.role == 'owner').toList();
    if (owners.length == 1 && members.length == 1) {
      return owners.first.id;
    }

    if (!mounted) return null;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MemberPickerSheet(inviterName: inviterName, members: members),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handledScan = true;
    _redeem(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const MkScreenHeader(title: 'Ввести код запрошення'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 260,
                  child: _scannerStarted
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onDetect,
                              errorBuilder: (context, error, child) =>
                                  _ScannerError(
                                      error: error, onRetry: _retryScanner),
                            ),
                            if (_submitting)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                              ),
                          ],
                        )
                      : _ScannerPlaceholder(onTap: _startScanner),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Наведіть камеру на QR-код\nабо введіть код вручну',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _manualController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary, letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: '________',
                        hintStyle: AppTextStyles.h2.copyWith(color: AppColors.textMuted, letterSpacing: 4),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  MkButton(
                    label: _submitting ? 'Перевірка…' : 'Приєднатись',
                    isLoading: _submitting,
                    onTap: () => _redeem(_manualController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _ScannerPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: 10),
              Text('Сканувати QR-код',
                  style: AppTextStyles.labelLg
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 2),
              Text('Натисніть, щоб увімкнути камеру',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onRetry;
  const _ScannerError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final deniedPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                deniedPermission
                    ? Icons.no_photography_rounded
                    : Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 28),
            const SizedBox(height: 10),
            Text(
              deniedPermission
                  ? 'Немає доступу до камери'
                  : 'Не вдалося увімкнути камеру',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLg,
            ),
            const SizedBox(height: 4),
            Text(
              deniedPermission
                  ? 'Дозвольте доступ до камери, щоб сканувати QR-код'
                  : error.errorCode.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Спробувати ще'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerSheet extends StatelessWidget {
  final String inviterName;
  final List<Member> members;
  const _MemberPickerSheet({required this.inviterName, required this.members});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('До якого профілю привʼязати?', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Запрошення від "$inviterName" — оберіть, чиї дані на цьому пристрої синхронізувати.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ...members.map((m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.name, style: AppTextStyles.labelLg),
                  subtitle: Text(m.role == 'owner' ? 'Це я' : m.role),
                  onTap: () => Navigator.of(context).pop(m.id),
                )),
          ],
        ),
      ),
    );
  }
}
