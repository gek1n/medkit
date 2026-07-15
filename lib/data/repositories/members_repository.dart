import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class MembersRepository {
  final AppDatabase _db;
  MembersRepository(this._db);
  static const _uuid = Uuid();

  Stream<List<Member>> watchAll() =>
      _db.select(_db.members).watch();

  Future<Member?> getById(int id) =>
      (_db.select(_db.members)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<Member?> getOwner() =>
      (_db.select(_db.members)..where((t) => t.role.equals('owner')))
          .getSingleOrNull();

  // Кожен профіль — новий чи мігрований зі старої версії — повинен мати
  // стабільний personUuid; жоден із наявних call site-ів це не задає
  // явно, тож підставляємо тут централізовано, щоб не забути десь один.
  Future<int> insert(MembersCompanion member) {
    final withUuid = member.personUuid.present ? member : member.copyWith(personUuid: Value(_uuid.v4()));
    return _db.into(_db.members).insert(withUuid);
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
  Future<int> delete(int id) => _db.transaction(() async {
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
        await (_db.delete(_db.doctorAppointments)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.labResults)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.allergies)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.chronicConditions)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.vaccinations)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.surgeries)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.wellbeingLogs)..where((t) => t.memberId.equals(id))).go();
        await (_db.delete(_db.wellbeingSchedules)..where((t) => t.memberId.equals(id))).go();

        return (_db.delete(_db.members)..where((t) => t.id.equals(id))).go();
      });

  // Той самий ризик, що й у [delete] — не покладаємось на ON DELETE CASCADE.
  Future<void> deleteAll() => _db.transaction(() async {
        await _db.delete(_db.schedules).go();
        await _db.delete(_db.symptoms).go();
        await _db.delete(_db.medications).go();
        await _db.delete(_db.activitySlots).go();
        await _db.delete(_db.activityLogs).go();
        await _db.delete(_db.activities).go();
        await _db.delete(_db.intakes).go();
        await _db.delete(_db.doctorAppointments).go();
        await _db.delete(_db.labResults).go();
        await _db.delete(_db.allergies).go();
        await _db.delete(_db.chronicConditions).go();
        await _db.delete(_db.vaccinations).go();
        await _db.delete(_db.surgeries).go();
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
}

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(databaseProvider));
});

/// Запускається один раз при старті застосунку, перед тим як показати
/// онбординг чи основний UI — див. [MembersRepository.ensureOwnerRole].
final ensureOwnerRoleProvider = FutureProvider<void>((ref) {
  return ref.watch(membersRepositoryProvider).ensureOwnerRole();
});
