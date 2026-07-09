import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/ai_consent_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/privacy_consent_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/members_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../legal/privacy_policy_screen.dart';
import '../today/providers/today_providers.dart';

class _ConsentInfo {
  final String kind;
  final IconData icon;
  final String title;
  final String description;
  const _ConsentInfo(this.kind, this.icon, this.title, this.description);
}

const _consents = [
  _ConsentInfo(
    'voice',
    Icons.mic_rounded,
    'Голосові команди',
    'Розпізнавання голосу через Anthropic (Claude) — додавання ліків, '
        'відмітки прийому та інші голосові команди.',
  ),
  _ConsentInfo(
    'scan',
    Icons.document_scanner_rounded,
    'Сканування рецептів',
    'Розпізнавання фото рецепта чи упаковки через Anthropic (Claude) — '
        'визначення назви, дозування, форми випуску.',
  ),
];

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  final Map<String, DateTime?> _dates = {};
  DateTime? _policyAcceptedAt;
  String? _policyAcceptedVersion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final c in _consents) {
      _dates[c.kind] = await AiConsentService.consentDate(c.kind);
    }
    _policyAcceptedAt = await PrivacyConsentService.acceptedAt();
    _policyAcceptedVersion = await PrivacyConsentService.acceptedVersion();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _revoke(String kind) async {
    await AiConsentService.revokeConsent(kind);
    if (mounted) setState(() => _dates[kind] = null);
  }

  Future<void> _confirmDeleteProfile(Member member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/illustrations/elly-thinking-2.png', height: 120),
            const SizedBox(height: AppDimensions.md),
            Text('Ви впевнені?', style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Будуть видалені весь розклад та медичні картки, прив\'язані до профілю ${member.name}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Видалити назавжди'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(databaseProvider);
    await FamilySyncService(db).deleteMemberEverywhere(member.id);
    await ref.read(membersRepositoryProvider).delete(member.id);
    ref.read(activeMemberIdProvider.notifier).state = null;
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(currentMemberProvider).valueOrNull;
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
                  Text('Конфіденційність', style: AppTextStyles.h2),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding,
                        AppDimensions.lg,
                        AppDimensions.screenPadding,
                        AppDimensions.xl,
                      ),
                      children: [
                        Text('Політика конфіденційності',
                            style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppDimensions.md),
                        _PolicyConsentTile(
                          acceptedAt: _policyAcceptedAt,
                          acceptedVersion: _policyAcceptedVersion,
                        ),
                        const SizedBox(height: AppDimensions.xl),
                        Text('Згоди на обробку даних AI-функціями',
                            style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppDimensions.md),
                        for (final c in _consents) ...[
                          _ConsentTile(
                            info: c,
                            date: _dates[c.kind],
                            onRevoke: () => _revoke(c.kind),
                          ),
                          const SizedBox(height: AppDimensions.md),
                        ],
                        const SizedBox(height: AppDimensions.sm),
                        Text(
                          'Скасування згоди не видаляє вже оброблені дані — '
                          'воно лише означає, що перед наступним використанням '
                          'цієї функції застосунок знову запитає підтвердження.',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted),
                        ),
                        if (member != null) ...[
                          const SizedBox(height: AppDimensions.xl),
                          Text('Небезпечна зона',
                              style: AppTextStyles.bodyMd.copyWith(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: AppDimensions.md),
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusLg),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0F000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 6)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppDimensions.radiusMd),
                                  ),
                                  child: const Icon(Icons.delete_forever_rounded,
                                      size: 20, color: AppColors.danger),
                                ),
                                const SizedBox(width: AppDimensions.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Видалити профіль назавжди',
                                          style: AppTextStyles.labelLg
                                              .copyWith(color: AppColors.danger)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Видалить усі дані профілю "${member.name}" — '
                                        'локально і на сервері, якщо налаштований обмін',
                                        style: AppTextStyles.bodySm
                                            .copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  borderRadius:
                                      BorderRadius.circular(AppDimensions.radiusFull),
                                  onTap: () => _confirmDeleteProfile(member),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.chevron_right_rounded,
                                        color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
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

class _PolicyConsentTile extends StatelessWidget {
  final DateTime? acceptedAt;
  final String? acceptedVersion;

  const _PolicyConsentTile({required this.acceptedAt, required this.acceptedVersion});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final accepted = acceptedAt != null;
    final isCurrent = acceptedVersion == PrivacyConsentService.currentVersion;
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (accepted && isCurrent ? AppColors.primary : AppColors.warning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Center(
                  child: Icon(Icons.privacy_tip_rounded,
                      size: 20,
                      color: accepted && isCurrent ? AppColors.primary : AppColors.warning),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Політика конфіденційності', style: AppTextStyles.labelLg),
                    const SizedBox(height: 2),
                    Text(
                      accepted
                          ? (isCurrent
                              ? 'Прийнято ${_formatDate(acceptedAt!)} · версія $acceptedVersion'
                              : 'Прийнято стару версію ($acceptedVersion) — буде запропоновано погодитись знову')
                          : 'Ще не прийнято',
                      style: AppTextStyles.bodySm.copyWith(
                          color: accepted && isCurrent ? AppColors.primary : AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
              child: const Text('Переглянути повний текст'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final _ConsentInfo info;
  final DateTime? date;
  final VoidCallback onRevoke;

  const _ConsentTile({
    required this.info,
    required this.date,
    required this.onRevoke,
  });

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final given = date != null;
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (given ? AppColors.primary : AppColors.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Center(
                  child: Icon(info.icon,
                      size: 20,
                      color:
                          given ? AppColors.primary : AppColors.textMuted),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title, style: AppTextStyles.labelLg),
                    const SizedBox(height: 2),
                    Text(
                      given
                          ? 'Надано ${_formatDate(date!)}'
                          : 'Згоду не надано',
                      style: AppTextStyles.bodySm.copyWith(
                          color: given
                              ? AppColors.primary
                              : AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(info.description,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub)),
          if (given) ...[
            const SizedBox(height: AppDimensions.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRevoke,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Скасувати згоду'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
