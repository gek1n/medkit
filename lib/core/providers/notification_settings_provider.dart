import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_resync_service.dart';
import '../services/notification_service.dart';

class NotificationSettings {
  final bool pushEnabled;
  final int offsetMinutes; // 0/5/10/15/30 — нагадати за N хв до часу
  final bool vibrationEnabled;
  final int repeatMinutes; // 5/20/45/60 — повторити, якщо нема відповіді
  final bool quietEnabled;
  final int quietFromMinutes; // хвилин з півночі
  final int quietToMinutes;
  final Map<int, bool> memberAlerts; // memberId -> увімкнено (локальні профілі)
  final Map<String, bool> peerAlerts;
  // personUuid автономного пір'а -> чи хочу Я особисто отримувати від
  // нього сповіщення. Показується лише для пірів, які самі дозволили
  // notify мені (FamilyPeer.notifyGranted) — двостороння згода: суб'єкт
  // дозволяє слати МЕНІ, а я окремо вирішую, чи хочу отримувати.

  const NotificationSettings({
    this.pushEnabled = true,
    this.offsetMinutes = 0,
    this.vibrationEnabled = true,
    this.repeatMinutes = 20,
    this.quietEnabled = false,
    this.quietFromMinutes = 23 * 60,
    this.quietToMinutes = 7 * 60,
    this.memberAlerts = const {},
    this.peerAlerts = const {},
  });

  bool isMemberEnabled(int memberId) => memberAlerts[memberId] ?? true;
  bool isPeerEnabled(String personUuid) => peerAlerts[personUuid] ?? true;

  bool isInQuietHours(DateTime at) {
    if (!quietEnabled) return false;
    final m = at.hour * 60 + at.minute;
    if (quietFromMinutes <= quietToMinutes) {
      return m >= quietFromMinutes && m < quietToMinutes;
    }
    return m >= quietFromMinutes || m < quietToMinutes;
  }

  /// Застосовує зсув та тихі години; null — сповіщення не потрібне.
  DateTime? adjust(DateTime at, {int? memberId}) {
    if (!pushEnabled) return null;
    if (memberId != null && !isMemberEnabled(memberId)) return null;

    var result = at.subtract(Duration(minutes: offsetMinutes));
    if (isInQuietHours(result)) {
      final day = DateTime(result.year, result.month, result.day);
      var shifted = day.add(Duration(minutes: quietToMinutes));
      if (shifted.isBefore(result)) {
        shifted = shifted.add(const Duration(days: 1));
      }
      result = shifted;
    }
    return result;
  }

  NotificationSettings copyWith({
    bool? pushEnabled,
    int? offsetMinutes,
    bool? vibrationEnabled,
    int? repeatMinutes,
    bool? quietEnabled,
    int? quietFromMinutes,
    int? quietToMinutes,
    Map<int, bool>? memberAlerts,
    Map<String, bool>? peerAlerts,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      repeatMinutes: repeatMinutes ?? this.repeatMinutes,
      quietEnabled: quietEnabled ?? this.quietEnabled,
      quietFromMinutes: quietFromMinutes ?? this.quietFromMinutes,
      quietToMinutes: quietToMinutes ?? this.quietToMinutes,
      memberAlerts: memberAlerts ?? this.memberAlerts,
      peerAlerts: peerAlerts ?? this.peerAlerts,
    );
  }

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'offsetMinutes': offsetMinutes,
        'vibrationEnabled': vibrationEnabled,
        'repeatMinutes': repeatMinutes,
        'quietEnabled': quietEnabled,
        'quietFromMinutes': quietFromMinutes,
        'quietToMinutes': quietToMinutes,
        'memberAlerts':
            memberAlerts.map((k, v) => MapEntry(k.toString(), v)),
        'peerAlerts': peerAlerts,
      };

  /// Незалежний від Riverpod завантажувач — для сервісів поза деревом
  /// віджетів (напр. FamilyPeerSyncService), яким потрібен лише
  /// peerAlerts-прапорець, без повного контексту Ref.
  static Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(NotificationSettingsNotifier._key);
    if (raw == null) return const NotificationSettings();
    try {
      return NotificationSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const NotificationSettings();
    }
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final rawAlerts = json['memberAlerts'] as Map<String, dynamic>? ?? {};
    final rawPeerAlerts = json['peerAlerts'] as Map<String, dynamic>? ?? {};
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      offsetMinutes: json['offsetMinutes'] as int? ?? 0,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      repeatMinutes: json['repeatMinutes'] as int? ?? 20,
      quietEnabled: json['quietEnabled'] as bool? ?? false,
      quietFromMinutes: json['quietFromMinutes'] as int? ?? 23 * 60,
      quietToMinutes: json['quietToMinutes'] as int? ?? 7 * 60,
      memberAlerts:
          rawAlerts.map((k, v) => MapEntry(int.parse(k), v as bool)),
      peerAlerts: rawPeerAlerts.map((k, v) => MapEntry(k, v as bool)),
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  final Ref _ref;
  NotificationSettingsNotifier(this._ref) : super(const NotificationSettings()) {
    _load();
  }

  static const _key = 'notification_settings';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      state =
          NotificationSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  // Будь-яка зміна, що впливає на результат NotificationSettings.adjust()
  // (push увімкнено, зсув, тихі години, вимкнено конкретного члена сім'ї),
  // сама по собі НЕ чіпає вже заплановані zonedSchedule — adjust() рахується
  // один раз, у момент СТВОРЕННЯ нагадування. Без цього виклику "вимкнути
  // сповіщення"/"увімкнути тихі години" означало б лише "з наступного разу",
  // а все заплановане раніше спрацьовувало б як було. Перепланування важке
  // (перебирає всі pending-рядки), тож не викликаємо його для vibration/
  // repeatMinutes — це деталі вже запланованого нагадування, а не "чи
  // спрацює воно взагалі і коли".
  Future<void> _resync() => _ref.read(notificationResyncServiceProvider).resyncAll();

  // Вимкнення push тут лише зупиняє ПЛАНУВАННЯ нового — але саме по собі не
  // чіпає те, що вже заплановано раніше через zonedSchedule, а OS-
  // планувальник живе незалежно від цього прапорця. Явне cancelAll() тут —
  // щоб вимикач дійсно означав "тихо негайно", а не "тихо із наступного
  // разу". Повторне увімкнення — навпаки, resync() перепланує все під
  // актуальні налаштування (в т.ч. тихі години, якщо вони теж увімкнені).
  Future<void> setPushEnabled(bool v) async {
    state = state.copyWith(pushEnabled: v);
    await _save();
    if (!v) {
      await NotificationService.cancelAll();
    } else {
      await _resync();
    }
  }

  Future<void> setOffsetMinutes(int v) async {
    state = state.copyWith(offsetMinutes: v);
    await _save();
    await _resync();
  }

  Future<void> setVibrationEnabled(bool v) async {
    state = state.copyWith(vibrationEnabled: v);
    await _save();
  }

  Future<void> setRepeatMinutes(int v) async {
    state = state.copyWith(repeatMinutes: v);
    await _save();
  }

  Future<void> setQuietEnabled(bool v) async {
    state = state.copyWith(quietEnabled: v);
    await _save();
    await _resync();
  }

  Future<void> setQuietFrom(TimeOfDay t) async {
    state = state.copyWith(quietFromMinutes: t.hour * 60 + t.minute);
    await _save();
    await _resync();
  }

  Future<void> setQuietTo(TimeOfDay t) async {
    state = state.copyWith(quietToMinutes: t.hour * 60 + t.minute);
    await _save();
    await _resync();
  }

  Future<void> setMemberAlert(int memberId, bool v) async {
    final updated = Map<int, bool>.from(state.memberAlerts)..[memberId] = v;
    state = state.copyWith(memberAlerts: updated);
    await _save();
    await _resync();
  }

  Future<void> setPeerAlert(String personUuid, bool v) async {
    final updated = Map<String, bool>.from(state.peerAlerts)..[personUuid] = v;
    state = state.copyWith(peerAlerts: updated);
    await _save();
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(ref),
);
