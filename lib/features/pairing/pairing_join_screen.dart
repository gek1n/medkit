import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/pairing_api_client.dart';
import '../../core/services/pairing_crypto_service.dart';
import '../../core/services/push_token_service.dart';
import '../../core/services/relay_api_client.dart';
import '../../core/services/shared_channel_key_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/shared_channels_repository.dart';
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
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Ввести код запрошення', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _scannerController, onDetect: _onDetect),
                    if (_submitting)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
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
                  TextField(
                    controller: _manualController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary, letterSpacing: 4),
                    decoration: InputDecoration(
                      hintText: '________',
                      filled: true,
                      fillColor: AppColors.primaryLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.primaryLighter, width: 2),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : () => _redeem(_manualController.text),
                      child: Text(_submitting ? 'Перевірка…' : 'Приєднатись'),
                    ),
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
