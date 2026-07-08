import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../data/db/app_database.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/wheel_time_picker.dart';
import '../today/providers/today_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // ── Не прив'язані до реальної логіки (поки що суто UI) ──
  bool _telegramEnabled = true;
  bool _vibrationEnabled = true;
  int _repeatIndex = 1; // 0=5хв 1=20хв 2=45хв 3=60хв

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
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
                      icon: Icons.send_rounded,
                      label: 'Telegram-бот',
                      sub: '@EllyBot підключено',
                      value: _telegramEnabled,
                      onChanged: (v) => setState(() => _telegramEnabled = v),
                    ),
                    _SwitchRow(
                      icon: Icons.vibration_rounded,
                      label: 'Вібрація',
                      sub: 'Разом зі звуком',
                      value: _vibrationEnabled,
                      onChanged: (v) => setState(() => _vibrationEnabled = v),
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
                      index: _repeatIndex,
                      onChanged: (v) => setState(() => _repeatIndex = v),
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
        style:
            AppTextStyles.labelMd.copyWith(color: AppColors.textSub),
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
              const Text('⏱', style: TextStyle(fontSize: 20)),
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
          Row(
            children: _options.map((opt) {
              final selected = current == opt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
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
  final int index;
  final ValueChanged<int> onChanged;

  const _RepeatRow({required this.index, required this.onChanged});

  static const _labels = ['5 хв', '20 хв', '45 хв', '1 год'];

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
              onChanged: (v) => onChanged(v.round()),
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
