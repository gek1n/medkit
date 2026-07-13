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

  static NotificationDetails _details({bool vibrationEnabled = true}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF4C9A6A),
          enableVibration: vibrationEnabled,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      );

  static Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    DateTimeComponents? matchDateTimeComponents,
    bool vibrationEnabled = true,
  }) async {
    if (matchDateTimeComponents == null && at.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      _details(vibrationEnabled: vibrationEnabled),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  /// Скасовує геть усі заплановані на цьому пристрої нагадування. Потрібно
  /// викликати при виході з акаунту / видаленні всіх даних — інакше вже
  /// заплановані OS-alarm'и (zonedSchedule) лишаються жити незалежно від
  /// БД і спрацьовують навіть після того, як профіль видалено.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Ліки ──────────────────────────────────────────────────────────────

  static int intakeNotificationId(int intakeId) => 1000000 + intakeId;
  static int intakeRepeatNotificationId(int intakeId) => 6000000 + intakeId;

  /// [repeatMinutes] — якщо > 0, планує ще одне нагадування через N хвилин
  /// після основного (лише прийом ліків: у нього є чіткий стан
  /// "прийнято/пропущено", тож "повторити, якщо нема відповіді" тут
  /// однозначне). Друге нагадування скасовується разом з основним у
  /// [cancelIntakeReminder] — якщо користувач вже відповів, воно просто
  /// ніколи не спрацює.
  static Future<void> scheduleIntakeReminder({
    required int intakeId,
    required String medName,
    required String dose,
    required DateTime scheduledAt,
    bool vibrationEnabled = true,
    int repeatMinutes = 0,
  }) async {
    await _zonedSchedule(
      id: intakeNotificationId(intakeId),
      title: '💊 Час прийняти ліки',
      body: '$medName — $dose',
      at: scheduledAt,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: intakeRepeatNotificationId(intakeId),
        title: '🔔 Ви ще не відмітили прийом',
        body: '$medName — $dose',
        at: scheduledAt.add(Duration(minutes: repeatMinutes)),
        vibrationEnabled: vibrationEnabled,
      );
    }
  }

  static Future<void> cancelIntakeReminder(int intakeId) async {
    await cancel(intakeNotificationId(intakeId));
    await cancel(intakeRepeatNotificationId(intakeId));
  }

  // ── Сім'я: миттєве нагадування "🔔 Нагадати" (натиснуте вручну) ──────
  // На відміну від запланованої заздалегідь перевірки (з'являється лише
  // якщо нема відповіді), це показується одразу на пристрої отримувача,
  // щойно інший член сім'ї натиснув кнопку. Текст (title/body) формує
  // викликач — тут лише показ, щоб один метод годився для ліків/
  // активностей/лікарів/самопочуття.
  static Future<void> showRemoteReminder({
    required String title,
    required String body,
  }) {
    final id = 9500000 + (DateTime.now().millisecondsSinceEpoch % 500000);
    return _plugin.show(id, title, body, _details());
  }

  // ── Залишок ліків ─────────────────────────────────────────────────────

  static int lowStockNotificationId(int medicationId) =>
      5000000 + medicationId;

  static Future<void> showLowStockAlert({
    required int medicationId,
    required String medName,
    required int remaining,
    required String unit,
    bool vibrationEnabled = true,
  }) {
    return _plugin.show(
      lowStockNotificationId(medicationId),
      '⚠️ Закінчуються ліки',
      '$medName — залишилось $remaining $unit',
      _details(vibrationEnabled: vibrationEnabled),
    );
  }

  // ── Активності ────────────────────────────────────────────────────────

  static int activityNotificationId(int logId) => 2000000 + logId;
  static int activityRepeatNotificationId(int logId) => 7000000 + logId;

  static Future<void> scheduleActivityReminder({
    required int logId,
    required String activityName,
    required DateTime scheduledAt,
    bool vibrationEnabled = true,
    int repeatMinutes = 0,
  }) async {
    await _zonedSchedule(
      id: activityNotificationId(logId),
      title: '🚶 Час для активності',
      body: activityName,
      at: scheduledAt,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: activityRepeatNotificationId(logId),
        title: '🔔 Ви ще не відмітили активність',
        body: activityName,
        at: scheduledAt.add(Duration(minutes: repeatMinutes)),
        vibrationEnabled: vibrationEnabled,
      );
    }
  }

  static Future<void> cancelActivityReminder(int logId) async {
    await cancel(activityNotificationId(logId));
    await cancel(activityRepeatNotificationId(logId));
  }

  // ── Лікарі ────────────────────────────────────────────────────────────

  static int appointmentNotificationId(int appointmentId) =>
      3000000 + appointmentId;
  static int appointmentRepeatNotificationId(int appointmentId) =>
      8000000 + appointmentId;

  static Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String doctorType,
    String? location,
    required DateTime scheduledAt,
    required int remindBeforeMin,
    bool vibrationEnabled = true,
    int repeatMinutes = 0,
  }) async {
    final at = scheduledAt.subtract(Duration(minutes: remindBeforeMin));
    final body = (location != null && location.isNotEmpty)
        ? '$doctorType · $location'
        : doctorType;
    await _zonedSchedule(
      id: appointmentNotificationId(appointmentId),
      title: '🩺 Прийом лікаря',
      body: body,
      at: at,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: appointmentRepeatNotificationId(appointmentId),
        title: '🔔 Не забудьте про прийом лікаря',
        body: body,
        at: at.add(Duration(minutes: repeatMinutes)),
        vibrationEnabled: vibrationEnabled,
      );
    }
  }

  static Future<void> cancelAppointmentReminder(int appointmentId) async {
    await cancel(appointmentNotificationId(appointmentId));
    await cancel(appointmentRepeatNotificationId(appointmentId));
  }

  // ── Самопочуття (щоденний повтор за часом) ───────────────────────────

  static int wellbeingNotificationId(int memberId, int slotIndex) =>
      4000000 + memberId * 100 + slotIndex;

  static Future<void> scheduleWellbeingDaily({
    required int memberId,
    required int slotIndex,
    required int hour,
    required int minute,
    bool vibrationEnabled = true,
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
      vibrationEnabled: vibrationEnabled,
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

  // ── Щеплення ──────────────────────────────────────────────────────────

  static int vaccinationNotificationId(int vaccinationId) =>
      10000000 + vaccinationId;

  /// Нагадування о 9:00 в день [nextDoseAt] — про наступну ревакцинацію.
  /// Викликати лише коли nextDoseAt заповнено; минулі дати мовчки
  /// ігноруються всередині [_zonedSchedule].
  static Future<void> scheduleVaccinationReminder({
    required int vaccinationId,
    required String name,
    required DateTime nextDoseAt,
    bool vibrationEnabled = true,
  }) async {
    final at = DateTime(nextDoseAt.year, nextDoseAt.month, nextDoseAt.day, 9);
    await _zonedSchedule(
      id: vaccinationNotificationId(vaccinationId),
      title: '💉 Час ревакцинації',
      body: name,
      at: at,
      vibrationEnabled: vibrationEnabled,
    );
  }

  static Future<void> cancelVaccinationReminder(int vaccinationId) =>
      cancel(vaccinationNotificationId(vaccinationId));

  // ── Сімейна група (FamilyPeers): перевірка суб'єкта з notify-дозволом ──
  // Заплановано на +30 хв, скасовується щойно прилетить підтвердження —
  // тут ідентифікатор рядка не локальний int id (даних у типізованих
  // таблицях немає, лише кеш SharedEntities), а syncUuid (String) від
  // суб'єкта, тож id сповіщення виводиться стабільним хешем.
  static int _stableId(int base, String uuid) => base + (uuid.hashCode.abs() % 900000);

  static int peerIntakeCheckId(String uuid) => _stableId(20000000, uuid);

  static Future<void> schedulePeerIntakeCheck({
    required String uuid,
    required String subjectName,
    required String medName,
    required String dose,
    required DateTime scheduledAt,
  }) async {
    final timeStr =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    await _zonedSchedule(
      id: peerIntakeCheckId(uuid),
      title: '🔔 Перевірте $subjectName',
      body: 'Чи прийнято "$medName" ($dose) о $timeStr? Відкрийте застосунок '
          'і зачекайте на синхронізацію, щоб побачити актуальний стан.',
      at: scheduledAt.add(const Duration(minutes: 30)),
    );
  }

  static Future<void> cancelPeerIntakeCheck(String uuid) => cancel(peerIntakeCheckId(uuid));

  static int peerActivityCheckId(String uuid) => _stableId(21000000, uuid);

  static Future<void> schedulePeerActivityCheck({
    required String uuid,
    required String subjectName,
    required String activityName,
    required DateTime scheduledAt,
  }) async {
    final timeStr =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    await _zonedSchedule(
      id: peerActivityCheckId(uuid),
      title: '🔔 Перевірте $subjectName',
      body: 'Чи виконано "$activityName" о $timeStr? Відкрийте застосунок '
          'і зачекайте на синхронізацію, щоб побачити актуальний стан.',
      at: scheduledAt.add(const Duration(minutes: 30)),
    );
  }

  static Future<void> cancelPeerActivityCheck(String uuid) => cancel(peerActivityCheckId(uuid));

  static int peerAppointmentCheckId(String uuid) => _stableId(23000000, uuid);

  static Future<void> schedulePeerAppointmentCheck({
    required String uuid,
    required String subjectName,
    required String doctorType,
    required DateTime scheduledAt,
  }) async {
    final timeStr =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    await _zonedSchedule(
      id: peerAppointmentCheckId(uuid),
      title: '🔔 Перевірте $subjectName',
      body: 'Чи відбувся прийом ("$doctorType") о $timeStr? Відкрийте застосунок '
          'і зачекайте на синхронізацію, щоб побачити актуальний стан.',
      at: scheduledAt.add(const Duration(minutes: 30)),
    );
  }

  static Future<void> cancelPeerAppointmentCheck(String uuid) => cancel(peerAppointmentCheckId(uuid));

  static int _peerWellbeingEpochDay() => DateTime.now().difference(DateTime(1970, 1, 1)).inDays;

  static int peerWellbeingCheckId(String subjectPersonUuid, int epochDay, int slotIndex) =>
      22000000 + (subjectPersonUuid.hashCode.abs() % 700000) + (epochDay % 1000) * 10 + slotIndex;

  static Future<void> schedulePeerWellbeingCheck({
    required String subjectPersonUuid,
    required String subjectName,
    required int slotIndex,
    required DateTime scheduledAt,
  }) async {
    final timeStr =
        '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
    await _zonedSchedule(
      id: peerWellbeingCheckId(subjectPersonUuid, _peerWellbeingEpochDay(), slotIndex),
      title: '🔔 Перевірте $subjectName',
      body: 'Чи зроблено зріз самопочуття о $timeStr? Відкрийте застосунок '
          'і зачекайте на синхронізацію, щоб побачити актуальний стан.',
      at: scheduledAt.add(const Duration(minutes: 30)),
    );
  }

  static Future<void> cancelTodayPeerWellbeingChecks(
    String subjectPersonUuid, {
    int maxSlots = 6,
  }) async {
    final today = _peerWellbeingEpochDay();
    for (var i = 0; i < maxSlots; i++) {
      await cancel(peerWellbeingCheckId(subjectPersonUuid, today, i));
    }
  }
}
