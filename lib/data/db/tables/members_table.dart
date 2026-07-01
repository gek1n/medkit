import 'package:drift/drift.dart';

class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get avatarIndex => integer().withDefault(const Constant(0))();
  TextColumn get role => text().withDefault(const Constant('member'))();
  // owner / member / dependent
  IntColumn get fontSize => integer().withDefault(const Constant(2))();
  // 1=small 2=normal 3=large 4=xlarge
  TextColumn get accessType => text().nullable()();
  // link / code / none — тільки для dependent
  TextColumn get accessCode => text().nullable()();
  TextColumn get telegramChatId => text().nullable()();
  TextColumn get notificationChannels =>
      text().withDefault(const Constant('["push"]'))();
  // json: ["push","telegram","sms"]
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
