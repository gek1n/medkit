import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db/app_database.dart';

// Реальний баг (07.08): 'edit' тут раніше був ОКРЕМИМ, майстер-гейтом для
// прийому edit_proposal/record_proposal — але жоден екран не перевіряв цей
// прапорець при рендері кнопок редагування (лише секційні
// edit*Granted), тож глядач міг бачити олівець/FAB, надіслати правку — і
// вона мовчки відхилялась через оцей ЗОВСІМ окремий, невидимий у своєму ж
// UI прапорець. Прибрано — тепер єдине джерело правди для "може
// редагувати" це секційний edit (isSectionAllowed), той самий, що й
// показує/ховає кнопки редагування у самих екранах.
enum FamilyPermission { notify, view }

/// Крок 4.1 плану: розділи, для яких перегляд/редагування видаються ОКРЕМО
/// один від одного, а не одним спільним перемикачем на всю людину.
/// Полички (shelves) додано в Кроку 4.3.4, коли самі Полички вже
/// синхронізуються (Крок 5.1) — до того перемикач для них не мав би на що
/// впливати.
enum FamilySection { schedule, medcard, shelves }

class FamilyGrantDeniedException implements Exception {
  final String message;
  const FamilyGrantDeniedException(this.message);
  @override
  String toString() => message;
}

/// Дозволи видимості між учасниками сім'ї — ключ (subjectPersonUuid,
/// viewerPersonUuid), а не локальний id, тож один і той самий запис
/// коректний незалежно від того, звідки прийшов viewer (інший локальний
/// профіль на цьому ж пристрої чи автономний учасник сім'ї на своєму
/// пристрої, Крок 11).
///
/// [setAllowed] можна викликати лише для subject'а, яким керує ЦЕЙ
/// пристрій (власний профіль або локальний dependent) — суб'єкт сам
/// визначає власну видимість; ніхто не вирішує за незалежного учасника.
/// Для медкартки цей сервіс — реальний бар'єр: `FamilyServerSyncService.
/// _pushToChannel()` перевіряє [isMedcardSyncAllowed] локально, на
/// пристрої-джерелі, ПЕРЕД формуванням payload — а не лише ховає дані в
/// інтерфейсі отримувача.
class FamilyVisibilityService {
  /// Дефолт, коли явного запису в [FamilyGrants] немає: завжди `false` —
  /// notify/edit/view. Щойно приєднаний учасник сімейної групи не отримує
  /// сповіщень, не бачить завдань/медкартки й не може нічого редагувати НІ
  /// В КОГО, поки кожен існуючий учасник особисто не відкриє йому доступ у
  /// "Конфіденційність → Видимість для сім'ї". Видимість — завжди явний
  /// opt-in з боку subject'а (чи його менеджера для dependent-профілю),
  /// ніколи не вмикається сама по собі фактом приєднання до групи.
  static bool _defaultFor(FamilyPermission permission) => false;

  static Future<bool> isAllowed(
    AppDatabase db,
    String subjectPersonUuid,
    String viewerPersonUuid,
    FamilyPermission permission,
  ) async {
    final row = await (db.select(db.familyGrants)
          ..where((t) =>
              t.subjectPersonUuid.equals(subjectPersonUuid) &
              t.viewerPersonUuid.equals(viewerPersonUuid) &
              t.permission.equals(permission.name)))
        .getSingleOrNull();
    if (row != null) return row.allowed;
    return _defaultFor(permission);
  }

  /// Кидає [FamilyGrantDeniedException], якщо [subjectPersonUuid] не є
  /// профілем, яким керує цей пристрій (перевірка "субʼєкт керує власною
  /// видимістю сам").
  static Future<void> setAllowed(
    AppDatabase db, {
    required String subjectPersonUuid,
    required String viewerPersonUuid,
    required FamilyPermission permission,
    required bool value,
  }) async {
    final subject = await (db.select(db.members)
          ..where((t) => t.personUuid.equals(subjectPersonUuid)))
        .getSingleOrNull();
    if (subject == null) {
      throw const FamilyGrantDeniedException(
        'Можна керувати видимістю лише власного профілю чи локальних учасників, яких ви ведете',
      );
    }
    await db.into(db.familyGrants).insertOnConflictUpdate(
          FamilyGrantsCompanion.insert(
            subjectPersonUuid: subjectPersonUuid,
            viewerPersonUuid: viewerPersonUuid,
            permission: permission.name,
            allowed: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  // ── Крок 4.1: перегляд/редагування по кожному розділу окремо ────────────
  // Технічно це той самий FamilyGrants.permission (звичайна text-колонка,
  // без enum на рівні БД) — нові значення виду "view_schedule"/"edit_medcard"
  // просто лягають поряд зі старими "view"/"edit"/"notify" під тим самим
  // ключем (subjectPersonUuid, viewerPersonUuid, permission), тому міграція
  // схеми для цього не потрібна.
  static String _sectionKey(FamilySection section, {required bool edit}) =>
      '${edit ? 'edit' : 'view'}_${section.name}';

  /// Якщо для цього розділу ще ніхто явно нічого не налаштовував —
  /// відкочуємось до старого спільного view/edit (те, що діяло до появи
  /// розбивки по розділах), а не до "заборонено за замовчуванням": інакше
  /// той, хто вже відкрив доступ до появи цього кроку, раптово втратив би
  /// його, поки суб'єкт сам не зайде і не торкнеться нового екрана.
  static Future<bool> isSectionAllowed(
    AppDatabase db,
    String subjectPersonUuid,
    String viewerPersonUuid,
    FamilySection section, {
    required bool edit,
  }) async {
    final row = await (db.select(db.familyGrants)
          ..where((t) =>
              t.subjectPersonUuid.equals(subjectPersonUuid) &
              t.viewerPersonUuid.equals(viewerPersonUuid) &
              t.permission.equals(_sectionKey(section, edit: edit))))
        .getSingleOrNull();
    if (row != null) return row.allowed;
    // edit більше нема куди відкочуватись (загальний FamilyPermission.edit
    // прибрано 07.08 разом із самим правом) — безпечний дефолт: не
    // редагувати, поки секцію явно не налаштували.
    if (edit) return false;
    // view — спершу відкочуємось до старого спільного "view" (те, що діяло
    // до появи розбивки по розділах), ЯКЩО хтось його колись явно
    // виставляв — так вже зроблений вибір існуючих користувачів лишається
    // недоторканим. Лише коли взагалі ніхто нічого не налаштовував (нова
    // пара subject/viewer) — #323: новий дефолт Перегляд=ON замість
    // колишнього opt-in-за-замовчуванням false.
    final legacyRow = await (db.select(db.familyGrants)
          ..where((t) =>
              t.subjectPersonUuid.equals(subjectPersonUuid) &
              t.viewerPersonUuid.equals(viewerPersonUuid) &
              t.permission.equals(FamilyPermission.view.name)))
        .getSingleOrNull();
    if (legacyRow != null) return legacyRow.allowed;
    return true;
  }

  // ── #323: 'create' — третій, незалежний від view/edit грант: дозволяє
  // ОДНОБІЧНО штовхати НОВІ записи суб'єкту (record_proposal
  // action=='create'), не даючи бачити чи змінювати вже наявні чужі
  // записи (те й далі керується view/edit вище). Новий формат картки
  // Видимість показує три перемикачі на кожен розділ; для НОВОГО
  // subject/viewer — Створення=ON і Перегляд=ON за замовчуванням,
  // Редагування=OFF (узгоджено з користувачем 12.08).
  static String _createKey(FamilySection section) => 'create_${section.name}';

  static Future<bool> isCreateAllowed(
    AppDatabase db,
    String subjectPersonUuid,
    String viewerPersonUuid,
    FamilySection section,
  ) async {
    final row = await (db.select(db.familyGrants)
          ..where((t) =>
              t.subjectPersonUuid.equals(subjectPersonUuid) &
              t.viewerPersonUuid.equals(viewerPersonUuid) &
              t.permission.equals(_createKey(section))))
        .getSingleOrNull();
    if (row != null) return row.allowed;
    return true;
  }

  /// Кидає [FamilyGrantDeniedException] за тим самим правилом, що й
  /// [setAllowed].
  static Future<void> setCreateAllowed(
    AppDatabase db, {
    required String subjectPersonUuid,
    required String viewerPersonUuid,
    required FamilySection section,
    required bool value,
  }) async {
    final subject = await (db.select(db.members)
          ..where((t) => t.personUuid.equals(subjectPersonUuid)))
        .getSingleOrNull();
    if (subject == null) {
      throw const FamilyGrantDeniedException(
        'Можна керувати видимістю лише власного профілю чи локальних учасників, яких ви ведете',
      );
    }
    await db.into(db.familyGrants).insertOnConflictUpdate(
          FamilyGrantsCompanion.insert(
            subjectPersonUuid: subjectPersonUuid,
            viewerPersonUuid: viewerPersonUuid,
            permission: _createKey(section),
            allowed: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Кидає [FamilyGrantDeniedException] за тим самим правилом, що й
  /// [setAllowed].
  static Future<void> setSectionAllowed(
    AppDatabase db, {
    required String subjectPersonUuid,
    required String viewerPersonUuid,
    required FamilySection section,
    required bool edit,
    required bool value,
  }) async {
    final subject = await (db.select(db.members)
          ..where((t) => t.personUuid.equals(subjectPersonUuid)))
        .getSingleOrNull();
    if (subject == null) {
      throw const FamilyGrantDeniedException(
        'Можна керувати видимістю лише власного профілю чи локальних учасників, яких ви ведете',
      );
    }
    await db.into(db.familyGrants).insertOnConflictUpdate(
          FamilyGrantsCompanion.insert(
            subjectPersonUuid: subjectPersonUuid,
            viewerPersonUuid: viewerPersonUuid,
            permission: _sectionKey(section, edit: edit),
            allowed: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  // ── Синхронізація медкартки на інші пристрої сім'ї ─────────────────────
  // Той самий принцип, що й isAllowed вище, але без матриці viewer'ів —
  // єдиний прапорець "пускати медкартку цього профілю за межі пристрою
  // взагалі". FamilyServerSyncService._pushToChannel() перевіряє це ПЕРЕД
  // формуванням payload — коли вимкнено, дані медкартки (Полички, візити
  // до лікарів, історія самопочуття, архів ліків, вкладення) просто
  // ніколи не потрапляють у payload. Синхронізація ліків і розкладу
  // прийому від цього прапорця не залежить.
  static String _medcardSyncKey(String subjectPersonUuid) => 'family_medcard_sync_$subjectPersonUuid';

  static Future<bool> isMedcardSyncAllowed(String subjectPersonUuid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_medcardSyncKey(subjectPersonUuid)) ?? true;
  }

  static Future<void> setMedcardSyncAllowed(String subjectPersonUuid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_medcardSyncKey(subjectPersonUuid), value);
  }
}
