import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_screen_header.dart';

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

class _FaqGroup {
  final String title;
  final IconData icon;
  final List<_Faq> items;
  const _FaqGroup(this.title, this.icon, this.items);
}

List<_FaqGroup> _buildGroups(BuildContext context) {
  final l10n = context.l10n;
  return <_FaqGroup>[
    _FaqGroup(l10n.faqGroupPrivacyTitle, Icons.lock_outline_rounded, [
      _Faq(l10n.faqPrivacyQ1, l10n.faqPrivacyA1),
      _Faq(l10n.faqPrivacyQ2, l10n.faqPrivacyA2),
      _Faq(l10n.faqPrivacyQ3, l10n.faqPrivacyA3),
      _Faq(l10n.faqPrivacyQ4, l10n.faqPrivacyA4),
    ]),
    _FaqGroup(l10n.faqGroupFamilyTitle, Icons.family_restroom_rounded, [
      _Faq(l10n.faqFamilyQ1, l10n.faqFamilyA1),
      _Faq(l10n.faqFamilyQ2, l10n.faqFamilyA2),
      _Faq(l10n.faqFamilyQ3, l10n.faqFamilyA3),
    ]),
    _FaqGroup(l10n.faqGroupAiTitle, Icons.smart_toy_outlined, [
      _Faq(l10n.faqAiQ1, l10n.faqAiA1),
      _Faq(l10n.faqAiQ2, l10n.faqAiA2),
    ]),
    _FaqGroup(l10n.notificationsLabel, Icons.notifications_none_rounded, [
      _Faq(l10n.faqNotificationsQ1, l10n.faqNotificationsA1),
      _Faq(l10n.faqNotificationsQ2, l10n.faqNotificationsA2),
    ]),
    _FaqGroup(l10n.plansLabel, Icons.workspace_premium_outlined, [
      _Faq(l10n.faqPlansQ1, l10n.faqPlansA1),
    ]),
    _FaqGroup(l10n.faqGroupTechTitle, Icons.build_outlined, [
      _Faq(l10n.faqTechQ1, l10n.faqTechA1),
      _Faq(l10n.faqTechQ2, l10n.faqTechA2),
    ]),
  ];
}

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            MkScreenHeader(title: context.l10n.helpFaqLabel),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  for (final g in groups) ...[
                    _GroupHeader(icon: g.icon, title: g.title),
                    const SizedBox(height: AppDimensions.sm),
                    ...g.items.map((f) => _FaqTile(faq: f)),
                    const SizedBox(height: AppDimensions.lg),
                  ],
                  const _ContactsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _GroupHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: AppTextStyles.bodyMd.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(faq.q, style: AppTextStyles.labelLg),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textMuted,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(faq.a, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard();

  Future<void> _openMail(String address) => launchUrl(Uri(scheme: 'mailto', path: address));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.faqNotFoundQuestionTitle, style: AppTextStyles.labelLg),
          const SizedBox(height: 4),
          Text(
            context.l10n.faqWriteUsSubtitle,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: AppDimensions.md),
          _ContactRow(
            icon: Icons.mail_outline_rounded,
            label: context.l10n.supportLabel,
            value: 'support@elly-medkit.com',
            onTap: () => _openMail('support@elly-medkit.com'),
          ),
          const SizedBox(height: AppDimensions.sm),
          _ContactRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: context.l10n.supportChatLabel,
            value: context.l10n.soonLabel,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
                  Text(
                    value,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: onTap != null ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
