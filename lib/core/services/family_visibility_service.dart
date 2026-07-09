import 'package:shared_preferences/shared_preferences.dart';
import '../../data/db/app_database.dart';

enum FamilyPermission { notify, edit, view }

/// Локальні налаштування видимості одного члена сім'ї для інших:
/// кому надсилати сповіщення про нього, хто може редагувати його профіль,
/// хто може бачити його завдання/медкартку/розклад.
class FamilyVisibilityService {
  static String _key(int subjectId, int viewerId, FamilyPermission p) =>
      'family_vis_${subjectId}_${viewerId}_${p.name}';

  static Future<bool> isAllowed(
    int subjectId,
    int viewerId,
    FamilyPermission permission,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(subjectId, viewerId, permission)) ?? true;
  }

  static Future<void> setAllowed(
    int subjectId,
    int viewerId,
    FamilyPermission permission,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(subjectId, viewerId, permission), value);
  }
}
