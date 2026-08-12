import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/plan_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/l10n_ext.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/medcard_sections_repository.dart';
import '../../features/today/providers/today_providers.dart';
import '../../shared/widgets/asset_icon.dart';
import '../../shared/widgets/mk_back_button.dart';
import '../../shared/widgets/space_picker.dart';
import '../appointments/add_appointment_screen.dart';
import '../family/peer_record_proposal.dart';
import '../family/peer_view_providers.dart';
import '../medcard/add_medcard_entry_screen.dart';
import '../medcard/add_medcard_section_screen.dart';
import '../medications/add_medication_screen.dart';
import '../plans/elly_denied_screen.dart';
import '../wellbeing/add_wellbeing_schedule_screen.dart';
import 'add_activity_screen.dart';

/// Відкриває екран створення завдання одразу (без проміжного меню-шторки):
/// перший елемент екрана — пікер із 5 пунктів, вибір одразу веде до
/// відповідної стандартної форми створення. [peer] непорожній — створення
/// іде не в локальну базу, а через `record_proposal` (Крок 11, #307):
/// потрібен `editSchedule`/`editMedcard` грант, перевірений ще до виклику
/// цієї функції (кнопка "+" сама ховається без гранту).
void openAddTaskScreen(BuildContext context, {int? memberId, PeerSubject? peer}) {
  if (peer != null) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(memberId: null, peer: peer)));
    return;
  }

  final container = ProviderScope.containerOf(context);
  final plan = container.read(planProvider);
  final members = container.read(allMembersProvider).valueOrNull ?? [];
  final localCount = members.length;
  final overLocalLimit =
      plan.limits.maxLocalMembers != 0 && localCount > plan.limits.maxLocalMembers;

  // Ліміт локальних профілів обмежує лише створення завдань ДЛЯ цих
  // "зайвих" локальних профілів — власнику завжди можна створювати собі.
  var targetIsLocalDependent = false;
  if (memberId != null) {
    for (final m in members) {
      if (m.id == memberId) {
        targetIsLocalDependent = m.role == 'dependent';
        break;
      }
    }
  }

  if (overLocalLimit && targetIsLocalDependent) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EllyDeniedScreen()));
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddTaskScreen(memberId: memberId)),
  );
}

enum _TaskType { reminder, routine, meds, note, wellbeing }

class AddTaskScreen extends ConsumerWidget {
  final int? memberId;
  final PeerSubject? peer;
  const AddTaskScreen({super.key, required this.memberId, this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return peer != null ? _buildForPeer(context, ref, peer!) : _buildForLocal(context, ref);
  }

  // ── Крок 11 (#307): та сама 5-пунктова шторка, але кожен вибір відкриває
  // форму в draft-режимі (onDraftCreated, а не memberId) — збережене йде не
  // в локальну базу, а через record_proposal конкретному піру. Нотатка
  // (medcard_entry) окремо: вимагає розділу, якого пір ще міг не мати —
  // простий власний пікер із розділів піра замість showSpacePicker
  // (той читає ЛОКАЛЬНУ таблицю розділів, для піра не підходить).
  Widget _buildForPeer(BuildContext context, WidgetRef ref, PeerSubject peer) {
    Future<void> finish() async {
      if (context.mounted) Navigator.pop(context, true);
    }

    Future<void> openType(_TaskType type) async {
      if (type == _TaskType.note) {
        final section = await _showPeerSpacePicker(context, ref, peer);
        if (section == null || !context.mounted) return;
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedcardEntryScreen(
              section: section,
              onDraftCreated: (draft) => submitMedcardEntryProposal(
                ref,
                peer,
                draft,
                syntheticSectionId: section.id,
              ),
            ),
          ),
        );
        if (saved == true) await finish();
        return;
      }

      final Widget screen = switch (type) {
        _TaskType.reminder => AddAppointmentScreen(
            memberId: null,
            onDraftCreated: (draft, slotTimes) =>
                submitReminderProposal(ref, peer, draft, slotTimes: slotTimes),
          ),
        _TaskType.routine => AddActivityScreen(
            memberId: null,
            hideTypePicker: true,
            forcedType: 'routine',
            compactMode: true,
            onDraftCreated: (draft) => submitActivityProposal(ref, peer, draft),
          ),
        _TaskType.meds => AddMedicationScreen(
            memberId: null,
            onDraftCreated: (draft) => submitMedicationProposal(ref, peer, draft),
          ),
        _TaskType.wellbeing => AddWellbeingScheduleScreen(
            memberId: null,
            onDraftCreated: (draft) => submitWellbeingScheduleProposal(ref, peer, draft),
          ),
        _TaskType.note => throw StateError('handled above'),
      };
      final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen));
      if (saved == true) await finish();
    }

    return _pickerScaffold(context, openType);
  }

  Widget _buildForLocal(BuildContext context, WidgetRef ref) {
    final fallbackMemberAsync = ref.watch(currentMemberProvider);
    final resolvedMemberId = memberId ?? fallbackMemberAsync.valueOrNull?.id;

    // push (не pushReplacement) — пікер лишається в стеку, тож кнопка
    // "назад"/свайп на формі повертає саме до вибору типу. Але після
    // успішного збереження форма повертає true, і ми одразу "пропускаємо"
    // пікер, popаючи й його — користувач опиняється одразу на Сьогодні/
    // Розкладі, а не знову на екрані вибору типу.
    Future<void> openType(_TaskType type) async {
      if (resolvedMemberId == null) return;

      if (type == _TaskType.routine) {
        final limits = ref.read(planProvider).limits;
        if (limits.maxRoutineTasks != 0) {
          final count = await ref
              .read(activitiesRepositoryProvider)
              .countByMember(resolvedMemberId);
          if (!context.mounted) return;
          if (count >= limits.maxRoutineTasks) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EllyDeniedScreen(
                  title: context.l10n.routineTasksLimitDeniedTitle,
                  subtitle: context.l10n.routineTasksLimitDeniedSubtitle,
                ),
              ),
            );
            return;
          }
        }
      }

      if (type == _TaskType.note) {
        // Нотатка завжди належить конкретному розділу — спершу пікер
        // Простору (з можливістю створити новий), лише потім форма запису.
        // "Без простору" (сентинел, не null — null означає просто закриту
        // без вибору шторку) падає в автостворений розділ "Нотатки", а не
        // блокує створення нотатки.
        var sectionId = await showSpacePicker(
          context,
          memberId: resolvedMemberId,
          current: null,
        );
        if (sectionId == null || !context.mounted) return;
        if (sectionId == noSpaceSelectedSentinel) {
          sectionId = await ref
              .read(medcardSectionsRepositoryProvider)
              .getOrCreateDefaultNotesSection(
                resolvedMemberId,
                context.l10n.defaultNotesSectionName,
              );
          if (!context.mounted) return;
        }
        final section = await ref
            .read(medcardSectionsRepositoryProvider)
            .getById(sectionId);
        if (section == null || !context.mounted) return;
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedcardEntryScreen(section: section),
          ),
        );
        if (saved == true && context.mounted) Navigator.pop(context, true);
        return;
      }

      final Widget screen = switch (type) {
        _TaskType.reminder => AddAppointmentScreen(memberId: resolvedMemberId),
        _TaskType.routine => AddActivityScreen(
            memberId: resolvedMemberId,
            hideTypePicker: true,
            forcedType: 'routine',
            compactMode: true,
          ),
        _TaskType.meds => AddMedicationScreen(memberId: resolvedMemberId),
        _TaskType.wellbeing =>
          AddWellbeingScheduleScreen(memberId: resolvedMemberId),
        _TaskType.note => throw StateError('handled above'),
      };
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
      if (saved == true && context.mounted) Navigator.pop(context, true);
    }

    return _pickerScaffold(context, openType);
  }

  Widget _pickerScaffold(BuildContext context, Future<void> Function(_TaskType) openType) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  MkBackButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(context.l10n.addTypeSheetTitle, style: AppTextStyles.h3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                context.l10n.addTypeSheetSubtitle,
                style: AppTextStyles.bodySm,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _TypeCard(
                    iconAsset: 'task_reminder',
                    title: context.l10n.reminderCategoryTitle,
                    sub: context.l10n.reminderCategorySub,
                    onTap: () => openType(_TaskType.reminder),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    iconAsset: 'task_routine',
                    title: context.l10n.taskTypeRoutine,
                    sub: context.l10n.taskTypeRoutineSub,
                    onTap: () => openType(_TaskType.routine),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    iconAsset: 'box',
                    title: context.l10n.categoryMeds,
                    sub: context.l10n.addTypeMedsSub,
                    onTap: () => openType(_TaskType.meds),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    iconAsset: 'task_note',
                    title: context.l10n.noteCategoryTitle,
                    sub: context.l10n.noteCategorySub,
                    onTap: () => openType(_TaskType.note),
                  ),
                  const SizedBox(height: 10),
                  _TypeCard(
                    iconAsset: 'task_wellbeing',
                    title: context.l10n.wellbeingTitle,
                    sub: context.l10n.addTypeWellbeingSub,
                    onTap: () => openType(_TaskType.wellbeing),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Простий пікер розділів піра для "Нотатки" (medcard_entry) — на відміну
/// від [showSpacePicker] (читає ЛОКАЛЬНУ таблицю) джерело тут
/// [peerMedcardSectionsProvider]. "Створити розділ" одразу шле
/// medcard_section-пропозицію (Крок 11 #307) і — ЯКЩО пір прийме її раніше,
/// ніж наступний повний синк — новий розділ з'явиться в списку піра вже на
/// наступному відкритті цього пікера (не миттєво, бо запис ще не
/// підтверджений стороною суб'єкта).
Future<MedcardSection?> _showPeerSpacePicker(BuildContext context, WidgetRef ref, PeerSubject peer) {
  final sections = ref.read(peerMedcardSectionsProvider(peer.personUuid));
  return showModalBottomSheet<MedcardSection>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding, AppDimensions.lg, AppDimensions.screenPadding, AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(context.l10n.spacePickerTitle, style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.md),
            if (sections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                child: Text(
                  context.l10n.peerNoSectionsYetBody,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSub),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (_, i) {
                    final s = sections[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AssetIcon(s.iconKey, size: 28),
                      title: Text(s.name, style: AppTextStyles.bodyMd),
                      onTap: () => Navigator.pop(sheetContext, s),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppDimensions.sm),
            TextButton.icon(
              onPressed: () async {
                final created = await Navigator.push<MedcardSection>(
                  sheetContext,
                  MaterialPageRoute(
                    builder: (_) => AddMedcardSectionScreen(
                      onDraftCreated: (draft) async {
                        final uuid = await submitMedcardSectionProposal(ref, peer, draft);
                        if (sheetContext.mounted) {
                          Navigator.pop(
                            sheetContext,
                            MedcardSection(
                              id: peerSyntheticId(uuid),
                              memberId: peerSyntheticId(peer.personUuid),
                              name: draft.name.value,
                              iconKey: draft.iconKey.present ? draft.iconKey.value : 'folder',
                              color: draft.color.present ? draft.color.value : '#4C9A6A',
                              comment: draft.comment.present ? draft.comment.value : null,
                              isDefaultNotes: false,
                              sortOrder: 0,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              syncUuid: uuid,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
                if (created != null && sheetContext.mounted) Navigator.pop(sheetContext, created);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.l10n.createNewSpaceAction),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TypeCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String sub;
  final VoidCallback onTap;

  const _TypeCard({
    required this.iconAsset,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: AssetIcon(iconAsset, size: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSub)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
