import 'package:drift/drift.dart';
import 'members_table.dart';

/// Прив'язка локального члена сім'ї (Members.id) до каналу пейрингу, через
/// який іде бідирекційна синхронізація його даних (family_sync) з іншим
/// пристроєм тієї ж людини (напр. телефон Тата, привʼязаний до профілю
/// "Тато" на телефоні Сина). Один канал — один член сім'ї (v1-обмеження,
/// задокументоване в плані: другий одночасний доглядач — майбутня задача).
class SharedChannels extends Table {
  TextColumn get channelId => text()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade).unique()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {channelId};
}
