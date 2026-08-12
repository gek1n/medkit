import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/attachment_cleanup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../shared/widgets/created_by_footer.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_header_action_button.dart';
import '../../shared/widgets/photo_gallery_viewer.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import '../today/providers/today_providers.dart';
import 'add_appointment_screen.dart';

final _reminderProvider =
    StreamProvider.family<Reminder?, int>((ref, id) {
  return ref.watch(remindersRepositoryProvider).watchById(id);
});

final _slotsProvider =
    FutureProvider.family<List<ReminderSlot>, int>((ref, reminderId) {
  return ref.watch(remindersRepositoryProvider).getSlotsForReminder(reminderId);
});

final _sectionProvider =
    FutureProvider.family<MedcardSection?, int>((ref, sectionId) {
  return ref.watch(medcardSectionsRepositoryProvider).getById(sectionId);
});

/// Перегляд збереженого нагадування — показує все заповнене, без прямого
/// редагування. Кнопка "Редагувати" веде на стандартну форму (той самий
/// патерн, що й MedcardEntryViewScreen/MedicationDetailScreen).
///
/// Крок 11 (view-only перший прохід): [peer] непорожній — нагадування
/// береться не з локальної бази (id синтетичний), а з перекладача кешу
/// піра ([peerRemindersProvider]); кнопки редагування/видалення завжди
/// ховаються (справжнє редагування "за іншого" — окремий, ще не
/// підключений наступний крок).
class ReminderViewScreen extends ConsumerWidget {
  final int reminderId;
  final PeerSubject? peer;
  const ReminderViewScreen({super.key, required this.reminderId, this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (peer != null) {
      final reminder = ref
          .watch(peerRemindersProvider(peer!.personUuid))
          .where((r) => r.id == reminderId)
          .firstOrNull;
      if (reminder == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
        return const Scaffold(backgroundColor: AppColors.bg, body: SizedBox.shrink());
      }
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: _ViewBody(reminder: reminder, peer: peer)),
      );
    }

    final reminderAsync = ref.watch(_reminderProvider(reminderId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: reminderAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text(context.l10n.errorGeneric('$e'))),
          data: (reminder) {
            if (reminder == null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.pop(context),
              );
              return const SizedBox.shrink();
            }
            return _ViewBody(reminder: reminder);
          },
        ),
      ),
    );
  }
}

class _ViewBody extends ConsumerWidget {
  final Reminder reminder;
  final PeerSubject? peer;
  const _ViewBody({required this.reminder, this.peer});

  List<String> get _tags {
    try {
      return List<String>.from(jsonDecode(reminder.tags) as List);
    } catch (_) {
      return const [];
    }
  }

  List<String> get _photos {
    try {
      return List<String>.from(jsonDecode(reminder.documentPaths) as List);
    } catch (_) {
      return const [];
    }
  }

  static String _dayLabel(BuildContext context, int weekday) {
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

  String _scheduleSummary(BuildContext context) {
    final hh = reminder.scheduledAt.hour.toString().padLeft(2, '0');
    final mm = reminder.scheduledAt.minute.toString().padLeft(2, '0');
    switch (reminder.repeatType) {
      case 'daily':
        return context.l10n.reminderRepeatDailyLabel;
      case 'weekly':
        try {
          final cfg = jsonDecode(reminder.repeatConfig) as Map<String, dynamic>;
          final days = List<int>.from(cfg['days'] as List)..sort();
          return days.map((d) => _dayLabel(context, d)).join(', ');
        } catch (_) {
          return context.l10n.reminderRepeatWeeklyLabel;
        }
      case 'monthly':
        return '${context.l10n.reminderRepeatMonthlyLabel} · '
            '${context.l10n.reminderMonthlyDayFieldLabel} ${reminder.scheduledAt.day}';
      case 'yearly':
        final fmt =
            DateFormat('d MMM', Localizations.localeOf(context).languageCode);
        return '${context.l10n.reminderRepeatYearlyLabel} · ${fmt.format(reminder.scheduledAt)}';
      default:
        final fmt = DateFormat(
            'd MMM yyyy', Localizations.localeOf(context).languageCode);
        return '${fmt.format(reminder.scheduledAt)} · $hh:$mm';
    }
  }

  static String _remindBeforeLabel(BuildContext context, int min) {
    final l10n = context.l10n;
    return switch (min) {
      10 => l10n.remindBefore10Min,
      30 => l10n.remindBefore30Min,
      60 => l10n.remindBefore1Hour,
      1440 => l10n.remindBefore1Day,
      2880 => l10n.remindBefore2Days,
      _ => l10n.remindBeforeAtTime,
    };
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteSurgeryConfirmTitle),
        content: Text(ctx.l10n.deleteAppointmentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.l10n.deleteAction,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await AttachmentCleanupService.deletePaths(reminder.documentPaths);
    await ref.read(remindersRepositoryProvider).delete(reminder.id);
    await NotificationService.cancelAppointmentReminder(reminder.id);
    await NotificationService.cancelRecurringReminder(reminder.id);
    ref.invalidate(tomorrowAppointmentsProvider);
    // НЕ викликаємо Navigator.pop тут — щойно рядок реально видалиться з
    // БД, watchById(id) реактивно віддасть null, і сам екран вище
    // (data: (reminder) => if (reminder == null) ...) закриється через
    // addPostFrameCallback. Виклик pop і тут, і там — подвійний pop на
    // одному навігаторі (чорний екран, що "лікується" лише перезапуском).
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = _tags;
    final photos = _photos;
    final color = colorFromHex(reminder.color) ?? AppColors.primary;
    final hasNote = reminder.notes != null && reminder.notes!.trim().isNotEmpty;
    final hasLocation =
        reminder.location != null && reminder.location!.trim().isNotEmpty;
    final hasSlots =
        reminder.repeatType == 'daily' || reminder.repeatType == 'weekly';
    final showRemindBefore = reminder.repeatType == 'none' ||
        reminder.repeatType == 'monthly' ||
        reminder.repeatType == 'yearly';
    final List<ReminderSlot>? peerSlots = peer != null && hasSlots
        ? (ref
                .watch(peerReminderSlotsProvider(peer!.personUuid))
                .where((s) => s.reminderId == reminder.id)
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : null;
    final slotsAsync = peer != null ? null : (hasSlots ? ref.watch(_slotsProvider(reminder.id)) : null);
    final MedcardSection? peerSection = peer != null && reminder.sectionId != null
        ? ref
            .watch(peerMedcardSectionsProvider(peer!.personUuid))
            .where((s) => s.id == reminder.sectionId)
            .firstOrNull
        : null;
    final sectionAsync = peer != null
        ? null
        : (reminder.sectionId != null ? ref.watch(_sectionProvider(reminder.sectionId!)) : null);
    // Крок 11 (#307): editSchedule дозволяє редагувати ЦІЛЕ нагадування
    // піра (compare-and-swap).
    final canEditForPeer = peer != null && ref.watch(activePeerGrantsProvider).editSchedule;

    return Column(
      children: [
        Container(
          color: AppColors.bg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              MkBackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(reminder.doctorType,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (peer == null)
                      MkEditIconButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddAppointmentScreen(
                              memberId: reminder.memberId,
                              existing: reminder,
                            ),
                          ),
                        ),
                      )
                    else if (canEditForPeer)
                      MkEditIconButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddAppointmentScreen(
                              memberId: null,
                              existing: reminder,
                              initialSlotTimes: peerSlots?.map((s) => s.timeOfDay).toList(),
                              onDraftCreated: (draft, slotTimes) => submitReminderProposal(
                                ref,
                                peer!,
                                draft,
                                existingSyncUuid: reminder.syncUuid,
                                existingUpdatedAt: reminder.updatedAt,
                                syntheticSectionId: reminder.sectionId,
                                slotTimes: slotTimes,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (peer == null)
                MkDeleteIconButton(onTap: () => _delete(context, ref, reminder)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.md,
              AppDimensions.screenPadding,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: MedcardIcon(reminder.iconKey, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_scheduleSummary(context),
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textSub)),
                    ),
                  ],
                ),
                if (hasSlots) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    Widget chips(List<ReminderSlot> slots) => slots.isEmpty
                        ? const SizedBox.shrink()
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: slots
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusFull),
                                        border:
                                            Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time_rounded,
                                              size: 14, color: color),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.timeOfDay,
                                            style: AppTextStyles.labelSm
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          );
                    if (peerSlots != null) return chips(peerSlots);
                    return slotsAsync!.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: chips,
                    );
                  }),
                ],
                if (showRemindBefore) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.notifications_outlined, size: 15, color: color),
                      const SizedBox(width: 8),
                      Text(
                        _remindBeforeLabel(context, reminder.remindBeforeMin),
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.textSub),
                      ),
                    ],
                  ),
                ],
                if (peerSection != null || sectionAsync != null) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    Widget row(MedcardSection section) => Row(
                          children: [
                            Icon(Icons.folder_outlined, size: 15, color: color),
                            const SizedBox(width: 8),
                            MedcardIcon(section.iconKey, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              section.name,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.textSub),
                            ),
                          ],
                        );
                    if (peerSection != null) return row(peerSection);
                    return sectionAsync!.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (section) => section == null ? const SizedBox.shrink() : row(section),
                    );
                  }),
                ],
                if (hasLocation) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(reminder.location!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSub)),
                      ),
                    ],
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusFull),
                              ),
                              child: Text(t,
                                  style: AppTextStyles.labelSm.copyWith(
                                      color: color, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
                if (hasNote) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(reminder.notes!, style: AppTextStyles.bodyMd),
                  ),
                ],
                // Крок 11 (view-only перший прохід): фото піра — на вимогу
                // через FamilyKeyService.sharedChannelKey+/family/photo,
                // ще не підключено в UI (C4 TODO) — поки просто ховаємо
                // секцію для піра, замість показу зламаних мініатюр.
                if (photos.isNotEmpty && peer == null) ...[
                  const SizedBox(height: 18),
                  Text(context.l10n.reminderPhotoLabel.toUpperCase(),
                      style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: photos.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => showPhotoGalleryViewer(
                          context, imagePaths: photos, initialIndex: i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        child: FutureBuilder<Uint8List>(
                          future: PhotoService.decryptedBytes(photos[i]),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return Container(color: AppColors.surface);
                            }
                            return Image.memory(snap.data!, fit: BoxFit.cover);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                peer == null
                    ? CreatedByFooter(entityType: 'doctor_appointment', localId: reminder.id)
                    : CreatedByFooter.forPeer(
                        entityType: 'doctor_appointment', peer: peer, entityUuid: reminder.syncUuid),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
