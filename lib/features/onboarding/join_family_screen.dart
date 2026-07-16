import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/services/pairing_api_client.dart';
import '../../core/services/pairing_crypto_service.dart';
import '../../core/services/push_token_service.dart';
import '../../core/services/relay_api_client.dart';
import '../../core/services/shared_channel_key_storage.dart';
import '../../core/services/sync_crypto_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/members_repository.dart';
import '../../data/repositories/shared_channels_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../today/providers/today_providers.dart';
import 'privacy_gate_screen.dart';

enum _JoinStage { entering, working, review }

/// Онбординг-варіант "Підключитися до сім'ї" — вводимо код запрошення
/// "Локальний → Автономний" (див. `FamilyGroupService.createConversionInvite`).
/// Локального профілю на цьому пристрої ще не існує — ми створюємо його самі
/// (ім'я/аватар з envelope), одноразово підтягуємо всю історію, яку вів
/// запрошувач, а тоді стаємо звичайним незалежним учасником сімейної групи:
/// той, хто нас запросив, отримує повний доступ до наших даних одразу
/// (секунду тому це були його ж дані), а надалі відносини між нами — звичайні
/// FamilyPeers/FamilyGrants, як і з будь-ким іншим у групі.
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _pairingApi = const PairingApiClient();
  final _relayApi = const RelayApiClient();
  final _codeController = TextEditingController();

  _JoinStage _stage = _JoinStage.entering;
  String? _error;
  String? _profileName;
  String? _inviterName;
  int? _memberId;
  bool _consentChecked = false;
  bool _finishing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    // Captured тут, ДО мережевих await нижче — так само, як container у
    // RestoreAccountScreen/onboarding_screen.dart: context після await може
    // вже належати розаттаченому State.
    final l10n = context.l10n;
    setState(() {
      _stage = _JoinStage.working;
      _error = null;
    });

    try {
      final codeHash = PairingCryptoService.codeHash(code);
      final blob = await _pairingApi.redeem(codeHash: codeHash);
      final plain = await PairingCryptoService.decrypt(
        code,
        salt: blob.salt,
        nonce: blob.nonce,
        cipherTextAndMac: blob.ciphertext,
      );
      final envelope = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      if (envelope['v'] != 4) {
        throw StateError('Цей код не підтримує підключення профілю');
      }
      final channelId = envelope['channelId'] as String;
      final familyId = envelope['familyId'] as String;
      final inviterPersonUuid = envelope['inviterPersonUuid'] as String;
      final inviterName = envelope['inviterName'] as String? ?? l10n.familyFallbackName;
      final inviterAvatarIndex = envelope['inviterAvatarIndex'] as int? ?? 0;
      final profileName = envelope['profileName'] as String? ?? l10n.profileFallbackName;
      final profileAvatarIndex = envelope['profileAvatarIndex'] as int? ?? 0;
      final syncKeyBytes = base64Decode(envelope['syncKey'] as String);

      // Свідомо БЕЗ перевірки ліміту автономних профілів тут: створити таке
      // запрошення міг лише той, хто вже на плані Elly Family (перевірено на
      // його боці, FamilyGroupInviteScreen/_FamilyGroupSection) — той, кого
      // запросили, приєднується як частина цієї ж сімейної групи, а не як
      // самостійна покупка власного плану.
      // familyId НЕ пишеться в Members тут: це поле означає лише "сім'я, яку
      // я створив і за яку плачу", а не "у яку сім'ю я приєднався" — щойно
      // створений профіль ще не веде власної сім'ї. Членство в цій групі
      // відображається нижче через FamilyPeers.
      final db = ref.read(databaseProvider);
      final memberId = await ref.read(membersRepositoryProvider).insert(
            MembersCompanion.insert(
              name: profileName,
              avatarIndex: Value(profileAvatarIndex),
              role: const Value('owner'),
            ),
          );
      final me = await ref.read(membersRepositoryProvider).getById(memberId);
      final myPersonUuid = me!.personUuid!;

      await ref
          .read(sharedChannelsRepositoryProvider)
          .bind(channelId: channelId, memberId: memberId);
      await SharedChannelKeyStorage.store(channelId, syncKeyBytes);

      String? token;
      try {
        token = await PushTokenService.getToken();
        if (token != null) {
          await _relayApi.register(
            channelId: channelId,
            pushToken: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
        }
      } catch (_) {
        // Не критично — реєстрацію push-токена можна повторити пізніше.
      }

      // Одноразово підтягуємо всю історію, яку запрошувач вів за цей
      // профіль — та сама машинерія, що й старий 1:1-пейринг, лише один раз.
      await FamilySyncService(db).syncChannelForMember(memberId);

      // Далі — звичайний незалежний учасник сімейної групи: запрошувач стає
      // FamilyPeer з повним доступом одразу (секунду тому це були його ж
      // дані), а одноразовий канал передачі історії більше не потрібен.
      await FamilyPeersRepository(db).upsert(FamilyPeersCompanion.insert(
        personUuid: inviterPersonUuid,
        familyId: familyId,
        name: inviterName,
        avatarIndex: Value(inviterAvatarIndex),
        channelId: channelId,
        // Я приєднався за ЙОГО кодом конверсії — це він мене запросив.
        invitedMe: const Value(true),
      ));
      for (final p in FamilyPermission.values) {
        await FamilyVisibilityService.setAllowed(
          db,
          subjectPersonUuid: myPersonUuid,
          viewerPersonUuid: inviterPersonUuid,
          permission: p,
          value: true,
        );
      }
      await ref.read(sharedChannelsRepositoryProvider).unbind(memberId);

      if (token != null) {
        try {
          final key = SecretKey(syncKeyBytes);
          final myCard = {
            'v': 3,
            'familyId': familyId,
            'personUuid': myPersonUuid,
            'name': profileName,
            'avatarIndex': profileAvatarIndex,
          };
          final encrypted = await SyncCryptoService.encryptEntity(key, myCard);
          await _relayApi.send(
            channelId: channelId,
            senderToken: token,
            encryptedPayloadBase64: base64Encode(encrypted),
          );
        } catch (_) {
          // Запрошувач підхопить картку на наступному тригері refreshPeers().
        }
      }
      unawaited(FamilyPeerSyncService(db).syncAllPeers());

      final existingMeds = await ref.read(medicationsRepositoryProvider).getByMember(memberId);

      if (!mounted) return;
      if (existingMeds.isNotEmpty) {
        setState(() {
          _profileName = profileName;
          _inviterName = inviterName;
          _memberId = memberId;
          _stage = _JoinStage.review;
        });
      } else {
        _goToDashboard(hasMedications: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _JoinStage.entering;
        _error = context.l10n.joinFailedCheckCodeError;
      });
    }
  }

  void _acceptSchedule() {
    _goToDashboard(hasMedications: true);
  }

  Future<void> _declineSchedule() async {
    if (_memberId == null || _finishing) return;
    setState(() => _finishing = true);
    final medsRepo = ref.read(medicationsRepositoryProvider);
    final meds = await medsRepo.getByMember(_memberId!);
    for (final m in meds) {
      await medsRepo.softDelete(m.id);
    }
    if (!mounted) return;
    _goToDashboard(hasMedications: false);
  }

  void _goToDashboard({required bool hasMedications}) {
    // Профіль і вся підтягнута через syncChannelForMember історія (в т.ч.
    // самопочуття) щойно записані напряму через репозиторії/FamilySyncService,
    // а не через звичайний потік "форма → repo.insert → реактивний Stream
    // на екрані" — деякі глобальні провайдери (generateTodayIntakesProvider
    // тощо) могли встигнути закешуватись ДО цього моменту порожніми ще на
    // ранніх кроках онбордингу. Явно скидаємо їх тут, а не покладаємось на
    // pull-to-refresh на Сьогодні — той самий патерн, що й після відновлення
    // бекапу (RestoreAccountScreen).
    ref.invalidate(databaseProvider);
    ref.invalidate(currentMemberProvider);
    ref.invalidate(generateTodayIntakesProvider);
    ref.invalidate(generateTodayActivityLogsProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivacyGateScreen(hasMedications: hasMedications),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _JoinStage.review,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: _stage == _JoinStage.review ? _buildReview() : _buildEntry(),
        ),
      ),
    );
  }

  Widget _buildEntry() {
    final working = _stage == _JoinStage.working;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MkBackButton(
              onTap: working ? null : () => Navigator.of(context).pop()),
          const SizedBox(height: 20),
          Text(context.l10n.connectToFamilyTitle, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            context.l10n.enterAccessCodeHint,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            enabled: !working,
            style: AppTextStyles.h2.copyWith(color: AppColors.primary, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: context.l10n.codeInputHint,
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
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: working ? null : _redeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                elevation: 0,
              ),
              child: Text(
                working ? context.l10n.checkingEllipsisLabel : context.l10n.joinAction,
                style: AppTextStyles.labelLg.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    final name = _inviterName ?? _profileName ?? context.l10n.familyFallbackName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.family_restroom_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(context.l10n.scheduleAlreadyReadyTitle, style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            context.l10n.scheduleSetByInviterBody(name),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
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
                    context.l10n.agreeUseFamilyScheduleCheckbox,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textMain),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_consentChecked && !_finishing) ? _acceptSchedule : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                elevation: 0,
              ),
              child: Text(context.l10n.startAction, style: AppTextStyles.labelLg.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _finishing ? null : _declineSchedule,
              child: Text(
                _finishing ? context.l10n.creatingEllipsisLabel : context.l10n.declineScheduleCreateOwnAction,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
