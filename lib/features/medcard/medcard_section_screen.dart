import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/shared_tags_library_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/medcard_entries_repository.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../data/repositories/medications_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/feed_post_card.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import '../../shared/widgets/tag_search_filter_bar.dart';
import '../add/routine_view_screen.dart';
import '../appointments/reminder_view_screen.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import '../medications/medication_detail_screen.dart';
import 'add_medcard_entry_screen.dart';
import 'add_medcard_section_screen.dart';
import 'medcard_entry_view_screen.dart';

final _sectionEntriesProvider =
    StreamProvider.family<List<MedcardEntry>, int>((ref, sectionId) {
  return ref.watch(medcardEntriesRepositoryProvider).watchBySection(sectionId);
});

final _sectionMedicationsProvider =
    StreamProvider.family<List<Medication>, int>((ref, sectionId) {
  return ref.watch(medicationsRepositoryProvider).watchBySection(sectionId);
});

final _sectionActivitiesProvider =
    StreamProvider.family<List<Activity>, int>((ref, sectionId) {
  return ref.watch(activitiesRepositoryProvider).watchBySection(sectionId);
});

final _sectionRemindersProvider =
    StreamProvider.family<List<Reminder>, int>((ref, sectionId) {
  return ref.watch(remindersRepositoryProvider).watchBySection(sectionId);
});

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

List<String> _parseTags(String raw) {
  try {
    return List<String>.from(jsonDecode(raw) as List);
  } catch (_) {
    return const [];
  }
}

// ─── Уніфікований елемент стрічки: запис архіву + все, що прив'язане до
// цього розділу через Простір (ліки/рутини/нагадування) ─────────────────────

enum _ItemKind { entry, medication, activity, reminder }

class _FeedItem {
  final _ItemKind kind;
  final DateTime date;
  final MedcardEntry? entry;
  final Medication? medication;
  final Activity? activity;
  final Reminder? reminder;
  const _FeedItem({
    required this.kind,
    required this.date,
    this.entry,
    this.medication,
    this.activity,
    this.reminder,
  });

  String get title => switch (kind) {
        _ItemKind.entry => entry!.title,
        _ItemKind.medication => medication!.name,
        _ItemKind.activity => activity!.name,
        _ItemKind.reminder => reminder!.doctorType,
      };

  String get searchableText => switch (kind) {
        _ItemKind.entry => '${entry!.title} ${entry!.notes ?? ''}',
        _ItemKind.reminder => '${reminder!.doctorType} ${reminder!.notes ?? ''}',
        _ => title,
      };

  // Ліки й рутини тегів не мають — при активному фільтрі тегів вони не
  // можуть йому відповідати, той самий підхід, що й в архіві нагадувань.
  List<String> get tags => switch (kind) {
        _ItemKind.entry => _parseTags(entry!.tags),
        _ItemKind.reminder => _parseTags(reminder!.tags),
        _ => const [],
      };
}

class MedcardSectionScreen extends ConsumerStatefulWidget {
  final MedcardSection section;
  final PeerSubject? peer;
  const MedcardSectionScreen({super.key, required this.section, this.peer});

  @override
  ConsumerState<MedcardSectionScreen> createState() => _MedcardSectionScreenState();
}

class _MedcardSectionScreenState extends ConsumerState<MedcardSectionScreen> {
  String _search = '';
  Set<String> _selectedTags = {};

  MedcardSection get section => widget.section;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteSectionConfirmTitle),
        content: Text(ctx.l10n.deleteSectionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.l10n.deleteAction,
              style: AppTextStyles.bodyMd.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(medcardSectionsRepositoryProvider).delete(section.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.peer != null;
    // Крок 4.4.4 плану: якщо суб'єкт дозволив редагування Поличок саме
    // цьому глядачеві — кнопка "додати" лишається доступною і для піра,
    // лише замість прямого запису шле record_proposal (Крок 4.4.1).
    final grants = ref.watch(activePeerGrantsProvider);
    final canEditPeer =
        widget.peer != null && grants != null && grants.editShelvesGranted;
    final AsyncValue<List<MedcardEntry>> entriesAsync;
    final AsyncValue<List<Medication>> medsAsync;
    final AsyncValue<List<Activity>> activitiesAsync;
    final AsyncValue<List<Reminder>> remindersAsync;
    if (widget.peer != null) {
      final uuid = widget.peer!.personUuid;
      entriesAsync = AsyncValue.data(
        ref.watch(peerMedcardEntriesProvider(uuid)).where((e) => e.sectionId == section.id).toList(),
      );
      medsAsync = AsyncValue.data(
        ref.watch(peerMedicationsProvider(uuid)).where((m) => m.sectionId == section.id).toList(),
      );
      activitiesAsync = AsyncValue.data(
        ref.watch(peerActivitiesProvider(uuid)).where((a) => a.sectionId == section.id).toList(),
      );
      remindersAsync = AsyncValue.data(
        ref.watch(peerRemindersProvider(uuid)).where((r) => r.sectionId == section.id).toList(),
      );
    } else {
      entriesAsync = ref.watch(_sectionEntriesProvider(section.id));
      medsAsync = ref.watch(_sectionMedicationsProvider(section.id));
      activitiesAsync = ref.watch(_sectionActivitiesProvider(section.id));
      remindersAsync = ref.watch(_sectionRemindersProvider(section.id));
    }
    final color = colorFromHex(section.color) ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: !readOnly
          ? MkAddFab(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMedcardEntryScreen(section: section),
                ),
              ),
            )
          : canEditPeer
              ? MkAddFab(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMedcardEntryScreen(
                        section: section,
                        onDraftCreated: (draft) => submitMedcardEntryProposal(
                          ref,
                          widget.peer!,
                          draft,
                          syntheticSectionId: section.id,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: MedcardIcon(section.iconKey, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(section.name, style: AppTextStyles.h3)),
                  if (!readOnly) ...[
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMedcardSectionScreen(
                          memberId: section.memberId,
                          existing: section,
                        ),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _delete(context, ref),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                    ),
                  ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                0,
                AppDimensions.screenPadding,
                AppDimensions.sm,
              ),
              child: TagSearchFilterBar(
                searchHint: context.l10n.searchHint,
                onSearchChanged: (v) => setState(() => _search = v),
                tagsLoader: SharedTagsLibraryService.getAll,
                selectedTags: _selectedTags,
                onTagsChanged: (tags) => setState(() => _selectedTags = tags),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await FamilyPeerSyncService(ref.read(databaseProvider)).syncAllPeers();
                  ref.invalidate(_sectionEntriesProvider(section.id));
                  ref.invalidate(_sectionMedicationsProvider(section.id));
                  ref.invalidate(_sectionActivitiesProvider(section.id));
                  ref.invalidate(_sectionRemindersProvider(section.id));
                },
                child: entriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                  data: (entries) {
                    final items = [
                      ...entries.map((e) => _FeedItem(
                            kind: _ItemKind.entry,
                            date: e.recordDate,
                            entry: e,
                          )),
                      ...(medsAsync.valueOrNull ?? const <Medication>[]).map(
                        (m) => _FeedItem(
                          kind: _ItemKind.medication,
                          date: m.startDate,
                          medication: m,
                        ),
                      ),
                      ...(activitiesAsync.valueOrNull ?? const <Activity>[]).map(
                        (a) => _FeedItem(
                          kind: _ItemKind.activity,
                          date: a.createdAt,
                          activity: a,
                        ),
                      ),
                      ...(remindersAsync.valueOrNull ?? const <Reminder>[]).map(
                        (r) => _FeedItem(
                          kind: _ItemKind.reminder,
                          date: r.scheduledAt,
                          reminder: r,
                        ),
                      ),
                    ]..sort((a, b) => b.date.compareTo(a.date));

                    final query = _search.trim().toLowerCase();
                    final filtered = items.where((it) {
                      if (query.isNotEmpty &&
                          !it.searchableText.toLowerCase().contains(query)) {
                        return false;
                      }
                      if (_selectedTags.isNotEmpty &&
                          !_selectedTags.every((t) => it.tags.contains(t))) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      final filtering = query.isNotEmpty || _selectedTags.isNotEmpty;
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          MkEmptyState(
                            hint: filtering
                                ? context.l10n.noResultsFoundHint
                                : context.l10n.sectionEmptyHint,
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenPadding,
                        AppDimensions.md,
                        AppDimensions.screenPadding,
                        88,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                        child: _FeedCard(
                          item: filtered[i],
                          section: section,
                          color: color,
                          peer: widget.peer,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final _FeedItem item;
  final MedcardSection section;
  final Color color;
  final PeerSubject? peer;
  const _FeedCard({
    required this.item,
    required this.section,
    required this.color,
    this.peer,
  });

  @override
  Widget build(BuildContext context) {
    // Крок 4.3.5 плану: екрани повного перегляду тепер вміють показувати
    // запис піра (peer прокидається далі) — тап відкриває той самий
    // екран, лише в режимі "тільки перегляд" всередині нього.
    switch (item.kind) {
      case _ItemKind.entry:
        final entry = item.entry!;
        final tags = _parseTags(entry.tags);
        final photos = _parseTags(entry.documentPaths);
        return FeedPostCard(
          icon: Icons.folder_rounded,
          iconWidget: MedcardIcon(section.iconKey, size: 22),
          color: color,
          title: entry.title,
          dateLabel: _formatDate(entry.recordDate),
          notePreview: entry.notes,
          tags: tags,
          photoPaths: photos,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedcardEntryViewScreen(
                section: section,
                entryId: entry.id,
                peer: peer,
              ),
            ),
          ),
        );
      case _ItemKind.medication:
        final m = item.medication!;
        return FeedPostCard(
          icon: Icons.medication_liquid_rounded,
          iconWidget: MedcardIcon(m.iconKey ?? 'form_cream', size: 22),
          color: color,
          title: m.name,
          dateLabel: _formatDate(m.startDate),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicationDetailScreen(
                medicationId: m.id,
                memberId: m.memberId,
                peer: peer,
              ),
            ),
          ),
        );
      case _ItemKind.activity:
        final a = item.activity!;
        return FeedPostCard(
          icon: Icons.home_repair_service_rounded,
          iconWidget: const AssetIcon('task_routine', size: 22),
          color: color,
          title: a.name,
          dateLabel: _formatDate(a.createdAt),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoutineViewScreen(activityId: a.id, peer: peer),
            ),
          ),
        );
      case _ItemKind.reminder:
        final r = item.reminder!;
        final tags = _parseTags(r.tags);
        final photos = _parseTags(r.documentPaths);
        return FeedPostCard(
          icon: Icons.notifications_rounded,
          iconWidget: MedcardIcon(r.iconKey, size: 22),
          color: color,
          title: r.doctorType,
          dateLabel: _formatDate(r.scheduledAt),
          notePreview: r.notes,
          tags: tags,
          photoPaths: photos,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReminderViewScreen(reminderId: r.id, peer: peer),
            ),
          ),
        );
    }
  }
}
