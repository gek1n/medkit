import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/pairing_api_client.dart';
import '../../core/services/pairing_crypto_service.dart';
import '../../core/services/push_token_service.dart';
import '../../core/services/relay_api_client.dart';
import '../../core/services/shared_channel_key_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/shared_channels_repository.dart';

/// Генерує одноразовий пейринг-код: шифрує невеликий envelope (channelId +
/// ім'я + ключ family_sync) цим кодом і завантажує на сервер
/// (`/pairing/create`, TTL 30 хв). Другий пристрій сканує QR (або вводить код
/// вручну) і забирає envelope через `PairingJoinScreen`. Сервер весь час
/// бачить лише sha256(код) і зашифрований blob.
///
/// Запрошення завжди прив'язане до конкретного локального профілю
/// [memberId] — саме його дані (ліки/розклад/прийоми/симптоми) підуть у
/// бідирекційну синхронізацію після приєднання другого пристрою.
class PairingInviteScreen extends ConsumerStatefulWidget {
  final String ownerName;
  final int memberId;

  const PairingInviteScreen({super.key, required this.ownerName, required this.memberId});

  @override
  ConsumerState<PairingInviteScreen> createState() => _PairingInviteScreenState();
}

class _PairingInviteScreenState extends ConsumerState<PairingInviteScreen> {
  final _pairingApi = const PairingApiClient();
  final _relayApi = const RelayApiClient();

  String? _code;
  String? _error;
  bool _loading = true;
  bool _alreadyBound = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAndGenerate();
  }

  Future<void> _checkExistingAndGenerate({bool force = false}) async {
    if (!force) {
      final existing =
          await ref.read(sharedChannelsRepositoryProvider).forMember(widget.memberId);
      if (existing != null && mounted) {
        setState(() {
          _alreadyBound = true;
          _loading = false;
        });
        return;
      }
    }
    await _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _alreadyBound = false;
      _error = null;
    });
    try {
      final code = PairingCryptoService.generateCode();
      final channelId = const Uuid().v4();
      final syncKey = _randomBytes(32);
      final inviter = await ref.read(membersRepositoryProvider).getOwner();
      final envelope = utf8.encode(jsonEncode({
        'v': 2,
        'channelId': channelId,
        'name': widget.ownerName,
        'inviterName': inviter?.name,
        'syncKey': base64Encode(syncKey),
      }));

      final result = await PairingCryptoService.encrypt(code, envelope);
      await _pairingApi.create(
        codeHash: result.codeHash,
        salt: result.salt,
        nonce: result.nonce,
        ciphertext: result.ciphertext,
      );

      // Прив'язуємо канал до профілю і зберігаємо ключ family_sync одразу —
      // це єдиний момент, коли інвайтер тримає їх у пам'яті; сам факт
      // приєднання другого пристрою інвайтеру ніяк не повідомляється.
      await ref
          .read(sharedChannelsRepositoryProvider)
          .bind(channelId: channelId, memberId: widget.memberId);
      await SharedChannelKeyStorage.store(channelId, syncKey);

      // Одразу реєструємось у власному каналі — інакше друге пристрій
      // приєднається, а надсилати push буде нікому.
      try {
        final token = await PushTokenService.getToken();
        if (token != null) {
          await _relayApi.register(
            channelId: channelId,
            pushToken: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
        }
      } catch (_) {
        // Не критично для самого пейрингу — просто не буде push-пробудження
        // до наступного відкриття застосунку.
      }

      if (!mounted) return;
      setState(() {
        _code = code;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Запросити ${widget.ownerName}', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _alreadyBound
                  ? _buildAlreadyBound(context)
                  : _error != null
                      ? _buildError(context)
                      : _buildCode(context),
        ),
      ),
    );
  }

  Widget _buildAlreadyBound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Профіль вже підключено', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            '${widget.ownerName} вже має підключений пристрій. Нове запрошення замінить попереднє підключення.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => _checkExistingAndGenerate(force: true),
            child: const Text('Створити нове запрошення'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text('Не вдалося створити запрошення', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _generate, child: const Text('Спробувати ще раз')),
        ],
      ),
    );
  }

  Widget _buildCode(BuildContext context) {
    final code = _code!;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: AppColors.surface,
              eyeStyle: const QrEyeStyle(color: AppColors.primary),
              dataModuleStyle: const QrDataModuleStyle(color: AppColors.textMain),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Відскануйте цей код на іншому пристрої\nабо введіть його вручну',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопійовано')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLighter, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: Row(
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Код діє 30 хвилин і працює лише один раз. Дані на сервері зашифровані — там немає нічого, крім коду доступу.',
                    style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
