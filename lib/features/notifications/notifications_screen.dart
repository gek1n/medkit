import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../today/providers/today_providers.dart';

final _notifyingPeersProvider = StreamProvider<List<FamilyPeer>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchAll();
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
    final peersAsync = ref.watch(_notifyingPeersProvider);
    final settings = ref.watch(notificationSettingsProvider);
    final settingsNotifier = ref.read(notificationSettingsProvider.notifier);
    final quietFrom = TimeOfDay(
        hour: settings.quietFromMinutes ~/ 60,
        minute: settings.quietFromMinutes % 60);
    final quietTo = TimeOfDay(
        hour: settings.quietToMinutes ~/ 60,
        minute: settings.quietToMinutes % 60);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackHeader(),
                  const SizedBox(height: AppDimensions.lg),
                  _SectionTitle('Основні'),
                  _SettingsCard(children: [
                    _SwitchRow(
                      icon: Icons.notifications_rounded,
                      label: 'Push-сповіщення',
                      sub: 'Нагадування про прийом ліків',
                      value: settings.pushEnabled,
                      onChanged: settingsNotifier.setPushEnabled,
                    ),
                    _SwitchRow(
                      icon: Icons.vibration_rounded,
                      label: 'Вібрація',
                      sub: 'Разом зі звуком',
                      value: settings.vibrationEnabled,
                      onChanged: settingsNotifier.setVibrationEnabled,
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.xl),
                  _SectionTitle('Час нагадувань'),
                  _SettingsCard(children: [
                    _OffsetRow(
                      current: settings.offsetMinutes,
                      onChanged: settingsNotifier.setOffsetMinutes,
                    ),
                    _RepeatRow(
                      minutes: settings.repeatMinutes,
                      onChanged: settingsNotifier.setRepeatMinutes,
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.xl),
                  _SectionTitle('Тихі години'),
                  _SettingsCard(children: [
                    _SwitchRow(
                      icon: Icons.dark_mode_rounded,
                      label: 'Не турбувати',
                      sub: 'Нічний режим',
                      value: settings.quietEnabled,
                      onChanged: settingsNotifier.setQuietEnabled,
                    ),
                    _TimeRow(
                      icon: Icons.schedule_rounded,
                      label: 'З',
                      time: quietFrom,
                      enabled: settings.quietEnabled,
                      onTap: () => _pickTime(
                          context, quietFrom, settingsNotifier.setQuietFrom),
                    ),
                    _TimeRow(
                      icon: Icons.schedule_rounded,
                      label: 'До',
                      time: quietTo,
                      enabled: settings.quietEnabled,
                      onTap: () => _pickTime(
                          context, quietTo, settingsNotifier.setQuietTo),
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.xl),
                  membersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (members) {
                      final nonOwners =
                          members.where((m) => m.role != 'owner').toList();
                      if (nonOwners.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Алерти при пропуску членів сімʼї'),
                          _MemberAlertsCard(
                            members: nonOwners,
                            alerts: settings.memberAlerts,
                            onChanged: settingsNotifier.setMemberAlert,
                          ),
                          const SizedBox(height: AppDimensions.xl),
                        ],
                      );
                    },
                  ),
                  peersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (peers) {
                      final notifying = peers.where((p) => p.notifyGranted).toList();
                      if (notifying.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Сповіщення від сім\'ї'),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppDimensions.screenPadding,
                              0,
                              AppDimensions.screenPadding,
                              AppDimensions.sm,
                            ),
                            child: Text(
                              'Ці учасники дозволили надсилати вам сповіщення про себе. '
                              'Тут ви вирішуєте, чи хочете їх отримувати.',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                            ),
                          ),
                          _PeerAlertsCard(
                            peers: notifying,
                            alerts: settings.peerAlerts,
                            onChanged: settingsNotifier.setPeerAlert,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showWheelTimePicker(context, initialTime: initial);
    if (picked != null) onPicked(picked);
  }
}

// ────────────────────────────── back header ──────────────────────────────

class _BackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.lg,
        AppDimensions.screenPadding,
        0,
      ),
      child: Row(
        children: [
          MkBackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(width: AppDimensions.md),
          Text('Сповіщення', style: AppTextStyles.h2),
        ],
      ),
    );
  }
}

// ────────────────────────────── section title ──────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        0,
        AppDimensions.screenPadding,
        AppDimensions.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.bodyMd
            .copyWith(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ────────────────────────────── settings card ──────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Container(
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
        child: Column(
          children: children
              .map((w) => Column(
                    children: [
                      w,
                      if (children.last != w)
                        const Divider(
                            height: 1,
                            indent: AppDimensions.screenPadding,
                            color: AppColors.borderLight),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ────────────────────────────── switch row ──────────────────────────────

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyMd),
                const SizedBox(height: 2),
                Text(sub,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSub)),
              ],
            ),
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

// ────────────────────────────── offset row ──────────────────────────────

class _OffsetRow extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const _OffsetRow({required this.current, required this.onChanged});

  static const _options = [0, 5, 10, 15, 30];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Зсув нагадування',
                        style: AppTextStyles.bodyMd),
                    const SizedBox(height: 2),
                    Text('Отримувати за N хв до прийому',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSub)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((opt) {
              final selected = current == opt;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    opt == 0 ? 'без зсуву' : '−$opt хв',
                    style: AppTextStyles.bodySm.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textMain,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── repeat row ──────────────────────────────

class _RepeatRow extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _RepeatRow({required this.minutes, required this.onChanged});

  static const _values = [5, 20, 45, 60];
  static const _labels = ['5 хв', '20 хв', '45 хв', '1 год'];

  @override
  Widget build(BuildContext context) {
    final index = _values.indexOf(minutes).clamp(0, _values.length - 1);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Повторити якщо нема відповіді',
                        style: AppTextStyles.bodyMd),
                    const SizedBox(height: 2),
                    Text(
                      'Через ${_labels[index]}',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLighter,
              thumbColor: AppColors.primary,
              overlayColor:
                  AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: index.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: (v) => onChanged(_values[v.round()]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _labels
                  .map((l) => Text(l,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textMuted)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────── time row ──────────────────────────────

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: enabled ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMd.copyWith(
                      color: enabled
                          ? AppColors.textMain
                          : AppColors.textMuted)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primaryLight
                    : AppColors.bg,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: enabled
                      ? AppColors.primaryLighter
                      : AppColors.border,
                ),
              ),
              child: Text(
                timeStr,
                style: AppTextStyles.labelMd.copyWith(
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── member alerts card ──────────────────────────────

class _MemberAlertsCard extends StatelessWidget {
  final List<Member> members;
  final Map<int, bool> alerts;
  final void Function(int id, bool value) onChanged;

  const _MemberAlertsCard({
    required this.members,
    required this.alerts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: 4,
        ),
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
        child: Column(
          children: members.map((m) {
            final isLast = members.last == m;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      AvatarImage(index: m.avatarIndex, size: 36),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Text(m.name,
                            style: AppTextStyles.bodyMd),
                      ),
                      Switch(
                        value: alerts[m.id] ?? true,
                        onChanged: (v) => onChanged(m.id, v),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, color: AppColors.borderLight),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ────────────────────────────── peer alerts card ──────────────────────────────
// Той самий патерн, що й _MemberAlertsCard, але для автономних учасників
// сімейної групи (FamilyPeer) — ключ personUuid, не локальний int id.
// Двостороння згода: тут я вирішую лише СВОЮ половину (чи хочу отримувати),
// список взагалі з'являється лише для тих, хто вже дозволив notify мені.

class _PeerAlertsCard extends StatelessWidget {
  final List<FamilyPeer> peers;
  final Map<String, bool> alerts;
  final void Function(String personUuid, bool value) onChanged;

  const _PeerAlertsCard({
    required this.peers,
    required this.alerts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: 4,
        ),
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
        child: Column(
          children: peers.map((p) {
            final isLast = peers.last == p;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      AvatarImage(index: p.avatarIndex, size: 36),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Text(p.name,
                            style: AppTextStyles.bodyMd),
                      ),
                      Switch(
                        value: alerts[p.personUuid] ?? true,
                        onChanged: (v) => onChanged(p.personUuid, v),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, color: AppColors.borderLight),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
