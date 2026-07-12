import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/family_visibility_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../today/providers/today_providers.dart';

/// Один можливий "глядач" видимості — незалежний учасник сімейної групи
/// ([FamilyPeer], Фаза 2) зі своїм власним акаунтом і пристроєм, АБО хтось,
/// кого я знаю через автопредставлення ([KnownFamilyMember], Фаза 5), але з
/// ким ще нема справжнього зашифрованого каналу ([isPending]). Локальні
/// профілі (dependent/member, керовані цим пристроєм) тут принципово не
/// показуються — власник і так має до них повний доступ, "видимість" як
/// окреме право для них не має сенсу: нема кому давати доступ, крім самого
/// власника.
class _ViewerInfo {
  final String personUuid;
  final String name;
  final int avatarIndex;
  final bool isPending;
  const _ViewerInfo({
    required this.personUuid,
    required this.name,
    required this.avatarIndex,
    this.isPending = false,
  });
}

/// Налаштування, кому з автономних учасників сім'ї видно завдання/
/// медкартку/розклад цього профілю, хто може його редагувати і кому
/// надсилати сповіщення. ⚠️ Перемикачі нижче (_ViewerCard) впливають лише
/// на дані, що йдуть через цей сервіс — реальний бар'єр для медкартки
/// ([_MedcardSyncCard], перевіряє `FamilySyncService`) і для перегляду в
/// межах групи ([_ViewerCard], keyed по personUuid — Фаза 3). setAllowed
/// можна викликати лише для subject'а, яким керує цей пристрій (перевірка
/// в самому сервісі).
class FamilyVisibilityScreen extends ConsumerWidget {
  final int subjectMemberId;
  const FamilyVisibilityScreen({super.key, required this.subjectMemberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);
    final peersAsync = ref.watch(_familyPeersProvider);
    final knownAsync = ref.watch(_knownFamilyMembersProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.md,
                AppDimensions.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Text('Видимість для сім\'ї', style: AppTextStyles.h2),
                ],
              ),
            ),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('$e')),
                data: (members) {
                  Member? subject;
                  for (final m in members) {
                    if (m.id == subjectMemberId) {
                      subject = m;
                      break;
                    }
                  }
                  if (subject?.personUuid == null) {
                    return const Center(child: Text('Профіль не знайдено'));
                  }
                  final subjectUuid = subject!.personUuid!;

                  final peers = peersAsync.valueOrNull ?? const [];
                  final peerUuids = peers.map((p) => p.personUuid).toSet();
                  final viewers = <_ViewerInfo>[
                    for (final p in peers)
                      _ViewerInfo(personUuid: p.personUuid, name: p.name, avatarIndex: p.avatarIndex),
                    // Візитівки без каналу (автопредставлення, Фаза 5) — уже
                    // реальний [FamilyPeer] на той самий personUuid завжди
                    // пріоритетніший, на випадок якщо два провайдери на
                    // мить розсинхронізовані.
                    for (final k in knownAsync.valueOrNull ?? const [])
                      if (!peerUuids.contains(k.personUuid))
                        _ViewerInfo(
                          personUuid: k.personUuid,
                          name: k.name,
                          avatarIndex: k.avatarIndex,
                          isPending: true,
                        ),
                  ];

                  if (viewers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(
                            AppDimensions.screenPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/illustrations/elly22.png',
                                height: 160),
                            const SizedBox(height: AppDimensions.lg),
                            Text(
                              'Якщо до вашої сімейної групи приєднаються '
                              'автономні учасники (зі своїм акаунтом), тут '
                              'можна буде керувати їхнім доступом до '
                              'вашого профілю',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.lg,
                      AppDimensions.screenPadding,
                      AppDimensions.xl,
                    ),
                    children: [
                      _MedcardSyncCard(subjectPersonUuid: subjectUuid),
                      const SizedBox(height: AppDimensions.lg),
                      Text(
                        'Що бачать і можуть робити інші члени сім\'ї з вашим профілем',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      for (final viewer in viewers) ...[
                        _ViewerCard(subjectPersonUuid: subjectUuid, viewer: viewer),
                        const SizedBox(height: AppDimensions.md),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _familyPeersProvider = StreamProvider<List<FamilyPeer>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchAll();
});

final _knownFamilyMembersProvider = StreamProvider<List<KnownFamilyMember>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchKnownMembers();
});

/// Головний перемикач: чи синхронізується медкартка цього профілю на інші
/// пристрої сім'ї через family-sync взагалі (незалежно від того, з ким саме
/// цей профіль спарено). На відміну від перемикачів нижче — це реальний
/// бар'єр: коли вимкнено, дані медкартки (алергії, хронічні захворювання,
/// щеплення, операції, аналізи, візити з вкладеннями) ніколи не потрапляють
/// у payload синхронізації. Ліки й розклад прийому синхронізуються завжди.
class _MedcardSyncCard extends StatefulWidget {
  final String subjectPersonUuid;
  const _MedcardSyncCard({required this.subjectPersonUuid});

  @override
  State<_MedcardSyncCard> createState() => _MedcardSyncCardState();
}

class _MedcardSyncCardState extends State<_MedcardSyncCard> {
  bool _loading = true;
  bool _value = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await FamilyVisibilityService.isMedcardSyncAllowed(widget.subjectPersonUuid);
    if (mounted) {
      setState(() {
        _value = value;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _value = value);
    await FamilyVisibilityService.setMedcardSyncAllowed(widget.subjectPersonUuid, value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Синхронізувати медкартку на інші пристрої', style: AppTextStyles.labelLg),
              ),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                Switch(
                  value: _value,
                  onChanged: _toggle,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primaryLight,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Якщо вимкнено, алергії, хронічні захворювання, щеплення, операції, '
            'аналізи й візити цього профілю (разом із вкладеннями) не передаються '
            'на інші пристрої сім\'ї, підключені через пейринг. Ліки й розклад '
            'прийому синхронізуються незалежно від цього перемикача.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

class _ViewerCard extends ConsumerStatefulWidget {
  final String subjectPersonUuid;
  final _ViewerInfo viewer;
  const _ViewerCard({required this.subjectPersonUuid, required this.viewer});

  @override
  ConsumerState<_ViewerCard> createState() => _ViewerCardState();
}

class _ViewerCardState extends ConsumerState<_ViewerCard> {
  bool _loading = true;
  bool _denied = false;
  final Map<FamilyPermission, bool> _values = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    for (final p in FamilyPermission.values) {
      _values[p] = await FamilyVisibilityService.isAllowed(
          db, widget.subjectPersonUuid, widget.viewer.personUuid, p);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(FamilyPermission p, bool value) async {
    setState(() => _values[p] = value);
    try {
      await FamilyVisibilityService.setAllowed(
        ref.read(databaseProvider),
        subjectPersonUuid: widget.subjectPersonUuid,
        viewerPersonUuid: widget.viewer.personUuid,
        permission: p,
        value: value,
      );
    } on FamilyGrantDeniedException {
      if (mounted) setState(() => _denied = true);
      return;
    }
    // Дозвіл збережено локально й спрацює одразу, щойно зʼявиться справжній
    // канал — але поки його нема (це лише візитівка з автопредставлення),
    // просимо платящого звести нас із цим учасником.
    if (widget.viewer.isPending && value) {
      await FamilyPeerSyncService(ref.read(databaseProvider))
          .requestIntroduction(widget.viewer.personUuid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarImage(index: widget.viewer.avatarIndex, size: 36),
              const SizedBox(width: AppDimensions.sm),
              Expanded(child: Text(widget.viewer.name, style: AppTextStyles.labelLg)),
              if (widget.viewer.isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Очікуємо з\'єднання',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppDimensions.md),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))),
            )
          else ...[
            const SizedBox(height: AppDimensions.sm),
            _PermissionRow(
              label: 'Отримує сповіщення',
              value: _values[FamilyPermission.notify]!,
              onChanged: (v) => _toggle(FamilyPermission.notify, v),
            ),
            _PermissionRow(
              label: 'Може редагувати профіль',
              value: _values[FamilyPermission.edit]!,
              onChanged: (v) => _toggle(FamilyPermission.edit, v),
            ),
            _PermissionRow(
              label: 'Бачить завдання, медкартку й розклад',
              value: _values[FamilyPermission.view]!,
              onChanged: (v) => _toggle(FamilyPermission.view, v),
            ),
            if (_denied) ...[
              const SizedBox(height: 4),
              Text(
                'Не вдалося змінити — це не ваш профіль',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PermissionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMd),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}
