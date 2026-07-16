import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../providers/app_language_provider.dart';
import 'app_logger.dart';

/// Єдина точка планування локальних сповіщень: ліки, активності,
/// прийоми лікарів, самопочуття та алерти про залишок ліків.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ⚠️ v2 — Android забороняє міняти звук/важливість каналу після його
  // першого створення (API 26+): на пристроях, де канал medkit_reminders
  // уже існував без звуку, жодна зміна тут нижче не подіяла б, доки не
  // з'явиться НОВИЙ channelId — тоді плагін створює канал заново вже з
  // playSound: true. Не повертати назад на 'medkit_reminders'.
  static const _channelId = 'medkit_reminders_v2';

  // Немає BuildContext у сервісі, що планує сповіщення (часто з фону) —
  // тому локаль береться напряму зі збереженого вибору мови застосунку
  // (той самий SharedPreferences-ключ, що й appLanguageProvider) через
  // згенерований lookupAppLocalizations, а не через context.l10n.
  static Future<AppLocalizations> _l10n() async {
    final id = await AppLanguageNotifier.loadLanguageId();
    final code = id.split('_').first;
    final locale = const ['uk', 'en'].contains(code) ? Locale(code) : const Locale('uk');
    return lookupAppLocalizations(locale);
  }

  /// Лише реєстрація плагіна/каналу/таймзони — без системного діалогу
  /// дозволу. Викликається одразу при старті застосунку (main.dart), щоб
  /// планування нагадувань було готове до роботи. Сам запит дозволу —
  /// окремо, [requestPermissions], викликається з онбордингу в потрібний
  /// момент (не одразу на холодному старті, до появи будь-якого екрана).
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
  }

  /// Системний діалог "Дозволити сповіщення" — викликається явно з
  /// онбордингу (крок 1 → крок 2), а не на холодному старті.
  static Future<void> requestPermissions() async {
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

  static Future<NotificationDetails> _details({bool vibrationEnabled = true}) async {
    final l10n = await _l10n();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.notifChannelName,
        channelDescription: l10n.notifChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF4C9A6A),
        enableVibration: vibrationEnabled,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );
  }

  static Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    DateTimeComponents? matchDateTimeComponents,
    bool vibrationEnabled = true,
  }) async {
    if (matchDateTimeComponents == null && at.isBefore(DateTime.now())) {
      AppLogger.log(
        'NotificationService.schedule SKIPPED (у минулому) id=$id at=${at.toIso8601String()} title="$title"',
      );
      return;
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        await _details(vibrationEnabled: vibrationEnabled),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      AppLogger.log(
        'NotificationService.schedule OK id=$id at=${at.toIso8601String()} match=$matchDateTimeComponents title="$title"',
      );
    } catch (e, st) {
      AppLogger.logError('NotificationService.schedule FAILED id=$id at=${at.toIso8601String()} title="$title"', e, st);
      rethrow;
    }
  }

  static Future<void> cancel(int id) {
    AppLogger.log('NotificationService.cancel id=$id');
    return _plugin.cancel(id);
  }

  /// Скасовує геть усі заплановані на цьому пристрої нагадування. Потрібно
  /// викликати при виході з акаунту / видаленні всіх даних — інакше вже
  /// заплановані OS-alarm'и (zonedSchedule) лишаються жити незалежно від
  /// БД і спрацьовують навіть після того, як профіль видалено.
  static Future<void> cancelAll() {
    AppLogger.log('NotificationService.cancelAll');
    return _plugin.cancelAll();
  }

  /// Знімок дозволів на сповіщення — викликати на cold-start/resume, щоб у
  /// лозі був слід, чи були ще ввімкнені точні будильники/сповіщення в
  /// момент, коли нагадування планувались. iOS не має еквівалента
  /// "точних будильників" — там перевіряємо лише загальний дозвіл.
  static Future<void> logDiagnostics() async {
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final exact = await android?.canScheduleExactNotifications();
        final enabled = await android?.areNotificationsEnabled();
        AppLogger.log(
          'NotificationService.diagnostics android exactAlarms=$exact notificationsEnabled=$enabled',
        );
      } else if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final settings = await ios?.checkPermissions();
        AppLogger.log(
          'NotificationService.diagnostics ios isEnabled=${settings?.isEnabled} isAlertEnabled=${settings?.isAlertEnabled}',
        );
      }
    } catch (e, st) {
      AppLogger.logError('NotificationService.diagnostics', e, st);
    }
  }

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
    required String memberName,
    required String medName,
    required String dose,
    required DateTime scheduledAt,
    bool vibrationEnabled = true,
    int repeatMinutes = 0,
  }) async {
    final l10n = await _l10n();
    await _zonedSchedule(
      id: intakeNotificationId(intakeId),
      title: '$memberName · ${l10n.notifTakeMedTitle}',
      body: '$medName — $dose',
      at: scheduledAt,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: intakeRepeatNotificationId(intakeId),
        title: '$memberName · ${l10n.notifIntakeNoResponseTitle}',
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
  }) async {
    final id = 9500000 + (DateTime.now().millisecondsSinceEpoch % 500000);
    return _plugin.show(id, title, body, await _details());
  }

  // ── Нагадування про резервну копію ───────────────────────────────────

  static const backupReminderNotificationId = 9100000;

  static Future<void> showBackupReminder() async {
    final l10n = await _l10n();
    return _plugin.show(
      backupReminderNotificationId,
      l10n.notifBackupReminderTitle,
      l10n.notifBackupReminderBody,
      await _details(),
    );
  }

  // ── Залишок ліків ─────────────────────────────────────────────────────

  static int lowStockNotificationId(int medicationId) =>
      5000000 + medicationId;

  static Future<void> showLowStockAlert({
    required int medicationId,
    required String memberName,
    required String medName,
    required int remaining,
    required String unit,
    bool vibrationEnabled = true,
  }) async {
    final l10n = await _l10n();
    return _plugin.show(
      lowStockNotificationId(medicationId),
      '$memberName · ${l10n.notifLowStockTitle}',
      l10n.notifLowStockBody(medName, remaining, unit),
      await _details(vibrationEnabled: vibrationEnabled),
    );
  }

  // ── Активності ────────────────────────────────────────────────────────

  static int activityNotificationId(int logId) => 2000000 + logId;
  static int activityRepeatNotificationId(int logId) => 7000000 + logId;

  static Future<void> scheduleActivityReminder({
    required int logId,
    required String memberName,
    required String activityName,
    required DateTime scheduledAt,
    bool vibrationEnabled = true,
    int repeatMinutes = 0,
  }) async {
    final l10n = await _l10n();
    await _zonedSchedule(
      id: activityNotificationId(logId),
      title: '$memberName · ${l10n.notifActivityTitle}',
      body: activityName,
      at: scheduledAt,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: activityRepeatNotificationId(logId),
        title: '$memberName · ${l10n.notifActivityNoResponseTitle}',
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
    required String memberName,
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
    final l10n = await _l10n();
    await _zonedSchedule(
      id: appointmentNotificationId(appointmentId),
      title: '$memberName · ${l10n.notifAppointmentTitle}',
      body: body,
      at: at,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: appointmentRepeatNotificationId(appointmentId),
        title: '$memberName · ${l10n.notifAppointmentNoResponseTitle}',
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
    required String memberName,
    required int slotIndex,
    required int hour,
    required int minute,
    bool vibrationEnabled = true,
  }) async {
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    final l10n = await _l10n();
    await _zonedSchedule(
      id: wellbeingNotificationId(memberId, slotIndex),
      title: '$memberName · ${l10n.notifWellbeingTitle}',
      body: l10n.notifWellbeingBody,
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
    required String memberName,
    required String name,
    required DateTime nextDoseAt,
    bool vibrationEnabled = true,
  }) async {
    final at = DateTime(nextDoseAt.year, nextDoseAt.month, nextDoseAt.day, 9);
    final l10n = await _l10n();
    await _zonedSchedule(
      id: vaccinationNotificationId(vaccinationId),
      title: '$memberName · ${l10n.notifVaccinationTitle}',
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
    final l10n = await _l10n();
    await _zonedSchedule(
      id: peerIntakeCheckId(uuid),
      title: l10n.notifPeerCheckTitle(subjectName),
      body: l10n.notifPeerIntakeCheckBody(medName, dose, timeStr),
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
    final l10n = await _l10n();
    await _zonedSchedule(
      id: peerActivityCheckId(uuid),
      title: l10n.notifPeerCheckTitle(subjectName),
      body: l10n.notifPeerActivityCheckBody(activityName, timeStr),
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
    final l10n = await _l10n();
    await _zonedSchedule(
      id: peerAppointmentCheckId(uuid),
      title: l10n.notifPeerCheckTitle(subjectName),
      body: l10n.notifPeerAppointmentCheckBody(doctorType, timeStr),
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
    final l10n = await _l10n();
    await _zonedSchedule(
      id: peerWellbeingCheckId(subjectPersonUuid, _peerWellbeingEpochDay(), slotIndex),
      title: l10n.notifPeerCheckTitle(subjectName),
      body: l10n.notifPeerWellbeingCheckBody(timeStr),
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
