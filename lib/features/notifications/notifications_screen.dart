import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../today/providers/today_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // ── Основні ──
  bool _pushEnabled = true;
  bool _telegramEnabled = true;
  bool _vibrationEnabled = true;

  // ── Час нагадувань ──
  int _offsetMinutes = 0; // 0/5/10/15/30
  int _repeatIndex = 1; // 0=5хв 1=20хв 2=45хв 3=60хв

  // ── Тихі години ──
  bool _quietEnabled = false;
  TimeOfDay _quietFrom = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _quietTo = const TimeOfDay(hour: 7, minute: 0);

  // ── Алерти за членами ──
  final Map<int, bool> _memberAlerts = {};

  static const _avatars = ['🧑', '👩', '👨', '👧', '👦', '👴', '👵', '🧒'];
  static const _avatarBg = [
    Color(0xFFEDE9FE),
    Color(0xFFDCFCE7),
    Color(0xFFFEE2E2),
    Color(0xFFFEF9C3),
    Color(0xFFDBEAFE),
    Color(0xFFFFEDD5),
    Color(0xFFF3E8FF),
    Color(0xFFF0FDFA),
  ];

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);

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
                      emoji: '🔔',
                      label: 'Push-сповіщення',
                      sub: 'Нагадування про прийом ліків',
                      value: _pushEnabled,
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                    _SwitchRow(
                      emoji: '✈️',
                      label: 'Telegram-бот',
                      sub: '@MedKitBot підключено',
                      value: _telegramEnabled,
                      onChanged: (v) => setState(() => _telegramEnabled = v),
                    ),
                    _SwitchRow(
                      emoji: '📳',
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
                      current: _offsetMinutes,
                      onChanged: (v) => setState(() => _offsetMinutes = v),
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
                      emoji: '🌙',
                      label: 'Не турбувати',
                      sub: 'Нічний режим',
                      value: _quietEnabled,
                      onChanged: (v) => setState(() => _quietEnabled = v),
                    ),
                    _TimeRow(
                      emoji: '🔲',
                      label: 'З',
                      time: _quietFrom,
                      enabled: _quietEnabled,
                      onTap: () => _pickTime(context, _quietFrom,
                          (t) => setState(() => _quietFrom = t)),
                    ),
                    _TimeRow(
                      emoji: '🔳',
                      label: 'До',
                      time: _quietTo,
                      enabled: _quietEnabled,
                      onTap: () => _pickTime(context, _quietTo,
                          (t) => setState(() => _quietTo = t)),
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
                      for (final m in nonOwners) {
                        _memberAlerts.putIfAbsent(m.id, () => true);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Алерти при пропуску членів сімʼї'),
                          _MemberAlertsCard(
                            members: nonOwners,
                            alerts: _memberAlerts,
                            avatars: _avatars,
                            avatarBg: _avatarBg,
                            onChanged: (id, v) =>
                                setState(() => _memberAlerts[id] = v),
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
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.textMain),
            ),
          ),
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
  final String emoji;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.emoji,
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
          Text(emoji, style: const TextStyle(fontSize: 20)),
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
              const Text('🔁', style: TextStyle(fontSize: 20)),
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
  final String emoji;
  final String label;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeRow({
    required this.emoji,
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
            Text(emoji,
                style: TextStyle(
                    fontSize: 20,
                    color: enabled ? null : AppColors.textMuted)),
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
  final List<String> avatars;
  final List<Color> avatarBg;
  final void Function(int id, bool value) onChanged;

  const _MemberAlertsCard({
    required this.members,
    required this.alerts,
    required this.avatars,
    required this.avatarBg,
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
            final emoji = avatars[m.avatarIndex % avatars.length];
            final bg = avatarBg[m.avatarIndex % avatarBg.length];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
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
