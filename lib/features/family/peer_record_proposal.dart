import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/activity_log_generator.dart';
import '../../core/services/family_server_sync_service.dart';
import '../../core/services/intake_generator.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/reminders_repository.dart';
import 'peer_view_providers.dart';

/// Крок 11 (портовано з архівного `peer_record_proposal.dart`, Крок 4.4.4
/// плану): місток між draft-режимом форм створення (`onDraftCreated` в
/// Add*Screen) і синхронізацією (`FamilyServerSyncService.proposeRecord`) —
/// тут, а не в самих екранах форм, щоб кожна з 6 форм лишалась зовсім не
/// обізнаною про Сім'ю: вона просто віддає типізований Companion, а решту
/// (переклад у fields-мапу, пошук sectionSyncUuid, надсилання) робить один
/// спільний шлях.
const _uuid = Uuid();

/// Синтетичний sectionId (peerSyntheticId) → оригінальний sectionSyncUuid
/// цього самого розділу піра — потрібно, бо draft-форма знає лише
/// синтетичний id (взятий із уже перекладеного [MedcardSection] об'єкта),
/// а на дроті записи ідентифікуються справжнім uuid.
String? _sectionSyncUuidFor(WidgetRef ref, PeerSubject peer, int? syntheticSectionId) {
  if (syntheticSectionId == null) return null;
  final sections = ref.read(peerMedcardSectionsProvider(peer.personUuid));
  return sections.where((s) => s.id == syntheticSectionId).firstOrNull?.syncUuid;
}

Future<void> _submit(
  WidgetRef ref,
  PeerSubject peer, {
  required String entityType,
  required String action,
  required String targetUuid,
  DateTime? baseUpdatedAt,
  int? syntheticSectionId,
  required Map<String, dynamic> fields,
}) {
  return FamilyServerSyncService(ref.read(databaseProvider), intakeGenerator: ref.read(intakeGeneratorProvider), activityLogGenerator: ref.read(activityLogGeneratorProvider), remindersRepository: ref.read(remindersRepositoryProvider)).proposeRecord(
    channelId: peer.channelId,
    counterpartPublicKeyHex: peer.publicKeyHex,
    subjectPersonUuid: peer.personUuid,
    entityType: entityType,
    action: action,
    targetUuid: targetUuid,
    baseUpdatedAt: baseUpdatedAt,
    sectionSyncUuid: _sectionSyncUuidFor(ref, peer, syntheticSectionId),
    fields: fields,
  );
}

// ── Companion → fields-мапа (лише present-поля, той самий порядок, що й у
// FamilyServerSyncService._insertRecord/_updateRecordIfUnchanged) ─────────

Map<String, dynamic> _medicationFields(MedicationsCompanion c) {
  final f = <String, dynamic>{};
  if (c.name.present) f['name'] = c.name.value;
  if (c.form.present) f['form'] = c.form.value;
  if (c.doseAmount.present) f['doseAmount'] = c.doseAmount.value;
  if (c.doseUnit.present) f['doseUnit'] = c.doseUnit.value;
  if (c.repeatType.present) f['repeatType'] = c.repeatType.value;
  if (c.repeatConfig.present) f['repeatConfig'] = c.repeatConfig.value;
  if (c.startDate.present) f['startDate'] = c.startDate.value.toIso8601String();
  if (c.endDate.present) f['endDate'] = c.endDate.value?.toIso8601String();
  if (c.totalCount.present) f['totalCount'] = c.totalCount.value;
  if (c.remainingCount.present) f['remainingCount'] = c.remainingCount.value;
  if (c.photoPaths.present) f['photoPaths'] = c.photoPaths.value;
  if (c.instructions.present) f['instructions'] = c.instructions.value;
  if (c.phases.present) f['phases'] = c.phases.value;
  if (c.trackStock.present) f['trackStock'] = c.trackStock.value;
  if (c.stockUnit.present) f['stockUnit'] = c.stockUnit.value;
  if (c.iconKey.present) f['iconKey'] = c.iconKey.value;
  if (c.color.present) f['color'] = c.color.value;
  if (c.sideEffects.present) f['sideEffects'] = c.sideEffects.value;
  return f;
}

Map<String, dynamic> _activityFields(ActivitiesCompanion c) {
  final f = <String, dynamic>{};
  if (c.name.present) f['name'] = c.name.value;
  if (c.durationMin.present) f['durationMin'] = c.durationMin.value;
  if (c.repeatDays.present) f['repeatDays'] = c.repeatDays.value;
  if (c.reminderBeforeMin.present) f['reminderBeforeMin'] = c.reminderBeforeMin.value;
  if (c.color.present) f['color'] = c.color.value;
  if (c.repeatType.present) f['repeatType'] = c.repeatType.value;
  if (c.repeatDayOfMonth.present) f['repeatDayOfMonth'] = c.repeatDayOfMonth.value;
  if (c.repeatIntervalDays.present) f['repeatIntervalDays'] = c.repeatIntervalDays.value;
  if (c.weeklyGoalCount.present) f['weeklyGoalCount'] = c.weeklyGoalCount.value;
  if (c.stepsJson.present) f['stepsJson'] = c.stepsJson.value;
  if (c.tags.present) f['tags'] = c.tags.value;
  if (c.documentPaths.present) f['documentPaths'] = c.documentPaths.value;
  if (c.location.present) f['location'] = c.location.value;
  if (c.iconKey.present) f['iconKey'] = c.iconKey.value;
  return f;
}

Map<String, dynamic> _reminderFields(RemindersCompanion c) {
  final f = <String, dynamic>{};
  if (c.doctorType.present) f['doctorType'] = c.doctorType.value;
  if (c.tags.present) f['tags'] = c.tags.value;
  if (c.location.present) f['location'] = c.location.value;
  if (c.scheduledAt.present) f['scheduledAt'] = c.scheduledAt.value.toIso8601String();
  if (c.remindBeforeMin.present) f['remindBeforeMin'] = c.remindBeforeMin.value;
  if (c.notes.present) f['notes'] = c.notes.value;
  if (c.documentPaths.present) f['documentPaths'] = c.documentPaths.value;
  if (c.color.present) f['color'] = c.color.value;
  if (c.iconKey.present) f['iconKey'] = c.iconKey.value;
  if (c.repeatType.present) f['repeatType'] = c.repeatType.value;
  if (c.repeatConfig.present) f['repeatConfig'] = c.repeatConfig.value;
  return f;
}

Map<String, dynamic> _wellbeingScheduleFields(WellbeingSchedulesCompanion c) {
  final f = <String, dynamic>{};
  if (c.timesPerDay.present) f['timesPerDay'] = c.timesPerDay.value;
  if (c.times.present) f['times'] = c.times.value;
  if (c.isActive.present) f['isActive'] = c.isActive.value;
  if (c.color.present) f['color'] = c.color.value;
  return f;
}

Map<String, dynamic> _medcardSectionFields(MedcardSectionsCompanion c) {
  final f = <String, dynamic>{};
  if (c.name.present) f['name'] = c.name.value;
  if (c.iconKey.present) f['iconKey'] = c.iconKey.value;
  if (c.color.present) f['color'] = c.color.value;
  if (c.comment.present) f['comment'] = c.comment.value;
  return f;
}

Map<String, dynamic> _medcardEntryFields(MedcardEntriesCompanion c) {
  final f = <String, dynamic>{};
  if (c.title.present) f['title'] = c.title.value;
  if (c.recordDate.present) f['recordDate'] = c.recordDate.value.toIso8601String();
  if (c.notes.present) f['notes'] = c.notes.value;
  if (c.tags.present) f['tags'] = c.tags.value;
  if (c.location.present) f['location'] = c.location.value;
  if (c.documentPaths.present) f['documentPaths'] = c.documentPaths.value;
  return f;
}

// ── Публічний API — по одній функції на тип, викликається з onDraftCreated
// відповідного Add*Screen. [existingSyncUuid]/[existingUpdatedAt] непорожні
// = редагування наявного запису піра (compare-and-swap), порожні = новий.

Future<void> submitMedicationProposal(
  WidgetRef ref,
  PeerSubject peer,
  MedicationsCompanion draft, {
  String? existingSyncUuid,
  DateTime? existingUpdatedAt,
  int? syntheticSectionId,
}) {
  return _submit(
    ref,
    peer,
    entityType: 'medication',
    action: existingSyncUuid == null ? 'create' : 'edit',
    targetUuid: existingSyncUuid ?? _uuid.v4(),
    baseUpdatedAt: existingUpdatedAt,
    syntheticSectionId: syntheticSectionId,
    fields: _medicationFields(draft),
  );
}

Future<void> submitActivityProposal(
  WidgetRef ref,
  PeerSubject peer,
  ActivitiesCompanion draft, {
  String? existingSyncUuid,
  DateTime? existingUpdatedAt,
  int? syntheticSectionId,
}) {
  return _submit(
    ref,
    peer,
    entityType: 'activity',
    action: existingSyncUuid == null ? 'create' : 'edit',
    targetUuid: existingSyncUuid ?? _uuid.v4(),
    baseUpdatedAt: existingUpdatedAt,
    syntheticSectionId: syntheticSectionId,
    fields: _activityFields(draft),
  );
}

Future<void> submitReminderProposal(
  WidgetRef ref,
  PeerSubject peer,
  RemindersCompanion draft, {
  String? existingSyncUuid,
  DateTime? existingUpdatedAt,
  int? syntheticSectionId,
  // daily/weekly (кілька разів на день) бере час(и) з окремої дочірньої
  // таблиці ReminderSlots, не з самого draft — без цього переданий тут
  // список часів (widget.onDraftCreated(draft, slotTimes) в
  // AddAppointmentScreen) губився б.
  List<String>? slotTimes,
}) {
  final fields = _reminderFields(draft);
  if (slotTimes != null) fields['slotTimes'] = jsonEncode(slotTimes);
  return _submit(
    ref,
    peer,
    entityType: 'doctor_appointment',
    action: existingSyncUuid == null ? 'create' : 'edit',
    targetUuid: existingSyncUuid ?? _uuid.v4(),
    baseUpdatedAt: existingUpdatedAt,
    syntheticSectionId: syntheticSectionId,
    fields: fields,
  );
}

Future<void> submitWellbeingScheduleProposal(
  WidgetRef ref,
  PeerSubject peer,
  WellbeingSchedulesCompanion draft, {
  String? existingSyncUuid,
  DateTime? existingUpdatedAt,
  int? syntheticSectionId,
}) {
  return _submit(
    ref,
    peer,
    entityType: 'wellbeing_schedule',
    action: existingSyncUuid == null ? 'create' : 'edit',
    targetUuid: existingSyncUuid ?? _uuid.v4(),
    baseUpdatedAt: existingUpdatedAt,
    syntheticSectionId: syntheticSectionId,
    fields: _wellbeingScheduleFields(draft),
  );
}

/// На відміну від решти submit*Proposal — повертає щойно згенерований
/// targetUuid (не void), щоб викликач міг одразу передати його як
/// sectionSyncUuid у submitMedcardEntryProposal У ТОМУ Ж потоці "створити
/// розділ і одразу додати запис" (той самий UX, що й локально в
/// showSpacePicker), не чекаючи, поки новий розділ повернеться назад через
/// повний раунд синку — сервер зберігає обидві пропозиції за чергою
/// надсилання, subject застосовує їх у тому самому порядку.
Future<String> submitMedcardSectionProposal(
  WidgetRef ref,
  PeerSubject peer,
  MedcardSectionsCompanion draft,
) async {
  final targetUuid = _uuid.v4();
  await _submit(
    ref,
    peer,
    entityType: 'medcard_section',
    action: 'create',
    targetUuid: targetUuid,
    fields: _medcardSectionFields(draft),
  );
  return targetUuid;
}

Future<void> submitMedcardEntryProposal(
  WidgetRef ref,
  PeerSubject peer,
  MedcardEntriesCompanion draft, {
  String? existingSyncUuid,
  DateTime? existingUpdatedAt,
  required int syntheticSectionId,
}) {
  return _submit(
    ref,
    peer,
    entityType: 'medcard_entry',
    action: existingSyncUuid == null ? 'create' : 'edit',
    targetUuid: existingSyncUuid ?? _uuid.v4(),
    baseUpdatedAt: existingUpdatedAt,
    syntheticSectionId: syntheticSectionId,
    fields: _medcardEntryFields(draft),
  );
}

/// Крок 11 (#310): передати чергу в рутинній справі — на відміну від решти
/// submit*Proposal вище тут немає draft-форми/Companion (реквест іде з
/// картки конкретного дня, не з екрана редагування), тож targetUuid/
/// baseUpdatedAt беруться напряму з уже перекладеного [ActivityLog] піра
/// ([syncUuid]/[updatedAt]), а не генеруються/приходять опційно —
/// action тут завжди 'edit' (лог завжди вже згенеровано на боці subject-а,
/// "створити" для цього типу не буває). Свідомо лише "взяти на себе" —
/// довільний обмін чергою між ДВОМА іншими людьми з боку піра не
/// підтримується (той самий скоуп, що й в архівній версії).
Future<void> submitActivityLogReassignProposal(
  WidgetRef ref,
  PeerSubject peer, {
  required String syncUuid,
  required DateTime updatedAt,
  required String assigneeIdentity,
}) {
  return _submit(
    ref,
    peer,
    entityType: 'activity_log',
    action: 'edit',
    targetUuid: syncUuid,
    baseUpdatedAt: updatedAt,
    fields: {'assigneeIdentity': assigneeIdentity},
  );
}
