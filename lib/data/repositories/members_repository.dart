import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

class MembersRepository {
  final AppDatabase _db;
  MembersRepository(this._db);

  Stream<List<Member>> watchAll() =>
      _db.select(_db.members).watch();

  Future<Member?> getById(int id) =>
      (_db.select(_db.members)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<Member?> getOwner() =>
      (_db.select(_db.members)..where((t) => t.role.equals('owner')))
          .getSingleOrNull();

  Future<int> insert(MembersCompanion member) =>
      _db.into(_db.members).insert(member);

  Future<bool> update(MembersCompanion member) =>
      _db.update(_db.members).replace(member);

  Future<int> delete(int id) =>
      (_db.delete(_db.members)..where((t) => t.id.equals(id))).go();

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
