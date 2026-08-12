import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/plan_access.dart';
import '../../core/utils/task_color.dart';
import '../../shared/widgets/created_by_footer.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_header_action_button.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/intakes_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/schedules_repository.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import '../plans/elly_denied_screen.dart';
import '../today/providers/today_providers.dart';
import 'add_medication_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _medWatchProvider = StreamProvider.family<Medication?, int>(
  (ref, id) => ref.watch(medicationsRepositoryProvider).watchById(id),
);

final _schedWatchProvider = StreamProvider.family<List<Schedule>, int>(
  (ref, medId) =>
      ref.watch(schedulesRepositoryProvider).watchByMedication(medId),
);

// (medicationId, memberId) — прийоми саме цих ліків, заплановані на сьогодні
// для профілю, який зараз переглядається (не для всіх учасників родини
// одразу, watchByMedicationAndDateRange вже фільтрує по memberId).
final _medTodayIntakesProvider =
    StreamProvider.family<List<Intake>, (int, int)>((ref, key) {
  final (medicationId, memberId) = key;
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref
      .watch(intakesRepositoryProvider)
      .watchByMedicationAndDateRange(medicationId, memberId, start, end);
});

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
  Medication med,
  List<Map<String, dynamic>> phases,
  DateTime date,
) {
  if (phases.isEmpty) return null;
  final day = DateTime(date.year, date.month, date.day);
  final daysElapsed = day
      .difference(
        DateTime(med.startDate.year, med.startDate.month, med.startDate.day),
      )
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
    final times = List<String>.from(activePhase['times'] as List? ?? const []);
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

// Вільний текст, що ввів користувач ("Флакон", "Пачка") — раніше похідне
// від фіксованого form-переліку, тепер form сам є довільним написом.
String? _stockFormLabel(Medication med) =>
    med.form.trim().isEmpty ? null : med.form.trim();

// Підпис під назвою в шапці: "10 мг на прийом · 2 рази на день".
String _doseSubtitle(BuildContext context, Medication med) {
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
  return '${context.l10n.perDoseLabel(doseAmountStr, med.doseUnit)} · ${context.l10n.timesPerDayLabel(timesPerDay)}';
}

// Спільний вигляд секцій-карток на кремовому фоні екрана: біла поверхня,
// м'яка тінь (як у медіа-картках "Сьогодні"), акцентна обводка кольору ліків.
BoxDecoration _softCard(Color accent) => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: accent.withValues(alpha: 0.25)),
  boxShadow: const [
    BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6)),
  ],
);

// ── Screen ────────────────────────────────────────────────────────────────────

/// Крок 11 (view-only перший прохід): [peer] непорожній — ліки беруться не
/// з локальної бази (id синтетичний), а з перекладача кешу піра; кнопки
/// редагування/зупинки/поповнення запасу завжди ховаються (справжнє
/// редагування "за іншого" — окремий, ще не підключений наступний крок).
class MedicationDetailScreen extends ConsumerWidget {
  final int medicationId;
  final int memberId;
  final PeerSubject? peer;
  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
    required this.memberId,
    this.peer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (peer != null) {
      final med = ref
          .watch(peerMedicationsProvider(peer!.personUuid))
          .where((m) => m.id == medicationId)
          .firstOrNull;
      if (med == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
        return const Scaffold(backgroundColor: AppColors.bg, body: SizedBox.shrink());
      }
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: _DetailBody(med: med, memberId: memberId, peer: peer)),
      );
    }

    final medAsync = ref.watch(_medWatchProvider(medicationId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: medAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => Center(child: Text(context.l10n.errorGenericShort)),
          data: (med) {
            if (med == null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.pop(context),
              );
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
  final PeerSubject? peer;
  const _DetailBody({required this.med, required this.memberId, this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = peer != null
        ? ref
            .watch(peerSchedulesProvider(peer!.personUuid))
            .where((s) => s.medicationId == med.id)
            .toList()
        : ref.watch(_schedWatchProvider(med.id)).valueOrNull ?? [];
    final accent = colorFromHex(med.color) ?? AppColors.primary;
    // Крок 11 (#307): editSchedule дозволяє редагувати ЦІЛИЙ запис піра
    // (compare-and-swap через record_proposal) — "зупинити"/видалити чужі
    // ліки лишається поза межами цього кроку, onDelete для піра й далі null.
    final canEditForPeer = peer != null && ref.watch(activePeerGrantsProvider).editSchedule;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BackHeader(
            title: med.name,
            subtitle: _doseSubtitle(context, med),
            onBack: () => Navigator.pop(context),
            onEdit: peer == null
                ? () => _openMedicationEditIfAllowed(context, ref, med)
                : (canEditForPeer ? () => _openPeerMedicationEdit(context, ref, peer!, med) : null),
            onDelete: peer == null ? () => _confirmStopMedication(context, ref, med) : null,
          ),
        ),
        SliverToBoxAdapter(
          child: _HeroSection(med: med, accent: accent, peer: peer),
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
              _TodayScheduleSection(med: med, accent: accent, peer: peer),
              if (_parsePhases(med.phases).isNotEmpty) ...[
                _PhasesSection(med: med, accent: accent),
                const SizedBox(height: AppDimensions.xl),
              ],
              _InfoBlock(med: med, accent: accent),
              const SizedBox(height: AppDimensions.xl),
              if (med.trackStock)
                Column(
                  children: [
                    _StockSection(
                      med: med,
                      schedules: schedules,
                      accent: accent,
                      peer: peer,
                    ),
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              peer == null
                  ? CreatedByFooter(entityType: 'medication', localId: med.id)
                  : CreatedByFooter.forPeer(entityType: 'medication', peer: peer, entityUuid: med.syncUuid),
              const SizedBox(height: 24),
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
  final PeerSubject? peer;
  const _HeroSection({required this.med, required this.accent, this.peer});

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
              ? context.l10n.courseDaysLeft(daysLeftInCourse)
              : context.l10n.courseFinished)
        : context.l10n.courseOngoing;

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
                label: context.l10n.perDoseLabel(doseAmountStr, med.doseUnit),
                accent: accent,
              ),
              _FactChip(
                icon: Icons.repeat_rounded,
                label: context.l10n.timesPerDaySlash(timesPerDay),
                accent: accent,
              ),
              _FactChip(
                icon: Icons.timer_outlined,
                label: courseLabel,
                accent: accent,
              ),
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
  const _FactChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

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
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Розклад на сьогодні (позначити прийом раніше, ніж настане час) ─────────────

// Дозволяє відмітити прийом виконаним ДО настання запланованого часу — щоб
// не чекати точної хвилини, якщо ліки фактично вже прийнято. Викликає той
// самий IntakesRepository.markTaken(), що й Today screen: рахує залишок
// (decrementRemaining), скасовує нагадування, прибирає з розкладу на
// сьогодні через реактивний provider — жодної окремої логіки, лише інший
// вхід до вже наявного, повністю робочого шляху.
class _TodayScheduleSection extends ConsumerWidget {
  final Medication med;
  final Color accent;
  final PeerSubject? peer;
  const _TodayScheduleSection({required this.med, required this.accent, this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Intake> intakes;
    if (peer != null) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      intakes = ref
          .watch(peerIntakesProvider(peer!.personUuid))
          .where((i) =>
              i.medicationId == med.id &&
              !i.scheduledAt.isBefore(start) &&
              i.scheduledAt.isBefore(end))
          .toList();
    } else {
      intakes = ref
              .watch(_medTodayIntakesProvider((med.id, med.memberId)))
              .valueOrNull ??
          const <Intake>[];
    }
    if (intakes.isEmpty) return const SizedBox.shrink();

    final sorted = [...intakes]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.today_rounded,
          label: context.l10n.todayScheduleForMedLabel,
          accent: accent,
        ),
        Container(
          decoration: _softCard(accent),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < sorted.length; i++)
                _TodayIntakeRow(
                  intake: sorted[i],
                  accent: accent,
                  isLast: i == sorted.length - 1,
                  readOnly: peer != null,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
      ],
    );
  }
}

class _TodayIntakeRow extends ConsumerWidget {
  final Intake intake;
  final Color accent;
  final bool isLast;
  final bool readOnly;
  const _TodayIntakeRow({
    required this.intake,
    required this.accent,
    required this.isLast,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canMark =
        !readOnly && (intake.status == 'pending' || intake.status == 'snoozed');
    final (icon, color, label) = switch (intake.status) {
      'taken' => (
          Icons.check_circle_rounded,
          AppColors.success,
          context.l10n.intakeTaken,
        ),
      'skipped' => (
          Icons.cancel_outlined,
          AppColors.textMuted,
          context.l10n.intakeSkipped,
        ),
      'snoozed' => (
          Icons.snooze_rounded,
          AppColors.warning,
          context.l10n.intakeSnoozed,
        ),
      _ => (null, null, null),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  _fmtTime(intake.scheduledAt),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              if (canMark)
                GestureDetector(
                  onTap: () =>
                      ref.read(intakesRepositoryProvider).markTaken(intake.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.doneAction,
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
            color: AppColors.border,
          ),
      ],
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Залишок ────────────────────────────────────────────────────────────────────

class _StockSection extends ConsumerWidget {
  final Medication med;
  final List<Schedule> schedules;
  final Color accent;
  final PeerSubject? peer;
  const _StockSection({
    required this.med,
    required this.schedules,
    required this.accent,
    this.peer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.inventory_2_outlined,
          label: context.l10n.stockSectionLabel,
          accent: accent,
        ),
        const SizedBox(height: 10),
        _buildCountCard(context, ref),
      ],
    );
  }

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
          toBuyPeriodLabel = context.l10n.untilCourseEndLabel;
        }
      } else if (daysLeft != null && daysLeft < 30) {
        final neededFor30Days = (dailyConsumption * 30).ceil();
        toBuy = (neededFor30Days - med.remainingCount).clamp(0, 99999);
        toBuyPeriodLabel = context.l10n.next30DaysLabel;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softCard(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stockFormLabel(med) != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  _stockFormLabel(med)!,
                  style: AppTextStyles.labelSm.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMd,
                  children: [
                    TextSpan(text: context.l10n.remainingColonLabel),
                    TextSpan(
                      text: '${med.remainingCount} ${med.doseUnit}',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (daysLeft != null)
                Text(
                  context.l10n.daysLeftShortLabel(daysLeft.toStringAsFixed(1)),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
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
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySm,
                        children: [
                          TextSpan(text: context.l10n.needToBuyLabel),
                          TextSpan(
                            text: '$toBuy ${med.doseUnit}',
                            style: AppTextStyles.labelMd.copyWith(
                              color: accent,
                            ),
                          ),
                          TextSpan(
                            text: ' ($toBuyPeriodLabel)',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (peer == null) ...[
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.l10n.refillPackageAction,
                  style: AppTextStyles.labelMd.copyWith(color: accent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRefillDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: '${med.totalCount}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.refillPackageTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            suffixText: med.doseUnit,
            hintText: context.l10n.quantityHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, v != null && v > 0 ? v : null);
            },
            child: Text(context.l10n.okAction),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(medicationsRepositoryProvider).refill(med.id, result);
    }
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

  // Кольорова смужка-заглушка з іконкою форми ліків — без фото, і як фон
  // під чіп запиту фото піра (фото піра не лежить локально, лише за запитом).
  Widget _stub() => Container(
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
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Center(
      child: MedcardIcon(med.iconKey ?? 'form_cream', size: 34),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final photoPath = _firstPhoto(med.photoPaths);

    // Без фото — вузька кольорова смужка з іконкою форми ліків (не порожнеча).
    if (photoPath == null) {
      return _stub();
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
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Image.memory(
            snap.data!,
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
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
    var cursor = DateTime(
      med.startDate.year,
      med.startDate.month,
      med.startDate.day,
    );
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
      rows.add(
        Container(
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
                    context.l10n.phaseNumberLabel(i + 1),
                    style: AppTextStyles.labelMd.copyWith(
                      color: isActive ? accent : AppColors.textMain,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.l10n.nowLabel,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                end != null
                    ? '${_fmtShortDate(context, start)} — ${_fmtShortDate(context, end)}'
                    : context.l10n.phaseFromOngoing(_fmtShortDate(context, start)),
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
              ),
              const SizedBox(height: 2),
              Text(
                '$doseAmountStr ${med.doseUnit} · ${times.join(", ")}',
                style: AppTextStyles.bodyMd,
              ),
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.timeline_rounded,
          label: context.l10n.courseStagesLabel,
          accent: accent,
        ),
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

  String _fmtShortDate(BuildContext context, DateTime d) =>
      DateFormat('d MMM', Localizations.localeOf(context).languageCode).format(d);
}

// ── Info Block ────────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final Medication med;
  final Color accent;
  const _InfoBlock({required this.med, required this.accent});

  @override
  Widget build(BuildContext context) {
    final config = _decodeJson(med.repeatConfig);
    final endLabel = med.endDate != null
        ? context.l10n.untilDateLabel(_fmt(context, med.endDate!))
        : context.l10n.ongoingLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.info_outline_rounded,
          label: context.l10n.detailsLabel,
          accent: accent,
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _softCard(accent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                Icons.event_repeat_rounded,
                context.l10n.intakeLabel,
                _repeatFull(context, med.repeatType, config),
                accent,
              ),
              _InfoRow(
                Icons.timer_rounded,
                context.l10n.courseNounLabel,
                context.l10n.courseRangeLabel(_fmt(context, med.startDate), endLabel),
                accent,
              ),
              if (med.instructions != null && med.instructions!.isNotEmpty)
                _InfoRow(
                  Icons.edit_note_rounded,
                  context.l10n.noteLabel,
                  med.instructions!,
                  accent,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _repeatFull(BuildContext context, String type, Map config) => switch (type) {
    'daily' => context.l10n.repeatDailyCap,
    'alternate' => context.l10n.repeatAlternateCap,
    'every_n' => context.l10n.repeatEveryNCap('${config['n'] ?? '?'}'),
    'cycle' =>
      context.l10n.repeatCycleCap('${config['on'] ?? '?'}', '${config['off'] ?? '?'}'),
    'weekdays' => () {
      final names = [
        '',
        context.l10n.dayMon,
        context.l10n.dayTue,
        context.l10n.dayWed,
        context.l10n.dayThu,
        context.l10n.dayFri,
        context.l10n.daySat,
        context.l10n.daySun,
      ];
      final days = (config['days'] as List? ?? []).cast<int>();
      return days.map((d) => names[d]).join(', ');
    }(),
    _ => context.l10n.repeatDailyCap,
  };

  Map _decodeJson(String json) {
    try {
      return jsonDecode(json) as Map;
    } catch (_) {
      return {};
    }
  }

  String _fmt(BuildContext context, DateTime d) =>
      DateFormat('d MMM yyyy', Localizations.localeOf(context).languageCode).format(d);
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
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSub),
            ),
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
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.accent,
  });

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

// onEdit/onDelete на _BackHeader — той самий плановий чек, що й раніше в
// _ActionRow, лише переміщений у заголовок (див. коментар класу _BackHeader).
void _openMedicationEditIfAllowed(
  BuildContext context,
  WidgetRef ref,
  Medication med,
) {
  if (isMemberBlockedByPlan(ref, med.memberId)) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EllyDeniedScreen()),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddMedicationScreen(memberId: med.memberId, existing: med),
    ),
  );
}

// Крок 11 (#307): compare-and-swap повне редагування піра — план-ліміти
// (isMemberBlockedByPlan) стосуються ЛИШЕ власного тарифу, для чужого
// запису тут не перевіряються.
void _openPeerMedicationEdit(BuildContext context, WidgetRef ref, PeerSubject peer, Medication med) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddMedicationScreen(
        memberId: null,
        existing: med,
        onDraftCreated: (draft) => submitMedicationProposal(
          ref,
          peer,
          draft,
          existingSyncUuid: med.syncUuid,
          existingUpdatedAt: med.updatedAt,
          syntheticSectionId: med.sectionId,
        ),
      ),
    ),
  );
}

Future<void> _confirmStopMedication(
  BuildContext context,
  WidgetRef ref,
  Medication med,
) async {
  if (isMemberBlockedByPlan(ref, med.memberId)) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EllyDeniedScreen()),
    );
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.stopCourseConfirmTitle, style: AppTextStyles.h3),
      content: Text(
        context.l10n.stopCourseConfirmBody(med.name),
        style: AppTextStyles.bodyMd,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            context.l10n.stopAction,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(medicationsRepositoryProvider).softDelete(med.id);
    // generateTodayIntakesProvider/tomorrowIntakesProvider — кешовані
    // FutureProvider'и: якщо "Коротко про завтра" вже було відкрито до
    // зупинки курсу, застарілий inтake для цих ліків лишався б там
    // видимим (а назва відображалась би як "Ліки", бо список медикаментів
    // для підпису вже реактивно оновився й перестав містити зупинений
    // препарат — розсинхрон між застарілим списком intake і живим списком
    // ліків).
    ref.invalidate(generateTodayIntakesProvider);
    ref.invalidate(tomorrowIntakesProvider);
    // НЕ викликаємо Navigator.pop тут — щойно softDelete позначить ліки
    // isActive=false, watchById(id) реактивно віддасть null, і сам екран
    // вище (data: (med) => if (med == null) ...) закриється через
    // addPostFrameCallback. Виклик pop і тут, і там — подвійний pop на
    // одному навігаторі, який на практиці міг зачинити на рівень більше,
    // ніж треба (чорний екран, що "лікується" лише перезапуском).
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

// onEdit/onDelete — той самий уніфікований патерн, що й у
// ReminderViewScreen/MedcardEntryViewScreen: олівець одразу біля заголовка,
// червоний кошик у правому куті того ж рядка (замість окремих кнопок
// внизу екрана).
class _BackHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _BackHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEdit != null) MkEditIconButton(onTap: onEdit!),
                  ],
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onDelete != null) MkDeleteIconButton(onTap: onDelete!),
        ],
      ),
    );
  }
}
