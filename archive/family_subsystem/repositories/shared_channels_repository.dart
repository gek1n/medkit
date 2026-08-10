import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../../core/providers/database_provider.dart';

/// Прив'язки member↔channel для family_sync (див. `shared_channels_table.dart`).
class SharedChannelsRepository {
  final AppDatabase _db;
  SharedChannelsRepository(this._db);

  Future<SharedChannel?> forMember(int memberId) =>
      (_db.select(_db.sharedChannels)..where((t) => t.memberId.equals(memberId)))
          .getSingleOrNull();

  Stream<SharedChannel?> watchForMember(int memberId) =>
      (_db.select(_db.sharedChannels)..where((t) => t.memberId.equals(memberId)))
          .watchSingleOrNull();

  Future<List<SharedChannel>> all() => _db.select(_db.sharedChannels).get();

  /// Прив'язує member до каналу, замінюючи попередню прив'язку цього member
  /// (якщо вона була) — напр. при повторному запрошенні з тієї ж картки.
  Future<void> bind({required String channelId, required int memberId}) async {
    await (_db.delete(_db.sharedChannels)..where((t) => t.memberId.equals(memberId))).go();
    await _db.into(_db.sharedChannels).insert(
          SharedChannelsCompanion.insert(channelId: channelId, memberId: memberId),
        );
  }

  Future<void> updateLastSynced(String channelId, DateTime at) =>
      (_db.update(_db.sharedChannels)..where((t) => t.channelId.equals(channelId)))
          .write(SharedChannelsCompanion(lastSyncedAt: Value(at)));

  Future<void> unbind(int memberId) =>
      (_db.delete(_db.sharedChannels)..where((t) => t.memberId.equals(memberId))).go();
}

final sharedChannelsRepositoryProvider = Provider<SharedChannelsRepository>((ref) {
  return SharedChannelsRepository(ref.watch(databaseProvider));
});
