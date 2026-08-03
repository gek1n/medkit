import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/family_peers_repository.dart';

/// Крок 4.3 плану: автономний член сім'ї (окремий пристрій), якого зараз
/// обрано в перемикачі "переглянути як" — на відміну від
/// `activeMemberIdProvider` (today_providers.dart), який тримає ЛОКАЛЬНИЙ
/// `Members.id`. Обране одне виключає інше: екрани перевіряють спершу
/// [activePeerProvider], і лише якщо він null — падають назад на локальну
/// поведінку через activeMemberIdProvider.
class PeerSubject {
  final String personUuid;
  final String channelId;
  final String name;
  final int avatarIndex;
  const PeerSubject({
    required this.personUuid,
    required this.channelId,
    required this.name,
    required this.avatarIndex,
  });

  @override
  bool operator ==(Object other) => other is PeerSubject && other.personUuid == personUuid;
  @override
  int get hashCode => personUuid.hashCode;
}

final activePeerProvider = StateProvider<PeerSubject?>((_) => null);

/// Стабільний, лише В МЕЖАХ ПЕРЕГЛЯДУ, "локальний" номер для запису піра —
/// справжнього автоінкрементного id в базі не існує (запис ніколи туди не
/// пишеться, це чисто відображення), тож беремо детермінований хеш його
/// syncUuid/personUuid. Досить, щоб картки намалювались і дочірні записи
/// (наприклад запис у Поличці) знайшли свій розділ — писати цим номером у
/// базу не можна й не потрібно, у цьому режимі однаково все лише для
/// перегляду (Крок 4.4 — окреме, справжнє редагування "за іншого").
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

/// [T.fromJson] уже сам вміє ігнорувати зайві ключі (той самий підхід, що й
/// у family_sync_service.dart/family_peer_sync_service.dart при застосуванні
/// вхідних записів) — тож досить дописати синтетичний `id` і будь-які поля,
/// перекладені з ...SyncUuid назад у ...Id, решту бере готовий fromJson.
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

/// completedByMemberId — це РАЗОВЕ повідомлення "хто саме з сім'ї натиснув
/// виконано", а не звʼязок із записом якогось профілю на ЦЬОМУ пристрої
/// (пір ротує чергу поміж людьми, чиї Members-рядки тут узагалі не
/// існують) — коректно розв'язати це до "чийогось" id тут нема як, тож поле
/// свідомо не переносимо (null), а не показуємо оманливо неправильне ім'я.
/// Точна синхронізація "чия черга" — окремий Крок 7 плану.
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
