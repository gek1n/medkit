import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/family_status_provider.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';
import '../today/providers/today_providers.dart' show allMembersProvider;

/// Крок 11: автономний член сім'ї (окремий пристрій), якого зараз обрано в
/// перемикачі "переглянути як" — на відміну від `activeMemberIdProvider`
/// (today_providers.dart), який тримає ЛОКАЛЬНИЙ `Members.id`. Обране одне
/// виключає інше: екрани перевіряють спершу [activePeerProvider], і лише
/// якщо він null — падають назад на локальну поведінку через
/// activeMemberIdProvider.
///
/// [accountId]/[publicKeyHex] (нові порівняно з архівною версією) —
/// потрібні лише для дій (proposeEdit/proposeRecord/sendRemoteReminder,
/// `FamilyServerSyncService`), не для самого перегляду — перегляд читає
/// вже розшифрований кеш (SharedEntities), який заповнює синк-сервіс.
class PeerSubject {
  final String personUuid;
  final String channelId;
  final String accountId;
  final String publicKeyHex;
  final String name;
  final int avatarIndex;
  const PeerSubject({
    required this.personUuid,
    required this.channelId,
    required this.accountId,
    required this.publicKeyHex,
    required this.name,
    required this.avatarIndex,
  });

  @override
  bool operator ==(Object other) => other is PeerSubject && other.personUuid == personUuid;
  @override
  int get hashCode => personUuid.hashCode;
}

final activePeerProvider = StateProvider<PeerSubject?>((_) => null);

/// Список автономних пірів для перемикача "переглянути як" — похідне від
/// кешованого `/family/status` ([familyStatusProvider]), а не окремої
/// Drift-таблиці (у Кроці 11 `FamilyPeers`-таблиця для цього більше не
/// потрібна — див. docblock `family_peers_repository.dart`). Один рядок на
/// (сім'я, контрагент каналу) — той самий учасник у двох різних сім'ях
/// (мультисемейність) дав би два різних рядки з різними channelId, це
/// коректно: перегляд завжди прив'язаний до конкретного каналу/сім'ї.
final allFamilyPeersProvider = Provider<List<PeerSubject>>((ref) {
  final status = ref.watch(familyStatusProvider).valueOrNull;
  if (status == null) return const [];
  final result = <PeerSubject>[];
  for (final family in status.families) {
    for (final channel in family.channels) {
      final counterpart = family.members.where((m) => m.accountId == channel.counterpartAccountId).firstOrNull;
      if (counterpart == null) continue;
      result.add(PeerSubject(
        personUuid: counterpart.personUuid,
        channelId: channel.channelId,
        accountId: counterpart.accountId,
        publicKeyHex: counterpart.publicKeyHex,
        name: counterpart.name,
        avatarIndex: counterpart.avatarIndex,
      ));
    }
  }
  return result;
});

/// Агрегований грант конкретного піра (те, що ВІН дозволив МЕНІ) — та сама
/// інформація, що архівна `FamilyPeer.*Granted`, зібрана з
/// `status.grantsToMe` (owner_account_id == peer.accountId, subject_person_uuid
/// == peer.personUuid) замість окремого relay-повідомлення 'grants_summary'.
/// notify пушиться однаковим у всіх 3 секціях ([FamilyServerSyncService.
/// _syncGrants] — не по-секційне право), тож досить взяти з будь-якого рядка.
class PeerGrantSummary {
  final bool notify;
  final bool viewSchedule;
  final bool editSchedule;
  final bool viewMedcard;
  final bool editMedcard;
  final bool viewShelves;
  final bool editShelves;
  const PeerGrantSummary({
    required this.notify,
    required this.viewSchedule,
    required this.editSchedule,
    required this.viewMedcard,
    required this.editMedcard,
    required this.viewShelves,
    required this.editShelves,
  });

  static const empty = PeerGrantSummary(
    notify: false,
    viewSchedule: false,
    editSchedule: false,
    viewMedcard: false,
    editMedcard: false,
    viewShelves: false,
    editShelves: false,
  );
}

final activePeerGrantsProvider = Provider<PeerGrantSummary>((ref) {
  final peer = ref.watch(activePeerProvider);
  if (peer == null) return PeerGrantSummary.empty;
  final status = ref.watch(familyStatusProvider).valueOrNull;
  if (status == null) return PeerGrantSummary.empty;

  bool flagFor(String section, {required bool edit}) {
    return status.grantsToMe.any((g) =>
        g.ownerAccountId == peer.accountId &&
        g.subjectPersonUuid == peer.personUuid &&
        g.section == section &&
        (edit ? g.canEdit : g.canView));
  }

  final notify = status.grantsToMe.any((g) =>
      g.ownerAccountId == peer.accountId && g.subjectPersonUuid == peer.personUuid && g.notify);

  return PeerGrantSummary(
    notify: notify,
    viewSchedule: flagFor('schedule', edit: false),
    editSchedule: flagFor('schedule', edit: true),
    viewMedcard: flagFor('medcard', edit: false),
    editMedcard: flagFor('medcard', edit: true),
    viewShelves: flagFor('shelves', edit: false),
    editShelves: flagFor('shelves', edit: true),
  );
});

/// Крок 7.3 плану: стабільний personUuid ВЛАСНОГО профілю на цьому пристрої
/// (owner, не dependent) — потрібен, щоб пір міг звірити identity в пулі
/// ротації ([PeerActivityAssignee.linkedPeerPersonUuid]/
/// [PeerActivityLogAssignee.identity]) із самим собою і зрозуміти "сьогодні
/// моя черга", а також щоб передати саме це значення назад у
/// submitActivityLogReassignProposal.
final ownPersonUuidProvider = Provider<String?>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? const [];
  return members.where((m) => m.role == 'owner').firstOrNull?.personUuid;
});

// Крок 7.3 плану (архів): shadowMembersProvider ("тіньові" dependent-рядки
// для екрана додавання піра в пул ротації) свідомо НЕ повернено тут —
// MembersRepository.watchShadowMembers()/findOrCreateShadowForPeer() були
// прибрані в Кроці 10.5 разом із рештою "тіньового" механізму. Повернення
// пулу ротації для автономних пірів (Крок 7-подібна функціональність) —
// окремий, ще не запланований шматок Кроку 11, не частина базового
// перегляду (Today/Schedule/Медкартка/Полички).

/// Стабільний, лише В МЕЖАХ ПЕРЕГЛЯДУ, "локальний" номер для запису піра —
/// справжнього автоінкрементного id в базі не існує (запис ніколи туди не
/// пишеться, це чисто відображення), тож беремо детермінований хеш його
/// syncUuid/personUuid. Досить, щоб картки намалювались і дочірні записи
/// (наприклад запис у Поличці) знайшли свій розділ — писати цим номером у
/// базу не можна й не потрібно, у цьому режимі однаково все лише для
/// перегляду (справжнє редагування "за іншого" — окремий шлях через
/// proposeRecord).
int peerSyntheticId(String uuid) => uuid.hashCode & 0x7fffffff;

/// Групування рядків [SharedEntity] по entityType + декодований dataJson —
/// одна підписка на пір, з якої всі типи даних нижче лише читають.
class _PeerSnapshot {
  final Map<String, List<Map<String, dynamic>>> byType;
  const _PeerSnapshot(this.byType);
  List<Map<String, dynamic>> of(String type) => byType[type] ?? const [];
}

final _peerSnapshotProvider = StreamProvider.family<_PeerSnapshot, String>((ref, personUuid) {
  final repo = ref.watch(familyPeersRepositoryProvider);
  return repo.watchSharedEntities(personUuid).map((rows) {
    final byType = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final json = jsonDecode(row.dataJson) as Map<String, dynamic>;
      (byType[row.entityType] ??= <Map<String, dynamic>>[]).add(json);
    }
    return _PeerSnapshot(byType);
  });
});

/// [T.fromJson] уже сам вміє ігнорувати зайві ключі — тож досить дописати
/// синтетичний `id` і будь-які поля, перекладені з ...SyncUuid назад у
/// ...Id, решту бере готовий fromJson.
Map<String, dynamic> _patch(Map<String, dynamic> json, Map<String, dynamic> overrides) =>
    Map<String, dynamic>.from(json)..addAll(overrides);

// ── Ліки та їхні дочірні записи ─────────────────────────────────────────

final peerMedicationsProvider = Provider.family<List<Medication>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('medication').map((json) {
        final uuid = json['uuid'] as String;
        final sectionUuid = json['sectionSyncUuid'] as String?;
        return Medication.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'syncUuid': uuid,
          'sectionId': sectionUuid == null ? null : peerSyntheticId(sectionUuid),
        }));
      }).toList() ??
      const [];
});

final peerSchedulesProvider = Provider.family<List<Schedule>, String>((ref, personUuid) {
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('schedule').map((json) {
        final uuid = json['uuid'] as String;
        final medUuid = json['medicationSyncUuid'] as String;
        return Schedule.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'medicationId': peerSyntheticId(medUuid),
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

final peerIntakesProvider = Provider.family<List<Intake>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('intake').map((json) {
        final uuid = json['uuid'] as String;
        final medUuid = json['medicationSyncUuid'] as String;
        final schedUuid = json['scheduleSyncUuid'] as String;
        return Intake.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'medicationId': peerSyntheticId(medUuid),
          'scheduleId': peerSyntheticId(schedUuid),
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

// ── Рутинні справи та їхні дочірні записи ───────────────────────────────

final peerActivitiesProvider = Provider.family<List<Activity>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('activity').map((json) {
        final uuid = json['uuid'] as String;
        final sectionUuid = json['sectionSyncUuid'] as String?;
        return Activity.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'syncUuid': uuid,
          'sectionId': sectionUuid == null ? null : peerSyntheticId(sectionUuid),
        }));
      }).toList() ??
      const [];
});

final peerActivitySlotsProvider = Provider.family<List<ActivitySlot>, String>((ref, personUuid) {
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('activity_slot').map((json) {
        final uuid = json['uuid'] as String;
        final actUuid = json['activitySyncUuid'] as String;
        return ActivitySlot.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'activityId': peerSyntheticId(actUuid),
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

/// Крок 7.1 плану: пул ротації рутинної справи — на відміну від решти
/// перекладених типів це НЕ Drift-рядок (ActivityAssignees ніколи не має
/// власного syncUuid/updatedAt, весь пул завжди замінюється цілком), тому
/// легкий власний клас, а не .fromJson() наявної моделі.
class PeerActivityAssignee {
  final int activityId;
  final int sortOrder;
  final String name;
  final int avatarIndex;
  final String? linkedPeerPersonUuid;
  const PeerActivityAssignee({
    required this.activityId,
    required this.sortOrder,
    required this.name,
    required this.avatarIndex,
    this.linkedPeerPersonUuid,
  });
}

final peerActivityAssigneesProvider =
    Provider.family<List<PeerActivityAssignee>, String>((ref, personUuid) {
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('activity_assignee').map((json) {
        final actUuid = json['activitySyncUuid'] as String;
        return PeerActivityAssignee(
          activityId: peerSyntheticId(actUuid),
          sortOrder: json['sortOrder'] as int,
          name: json['name'] as String,
          avatarIndex: json['avatarIndex'] as int,
          linkedPeerPersonUuid: json['assigneeLinkedPeerPersonUuid'] as String?,
        );
      }).toList() ??
      const [];
});

/// completedByMemberId — це РАЗОВЕ повідомлення "хто саме з сім'ї натиснув
/// виконано", а не звʼязок із записом якогось профілю на ЦЬОМУ пристрої —
/// коректно розв'язати це до "чийогось" id тут нема як, тож поле свідомо не
/// переносимо (null), а не показуємо оманливо неправильне ім'я.
final peerActivityLogsProvider = Provider.family<List<ActivityLog>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('activity_log').map((json) {
        final uuid = json['uuid'] as String;
        final actUuid = json['activitySyncUuid'] as String;
        return ActivityLog.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'activityId': peerSyntheticId(actUuid),
          'syncUuid': uuid,
          'completedByMemberId': null,
        }));
      }).toList() ??
      const [];
});

/// Крок 7.2 плану: хто ФАКТИЧНО призначений на конкретний вже згенерований
/// день рутини — той самий формат identity, що й у [PeerActivityAssignee]
/// ('m123' для звичайного локального члена subject-а, або personUuid
/// тіньового піра). Звірянням [identity] із власним
/// Members(role=owner).personUuid пір впізнає "сьогодні моя черга".
class PeerActivityLogAssignee {
  final String identity;
  final String? name;
  final int? avatarIndex;
  const PeerActivityLogAssignee({required this.identity, this.name, this.avatarIndex});
}

final peerActivityLogAssigneesProvider =
    Provider.family<Map<int, PeerActivityLogAssignee>, String>((ref, personUuid) {
  final result = <int, PeerActivityLogAssignee>{};
  for (final json in ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('activity_log') ?? const []) {
    final identity = json['assigneeIdentity'] as String?;
    if (identity == null) continue;
    final uuid = json['uuid'] as String;
    result[peerSyntheticId(uuid)] = PeerActivityLogAssignee(
      identity: identity,
      name: json['assigneeName'] as String?,
      avatarIndex: json['assigneeAvatarIndex'] as int?,
    );
  }
  return result;
});

// ── Самопочуття ──────────────────────────────────────────────────────────

final peerWellbeingSchedulesProvider = Provider.family<List<WellbeingSchedule>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('wellbeing_schedule').map((json) {
        final uuid = json['uuid'] as String;
        final sectionUuid = json['sectionSyncUuid'] as String?;
        return WellbeingSchedule.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'syncUuid': uuid,
          'sectionId': sectionUuid == null ? null : peerSyntheticId(sectionUuid),
        }));
      }).toList() ??
      const [];
});

final peerWellbeingLogsProvider = Provider.family<List<WellbeingLog>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('wellbeing_log').map((json) {
        final uuid = json['uuid'] as String;
        return WellbeingLog.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

// ── Нагадування та їхні дочірні записи ───────────────────────────────────

final peerRemindersProvider = Provider.family<List<Reminder>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('doctor_appointment').map((json) {
        final uuid = json['uuid'] as String;
        final sectionUuid = json['sectionSyncUuid'] as String?;
        return Reminder.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'syncUuid': uuid,
          'sectionId': sectionUuid == null ? null : peerSyntheticId(sectionUuid),
        }));
      }).toList() ??
      const [];
});

final peerReminderSlotsProvider = Provider.family<List<ReminderSlot>, String>((ref, personUuid) {
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('reminder_slot').map((json) {
        final uuid = json['uuid'] as String;
        final reminderUuid = json['reminderSyncUuid'] as String;
        return ReminderSlot.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'reminderId': peerSyntheticId(reminderUuid),
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

final peerReminderLogsProvider = Provider.family<List<ReminderLog>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('reminder_log').map((json) {
        final uuid = json['uuid'] as String;
        final reminderUuid = json['reminderSyncUuid'] as String;
        return ReminderLog.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'reminderId': peerSyntheticId(reminderUuid),
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

// ── Полички ──────────────────────────────────────────────────────────────

final peerMedcardSectionsProvider = Provider.family<List<MedcardSection>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('medcard_section').map((json) {
        final uuid = json['uuid'] as String;
        return MedcardSection.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

final peerMedcardEntriesProvider = Provider.family<List<MedcardEntry>, String>((ref, personUuid) {
  final memberId = peerSyntheticId(personUuid);
  return ref.watch(_peerSnapshotProvider(personUuid)).valueOrNull?.of('medcard_entry').map((json) {
        final uuid = json['uuid'] as String;
        final sectionUuid = json['sectionSyncUuid'] as String;
        return MedcardEntry.fromJson(_patch(json, {
          'id': peerSyntheticId(uuid),
          'memberId': memberId,
          'sectionId': peerSyntheticId(sectionUuid),
          'syncUuid': uuid,
        }));
      }).toList() ??
      const [];
});

// ── Похідні провайдери для екранів ──────────────────────────────────────

/// Той самий принцип, що й ActivitiesRepository.watchNoFixedTimeActivityIds
/// (today_providers.dart) — рутина без жодного ActivitySlot вважається
/// "без фіксованого часу". Рахуємо з уже перекладених peer-списків, а не
/// окремим запитом до бази, якої для піра просто не існує.
final peerNoFixedTimeActivityIdsProvider = Provider.family<Set<int>, String>((ref, personUuid) {
  final slotActivityIds =
      ref.watch(peerActivitySlotsProvider(personUuid)).map((s) => s.activityId).toSet();
  return ref
      .watch(peerActivitiesProvider(personUuid))
      .where((a) => a.isActive)
      .map((a) => a.id)
      .where((id) => !slotActivityIds.contains(id))
      .toSet();
});

/// Дзеркало familyMemberTodayProgressProvider (today_providers.dart) для
/// піра — ті самі лічильники "виконано/всього/пропущено" для бейджа в
/// перемикачі "переглянути як", лише джерело даних інше.
final peerTodayProgressProvider =
    Provider.family<({int done, int total, int missed}), String>((ref, personUuid) {
  final intakes = ref.watch(peerIntakesProvider(personUuid));
  final activityLogs = ref.watch(peerActivityLogsProvider(personUuid));
  final noFixedTimeIds = ref.watch(peerNoFixedTimeActivityIdsProvider(personUuid));
  final reminders = {for (final r in ref.watch(peerRemindersProvider(personUuid))) r.id: r}.values;
  final reminderLogs = ref.watch(peerReminderLogsProvider(personUuid));
  final wbSchedule = ref.watch(peerWellbeingSchedulesProvider(personUuid)).firstOrNull;
  final wbLogs = ref.watch(peerWellbeingLogsProvider(personUuid));

  final now = DateTime.now();
  final activeWindowStart = now.subtract(const Duration(minutes: 15));

  var done = 0;
  var total = 0;
  var missed = 0;

  DateTime effectiveDue(Intake i) =>
      i.status == 'snoozed' && i.snoozedUntil != null ? i.snoozedUntil! : i.scheduledAt;

  total += intakes.length;
  done += intakes.where((i) => i.status == 'taken').length;
  missed += intakes
      .where((i) =>
          (i.status == 'pending' || i.status == 'snoozed') &&
          effectiveDue(i).isBefore(activeWindowStart))
      .length;

  final occurrences = reminders.expand((r) {
    if (r.repeatType == 'none') {
      return [(status: r.status, scheduledAt: r.scheduledAt)];
    }
    return reminderLogs
        .where((l) => l.reminderId == r.id)
        .map((l) => (status: l.status, scheduledAt: l.snoozedUntil ?? l.scheduledAt));
  });
  for (final o in occurrences) {
    total++;
    if (o.status == 'attended' || o.status == 'done') done++;
    if (o.status == 'pending' && o.scheduledAt.isBefore(activeWindowStart)) missed++;
  }

  total += activityLogs.length;
  done += activityLogs.where((l) => l.status == 'done' || l.status == 'skipped').length;
  missed += activityLogs
      .where((l) =>
          (l.status == 'pending' || l.status == 'partial') &&
          !noFixedTimeIds.contains(l.activityId) &&
          l.scheduledAt.isBefore(activeWindowStart))
      .length;

  if (wbSchedule != null && wbSchedule.isActive) {
    List<String> times;
    try {
      times = List<String>.from(jsonDecode(wbSchedule.times) as List);
    } catch (_) {
      times = const [];
    }
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final slots = times.map((t) {
      final p = t.split(':');
      return DateTime(today.year, today.month, today.day, int.parse(p[0]), int.parse(p[1]));
    }).toList()
      ..sort();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final windowEnd = i + 1 < slots.length ? slots[i + 1] : endOfDay;
      final hasLog = wbLogs.any((l) =>
          l.loggedAt.isAfter(slot.subtract(const Duration(minutes: 30))) &&
          l.loggedAt.isBefore(windowEnd));
      if (slot.isAfter(now) && !hasLog) continue;
      total++;
      if (hasLog) {
        done++;
      } else if (slot.isBefore(activeWindowStart)) {
        missed++;
      }
    }
  }

  return (done: done, total: total, missed: missed);
});
