import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/family_peer_sync_service.dart';
import '../../core/services/peer_photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/avatars.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';

const _notesFieldByType = {
  'medication': 'instructions',
  'doctor_appointment': 'notes',
  'lab_result': 'notes',
  'allergy': 'notes',
  'chronic_condition': 'notes',
  'vaccination': 'notes',
  'surgery': 'notes',
};

String _entityTypeLabel(BuildContext context, String type) {
  final l10n = context.l10n;
  return switch (type) {
    'medication' => l10n.categoryMeds,
    'doctor_appointment' => l10n.doctorVisitLabel,
    'lab_result' => l10n.labResultTitle,
    'allergy' => l10n.allergyTitle,
    'chronic_condition' => l10n.chronicConditionTitle,
    'vaccination' => l10n.vaccinationTitle,
    'surgery' => l10n.surgeryTitle,
    'activity' => l10n.defaultActivityName,
    'wellbeing_schedule' => l10n.wellbeingTitle,
    _ => type,
  };
}

const _entityTypeIcons = {
  'medication': Icons.medication_rounded,
  'doctor_appointment': Icons.calendar_month_rounded,
  'lab_result': Icons.biotech_rounded,
  'allergy': Icons.warning_amber_rounded,
  'chronic_condition': Icons.favorite_rounded,
  'vaccination': Icons.vaccines_rounded,
  'surgery': Icons.local_hospital_rounded,
  'activity': Icons.directions_walk_rounded,
  'wellbeing_schedule': Icons.favorite_border_rounded,
};

// Дочірні "інстанси на день" (intake/activity_log/wellbeing_log) та внутрішні
// службові типи не показуються як окремі картки у плоскому списку — інакше
// список ріс би необмежено з кожним новим днем. Вони все одно обробляються
// (перевірки пропущеного, підрахунок стану), просто не рендеряться напряму;
// час прийому видно всередині картки відповідних ліків/активності нижче.
const _hiddenFromList = {'schedule', 'intake', 'activity_slot', 'activity_log', 'wellbeing_log'};

/// Читає найбільш "людяне" поле з довільного JSON — записи різних типів
/// мають різні назви ключового поля (name/testName/allergen/doctorType),
/// тому радше вгадуємо перше підходяще, ніж дублюємо типізовану модель
/// заради суто інформаційного, нередагованого перегляду.
String _primaryLabel(BuildContext context, Map<String, dynamic> json) {
  for (final key in ['name', 'testName', 'allergen', 'doctorType']) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return context.l10n.recordFallbackLabel;
}

final _sharedSubjectsProvider = StreamProvider<List<SharedSubject>>((ref) {
  return ref.watch(familyPeersRepositoryProvider).watchSharedSubjects();
});

final _sharedEntitiesProvider = StreamProvider.family<List<SharedEntity>, String>((ref, subjectPersonUuid) {
  return ref.watch(familyPeersRepositoryProvider).watchSharedEntities(subjectPersonUuid);
});

/// Перегляд того, що поділився зі мною конкретний пір (Фаза 4). Редагувати
/// можна лише нотатки (notes/instructions) — навмисно мінімальний перший
/// крок для "edit"-права: правка йде назад до власника даних і
/// застосовується лише якщо запис не змінився з моменту, коли я його
/// побачив (compare-and-swap, див. FamilyPeerSyncService.proposeEdit).
/// Якщо власник тим часом сам відредагував запис — моя правка тихо
/// губиться, а не затирає його свіжішу версію.
class SharedFamilyDataScreen extends ConsumerWidget {
  final String peerChannelId;
  final String peerName;
  const SharedFamilyDataScreen({super.key, required this.peerChannelId, required this.peerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(_sharedSubjectsProvider);
    final subjects =
        (subjectsAsync.valueOrNull ?? const []).where((s) => s.peerChannelId == peerChannelId).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(context.l10n.dataFromPeerTitle(peerName), style: AppTextStyles.h3)),
                ],
              ),
            ),
            Expanded(
              child: subjectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('$e')),
                data: (_) {
                  if (subjects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.screenPadding),
                        child: Text(
                          context.l10n.peerNothingSharedYet(peerName),
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.md,
                      AppDimensions.screenPadding,
                      AppDimensions.xl,
                    ),
                    children: [
                      for (final subject in subjects) ...[
                        Row(
                          children: [
                            AvatarImage(index: subject.avatarIndex, size: 28),
                            const SizedBox(width: 8),
                            Text(subject.name, style: AppTextStyles.labelLg),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        _SubjectEntities(
                          subjectPersonUuid: subject.personUuid,
                          peerChannelId: peerChannelId,
                        ),
                        const SizedBox(height: AppDimensions.lg),
                      ],
                    ],
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

class _SubjectEntities extends ConsumerWidget {
  final String subjectPersonUuid;
  final String peerChannelId;
  const _SubjectEntities({required this.subjectPersonUuid, required this.peerChannelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(_sharedEntitiesProvider(subjectPersonUuid));
    final entities =
        (entitiesAsync.valueOrNull ?? const []).where((e) => !_hiddenFromList.contains(e.entityType)).toList();

    if (entities.isEmpty) {
      return Text(
        context.l10n.noViewableDataLabel,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
      );
    }

    return Column(
      children: entities.map((e) {
        Map<String, dynamic> json;
        try {
          json = jsonDecode(e.dataJson) as Map<String, dynamic>;
        } catch (_) {
          json = const {};
        }
        final editable = _notesFieldByType.containsKey(e.entityType);
        final documentPaths = _documentPathsOf(json);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: editable
                      ? () => _openEditNotesSheet(context, ref, entity: e, json: json, peerChannelId: peerChannelId)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Row(
                      children: [
                        Icon(_entityTypeIcons[e.entityType] ?? Icons.description_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_primaryLabel(context, json), style: AppTextStyles.labelMd),
                              Text(
                                _entityTypeLabel(context, e.entityType),
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
                              ),
                            ],
                          ),
                        ),
                        if (editable)
                          const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                if (documentPaths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.md, 0, AppDimensions.md, AppDimensions.md),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: documentPaths
                          .map((path) => _AttachmentChip(channelId: peerChannelId, photoPath: path))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// documentPaths у dataJson лишається у своєму сирому вигляді з БД —
/// TextColumn, тобто рядок, що сам містить JSON-масив (подвійне кодування).
List<String> _documentPathsOf(Map<String, dynamic> json) {
  final raw = json['documentPaths'];
  try {
    if (raw is String) return (jsonDecode(raw) as List).cast<String>();
    if (raw is List) return raw.cast<String>();
  } catch (_) {}
  return const [];
}

/// Стан вкладення: ще не запитане → "Запросити файл"; запит надіслано, але
/// файл не прийшов → "Очікуємо файл…"; файл уже локально → тап відкриває
/// перегляд. Дані самого файлу приходять лише за запитом (GDPR-мінімізація)
/// — на відміну від текстових полів запису, вони не пушаться заздалегідь.
class _AttachmentChip extends ConsumerStatefulWidget {
  final String channelId;
  final String photoPath;
  const _AttachmentChip({required this.channelId, required this.photoPath});

  @override
  ConsumerState<_AttachmentChip> createState() => _AttachmentChipState();
}

enum _AttachmentState { unknown, available, pending, none }

class _AttachmentChipState extends ConsumerState<_AttachmentChip> {
  _AttachmentState _state = _AttachmentState.unknown;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final exists = await PeerPhotoService.exists(widget.channelId, widget.photoPath);
    if (exists) {
      if (mounted) setState(() => _state = _AttachmentState.available);
      return;
    }
    final pending = await PeerPhotoService.isRequested(widget.channelId, widget.photoPath);
    if (mounted) setState(() => _state = pending ? _AttachmentState.pending : _AttachmentState.none);
  }

  Future<void> _request() async {
    setState(() => _state = _AttachmentState.pending);
    try {
      await FamilyPeerSyncService(ref.read(databaseProvider))
          .requestPhoto(channelId: widget.channelId, photoPath: widget.photoPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fileRequestSentSnackbar)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _AttachmentState.none);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.fileRequestFailedError('$e'))));
      }
    }
  }

  Future<void> _open() async {
    try {
      final bytes = await PeerPhotoService.decryptedBytes(widget.channelId, widget.photoPath);
      if (!mounted) return;
      if (PeerPhotoService.isPdf(widget.photoPath)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.pdfReceivedSavedSnackbar)));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: Image.memory(bytes)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.fileOpenFailedError('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = PeerPhotoService.isPdf(widget.photoPath);
    final baseIcon = isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded;

    late final IconData icon;
    late final String label;
    late final VoidCallback? onTap;
    late final Color color;

    switch (_state) {
      case _AttachmentState.unknown:
        icon = baseIcon;
        label = context.l10n.loadingEllipsis;
        onTap = null;
        color = AppColors.textMuted;
      case _AttachmentState.available:
        icon = baseIcon;
        label = isPdf ? context.l10n.pdfLabel : context.l10n.photoLabel;
        onTap = _open;
        color = AppColors.primary;
      case _AttachmentState.pending:
        icon = Icons.hourglass_top_rounded;
        label = context.l10n.awaitingFileLabel;
        onTap = null;
        color = AppColors.textMuted;
      case _AttachmentState.none:
        icon = Icons.download_rounded;
        label = context.l10n.requestFileAction;
        onTap = _request;
        color = AppColors.primary;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: AppTextStyles.bodySm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

Future<void> _openEditNotesSheet(
  BuildContext context,
  WidgetRef ref, {
  required SharedEntity entity,
  required Map<String, dynamic> json,
  required String peerChannelId,
}) async {
  final field = _notesFieldByType[entity.entityType] ?? 'notes';
  final controller = TextEditingController(text: json[field] as String? ?? '');
  final baseUpdatedAtRaw = json['updatedAt'] as String?;
  final baseUpdatedAt = baseUpdatedAtRaw != null ? DateTime.tryParse(baseUpdatedAtRaw) : null;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.editNotesTitle, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            context.l10n.editNotesDisclaimer,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: InputBorder.none,
                hintText: context.l10n.notesHintEllipsis,
              ),
              style: AppTextStyles.bodyMd,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: baseUpdatedAt == null
                  ? null
                  : () async {
                      Navigator.pop(sheetContext);
                      try {
                        await FamilyPeerSyncService(ref.read(databaseProvider)).proposeEdit(
                          channelId: peerChannelId,
                          subjectPersonUuid: entity.subjectPersonUuid,
                          entityType: entity.entityType,
                          targetUuid: entity.uuid,
                          value: controller.text,
                          baseUpdatedAt: baseUpdatedAt,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.editSentSnackbar)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(context.l10n.sendFailedError('$e'))));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(context.l10n.sendEditAction),
            ),
          ),
        ],
      ),
    ),
  );
}
