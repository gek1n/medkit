import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/med_form_icons.dart';
import '../../core/utils/task_color.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/schedules_repository.dart';
import 'add_medication_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _medWatchProvider = StreamProvider.family<Medication?, int>(
  (ref, id) => ref.watch(medicationsRepositoryProvider).watchById(id),
);

final _schedWatchProvider = StreamProvider.family<List<Schedule>, int>(
  (ref, medId) =>
      ref.watch(schedulesRepositoryProvider).watchByMedication(medId),
);

// ── Фази курсу ────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _parsePhases(String? phasesJson) {
  if (phasesJson == null) return const [];
  try {
    return List<Map<String, dynamic>>.from(jsonDecode(phasesJson) as List);
  } catch (_) {
    return const [];
  }
}

// Індекс фази, яка є активною на вказану дату (durationDays == null —
// постійна фаза, завжди останній варіант, якщо жодна попередня не підійшла).
int? _activePhaseIndex(
    Medication med, List<Map<String, dynamic>> phases, DateTime date) {
  if (phases.isEmpty) return null;
  final day = DateTime(date.year, date.month, date.day);
  final daysElapsed = day
      .difference(DateTime(
        med.startDate.year,
        med.startDate.month,
        med.startDate.day,
      ))
      .inDays;

  int accumulated = 0;
  for (var i = 0; i < phases.length; i++) {
    final dur = phases[i]['durationDays'] as int?;
    if (dur == null) return i;
    accumulated += dur;
    if (daysElapsed < accumulated) return i;
  }
  return phases.length - 1;
}

// Скільки одиниць препарату витрачається на день зараз (з активної фази
// курсу, або, для старих ліків без фаз, з таблиці schedules).
double? _dailyConsumption(Medication med, List<Schedule> schedules) {
  final phases = _parsePhases(med.phases);
  if (phases.isNotEmpty) {
    final idx = _activePhaseIndex(med, phases, DateTime.now());
    if (idx == null) return null;
    final activePhase = phases[idx];
    final times =
        List<String>.from(activePhase['times'] as List? ?? const []);
    if (times.isEmpty) return null;
    final doseAmount =
        (activePhase['doseAmount'] as num?)?.toDouble() ?? med.doseAmount;
    return times.length * doseAmount;
  }

  if (schedules.isNotEmpty) {
    return schedules.length * med.doseAmount;
  }
  return null;
}

Color _pillBarColor(int remaining, int total) {
  if (total == 0) return AppColors.primary;
  final ratio = remaining / total;
  if (ratio > 0.3) return AppColors.success;
  if (ratio > 0.1) return AppColors.warning;
  return AppColors.danger;
}

String _stockUnitLabel(String form) => switch (form) {
      'tablet' || 'capsule' => 'ТАБЛЕТКИ / КАПСУЛИ',
      'syrup' => 'СИРОП',
      'drops' => 'КРАПЛІ',
      'injection' => 'ІН\'ЄКЦІЇ',
      'suppository' => 'СВІЧКИ',
      'vial' => 'ФЛАКОН',
      'cream' => 'КРЕМ',
      'inhaler' => 'ІНГАЛЯТОР',
      _ => 'ЗАЛИШОК',
    };

String _daysWordUk(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'днів';
  if (mod10 == 1) return 'день';
  if (mod10 >= 2 && mod10 <= 4) return 'дні';
  return 'днів';
}

String _timesWordUk(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'разів';
  if (mod10 == 1) return 'раз';
  if (mod10 >= 2 && mod10 <= 4) return 'рази';
  return 'разів';
}

// Підпис під назвою в шапці: "10 мг на прийом · 2 рази на день".
String _doseSubtitle(Medication med) {
  final phases = _parsePhases(med.phases);
  final idx = _activePhaseIndex(med, phases, DateTime.now());
  final activePhase = idx != null ? phases[idx] : null;
  final doseAmount = activePhase != null
      ? ((activePhase['doseAmount'] as num?)?.toDouble() ?? med.doseAmount)
      : med.doseAmount;
  final doseAmountStr = doseAmount == doseAmount.roundToDouble()
      ? doseAmount.toInt().toString()
      : doseAmount.toStringAsFixed(1);
  final timesPerDay = activePhase != null
      ? (activePhase['times'] as List? ?? const []).length
      : 1;
  return '$doseAmountStr ${med.doseUnit} на прийом · $timesPerDay ${_timesWordUk(timesPerDay)} на день';
}

// Спільний вигляд секцій-карток на кремовому фоні екрана: біла поверхня,
// м'яка тінь (як у медіа-картках "Сьогодні"), акцентна обводка кольору ліків.
BoxDecoration _softCard(Color accent) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withValues(alpha: 0.25)),
      boxShadow: const [
        BoxShadow(
            color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
      ],
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
    final schedules = ref.watch(_schedWatchProvider(med.id)).valueOrNull ?? [];
    final accent = colorFromHex(med.color) ?? AppColors.primary;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BackHeader(
            title: med.name,
            subtitle: _doseSubtitle(med),
            onBack: () => Navigator.pop(context),
          ),
        ),
        SliverToBoxAdapter(
          child: _HeroSection(med: med, accent: accent),
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
              if (_parsePhases(med.phases).isNotEmpty) ...[
                _PhasesSection(med: med, accent: accent),
                const SizedBox(height: AppDimensions.xl),
              ],
              _InfoBlock(med: med, accent: accent),
              const SizedBox(height: AppDimensions.xl),
              if (med.totalCount > 0 || med.stockPercent != null) ...[
                _StockSection(med: med, schedules: schedules, accent: accent),
                const SizedBox(height: AppDimensions.xl),
              ],
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
  final Color accent;
  const _HeroSection({required this.med, required this.accent});

  @override
  Widget build(BuildContext context) {
    final phases = _parsePhases(med.phases);
    final idx = _activePhaseIndex(med, phases, DateTime.now());
    final activePhase = idx != null ? phases[idx] : null;

    final doseAmount = activePhase != null
        ? ((activePhase['doseAmount'] as num?)?.toDouble() ?? med.doseAmount)
        : med.doseAmount;
    final doseAmountStr = doseAmount == doseAmount.roundToDouble()
        ? doseAmount.toInt().toString()
        : doseAmount.toStringAsFixed(1);

    final timesPerDay = activePhase != null
        ? (activePhase['times'] as List? ?? const []).length
        : 1;

    final daysLeftInCourse = med.endDate != null
        ? med.endDate!.difference(DateTime.now()).inDays + 1
        : null;
    final courseLabel = daysLeftInCourse != null
        ? (daysLeftInCourse > 0
            ? '$daysLeftInCourse ${_daysWordUk(daysLeftInCourse)} курсу'
            : 'курс завершено')
        : 'постійний курс';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MedPhotoBlock(med: med, accent: accent),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FactChip(
                  icon: Icons.medication_outlined,
                  label: '$doseAmountStr ${med.doseUnit} на прийом',
                  accent: accent),
              _FactChip(
                  icon: Icons.repeat_rounded,
                  label: '$timesPerDay ${_timesWordUk(timesPerDay)}/день',
                  accent: accent),
              _FactChip(
                  icon: Icons.timer_outlined,
                  label: courseLabel,
                  accent: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _FactChip(
      {required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.textMain)),
        ],
      ),
    );
  }
}

// ── Залишок ────────────────────────────────────────────────────────────────────

class _StockSection extends ConsumerWidget {
  final Medication med;
  final List<Schedule> schedules;
  final Color accent;
  const _StockSection(
      {required this.med, required this.schedules, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
            icon: Icons.inventory_2_outlined, label: 'Залишок', accent: accent),
        const SizedBox(height: 10),
        isPercentTrackedForm(med.form)
            ? _buildPercentCard(context, ref)
            : _buildCountCard(context, ref),
      ],
    );
  }

  // ── Дискретні одиниці (таблетки, капсули, свічки тощо) ──────────────────

  Widget _buildCountCard(BuildContext context, WidgetRef ref) {
    final dailyConsumption = _dailyConsumption(med, schedules);
    final daysLeft = (dailyConsumption != null && dailyConsumption > 0)
        ? med.remainingCount / dailyConsumption
        : null;
    final pct = med.totalCount > 0
        ? (med.remainingCount / med.totalCount).clamp(0.0, 1.0)
        : 0.0;
    final color = _pillBarColor(med.remainingCount, med.totalCount);

    // Скільки одиниць треба докупити: якщо курс має кінець — на решту курсу,
    // якщо постійний — щоб покрити найближчі 30 днів.
    int toBuy = 0;
    String? toBuyPeriodLabel;
    if (dailyConsumption != null && dailyConsumption > 0) {
      if (med.endDate != null) {
        final daysRemaining =
            med.endDate!.difference(DateTime.now()).inDays + 1;
        if (daysRemaining > 0) {
          final neededForCourse = (dailyConsumption * daysRemaining).ceil();
          toBuy = (neededForCourse - med.remainingCount).clamp(0, 99999);
          toBuyPeriodLabel = 'до кінця курсу';
        }
      } else if (daysLeft != null && daysLeft < 30) {
        final neededFor30Days = (dailyConsumption * 30).ceil();
        toBuy = (neededFor30Days - med.remainingCount).clamp(0, 99999);
        toBuyPeriodLabel = 'на найближчі 30 днів';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCard(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(_stockUnitLabel(med.form),
                  style: AppTextStyles.labelSm.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMd,
                  children: [
                    const TextSpan(text: 'Залишилось: '),
                    TextSpan(
                      text: '${med.remainingCount} ${med.doseUnit}',
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (daysLeft != null)
                Text(
                  'на ${daysLeft.toStringAsFixed(1)} дн.',
                  style: AppTextStyles.bodyMd.copyWith(
                      color: accent, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (toBuy > 0 && toBuyPeriodLabel != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySm,
                        children: [
                          const TextSpan(text: 'Потрібно докупити: '),
                          TextSpan(
                            text: '$toBuy ${med.doseUnit}',
                            style: AppTextStyles.labelMd
                                .copyWith(color: accent),
                          ),
                          TextSpan(
                            text: ' ($toBuyPeriodLabel)',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showRefillDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('+ Поповнити упаковку',
                  style: AppTextStyles.labelMd.copyWith(color: accent)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefillDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: '${med.totalCount}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Поповнити упаковку'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: med.doseUnit, hintText: 'Кількість'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(medicationsRepositoryProvider).refill(med.id, result);
    }
  }

  // ── Рідкі форми (сироп, краплі, крем, інгалятор) — залишок у % ──────────

  Widget _buildPercentCard(BuildContext context, WidgetRef ref) {
    final percent = med.stockPercent ?? 100;
    final openedAt = med.openedAt;
    double? daysLeft;
    if (openedAt != null) {
      final daysSince = DateTime.now().difference(openedAt).inDays;
      if (daysSince > 0 && percent < 100) {
        final ratePerDay = (100 - percent) / daysSince;
        if (ratePerDay > 0) daysLeft = percent / ratePerDay;
      }
    }
    final color = _pillBarColor(percent, 100);
    const presets = [75, 50, 25, 10];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCard(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(_stockUnitLabel(med.form),
                  style: AppTextStyles.labelSm.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (percent / 100).clamp(0.03, 1.0),
                        child: Container(color: color.withValues(alpha: 0.55)),
                      ),
                    ),
                    Center(
                      child: Text('$percent%',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Залишилось ~$percent%',
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    if (daysLeft != null)
                      Text(
                        '~${daysLeft.toStringAsFixed(0)} днів при поточній витраті',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.textSub),
                      ),
                    if (openedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(_openedAgoLabel(openedAt),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Оновити оцінку залишку:',
              style: AppTextStyles.labelSm.copyWith(fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: presets.asMap().entries.map((e) {
              final p = e.value;
              final selected = percent == p;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < presets.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(medicationsRepositoryProvider)
                        .setStockPercent(med.id, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? accent : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected
                                ? accent
                                : accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '~$p%',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 11,
                          color: selected ? Colors.white : accent,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ref
                  .read(medicationsRepositoryProvider)
                  .openNewContainer(med.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('+ Відкрив новий флакон',
                  style: AppTextStyles.labelMd.copyWith(color: accent)),
            ),
          ),
        ],
      ),
    );
  }

  String _openedAgoLabel(DateTime openedAt) {
    final days = DateTime.now().difference(openedAt).inDays;
    if (days <= 0) return 'Відкрито сьогодні';
    return 'Відкрито $days ${_daysWordUk(days)} тому';
  }
}

// ── Medication photo (big) or icon (small) ────────────────────────────────────

class _MedPhotoBlock extends StatelessWidget {
  final Medication med;
  final Color accent;
  const _MedPhotoBlock({required this.med, required this.accent});

  String? _firstPhoto(String? json) {
    if (json == null || json == '[]') return null;
    try {
      final list = jsonDecode(json) as List;
      return list.isNotEmpty ? list.first as String : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = _firstPhoto(med.photoPaths);

    // Без фото — вузька кольорова смужка з іконкою форми ліків (не порожнеча).
    if (photoPath == null) {
      return Container(
        width: double.infinity,
        height: 64,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: Center(
            child: Icon(medFormIcon(med.form), size: 28, color: accent)),
      );
    }

    return FutureBuilder<Uint8List>(
      future: PhotoService.decryptedBytes(photoPath),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Image.memory(
            snap.data!,
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: double.infinity,
              height: 190,
              color: accent.withValues(alpha: 0.1),
            ),
          ),
        );
      },
    );
  }
}

// ── Етапи курсу ───────────────────────────────────────────────────────────────

class _PhasesSection extends StatelessWidget {
  final Medication med;
  final Color accent;
  const _PhasesSection({required this.med, required this.accent});

  @override
  Widget build(BuildContext context) {
    final phases = _parsePhases(med.phases);
    if (phases.isEmpty) return const SizedBox.shrink();
    final activeIdx = _activePhaseIndex(med, phases, DateTime.now());

    final rows = <Widget>[];
    var cursor =
        DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
    for (var i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final dur = phase['durationDays'] as int?;
      final start = cursor;
      final end = dur != null ? start.add(Duration(days: dur - 1)) : null;
      if (dur != null) cursor = start.add(Duration(days: dur));

      final times = List<String>.from(phase['times'] as List? ?? const []);
      final doseAmount =
          (phase['doseAmount'] as num?)?.toDouble() ?? med.doseAmount;
      final doseAmountStr = doseAmount == doseAmount.roundToDouble()
          ? doseAmount.toInt().toString()
          : doseAmount.toStringAsFixed(1);
      final comment = phase['doseComment'] as String?;
      final isActive = i == activeIdx;

      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Етап ${i + 1}',
                  style: AppTextStyles.labelMd.copyWith(
                      color: isActive ? accent : AppColors.textMain),
                ),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('зараз',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              end != null
                  ? '${_fmtShortDate(start)} — ${_fmtShortDate(end)}'
                  : 'з ${_fmtShortDate(start)}, постійно',
              style:
                  AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: 2),
            Text('$doseAmountStr ${med.doseUnit} · ${times.join(", ")}',
                style: AppTextStyles.bodyMd),
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(comment,
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.timeline_rounded, label: 'Етапи курсу', accent: accent),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _softCard(accent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ],
    );
  }

  String _fmtShortDate(DateTime d) {
    const m = [
      '', 'січ', 'лют', 'бер', 'кві', 'тра', 'чер',
      'лип', 'сер', 'вер', 'жов', 'лис', 'гру',
    ];
    return '${d.day} ${m[d.month]}';
  }
}

// ── Info Block ────────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final Medication med;
  final Color accent;
  const _InfoBlock({required this.med, required this.accent});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.info_outline_rounded, label: 'Деталі', accent: accent),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _softCard(accent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(Icons.event_repeat_rounded, 'Прийом', _repeatFull(med.repeatType, config), accent),
              _InfoRow(Icons.restaurant_rounded, 'З їжею', foodLabel, accent),
              _InfoRow(Icons.timer_rounded, 'Курс',
                  'з ${_fmt(med.startDate)} $endLabel', accent),
              if (med.instructions != null && med.instructions!.isNotEmpty)
                _InfoRow(Icons.edit_note_rounded, 'Примітка', med.instructions!, accent),
            ],
          ),
        ),
      ],
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
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _InfoRow(this.icon, this.label, this.value, this.accent);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: accent),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _SectionTitle(
      {required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: AppTextStyles.labelSm),
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
            label: 'Зупинити',
            isDestructive: true,
            onTap: () => _confirmStop(context, ref),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActBtn(
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
            label: 'Редагувати',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMedicationScreen(
                    memberId: med.memberId, existing: med),
              ),
            ),
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
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger)),
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

// Нейтральні текстові кнопки без тіні (навмисно — щоб не з'являлась кольорова
// підсвітка під кнопками, як у референсі).
class _ActBtn extends StatelessWidget {
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;
  const _ActBtn({
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFFECACA)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: isDestructive ? AppColors.danger : AppColors.textMain,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _BackHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _BackHeader(
      {required this.title, required this.subtitle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MkBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.h2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

