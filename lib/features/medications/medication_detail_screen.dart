import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/schedules_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _medWatchProvider = StreamProvider.family<Medication?, int>(
  (ref, id) => ref.watch(medicationsRepositoryProvider).watchById(id),
);

final _schedWatchProvider = StreamProvider.family<List<Schedule>, int>(
  (ref, medId) =>
      ref.watch(schedulesRepositoryProvider).watchByMedication(medId),
);

typedef _MK = ({int medId, int memberId});

final _todayMedIntakesProvider = StreamProvider.family<List<Intake>, _MK>(
  (ref, k) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return ref
        .watch(intakesRepositoryProvider)
        .watchByMedicationAndDateRange(k.medId, k.memberId, start, end);
  },
);

final _monthIntakesProvider = StreamProvider.family<List<Intake>, _MK>(
  (ref, k) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return ref
        .watch(intakesRepositoryProvider)
        .watchByMedicationAndDateRange(k.medId, k.memberId, start, end);
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────

class MedicationDetailScreen extends ConsumerWidget {
  final int medicationId;
  final int memberId;
  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medAsync = ref.watch(_medWatchProvider(medicationId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: medAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, _) => const Center(child: Text('Помилка')),
          data: (med) {
            if (med == null) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => Navigator.pop(context));
              return const SizedBox.shrink();
            }
            return _DetailBody(med: med, memberId: memberId);
          },
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final Medication med;
  final int memberId;
  const _DetailBody({required this.med, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mk = (medId: med.id, memberId: memberId);
    final schedules = ref.watch(_schedWatchProvider(med.id)).valueOrNull ?? [];
    final todayIntakes =
        ref.watch(_todayMedIntakesProvider(mk)).valueOrNull ?? [];
    final monthIntakes =
        ref.watch(_monthIntakesProvider(mk)).valueOrNull ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BackHeader(onBack: () => Navigator.pop(context)),
        ),
        SliverToBoxAdapter(
          child: _HeroSection(
            med: med,
            schedules: schedules,
            monthIntakes: monthIntakes,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            AppDimensions.xl,
            AppDimensions.screenPadding,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (schedules.isNotEmpty)
                _TodayScheduleSection(
                  schedules: schedules,
                  todayIntakes: todayIntakes,
                  ref: ref,
                ),
              const SizedBox(height: AppDimensions.xl),
              _CalendarSection(intakes: monthIntakes),
              const SizedBox(height: AppDimensions.xl),
              _InfoBlock(med: med),
              const SizedBox(height: AppDimensions.xl),
              _ActionRow(med: med),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Medication med;
  final List<Schedule> schedules;
  final List<Intake> monthIntakes;
  const _HeroSection({
    required this.med,
    required this.schedules,
    required this.monthIntakes,
  });

  @override
  Widget build(BuildContext context) {
    final taken = monthIntakes.where((i) => i.status == 'taken').length;
    final completed = monthIntakes
        .where((i) => i.status == 'taken' || i.status == 'skipped')
        .length;
    final pct = completed > 0 ? (taken / completed * 100).round() : 0;

    final timesPerDay = schedules.length;
    final daysLeft = timesPerDay > 0 && med.remainingCount > 0
        ? (med.remainingCount / timesPerDay).floor()
        : null;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(_formEmoji(med.form),
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name,
                        style: AppTextStyles.h2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      '${_doseStr(med)}  ·  ${_repeatShort(med)}',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$pct%',
                  label: 'Виконання',
                  danger: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: daysLeft != null ? '$daysLeft д' : '∞',
                  label: 'Залишилось',
                  danger: daysLeft != null && daysLeft < 5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: med.totalCount > 0 ? '${med.remainingCount}' : '∞',
                  label: 'Таблеток',
                  danger: false,
                ),
              ),
            ],
          ),
          if (med.totalCount > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Залишок',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.textSub)),
                Text('${med.remainingCount} / ${med.totalCount}',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.textSub)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: med.totalCount > 0
                    ? (med.remainingCount / med.totalCount).clamp(0.0, 1.0)
                    : 0,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _pillBarColor(med.remainingCount, med.totalCount),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _pillBarColor(int remaining, int total) {
    if (total == 0) return AppColors.primary;
    final ratio = remaining / total;
    if (ratio > 0.3) return AppColors.success;
    if (ratio > 0.1) return AppColors.warning;
    return AppColors.danger;
  }

  String _doseStr(Medication m) {
    final amount = m.doseAmount == m.doseAmount.roundToDouble()
        ? m.doseAmount.toInt().toString()
        : m.doseAmount.toStringAsFixed(1);
    return '$amount ${m.doseUnit}';
  }

  String _repeatShort(Medication m) => switch (m.repeatType) {
        'daily' => 'щодня',
        'alternate' => 'через день',
        'weekdays' => 'певні дні',
        'every_n' => 'кожні N днів',
        'cycle' => 'циклом',
        _ => '',
      };

  String _formEmoji(String form) => switch (form) {
        'syrup' => '🍶',
        'drops' => '💧',
        'cream' => '🧴',
        'inhaler' => '💨',
        'injection' => '💉',
        _ => '💊',
      };
}

// ── Today Schedule ────────────────────────────────────────────────────────────

class _TodayScheduleSection extends StatelessWidget {
  final List<Schedule> schedules;
  final List<Intake> todayIntakes;
  final WidgetRef ref;
  const _TodayScheduleSection({
    required this.schedules,
    required this.todayIntakes,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Сьогодні', style: AppTextStyles.labelLg),
        const SizedBox(height: 10),
        ...schedules.map((s) {
          final intake =
              todayIntakes.where((i) => i.scheduleId == s.id).firstOrNull;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SlotRow(schedule: s, intake: intake, ref: ref),
          );
        }),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  final Schedule schedule;
  final Intake? intake;
  final WidgetRef ref;
  const _SlotRow({
    required this.schedule,
    required this.intake,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = intake?.status == 'taken';
    final isSkipped = intake?.status == 'skipped';
    final isDone = isTaken || isSkipped;

    Color bg = AppColors.surface;
    Color border = AppColors.border;
    if (isTaken) {
      bg = AppColors.successLight;
      border = AppColors.success;
    }
    if (isSkipped) {
      bg = AppColors.bgPage;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            schedule.timeOfDay,
            style: AppTextStyles.labelLg.copyWith(
              color: isSkipped ? AppColors.textMuted : AppColors.textMain,
              decoration:
                  isSkipped ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isDone
                ? Text(
                    isTaken ? '✓ Прийнято' : '✕ Пропущено',
                    style: AppTextStyles.bodySm.copyWith(
                      color:
                          isTaken ? AppColors.success : AppColors.textMuted,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (!isDone && intake != null) ...[
            _SlotBtn(
              label: '✓',
              color: AppColors.success,
              bg: AppColors.successLight,
              onTap: () => ref
                  .read(intakesRepositoryProvider)
                  .markTaken(intake!.id),
            ),
            const SizedBox(width: 6),
            _SlotBtn(
              label: '✕',
              color: AppColors.textMuted,
              bg: AppColors.bgPage,
              onTap: () => ref
                  .read(intakesRepositoryProvider)
                  .markSkipped(intake!.id),
            ),
          ] else if (isDone) ...[
            _SlotBtn(
              label: '↩',
              color: AppColors.textMuted,
              bg: AppColors.surface,
              onTap: () => ref
                  .read(intakesRepositoryProvider)
                  .markPending(intake!.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _SlotBtn({
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(label,
              style: AppTextStyles.labelMd.copyWith(color: color)),
        ),
      ),
    );
  }
}

// ── Calendar ──────────────────────────────────────────────────────────────────

class _CalendarSection extends StatelessWidget {
  final List<Intake> intakes;
  const _CalendarSection({required this.intakes});

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  static const _monthNames = [
    '', 'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
    'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startPad = firstDay.weekday - 1; // Mon=1→0 pad, Sun=7→6 pad

    // Group intakes by day number
    final byDay = <int, List<Intake>>{};
    for (final i in intakes) {
      byDay.putIfAbsent(i.scheduledAt.day, () => []).add(i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Календар', style: AppTextStyles.labelLg),
            Text(
              '${_monthNames[now.month]} ${now.year}',
              style:
                  AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _dayNames
              .map((d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            ...List.generate(startPad,
                (_) => const SizedBox(width: 36, height: 28)),
            ...List.generate(daysInMonth, (i) {
              final day = i + 1;
              final dayIntakes = byDay[day] ?? [];
              final isFuture = day > now.day;
              final isToday = day == now.day;

              _CalStatus status;
              if (isFuture || dayIntakes.isEmpty) {
                status = _CalStatus.empty;
              } else {
                final taken =
                    dayIntakes.where((x) => x.status == 'taken').length;
                if (taken == dayIntakes.length) {
                  status = _CalStatus.green;
                } else if (taken > 0) {
                  status = _CalStatus.yellow;
                } else {
                  status = _CalStatus.red;
                }
              }

              return _CalCell(day: day, status: status, isToday: isToday);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: const [
            _Legend(color: Color(0xFFDCFCE7), label: 'Всі прийняті'),
            _Legend(color: Color(0xFFFEF9C3), label: 'Частково'),
            _Legend(color: Color(0xFFFEE2E2), label: 'Пропущено'),
          ],
        ),
      ],
    );
  }
}

enum _CalStatus { green, yellow, red, empty }

class _CalCell extends StatelessWidget {
  final int day;
  final _CalStatus status;
  final bool isToday;
  const _CalCell({
    required this.day,
    required this.status,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      _CalStatus.green =>
        (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      _CalStatus.yellow =>
        (const Color(0xFFFEF9C3), const Color(0xFF854D0E)),
      _CalStatus.red =>
        (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      _CalStatus.empty =>
        (const Color(0xFFF1F5F9), const Color(0xFFCBD5E1)),
    };

    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        color: isToday ? AppColors.primaryLight : bg,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTextStyles.caption.copyWith(
            color: isToday ? AppColors.primary : fg,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSub)),
      ],
    );
  }
}

// ── Info Block ────────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final Medication med;
  const _InfoBlock({required this.med});

  @override
  Widget build(BuildContext context) {
    final config = _decodeJson(med.repeatConfig);
    final foodLabel = switch (med.foodRelation) {
      'before' => '🕐 До їжі',
      'after' => '🍽 Після їжі',
      'with' => '🥗 Під час їжі',
      _ => '✓ Незалежно від їжі',
    };
    final endLabel =
        med.endDate != null ? 'до ${_fmt(med.endDate!)}' : 'постійно';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Деталі', style: AppTextStyles.labelLg),
          const SizedBox(height: 10),
          _InfoRow('📅', 'Прийом', _repeatFull(med.repeatType, config)),
          _InfoRow('🍴', 'З їжею', foodLabel),
          _InfoRow('⏱', 'Курс',
              'з ${_fmt(med.startDate)} $endLabel'),
          if (med.instructions != null && med.instructions!.isNotEmpty)
            _InfoRow('📝', 'Примітка', med.instructions!),
        ],
      ),
    );
  }

  String _repeatFull(String type, Map config) => switch (type) {
        'daily' => 'Щодня',
        'alternate' => 'Через день',
        'every_n' => 'Кожні ${config['n'] ?? '?'} дні',
        'cycle' =>
          '${config['on'] ?? '?'} днів / ${config['off'] ?? '?'} відпочинок',
        'weekdays' => () {
            const names = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
            final days = (config['days'] as List? ?? []).cast<int>();
            return days.map((d) => names[d]).join(', ');
          }(),
        _ => 'Щодня',
      };

  Map _decodeJson(String json) {
    try {
      return jsonDecode(json) as Map;
    } catch (_) {
      return {};
    }
  }

  String _fmt(DateTime d) {
    const m = [
      '', 'січ', 'лют', 'бер', 'кві', 'тра', 'чер',
      'лип', 'сер', 'вер', 'жов', 'лис', 'гру',
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSub)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMd)),
        ],
      ),
    );
  }
}

// ── Actions ───────────────────────────────────────────────────────────────────

class _ActionRow extends ConsumerWidget {
  final Medication med;
  const _ActionRow({required this.med});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActBtn(
            icon: '⏸',
            label: 'Пауза',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Функція призупинення скоро буде доступна')),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActBtn(
            icon: '✏️',
            label: 'Редагувати',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Редагування скоро буде доступне')),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActBtn(
            icon: '🗑',
            label: 'Зупинити',
            isDestructive: true,
            onTap: () => _confirmStop(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmStop(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Зупинити курс?', style: AppTextStyles.h3),
        content: Text(
          '«${med.name}» буде видалено зі списку активних ліків.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Зупинити',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(medicationsRepositoryProvider).softDelete(med.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _ActBtn extends StatelessWidget {
  final String icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;
  const _ActBtn({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.dangerLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFFECACA)
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isDestructive ? AppColors.danger : AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _BackHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool danger;
  const _StatTile({
    required this.value,
    required this.label,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: danger
              ? const Color(0xFFFECACA)
              : AppColors.primaryLighter,
        ),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.h2.copyWith(color: color, fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSub),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
