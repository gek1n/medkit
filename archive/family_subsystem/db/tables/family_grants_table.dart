import 'package:drift/drift.dart';

/// Явний дозвіл/заборона (subject → viewer, permission) — керується
/// ВИКЛЮЧНО пристроєм, що керує subject'ом (власний профіль або локальний
/// dependent, чий менеджер — власник цього пристрою). Ключ — personUuid
/// (Фаза 1), а не локальний id, тому один і той самий запис лишається
/// коректним незалежно від того, звідки прийшов viewer (інший локальний
/// профіль на цьому ж пристрої чи FamilyPeer з іншого пристрою).
///
/// Немає явного рядка = заборонено (deny-by-default,
/// `FamilyVisibilityService._defaultFor`) — щойно приєднаний учасник
/// сімейної групи нічого не бачить і нічого не редагує, поки кожен subject
/// особисто не відкриє йому доступ. Enforcement реальний лише для того, що
/// й так проходить через код, який цю таблицю питає (`FamilySyncService`,
/// UI-гейти) — сама таблиця нічого не шифрує і нікуди не синкається, живе
/// тільки на пристрої-джерелі даних.
class FamilyGrants extends Table {
  TextColumn get subjectPersonUuid => text()();
  TextColumn get viewerPersonUuid => text()();
  TextColumn get permission => text()();
  // 'view' | 'edit' | 'notify' — FamilyPermission.name
  BoolColumn get allowed => boolean()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {subjectPersonUuid, viewerPersonUuid, permission};
}
