import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/family_status_provider.dart';
import '../../core/services/camera_permission_service.dart';
import '../../core/services/family_group_service.dart';
import '../../core/services/family_join_popup_service.dart';
import '../../core/services/family_server_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_button.dart';
import '../../shared/widgets/mk_screen_header.dart';
import 'family_join_popup.dart';

enum _Stage { scanning, review, done }

/// Приєднання до сімейної групи (Крок 11 C6) для ВЖЕ заповненого акаунта.
/// На відміну від архівної версії, дублікат-перевірка ("я вже в цій
/// сім'ї") звіряється з кешованим `/family/status`
/// ([FamilyServerSyncService.cachedStatus]), а не з локальною
/// FamilyPeers-таблицею — сервер сам знає, хто в якій сім'ї, і `join()`
/// все одно idempotent (ON DUPLICATE KEY UPDATE), тож помилковий негатив
/// тут (застарілий кеш) не ламає нічого, лише пропускає зайве
/// попередження.
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

      final cached = await FamilyServerSyncService.cachedStatus();
      final alreadyIn = cached?.families.any((f) => f.familyId == preview.familyId) ?? false;
      if (alreadyIn) {
        if (!mounted) return;
        setState(() {
          _error = context.l10n.alreadyJoinedFamilyError(preview.inviterName);
          _submitting = false;
          _handledScan = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _stage = _Stage.review;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.joinInvalidCodeError;
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
      // Одразу тягнемо свіжий /family/status — не чекаємо наступного
      // пасивного тригера (resume), інакше глядач бачив би порожню сім'ю
      // до наступного відкриття застосунку.
      try {
        await FamilyServerSyncService(db).syncAll();
      } catch (_) {
        // Тиха невдача — статус все одно підхопиться наступним тригером.
      }
      if (!mounted) return;
      ref.invalidate(familyStatusProvider);
      setState(() {
        _stage = _Stage.done;
        _submitting = false;
      });
      // Один показ на кожну сім'ю, якою я приєднуюсь вперше — familyId як
      // дедуп-ключ (FamilyJoinPopupService байдужий до семантики ключа).
      if (await FamilyJoinPopupService.shouldShowForInvitee(_preview!.familyId)) {
        await FamilyJoinPopupService.markShownForInvitee(_preview!.familyId);
        if (mounted) {
          await showFamilyJoinPopup(context, peerName: _preview!.inviterName, asInvitee: true);
        }
      }
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
                  _Stage.scanning => context.l10n.joinFamilyTitle,
                  _Stage.review => context.l10n.confirmationTitle,
                  _Stage.done => context.l10n.doneTitle,
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
            context.l10n.scanQrOrEnterHint,
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
                hintText: context.l10n.codeInputHint,
                hintStyle: AppTextStyles.h2.copyWith(color: AppColors.textMuted, letterSpacing: 4),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
            label: _submitting ? context.l10n.checkingLabel : context.l10n.continueAction,
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
                                context.l10n.invitesYouToFamilyGroup,
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
                    context.l10n.joinConsentBody(preview.inviterName),
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
                            context.l10n.joinConsentCheckbox(preview.inviterName),
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
            label: _submitting ? context.l10n.joiningLabel : context.l10n.joinAction,
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
          Text(context.l10n.joinedFamilyTitle, style: AppTextStyles.h2, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            context.l10n.joinedFamilyBody(preview.inviterName),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          MkButton(label: context.l10n.doneTitle, onTap: () => Navigator.of(context).pop(true)),
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
              Text(context.l10n.scanQrCodeLabel, style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(context.l10n.tapToEnableCameraHint,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
