import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db/app_database.dart';

enum FamilyPermission { notify, edit, view }

class FamilyGrantDeniedException implements Exception {
  final String message;
  const FamilyGrantDeniedException(this.message);
  @override
  String toString() => message;
}

/// Дозволи видимості між учасниками сім'ї — ключ (subjectPersonUuid,
/// viewerPersonUuid), а не локальний id, тож один і той самий запис
/// коректний незалежно від того, звідки прийшов viewer (інший локальний
/// профіль на цьому ж пристрої чи [FamilyPeer] з іншого пристрою).
///
/// [setAllowed] можна викликати лише для subject'а, яким керує ЦЕЙ
/// пристрій (власний профіль або локальний dependent) — суб'єкт сам
/// визначає власну видимість; ніхто не вирішує за незалежного учасника
/// (FamilyPeer). Для медкартки цей сервіс — реальний бар'єр:
/// `FamilySyncService._push()` перевіряє [isMedcardSyncAllowed] локально,
/// на пристрої-джерелі, ПЕРЕД формуванням payload — а не лише ховає дані в
/// інтерфейсі отримувача.
class FamilyVisibilityService {
  /// Дефолт, коли явного запису в [FamilyGrants] немає: завжди `false` —
  /// notify/edit/view. Щойно приєднаний учасник сімейної групи (Фаза 2) не
  /// отримує сповіщень, не бачить завдань/медкартки й не може нічого
  /// редагувати НІ В КОГО, поки кожен існуючий учасник особисто не відкриє
  /// йому доступ у "Конфіденційність → Видимість для сім'ї". Видимість —
  /// завжди явний opt-in з боку subject'а (чи його менеджера для
  /// dependent-профілю), ніколи не вмикається сама по собі фактом
  /// приєднання до групи.
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

  // ── Синхронізація медкартки на інші пристрої сім'ї ─────────────────────
  // Той самий принцип, що й isAllowed вище, але без матриці viewer'ів —
  // єдиний прапорець "пускати медкартку цього профілю за межі пристрою
  // взагалі". FamilySyncService._push() перевіряє це ПЕРЕД формуванням
  // payload — коли вимкнено, дані медкартки (алергії, хронічні
  // захворювання, щеплення, операції, аналізи, візити, вкладення) просто
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
