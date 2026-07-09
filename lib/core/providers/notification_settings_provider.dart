import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool pushEnabled;
  final int offsetMinutes; // 0/5/10/15/30 — нагадати за N хв до часу
  final bool vibrationEnabled;
  final int repeatMinutes; // 5/20/45/60 — повторити, якщо нема відповіді
  final bool quietEnabled;
  final int quietFromMinutes; // хвилин з півночі
  final int quietToMinutes;
  final Map<int, bool> memberAlerts; // memberId -> увімкнено

  const NotificationSettings({
    this.pushEnabled = true,
    this.offsetMinutes = 0,
    this.vibrationEnabled = true,
    this.repeatMinutes = 20,
    this.quietEnabled = false,
    this.quietFromMinutes = 23 * 60,
    this.quietToMinutes = 7 * 60,
    this.memberAlerts = const {},
  });

  bool isMemberEnabled(int memberId) => memberAlerts[memberId] ?? true;

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
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final rawAlerts = json['memberAlerts'] as Map<String, dynamic>? ?? {};
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
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
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

  Future<void> setPushEnabled(bool v) async {
    state = state.copyWith(pushEnabled: v);
    await _save();
  }

  Future<void> setOffsetMinutes(int v) async {
    state = state.copyWith(offsetMinutes: v);
    await _save();
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
  }

  Future<void> setQuietFrom(TimeOfDay t) async {
    state = state.copyWith(quietFromMinutes: t.hour * 60 + t.minute);
    await _save();
  }

  Future<void> setQuietTo(TimeOfDay t) async {
    state = state.copyWith(quietToMinutes: t.hour * 60 + t.minute);
    await _save();
  }

  Future<void> setMemberAlert(int memberId, bool v) async {
    final updated = Map<int, bool>.from(state.memberAlerts)..[memberId] = v;
    state = state.copyWith(memberAlerts: updated);
    await _save();
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(),
);
