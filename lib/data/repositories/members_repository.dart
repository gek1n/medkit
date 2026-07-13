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

  Future<int> delete(int id) =>
      (_db.delete(_db.members)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => _db.delete(_db.members).go();

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
