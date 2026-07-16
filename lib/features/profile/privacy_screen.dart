import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/ai_consent_service.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/services/family_sync_service.dart';
import '../../core/services/privacy_consent_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
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

const _consentKinds = ['voice', 'scan'];

List<_ConsentInfo> _consentsFor(BuildContext context) => [
      _ConsentInfo(
        'voice',
        Icons.mic_rounded,
        context.l10n.voiceConsentTitle,
        context.l10n.voiceConsentDescription,
      ),
      _ConsentInfo(
        'scan',
        Icons.document_scanner_rounded,
        context.l10n.scanConsentTitle,
        context.l10n.scanConsentDescription,
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
  bool _appLockEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final kind in _consentKinds) {
      _dates[kind] = await AiConsentService.consentDate(kind);
    }
    _policyAcceptedAt = await PrivacyConsentService.acceptedAt();
    _policyAcceptedVersion = await PrivacyConsentService.acceptedVersion();
    _appLockEnabled = await AppLockService.isEnabled();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleAppLock(bool value) async {
    setState(() => _appLockEnabled = value);
    await AppLockService.setEnabled(value);
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
            Text(context.l10n.areYouSureTitle, style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              context.l10n.deleteMemberConfirmBody(member.name),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.l10n.deleteForeverAction),
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
                  Text(context.l10n.privacyLabel, style: AppTextStyles.h2),
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
                        Text(context.l10n.securityLabel,
                            style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppDimensions.md),
                        _AppLockTile(
                          enabled: _appLockEnabled,
                          onChanged: _toggleAppLock,
                        ),
                        const SizedBox(height: AppDimensions.xl),
                        Text(context.l10n.privacyPolicyLabel,
                            style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppDimensions.md),
                        _PolicyConsentTile(
                          acceptedAt: _policyAcceptedAt,
                          acceptedVersion: _policyAcceptedVersion,
                        ),
                        const SizedBox(height: AppDimensions.xl),
                        Text(context.l10n.aiConsentSectionLabel,
                            style: AppTextStyles.bodyMd.copyWith(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppDimensions.md),
                        for (final c in _consentsFor(context)) ...[
                          _ConsentTile(
                            info: c,
                            date: _dates[c.kind],
                            onRevoke: () => _revoke(c.kind),
                          ),
                          const SizedBox(height: AppDimensions.md),
                        ],
                        const SizedBox(height: AppDimensions.sm),
                        Text(
                          context.l10n.consentRevokeNoteBody,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted),
                        ),
                        if (member != null) ...[
                          const SizedBox(height: AppDimensions.xl),
                          Text(context.l10n.dangerZoneLabel,
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
                                      Text(context.l10n.deleteProfileForeverLabel,
                                          style: AppTextStyles.labelLg
                                              .copyWith(color: AppColors.danger)),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.l10n.deleteProfileForeverBody(member.name),
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

class _AppLockTile extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _AppLockTile({required this.enabled, required this.onChanged});

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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (enabled ? AppColors.primary : AppColors.textMuted)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 20, color: enabled ? AppColors.primary : AppColors.textMuted),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.appLockToggleLabel, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Text(
                  context.l10n.appLockDescription,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
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
                    Text(context.l10n.privacyPolicyLabel, style: AppTextStyles.labelLg),
                    const SizedBox(height: 2),
                    Text(
                      accepted
                          ? (isCurrent
                              ? context.l10n.policyAcceptedLabel(
                                  _formatDate(acceptedAt!), '$acceptedVersion')
                              : context.l10n.policyAcceptedOldVersionLabel(
                                  '$acceptedVersion'))
                          : context.l10n.policyNotAcceptedLabel,
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
              child: Text(context.l10n.viewFullTextAction),
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
                          ? context.l10n.consentGivenLabel(_formatDate(date!))
                          : context.l10n.consentNotGivenLabel,
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
                child: Text(context.l10n.revokeConsentAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
