import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/notification_service.dart';

class MembersRepository {
  final AppDatabase _db;
  MembersRepository(this._db);
  static const _uuid = Uuid();

  // linkedPeerPersonUuid IS NULL — "тіньові" рядки (Крок 7.1 плану, пул
  // ротації автономного піра) не є реальними профілями і не повинні
  // з'являтись у жодному з місць, де watchAll() уже використовується
  // (перемикачі "хто зараз активний", список Сім'ї тощо). Хто саме в пулі
  // конкретної рутини (включно з тіньовими рядками) читається окремо, через
  // ActivitiesRepository.getAssignees/watchAssignees за FK, не через цей метод.
  // sortOrder — драг-н-дроп на екрані Сім'я; id — стабільний tiebreak для
  // тих, хто ще на дефолтних 0 (порядок створення, той самий, що й до
  // появи sortOrder). Власник лишається на дефолтних 0 і сортується першим
  // природно — реордер серед залежних профілів рахує з 1, див. reorder().
  Stream<List<Member>> watchAll() => (_db.select(_db.members)
        ..where((t) => t.linkedPeerPersonUuid.isNull())
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
      .watch();

  Future<Member?> getById(int id) =>
      (_db.select(_db.members)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<Member?> getOwner() =>
      (_db.select(_db.members)..where((t) => t.role.equals('owner')))
          .getSingleOrNull();

  // Кожен профіль — новий чи мігрований зі старої версії — повинен мати
  // стабільний personUuid; жоден із наявних call site-ів це не задає
  // явно, тож підставляємо тут централізовано, щоб не забути десь один.
  //
  // Новий залежний профіль (не owner, не тіньовий рядок піра) додається в
  // КІНЕЦЬ поточного порядку драг-н-дропу (sortOrder = кількість уже
  // існуючих залежних + 1) — інакше він default-ним 0 "перестрибнув" би
  // на початок списку разом із власником. Owner/тіньові рядки лишаються
  // на дефолтних 0 — перший завжди сортується першим природно, а тіньові
  // рядки взагалі не потрапляють у жоден sortOrder-based список
  // (watchAll() їх виключає).
  Future<int> insert(MembersCompanion member) async {
    var toInsert = member.personUuid.present ? member : member.copyWith(personUuid: Value(_uuid.v4()));
    final isRealDependent = !member.role.present || member.role.value != 'owner';
    if (isRealDependent && !member.sortOrder.present && !member.linkedPeerPersonUuid.present) {
      final count = await (_db.select(_db.members)
            ..where((t) => t.linkedPeerPersonUuid.isNull() & t.role.equals('dependent')))
          .get()
          .then((rows) => rows.length);
      toInsert = toInsert.copyWith(sortOrder: Value(count + 1));
    }
    return _db.into(_db.members).insert(toInsert);
  }

  /// Викликати з нового порядку id-шників (лише залежні профілі, БЕЗ
  /// власника — той ніколи не входить у драг-н-дроп) після реордеру на
  /// екрані Сім'я. Рахуємо з 1, а не з 0 — щоб жоден залежний профіль не
  /// міг зрівнятись/обігнати власника (лишається на дефолтних 0) у
  /// перемикачах, де owner має завжди йти першим.
  Future<void> reorder(List<int> orderedDependentIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedDependentIds.length; i++) {
        await (_db.update(_db.members)..where((t) => t.id.equals(orderedDependentIds[i])))
            .write(MembersCompanion(sortOrder: Value(i + 1)));
      }
    });
  }

  // ⚠️ Навмисно НЕ .replace() — той вимагає всі required-колонки (напр.
  // name) присутніми в companion, а більшість викликів тут — часткові
  // оновлення (лише fontSize, лише role тощо). .write() з явним where
  // оновлює лише передані поля, решта рядка лишається незмінною.
  Future<bool> update(MembersCompanion member) async {
    final rows = await (_db.update(_db.members)
          ..where((t) => t.id.equals(member.id.value)))
        .write(member);
    return rows > 0;
  }

  // ⚠️ Явне каскадне видалення в транзакції — не покладаємось лише на
  // ON DELETE CASCADE у схемі. Той FK-звʼязок задекларований для всіх
  // таблиць нижче, але на пристроях, чия локальна база пройшла через
  // кілька версій міграцій, обмеження могло фізично не застосуватись до
  // вже наявних рядків (SQLite не завжди ретроактивно перебудовує FK при
  // ALTER TABLE) — тоді видалення профілю мовчки лишало б усю його
  // історію (ліки, аналізи, самопочуття, візити тощо) висіти в базі
  // назавжди. sharedChannels/FamilyPeers тут навмисно НЕ займаємо —
  // синхронізацію прибирає окремо [FamilySyncService.deleteMemberEverywhere],
  // виклик якого йде ДО цього методу на обох call site-ах (Сім'я,
  // Конфіденційність).
  Future<int> delete(int id) async {
    // ⚠️ Заплановані OS-нагадування (zonedSchedule) живуть незалежно від БД
    // — видалення рядків нижче саме по собі їх не скасовує. Той самий факт
    // уже враховано для повного логауту (NotificationService.cancelAll()
    // перед deleteAll(), profile_screen.dart), але видалення ОДНОГО
    // профілю трьома різними викликачами (Сім'я, Конфіденційність,
    // конверсія "Локальний→Автономний") про це мовчало — нагадування
    // видаленого профілю продовжували спрацьовувати. Ідентифікатори
    // нагадувань виводяться з id рядків (intakeId/activityLogId/...), тож
    // збираємо їх ДО видалення, поки вони ще існують.
    final intakeIds = (await (_db.select(_db.intakes)..where((t) => t.memberId.equals(id))).get())
        .map((i) => i.id)
        .toList();
    final activityLogIds =
        (await (_db.select(_db.activityLogs)..where((t) => t.memberId.equals(id))).get())
            .map((l) => l.id)
            .toList();
    final appointmentIds =
        (await (_db.select(_db.reminders)..where((t) => t.memberId.equals(id))).get())
            .map((a) => a.id)
            .toList();
    final medIdsForNotify =
        (await (_db.select(_db.medications)..where((t) => t.memberId.equals(id))).get())
            .map((m) => m.id)
            .toList();

    final result = await _db.transaction(() async {
      final medIds = (await (_db.select(_db.medications)
                ..where((t) => t.memberId.equals(id)))
              .get())
          .map((m) => m.id)
          .toList();
      if (medIds.isNotEmpty) {
        await (_db.delete(_db.schedules)..where((t) => t.medicationId.isIn(medIds))).go();
        await (_db.delete(_db.symptoms)..where((t) => t.medicationId.isIn(medIds))).go();
      }
      await (_db.delete(_db.medications)..where((t) => t.memberId.equals(id))).go();

      final activityIds = (await (_db.select(_db.activities)
                ..where((t) => t.memberId.equals(id)))
              .get())
          .map((a) => a.id)
          .toList();
      if (activityIds.isNotEmpty) {
        await (_db.delete(_db.activitySlots)..where((t) => t.activityId.isIn(activityIds))).go();
      }
      await (_db.delete(_db.activityLogs)..where((t) => t.memberId.equals(id))).go();
      await (_db.delete(_db.activities)..where((t) => t.memberId.equals(id))).go();

      await (_db.delete(_db.intakes)..where((t) => t.memberId.equals(id))).go();
      await (_db.delete(_db.reminders)..where((t) => t.memberId.equals(id))).go();
      await (_db.delete(_db.wellbeingLogs)..where((t) => t.memberId.equals(id))).go();
      await (_db.delete(_db.wellbeingSchedules)..where((t) => t.memberId.equals(id))).go();

      return (_db.delete(_db.members)..where((t) => t.id.equals(id))).go();
    });

    for (final i in intakeIds) {
      await NotificationService.cancelIntakeReminder(i);
    }
    for (final l in activityLogIds) {
      await NotificationService.cancelActivityReminder(l);
    }
    for (final a in appointmentIds) {
      await NotificationService.cancelAppointmentReminder(a);
    }
    for (final m in medIdsForNotify) {
      await NotificationService.cancel(NotificationService.lowStockNotificationId(m));
    }
    await NotificationService.cancelAllWellbeingForMember(id);

    return result;
  }

  // Той самий ризик, що й у [delete] — не покладаємось на ON DELETE CASCADE.
  Future<void> deleteAll() => _db.transaction(() async {
        await _db.delete(_db.schedules).go();
        await _db.delete(_db.symptoms).go();
        await _db.delete(_db.medications).go();
        await _db.delete(_db.activitySlots).go();
        await _db.delete(_db.activityLogs).go();
        await _db.delete(_db.activities).go();
        await _db.delete(_db.intakes).go();
        await _db.delete(_db.reminders).go();
        await _db.delete(_db.wellbeingLogs).go();
        await _db.delete(_db.wellbeingSchedules).go();
        await _db.delete(_db.members).go();
      });

  Future<void> ensureOwnerExists(String name) async {
    final owner = await getOwner();
    if (owner == null) {
      await insert(MembersCompanion.insert(
        name: name,
        role: const Value('owner'),
      ));
    }
  }

  /// Самовідновлення: якщо серед наявних локальних профілів немає жодного
  /// з role='owner' (пошкоджені дані — не мало так бути, але онбординг/join
  /// мають створювати owner завжди), підвищуємо найдавніший профіль до
  /// owner, а не додаємо новий рядок. Інакше власний профіль користувача
  /// назавжди застрягає в гілках коду "не owner" — видно чужі дії
  /// (запросити/видалити/переглянути як) на своїй же картці в Сім'ї, і
  /// бейдж "пропущено", розрахований лише для не-owner.
  /// Не займається множинними owner — той сценарій виявляє [getOwner]
  /// сам (кидає виняток), це окрема, серйозніша проблема даних.
  Future<void> ensureOwnerRole() async {
    final owner = await getOwner();
    if (owner != null) return;
    final all = await _db.select(_db.members).get();
    if (all.isEmpty) return;
    all.sort((a, b) => a.id.compareTo(b.id));
    await update(MembersCompanion(id: Value(all.first.id), role: const Value('owner')));
  }

  /// Відновлено для #318/#325-доробки (Крок 7.1 плану ввів це вперше;
  /// Крок 10.5 прибрав разом ІЗ РЕШТОЮ карантину; Крок 11 повернув усе
  /// пірове, КРІМ саме цього — окремо позначено там "ще не заплановано").
  /// Знаходить "тіньовий" локальний рядок, що представляє автономного
  /// піра в пулі виконавців (ActivityAssignees.memberId — FK лише на
  /// реальні рядки Members, тому пір без такого рядка в пул не потрапить),
  /// або створює новий. Ім'я/аватар оновлюються, якщо пір їх змінив.
  Future<int> findOrCreateShadowForPeer(
    String personUuid, {
    required String name,
    required int avatarIndex,
  }) async {
    final existing = await (_db.select(_db.members)
          ..where((t) => t.linkedPeerPersonUuid.equals(personUuid)))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.name != name || existing.avatarIndex != avatarIndex) {
        await update(MembersCompanion(
          id: Value(existing.id),
          name: Value(name),
          avatarIndex: Value(avatarIndex),
        ));
      }
      return existing.id;
    }
    return insert(MembersCompanion.insert(
      name: name,
      avatarIndex: Value(avatarIndex),
      role: const Value('dependent'),
      linkedPeerPersonUuid: Value(personUuid),
    ));
  }

}

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(databaseProvider));
});

/// Запускається один раз при старті застосунку, перед тим як показати
/// онбординг чи основний UI — див. [MembersRepository.ensureOwnerRole].
final ensureOwnerRoleProvider = FutureProvider<void>((ref) {
  return ref.watch(membersRepositoryProvider).ensureOwnerRole();
});
