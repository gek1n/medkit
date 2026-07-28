import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/medcard_icons.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_entries_repository.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../shared/widgets/feed_post_card.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_list_widgets.dart';
import 'add_medcard_entry_screen.dart';
import 'add_medcard_section_screen.dart';
import 'medcard_entry_view_screen.dart';

final _sectionEntriesProvider =
    StreamProvider.family<List<MedcardEntry>, int>((ref, sectionId) {
  return ref.watch(medcardEntriesRepositoryProvider).watchBySection(sectionId);
});

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class MedcardSectionScreen extends ConsumerWidget {
  final MedcardSection section;
  const MedcardSectionScreen({super.key, required this.section});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(_sectionEntriesProvider(section.id));
    final color = colorFromHex(section.color) ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: MkAddFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedcardEntryScreen(section: section),
          ),
        ),
      ),
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
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(_sectionEntriesProvider(section.id)),
                child: entriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          MkEmptyState(hint: context.l10n.sectionEmptyHint),
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
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        final tags = () {
                          try {
                            return List<String>.from(jsonDecode(entry.tags) as List);
                          } catch (_) {
                            return <String>[];
                          }
                        }();
                        final photos = () {
                          try {
                            return List<String>.from(jsonDecode(entry.documentPaths) as List);
                          } catch (_) {
                            return <String>[];
                          }
                        }();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                          child: FeedPostCard(
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
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
