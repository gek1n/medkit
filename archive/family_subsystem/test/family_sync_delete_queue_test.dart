import 'package:flutter_test/flutter_test.dart';
import 'package:medkit/core/services/family_sync_delete_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue then pendingForChannel returns the item', () async {
    await FamilySyncDeleteQueue.enqueue(
      channelId: 'chan-1',
      entityType: 'schedule',
      syncUuid: 'uuid-1',
    );

    final pending = await FamilySyncDeleteQueue.pendingForChannel('chan-1');
    expect(pending, hasLength(1));
    expect(pending.first['entityType'], 'schedule');
    expect(pending.first['syncUuid'], 'uuid-1');
  });

  test('pendingForChannel only returns items for the requested channel', () async {
    await FamilySyncDeleteQueue.enqueue(channelId: 'chan-1', entityType: 'schedule', syncUuid: 'uuid-1');
    await FamilySyncDeleteQueue.enqueue(channelId: 'chan-2', entityType: 'intake', syncUuid: 'uuid-2');

    final pending = await FamilySyncDeleteQueue.pendingForChannel('chan-1');
    expect(pending, hasLength(1));
    expect(pending.first['syncUuid'], 'uuid-1');
  });

  test('enqueue twice for the same item does not duplicate it', () async {
    await FamilySyncDeleteQueue.enqueue(channelId: 'chan-1', entityType: 'schedule', syncUuid: 'uuid-1');
    await FamilySyncDeleteQueue.enqueue(channelId: 'chan-1', entityType: 'schedule', syncUuid: 'uuid-1');

    final pending = await FamilySyncDeleteQueue.pendingForChannel('chan-1');
    expect(pending, hasLength(1));
  });

  test('clear removes the item', () async {
    await FamilySyncDeleteQueue.enqueue(channelId: 'chan-1', entityType: 'schedule', syncUuid: 'uuid-1');
    await FamilySyncDeleteQueue.clear(channelId: 'chan-1', entityType: 'schedule', syncUuid: 'uuid-1');

    final pending = await FamilySyncDeleteQueue.pendingForChannel('chan-1');
    expect(pending, isEmpty);
  });
}
