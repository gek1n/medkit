import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/task_color.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medcard_entries_repository.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/mk_header_action_button.dart';
import '../../shared/widgets/peer_attachment_chip.dart';
import '../../shared/widgets/photo_gallery_viewer.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import 'add_medcard_entry_screen.dart';

final _entryProvider =
    StreamProvider.family<MedcardEntry?, int>((ref, id) {
  return ref.watch(medcardEntriesRepositoryProvider).watchById(id);
});

/// Перегляд збереженого запису — показує лише те, що юзер справді вніс,
/// без можливості редагувати напряму. Кнопка "Редагувати" веде на
/// стандартну форму створення/редагування.
///
/// Крок 4.3.5 плану: [peer] непорожній — запис береться не з локальної
/// бази (id синтетичний, реального рядка нема), а з перекладача кешу
/// піра; кнопка редагування ховається.
class MedcardEntryViewScreen extends ConsumerWidget {
  final MedcardSection section;
  final int entryId;
  final PeerSubject? peer;
  const MedcardEntryViewScreen({
    super.key,
    required this.section,
    required this.entryId,
    this.peer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorFromHex(section.color) ?? AppColors.primary;

    if (peer != null) {
      final entry = ref
          .watch(peerMedcardEntriesProvider(peer!.personUuid))
          .where((e) => e.id == entryId)
          .firstOrNull;
      if (entry == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
        return const Scaffold(backgroundColor: AppColors.bg, body: SizedBox.shrink());
      }
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: _ViewBody(section: section, entry: entry, color: color, peer: peer),
        ),
      );
    }

    final entryAsync = ref.watch(_entryProvider(entryId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: entryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text(context.l10n.errorGeneric('$e'))),
          data: (entry) {
            if (entry == null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.pop(context),
              );
              return const SizedBox.shrink();
            }
            return _ViewBody(section: section, entry: entry, color: color);
          },
        ),
      ),
    );
  }
}

class _ViewBody extends ConsumerWidget {
  final MedcardSection section;
  final MedcardEntry entry;
  final Color color;
  final PeerSubject? peer;
  const _ViewBody({
    required this.section,
    required this.entry,
    required this.color,
    this.peer,
  });

  List<String> get _tags {
    try {
      return List<String>.from(jsonDecode(entry.tags) as List);
    } catch (_) {
      return const [];
    }
  }

  List<String> get _photos {
    try {
      return List<String>.from(jsonDecode(entry.documentPaths) as List);
    } catch (_) {
      return const [];
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = _tags;
    final photos = _photos;
    final hasNote = entry.notes != null && entry.notes!.trim().isNotEmpty;
    final hasLocation = entry.location != null && entry.location!.trim().isNotEmpty;
    // Крок 4.4.4 плану: якщо суб'єкт дозволив редагування Поличок саме
    // цьому глядачеві — олівець лишається доступним і для запису піра,
    // лише замість прямого запису шле record_proposal (Крок 4.4.1).
    final grants = peer == null ? null : ref.watch(activePeerGrantsProvider);
    final canEditPeer = grants != null && grants.editShelvesGranted;

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
                      child: Text(entry.title,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (peer == null)
                      MkEditIconButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddMedcardEntryScreen(section: section, existing: entry),
                          ),
                        ),
                      )
                    else if (canEditPeer)
                      MkEditIconButton(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMedcardEntryScreen(
                              section: section,
                              existing: entry,
                              onDraftCreated: (draft) => submitMedcardEntryProposal(
                                ref,
                                peer!,
                                draft,
                                existingSyncUuid: entry.syncUuid,
                                existingUpdatedAt: entry.updatedAt,
                                syntheticSectionId: section.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
                    Icon(Icons.calendar_today_rounded, size: 15, color: color),
                    const SizedBox(width: 8),
                    Text(_formatDate(entry.recordDate), style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub)),
                  ],
                ),
                if (hasLocation) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.location!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub))),
                    ],
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Text(t, style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w600)),
                        )).toList(),
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
                    child: Text(entry.notes!, style: AppTextStyles.bodyMd),
                  ),
                ],
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(context.l10n.reminderPhotoLabel.toUpperCase(), style: AppTextStyles.labelSm),
                  const SizedBox(height: 8),
                  // Фото піра ще не лежать локально — підвантажуються за
                  // запитом (PeerAttachmentChip), тож для піра — чіпи
                  // запиту, а не готова сітка мініатюр.
                  if (peer != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: photos
                          .map((path) => PeerAttachmentChip(channelId: peer!.channelId, photoPath: path))
                          .toList(),
                    )
                  else
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
                        onTap: () => showPhotoGalleryViewer(context, imagePaths: photos, initialIndex: i),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
