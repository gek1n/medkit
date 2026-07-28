import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/reminder_tags_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../shared/widgets/feed_post_card.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../add/add_activity_screen.dart';
import '../today/providers/today_providers.dart';
import 'add_appointment_screen.dart';

const _kActivityTypeRoutine = 'routine';

List<String> _parseTags(String raw) {
  try {
    return List<String>.from(jsonDecode(raw) as List);
  } catch (_) {
    return const [];
  }
}

// ────────────────────────────── providers ──────────────────────────────

final _allAppointmentsProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(remindersRepositoryProvider).watchAll();
});

final _allTaskActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).watchAll();
});

// ────────────────────────────── archive item (unified) ─────────────────

enum _ArchiveKind { reminder, routine }

class _ArchiveItem {
  final _ArchiveKind kind;
  final DateTime effectiveDate;
  final int memberId;
  final Reminder? reminder;
  final Activity? activity;
  const _ArchiveItem({
    required this.kind,
    required this.effectiveDate,
    required this.memberId,
    this.reminder,
    this.activity,
  });
}

// ────────────────────────────── screen ──────────────────────────────

class AppointmentsHistoryScreen extends ConsumerStatefulWidget {
  // Якщо задано (напр. з Медкартки, де вже обраний конкретний профіль) —
  // показує записи лише цього члена сім'ї. Без нього — усі записи родини,
  // як і раніше (той самий шлях, яким Сім'я/Профіль можуть показати
  // спільний календар).
  final int? memberId;
  const AppointmentsHistoryScreen({super.key, this.memberId});

  @override
  ConsumerState<AppointmentsHistoryScreen> createState() =>
      _AppointmentsHistoryScreenState();
}

class _AppointmentsHistoryScreenState
    extends ConsumerState<AppointmentsHistoryScreen> {
  String? _tag;

  Future<void> _pickTag() async {
    final history = await ReminderTagsLibraryService.getAll();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TagFilterSheet(tags: history, current: _tag),
    );
    if (picked != null) setState(() => _tag = picked);
  }

  @override
  Widget build(BuildContext context) {
    final aptsAsync = ref.watch(_allAppointmentsProvider);
    final activitiesAsync = ref.watch(_allTaskActivitiesProvider);
    final currentMemberAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () {
          final targetId = widget.memberId ?? currentMemberAsync.valueOrNull?.id;
          if (targetId == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddAppointmentScreen(memberId: targetId)),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TagFilterChip(
                  tag: _tag,
                  onTap: _pickTag,
                  onClear: () => setState(() => _tag = null),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Expanded(
              child: aptsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) =>
                    Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                data: (allApts) {
                  return activitiesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (e, _) =>
                        Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                    data: (allActivities) {
                      final hasFilter = _tag != null;

                      final reminderItems = allApts
                          .where((a) => widget.memberId == null || a.memberId == widget.memberId)
                          .where((a) => _tag == null || _parseTags(a.tags).contains(_tag))
                          .map((a) => _ArchiveItem(
                                kind: _ArchiveKind.reminder,
                                effectiveDate: a.scheduledAt,
                                memberId: a.memberId,
                                reminder: a,
                              ));

                      // Рутинні справи не мають тегів — коли фільтр за тегом
                      // активний, вони не мають чому відповідати, тож ховаються.
                      final activityItems = hasFilter
                          ? const Iterable<_ArchiveItem>.empty()
                          : allActivities
                              .where((a) =>
                                  widget.memberId == null || a.memberId == widget.memberId)
                              .where((a) => a.type == _kActivityTypeRoutine)
                              .map((a) => _ArchiveItem(
                                    kind: _ArchiveKind.routine,
                                    effectiveDate: a.createdAt,
                                    memberId: a.memberId,
                                    activity: a,
                                  ));

                      final items = [...reminderItems, ...activityItems]
                        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

                      if (items.isEmpty) return _EmptyState(filtered: hasFilter);

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.screenPadding,
                          AppDimensions.md,
                          AppDimensions.screenPadding,
                          88,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                          child: _ArchiveCard(item: items[i]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── header ──────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          MkBackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(context.l10n.appointmentsHistoryTitle, style: AppTextStyles.h3)),
        ],
      ),
    );
  }
}

// ────────────────────────────── tag filter chip ─────────────────────

class _TagFilterChip extends StatelessWidget {
  final String? tag;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _TagFilterChip({
    required this.tag,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final active = tag != null;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              tag ?? context.l10n.allTagsFilter,
              style: AppTextStyles.labelMd.copyWith(
                color: active ? AppColors.primary : AppColors.textSub,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── tag filter sheet ─────────────────────

class _TagFilterSheet extends StatelessWidget {
  final List<String> tags;
  final String? current;
  const _TagFilterSheet({required this.tags, required this.current});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.6,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(context.l10n.reminderTagsPickerTitle, style: AppTextStyles.h3),
            ),
            Expanded(
              child: tags.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.noTagsYetLabel,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final t = tags[index];
                        final selected = t == current;
                        return ListTile(
                          title: Text(t, style: AppTextStyles.bodyLg),
                          trailing: selected
                              ? const Icon(Icons.check_rounded, color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.pop(context, t),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── archive card ──────────────────────────

class _ArchiveCard extends StatelessWidget {
  final _ArchiveItem item;
  const _ArchiveCard({required this.item});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _dayLabel(BuildContext context, int weekday) {
    final l10n = context.l10n;
    return switch (weekday) {
      1 => l10n.dayMon,
      2 => l10n.dayTue,
      3 => l10n.dayWed,
      4 => l10n.dayThu,
      5 => l10n.dayFri,
      6 => l10n.daySat,
      _ => l10n.daySun,
    };
  }

  String _scheduleSummary(BuildContext context, Activity a) {
    List<int> days = const [];
    try {
      days = List<int>.from(jsonDecode(a.repeatDays) as List);
    } catch (_) {}
    final sorted = days.toList()..sort();
    return sorted.length == 7
        ? context.l10n.repeatDaily
        : sorted.map((d) => _dayLabel(context, d)).join(', ');
  }

  // scheduledAt — лише якір для daily/weekly/yearly (не буквальна дата
  // конкретного випадку), тож замість дати показуємо тип повтору; для
  // weekly — конкретні дні тижня з repeatConfig.
  String _reminderScheduleSummary(BuildContext context, Reminder r) {
    switch (r.repeatType) {
      case 'daily':
        return context.l10n.reminderRepeatDailyLabel;
      case 'weekly':
        try {
          final cfg = jsonDecode(r.repeatConfig) as Map<String, dynamic>;
          final days = List<int>.from(cfg['days'] as List)..sort();
          return days.map((d) => _dayLabel(context, d)).join(', ');
        } catch (_) {
          return context.l10n.reminderRepeatWeeklyLabel;
        }
      case 'yearly':
        return '${context.l10n.reminderRepeatYearlyLabel} · ${_fmtDate(r.scheduledAt).substring(0, 5)}';
      default:
        return '${_fmtDate(r.scheduledAt)} · ${_fmtTime(r.scheduledAt)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case _ArchiveKind.reminder:
        final r = item.reminder!;
        final tags = _parseTags(r.tags);
        final photos = () {
          try {
            return List<String>.from(jsonDecode(r.documentPaths) as List);
          } catch (_) {
            return <String>[];
          }
        }();
        final color = colorFromHex(r.color) ?? AppColors.primary;
        final isPast = r.repeatType == 'none' &&
            r.scheduledAt.isBefore(DateTime.now());
        return FeedPostCard(
          icon: medcardIconFor(r.iconKey),
          color: color,
          title: r.doctorType,
          dateLabel: _reminderScheduleSummary(context, r),
          subtitle: isPast
              ? context.l10n.visitPassedLabel
              : (r.location != null && r.location!.isNotEmpty ? r.location : null),
          notePreview: r.notes,
          tags: tags,
          photoPaths: photos,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAppointmentScreen(memberId: r.memberId, existing: r),
            ),
          ),
        );
      case _ArchiveKind.routine:
        final a = item.activity!;
        final color = colorFromHex(a.color) ?? AppColors.primary;
        return FeedPostCard(
          icon: Icons.home_repair_service_rounded,
          color: color,
          title: a.name,
          dateLabel: _scheduleSummary(context, a),
          subtitle: context.l10n.taskTypeRoutine,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddActivityScreen(
                memberId: a.memberId,
                existing: a,
                hideTypePicker: true,
                compactMode: true,
              ),
            ),
          ),
        );
    }
  }
}

// ────────────────────────────── empty ──────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({this.filtered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(filtered ? context.l10n.noAppointmentsForSpecialty : context.l10n.noRecordsYetTitle,
              style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            filtered
                ? context.l10n.tryDifferentSpecialtyHint
                : context.l10n.tapToAddFirstHint,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
