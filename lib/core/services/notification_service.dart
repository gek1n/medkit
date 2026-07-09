import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Єдина точка планування локальних сповіщень: ліки, активності,
/// прийоми лікарів, самопочуття та алерти про залишок ліків.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'medkit_reminders';
  static const _channelName = 'Нагадування Elly';
  static const _channelDesc =
      'Нагадування про ліки, активності, візити та самопочуття';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    _setLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_leaf');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static void _setLocalTimeZone() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final name = offsetHours == 0
        ? 'UTC'
        : 'Etc/GMT${offsetHours > 0 ? '-' : '+'}${offsetHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF4C9A6A),
        ),
        iOS: DarwinNotificationDetails(),
      );

  static Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (matchDateTimeComponents == null && at.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  // ── Ліки ──────────────────────────────────────────────────────────────

  static int intakeNotificationId(int intakeId) => 1000000 + intakeId;

  static Future<void> scheduleIntakeReminder({
    required int intakeId,
    required String medName,
    required String dose,
    required DateTime scheduledAt,
  }) {
    return _zonedSchedule(
      id: intakeNotificationId(intakeId),
      title: '💊 Час прийняти ліки',
      body: '$medName — $dose',
      at: scheduledAt,
    );
  }

  static Future<void> cancelIntakeReminder(int intakeId) =>
      cancel(intakeNotificationId(intakeId));

  // ── Залишок ліків ─────────────────────────────────────────────────────

  static int lowStockNotificationId(int medicationId) =>
      5000000 + medicationId;

  static Future<void> showLowStockAlert({
    required int medicationId,
    required String medName,
    required int remaining,
    required String unit,
  }) {
    return _plugin.show(
      lowStockNotificationId(medicationId),
      '⚠️ Закінчуються ліки',
      '$medName — залишилось $remaining $unit',
      _details(),
    );
  }

  // ── Активності ────────────────────────────────────────────────────────

  static int activityNotificationId(int logId) => 2000000 + logId;

  static Future<void> scheduleActivityReminder({
    required int logId,
    required String activityName,
    required DateTime scheduledAt,
  }) {
    return _zonedSchedule(
      id: activityNotificationId(logId),
      title: '🚶 Час для активності',
      body: activityName,
      at: scheduledAt,
    );
  }

  static Future<void> cancelActivityReminder(int logId) =>
      cancel(activityNotificationId(logId));

  // ── Лікарі ────────────────────────────────────────────────────────────

  static int appointmentNotificationId(int appointmentId) =>
      3000000 + appointmentId;

  static Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String doctorType,
    String? location,
    required DateTime scheduledAt,
    required int remindBeforeMin,
  }) {
    final at = scheduledAt.subtract(Duration(minutes: remindBeforeMin));
    return _zonedSchedule(
      id: appointmentNotificationId(appointmentId),
      title: '🩺 Прийом лікаря',
      body: (location != null && location.isNotEmpty)
          ? '$doctorType · $location'
          : doctorType,
      at: at,
    );
  }

  static Future<void> cancelAppointmentReminder(int appointmentId) =>
      cancel(appointmentNotificationId(appointmentId));

  // ── Самопочуття (щоденний повтор за часом) ───────────────────────────

  static int wellbeingNotificationId(int memberId, int slotIndex) =>
      4000000 + memberId * 100 + slotIndex;

  static Future<void> scheduleWellbeingDaily({
    required int memberId,
    required int slotIndex,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    await _zonedSchedule(
      id: wellbeingNotificationId(memberId, slotIndex),
      title: '💜 Зріз самопочуття',
      body: 'Як ви себе почуваєте?',
      at: at,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelWellbeingSlot(int memberId, int slotIndex) =>
      cancel(wellbeingNotificationId(memberId, slotIndex));

  static Future<void> cancelAllWellbeingForMember(
    int memberId, {
    int maxSlots = 6,
  }) async {
    for (var i = 0; i < maxSlots; i++) {
      await cancelWellbeingSlot(memberId, i);
    }
  }
}
