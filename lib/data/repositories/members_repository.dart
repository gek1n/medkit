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

  Future<bool> update(MembersCompanion member) =>
      _db.update(_db.members).replace(member);

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
}

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(databaseProvider));
});
