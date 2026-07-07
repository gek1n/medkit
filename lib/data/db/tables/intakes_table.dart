import 'package:drift/drift.dart';
import 'schedules_table.dart';
import 'medications_table.dart';
import 'members_table.dart';

class Intakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleId =>
      integer().references(Schedules, #id, onDelete: KeyAction.cascade)();
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();
  IntColumn get memberId =>
      integer().references(Members, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  // pending/taken/skipped/snoozed
  DateTimeColumn get takenAt => dateTime().nullable()();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // для синхронізації — коли рядок востаннє змінювався локально
  TextColumn get syncUuid => text().nullable().unique()();
  // для family_sync — див. коментар у medications_table.dart
}
