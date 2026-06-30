import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../shared/widgets/mk_card.dart';
import '../../shared/widgets/pro_gate.dart';

class ProfileScreen extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const ProfileScreen({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.profileTitle, style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        children: [
          _ProfileHeader(),
          const SizedBox(height: AppDimensions.xxl),
          if (!AppConfig.isPro) ...[
            _ProBanner(l10n: l10n),
            const SizedBox(height: AppDimensions.xxl),
          ],
          _SectionTitle(l10n.profileMyProfile),
          const SizedBox(height: AppDimensions.md),
          MkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LanguageTile(
                  currentLocale: currentLocale,
                  onChanged: onLocaleChanged,
                  l10n: l10n,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),
          _SectionTitle(l10n.comingSoon),
          const SizedBox(height: AppDimensions.md),
          MkCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: l10n.profileNotifications,
                  subtitle: l10n.profileNotificationsHint,
                  locked: !AppConfig.canSetReminders,
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.bar_chart_outlined,
                  title: l10n.profileAnalytics,
                  subtitle: l10n.profileAnalyticsHint,
                  locked: !AppConfig.canViewAnalytics,
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: l10n.profileExportData,
                  subtitle: l10n.profileExportDataHint,
                  locked: !AppConfig.canExportData,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),
          MkCard(
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: Icons.info_outline,
              title: l10n.profileAbout,
              subtitle: l10n.profileVersion('1.0.0'),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppDimensions.avatarLg,
          height: AppDimensions.avatarLg,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🧑', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(width: AppDimensions.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Мій профіль', style: AppTextStyles.h3),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppConfig.isPro
                    ? AppColors.proGoldLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusFull),
              ),
              child: Text(
                AppConfig.isPro ? '👑 Pro' : 'Free',
                style: AppTextStyles.caption.copyWith(
                  color: AppConfig.isPro
                      ? AppColors.proGold
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProBanner extends StatelessWidget {
  final AppLocalizations l10n;
  const _ProBanner({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8860B), Color(0xFFD4A017)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 32)),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.proTitle,
                    style: AppTextStyles.labelLg
                        .copyWith(color: Colors.white)),
                Text(l10n.proSubtitle,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.proGold,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd),
              ),
            ),
            child: Text(l10n.proUpgradeButton,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: AppTextStyles.caption
            .copyWith(fontWeight: FontWeight.w700));
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;
  final AppLocalizations l10n;

  const _LanguageTile({
    required this.currentLocale,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.primary),
      title: Text(l10n.profileLanguage, style: AppTextStyles.bodyLg),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: currentLocale,
          items: [
            DropdownMenuItem(
              value: const Locale('uk'),
              child: Text(l10n.profileLanguageUk,
                  style: AppTextStyles.bodyMd),
            ),
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(l10n.profileLanguageEn,
                  style: AppTextStyles.bodyMd),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: locked ? AppColors.textMuted : AppColors.primary,
      ),
      title: Row(
        children: [
          Text(title,
              style: AppTextStyles.bodyLg.copyWith(
                color: locked
                    ? AppColors.textMuted
                    : AppColors.textMain,
              )),
          if (locked) ...[
            const SizedBox(width: 8),
            const ProBadge(),
          ],
        ],
      ),
      subtitle: Text(subtitle, style: AppTextStyles.bodySm),
      trailing: locked
          ? const Icon(Icons.lock_outline,
              size: 16, color: AppColors.textMuted)
          : const Icon(Icons.chevron_right,
              color: AppColors.textMuted),
      onTap: locked ? null : () {},
    );
  }
}
