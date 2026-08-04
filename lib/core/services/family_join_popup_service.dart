import 'package:shared_preferences/shared_preferences.dart';

/// Дедуп для [showFamilyJoinPopup] (family_join_popup.dart) — той самий
/// підхід, що й [BackupReminderService]/ReviewPromptService: прапорець у
/// SharedPreferences, пишеться ДО показу поп-апу (не після), щоб навіть
/// швидкий повторний вхід одразу після показу не спричинив дубль. Ключ
/// прив'язаний до конкретного personUuid — кожне нове приєднання (свій
/// особистий peerUuid) отримує власний одноразовий показ, а не один
/// прапорець на всю історію застосунку.
class FamilyJoinPopupService {
  static const _ownerPrefix = 'family_join_popup_shown_owner_';
  static const _inviteePrefix = 'family_join_popup_shown_invitee_';

  static Future<bool> shouldShowForOwner(String personUuid) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_ownerPrefix$personUuid') ?? false);
  }

  static Future<void> markShownForOwner(String personUuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_ownerPrefix$personUuid', true);
  }

  static Future<bool> shouldShowForInvitee(String personUuid) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_inviteePrefix$personUuid') ?? false);
  }

  static Future<void> markShownForInvitee(String personUuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_inviteePrefix$personUuid', true);
  }
}
