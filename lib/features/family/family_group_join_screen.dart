import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/camera_permission_service.dart';
import '../../core/services/family_group_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../shared/widgets/mk_button.dart';
import '../../shared/widgets/mk_screen_header.dart';

enum _Stage { scanning, review, done }

/// Приєднання до сімейної групи для ВЖЕ заповненого акаунта — на відміну
/// від онбордингового `JoinFamilyScreen` (для порожнього пристрою, створює
/// профіль-дзеркало), тут пристрій вже має власні дані. Тому обов'язковий
/// явний екран згоди між скануванням коду і фактичним приєднанням: перед
/// цим користувач повинен побачити, з ким саме приєднується, і підтвердити
/// активною дією (чекбокс), а не мовчазним "далі".
class FamilyGroupJoinScreen extends ConsumerStatefulWidget {
  const FamilyGroupJoinScreen({super.key});

  @override
  ConsumerState<FamilyGroupJoinScreen> createState() => _FamilyGroupJoinScreenState();
}

class _FamilyGroupJoinScreenState extends ConsumerState<FamilyGroupJoinScreen> {
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController();

  _Stage _stage = _Stage.scanning;
  bool _submitting = false;
  bool _consentChecked = false;
  String? _error;
  bool _handledScan = false;
  bool _scannerStarted = false;
  GroupInvitePreview? _preview;

  Future<void> _startScanner() async {
    if (await CameraPermissionService.openSettingsIfPermanentlyDenied()) return;
    setState(() => _scannerStarted = true);
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _decode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final preview = await FamilyGroupService(db).decodeInvite(trimmed);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _stage = _Stage.review;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не вдалося приєднатись: невірний або прострочений код';
        _submitting = false;
        _handledScan = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_preview == null || !_consentChecked || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      await FamilyGroupService(db).acceptInvite(_preview!);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.done;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handledScan = true;
    _decode(value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == _Stage.scanning,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              MkScreenHeader(
                title: switch (_stage) {
                  _Stage.scanning => 'Приєднатись до сім\'ї',
                  _Stage.review => 'Підтвердження',
                  _Stage.done => 'Готово',
                },
                onBack: _stage == _Stage.scanning ? () => Navigator.pop(context) : null,
              ),
              Expanded(
                child: switch (_stage) {
                  _Stage.scanning => _buildScan(),
                  _Stage.review => _buildReview(),
                  _Stage.done => _buildDone(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 260,
              child: _scannerStarted
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(controller: _scannerController, onDetect: _onDetect),
                        if (_submitting)
                          Container(
                            color: Colors.black45,
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                      ],
                    )
                  : _ScannerPlaceholder(onTap: _startScanner),
            ),
          ),
          const SizedBox(height: 20),
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
            label: _submitting ? 'Перевірка…' : 'Продовжити',
            isLoading: _submitting,
            onTap: () => _decode(_manualController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    final preview = _preview!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset('assets/illustrations/family.png', height: 140),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        AvatarImage(index: preview.inviterAvatarIndex, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(preview.inviterName, style: AppTextStyles.labelLg),
                              const SizedBox(height: 2),
                              Text(
                                'запрошує вас до сімейної групи',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ви приєднуєтесь як рівноправний учасник — ваш власний профіль '
                    '(ім\'я й аватар) стане видимим "${preview.inviterName}". Це не '
                    'скасовує і не змінює жодних ваших даних, уже внесених у застосунок. '
                    'Ваша медкартка НІКОМУ автоматично не показується — які саме дані '
                    'бачитимуть інші учасники, ви налаштуєте окремо, вже після приєднання.',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setState(() => _consentChecked = !_consentChecked),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _consentChecked ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _consentChecked ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: _consentChecked
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Я погоджуюсь приєднатись до сімейної групи "${preview.inviterName}"',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: AppTextStyles.bodySm.copyWith(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MkButton(
            label: _submitting ? 'Приєднуємось…' : 'Приєднатись',
            isLoading: _submitting,
            onTap: (_consentChecked && !_submitting) ? _confirm : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    final preview = _preview!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Ви в сім\'ї!', style: AppTextStyles.h2, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Тепер ви й "${preview.inviterName}" бачите одне одного в розділі "Сім\'я".',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          MkButton(label: 'Готово', onTap: () => Navigator.of(context).pop(true)),
        ],
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
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: 10),
              Text('Сканувати QR-код', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
              const SizedBox(height: 2),
              Text('Натисніть, щоб увімкнути камеру',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
