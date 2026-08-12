import 'package:drift/drift.dart';

import 'app_database.dart';

/// "Хто створив" (#324) — знімок ідентичності автора запису (Ліки/
/// Нагадування/Рутини/нотатки Поличок). Зберігається в окремій таблиці
/// record_creators (raw SQL, CREATE TABLE IF NOT EXISTS у beforeOpen
/// app_database.dart) замість колонок на самих таблицях — build_runner/
/// drift_dev у поточному середовищі (Dart 3.12.2) не генерує код для
/// app_database.dart взагалі (перевірено: навіть на повністю незміненому
/// вихідному коді drift_dev видає 0 елементів для файлу з @DriftDatabase,
/// тобто codegen тут довелось би патчити вручну в 600КБ згенерованого
/// файлу — надто ризиковано для 4 вже широко використовуваних класів).
/// Raw-SQL шлях через уже наявні customStatement/customSelect обходить
/// codegen повністю.
class CreatorInfo {
  final String? personUuid;
  final String name;
  final int avatarIndex;

  const CreatorInfo({
    required this.personUuid,
    required this.name,
    required this.avatarIndex,
  });
}

/// Ідентичність ВЛАСНИКА цього пристрою (Members.role=='owner') — саме її
/// зберігаємо як автора для будь-якого локального створення, незалежно від
/// того, якому профілю (собі чи залежному) належить сам запис, бо на
/// одному пристрої створювати може лише власник (див. дослідження #324:
/// окремої "хто зараз тисне Зберегти" ідентичності для dependent-профілів
/// у застосунку немає).
Future<CreatorInfo> ownCreatorInfo(AppDatabase db) async {
  final owner = await (db.select(db.members)..where((t) => t.role.equals('owner'))).getSingleOrNull();
  return CreatorInfo(
    personUuid: owner?.personUuid,
    name: owner?.name ?? '',
    avatarIndex: owner?.avatarIndex ?? 0,
  );
}

/// entityType — той самий рядок, що й у record_proposal/family sync
/// (`medication`/`activity`/`doctor_appointment`/`medcard_entry`), щоб
/// (entityType, localId) лишався унікальним у межах усіх 4 таблиць разом.
Future<void> recordCreator(AppDatabase db, String entityType, int localId, CreatorInfo info) async {
  await db.customStatement(
    'INSERT OR REPLACE INTO record_creators '
    '(entity_type, entity_local_id, person_uuid, name, avatar_index) '
    'VALUES (?, ?, ?, ?, ?)',
    [entityType, localId, info.personUuid, info.name, info.avatarIndex],
  );
}

Future<CreatorInfo?> lookupCreator(AppDatabase db, String entityType, int localId) async {
  final rows = await db.customSelect(
    'SELECT person_uuid, name, avatar_index FROM record_creators '
    'WHERE entity_type = ? AND entity_local_id = ?',
    variables: [Variable.withString(entityType), Variable.withInt(localId)],
  ).get();
  if (rows.isEmpty) return null;
  final row = rows.first;
  return CreatorInfo(
    personUuid: row.read<String?>('person_uuid'),
    name: row.read<String>('name'),
    avatarIndex: row.read<int>('avatar_index'),
  );
}
