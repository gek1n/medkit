import 'package:drift/drift.dart';
import 'members_table.dart';

class WellbeingSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  IntColumn get timesPerDay =>
      integer().withDefault(const Constant(2))();
  // 1/2/3
  TextColumn get times =>
      text().withDefault(const Constant('["08:00","20:00"]'))();
  // json: ["08:00","13:00","20:00"]
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
