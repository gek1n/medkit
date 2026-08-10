import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final locale = const ['uk', 'en', 'ru'].contains(code) ? Locale(code) : const Locale('uk');
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
      title: '$memberName · ${l10n.notifTakeMedTitle(medName)}',
      body: dose,
      at: scheduledAt,
      vibrationEnabled: vibrationEnabled,
    );
    if (repeatMinutes > 0) {
      await _zonedSchedule(
        id: intakeRepeatNotificationId(intakeId),
        title: '$memberName · ${l10n.notifIntakeNoResponseTitle(medName)}',
        body: dose,
        at: scheduledAt.add(Duration(minutes: repeatMinutes)),
        vibrationEnabled: vibrationEnabled,
      );
    }
  }

  static Future<void> cancelIntakeReminder(int intakeId) async {
    await cancel(intakeNotificationId(intakeId));
    await cancel(intakeRepeatNotificationId(intakeId));
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

  // ── Нагадування: щоденний/щотижневий/щорічний повтор ────────────────────
  // Об'єднана форма "Нагадування" (заміна окремих Зустрічі/Спорт/Прості
  // завдання) — на відміну від разового (scheduleAppointmentReminder вище),
  // тут повтор нативний (matchDateTimeComponents), без фонового
  // перегенерування на кшталт ActivityLogGenerator: ОС сама повторює
  // сповіщення, доки його явно не скасовано.

  static int recurringReminderNotificationId(int reminderId, int variant) =>
      5000000 + reminderId * 1000 + variant;

  // Скасовує всі можливі варіанти (дні тижня × слоти) одного нагадування —
  // викликається перед кожним новим плануванням, щоб не лишати "хвостів"
  // від попередньої конфігурації повтору.
  static Future<void> cancelRecurringReminder(
    int reminderId, {
    int maxVariants = 80,
  }) async {
    for (var i = 0; i < maxVariants; i++) {
      await cancel(recurringReminderNotificationId(reminderId, i));
    }
  }

  static Future<void> scheduleYearlyReminder({
    required int reminderId,
    required String memberName,
    required String title,
    String? location,
    required DateTime date,
    int remindBeforeMin = 0,
    bool vibrationEnabled = true,
  }) async {
    var at = date.subtract(Duration(minutes: remindBeforeMin));
    final now = DateTime.now();
    // Як і в scheduleDailyReminderSlots/scheduleWeeklyReminderSlots — явно
    // рахуємо найближче МАЙБУТНЄ входження (рік у даті-джерелі не важливий,
    // matchDateTimeComponents.dateAndTime все одно ігнорує рік при
    // повторному спрацюванні), а не покладаємось на неявний rollover плагіна.
    at = DateTime(now.year, at.month, at.day, at.hour, at.minute);
    if (at.isBefore(now)) {
      at = DateTime(now.year + 1, at.month, at.day, at.hour, at.minute);
    }
    final body =
        (location != null && location.isNotEmpty) ? '$title · $location' : title;
    final l10n = await _l10n();
    await _zonedSchedule(
      id: recurringReminderNotificationId(reminderId, 0),
      title: '$memberName · ${l10n.notifAppointmentTitle}',
      body: body,
      at: at,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      vibrationEnabled: vibrationEnabled,
    );
    for (var i = 1; i < 80; i++) {
      await cancel(recurringReminderNotificationId(reminderId, i));
    }
  }

  // Один слот = один час доби, що повторюється щодня.
  static Future<void> scheduleDailyReminderSlots({
    required int reminderId,
    required String memberName,
    required String title,
    required List<(int hour, int minute)> slots,
    bool vibrationEnabled = true,
  }) async {
    final l10n = await _l10n();
    final now = DateTime.now();
    for (var i = 0; i < slots.length; i++) {
      final (hour, minute) = slots[i];
      var at = DateTime(now.year, now.month, now.day, hour, minute);
      if (at.isBefore(now)) at = at.add(const Duration(days: 1));
      await _zonedSchedule(
        id: recurringReminderNotificationId(reminderId, i),
        title: '$memberName · ${l10n.notifAppointmentTitle}',
        body: title,
        at: at,
        matchDateTimeComponents: DateTimeComponents.time,
        vibrationEnabled: vibrationEnabled,
      );
    }
    // Прибираємо "хвости" від попередньої конфігурації з БІЛЬШОЮ кількістю
    // слотів — лише варіанти ПОЗА щойно запланованими (кожен _zonedSchedule
    // вище й так перезаписує свій id на місці), щоб не було вікна, коли
    // щойно заплановане тимчасово скасовується.
    for (var i = slots.length; i < 80; i++) {
      await cancel(recurringReminderNotificationId(reminderId, i));
    }
  }

  // Плагін не має нативного matchDateTimeComponents для "щомісяця" (лише
  // time/dayOfWeekAndTime/dateAndTime) — тож замість одного "вічного"
  // повтору плануємо наперед [monthsAhead] окремих одноразових сповіщень
  // (варіанти 0..monthsAhead-1), з клемпінгом дня для коротших місяців
  // (напр. 31 у лютому → останній день лютого). Через рік, якщо запис не
  // пересворено чи не перепланований через resync, нові сповіщення
  // перестануть з'являтись — прийнятний компроміс у межах архітектури без
  // фонового генератора (як і решта Нагадування).
  static Future<void> scheduleMonthlyReminder({
    required int reminderId,
    required String memberName,
    required String title,
    String? location,
    required int dayOfMonth,
    required int hour,
    required int minute,
    bool vibrationEnabled = true,
    int monthsAhead = 12,
  }) async {
    final l10n = await _l10n();
    final body =
        (location != null && location.isNotEmpty) ? '$title · $location' : title;
    final now = DateTime.now();
    for (var i = 0; i < monthsAhead; i++) {
      final targetMonth = DateTime(now.year, now.month + i, 1);
      final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      final clampedDay = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
      final at =
          DateTime(targetMonth.year, targetMonth.month, clampedDay, hour, minute);
      if (at.isBefore(now)) continue;
      await _zonedSchedule(
        id: recurringReminderNotificationId(reminderId, i),
        title: '$memberName · ${l10n.notifAppointmentTitle}',
        body: body,
        at: at,
        vibrationEnabled: vibrationEnabled,
      );
    }
    for (var i = monthsAhead; i < 80; i++) {
      await cancel(recurringReminderNotificationId(reminderId, i));
    }
  }

  // Дні тижня (1=Пн..7=Нд, як DateTime.weekday) × слоти — кожна пара
  // отримує власний ідентифікатор сповіщення, що повторюється щотижня.
  static Future<void> scheduleWeeklyReminderSlots({
    required int reminderId,
    required String memberName,
    required String title,
    required List<int> weekdays,
    required List<(int hour, int minute)> slots,
    bool vibrationEnabled = true,
  }) async {
    final l10n = await _l10n();
    final now = DateTime.now();
    var variant = 0;
    for (final weekday in weekdays) {
      for (final (hour, minute) in slots) {
        var at = DateTime(now.year, now.month, now.day, hour, minute);
        final daysAhead = (weekday - at.weekday + 7) % 7;
        at = at.add(Duration(days: daysAhead));
        if (at.isBefore(now)) at = at.add(const Duration(days: 7));
        await _zonedSchedule(
          id: recurringReminderNotificationId(reminderId, variant),
          title: '$memberName · ${l10n.notifAppointmentTitle}',
          body: title,
          at: at,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          vibrationEnabled: vibrationEnabled,
        );
        variant++;
      }
    }
    // Той самий принцип, що й у scheduleDailyReminderSlots: прибираємо
    // варіанти ПОЗА щойно запланованим діапазоном (напр. після зменшення
    // кількості днів/слотів), а не скасовуємо все заздалегідь.
    for (var i = variant; i < 80; i++) {
      await cancel(recurringReminderNotificationId(reminderId, i));
    }
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
  // Фіча видалена (Vaccinations-таблиця дропається в AppDatabase-міграції
  // 30) — schedule-метод прибрано, нових нагадувань більше не ставиться.
  // id/cancel лишаються лише для одноразового прибирання ЗАСТАРІЛИХ
  // нагадувань, запланованих ДО цього оновлення — див.
  // _cancelStaleVaccinationReminders у main.dart.

  static int vaccinationNotificationId(int vaccinationId) =>
      10000000 + vaccinationId;

  static Future<void> cancelVaccinationReminder(int vaccinationId) =>
      cancel(vaccinationNotificationId(vaccinationId));

  static const _pendingCancelVaccinationIdsKey = 'pending_cancel_vaccination_notification_ids';

  /// Викликати раз при старті застосунку (main.dart) — AppDatabase-міграція
  /// 30 залишає тут id тих щеплень, чиї нагадування вже могли бути
  /// заплановані до оновлення (сама міграція, суто SQL-контекст, не має
  /// доступу до плагіна сповіщень, щоб скасувати їх напряму).
  static Future<void> cancelStalePendingVaccinationReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_pendingCancelVaccinationIdsKey);
    if (ids == null || ids.isEmpty) return;
    for (final raw in ids) {
      final id = int.tryParse(raw);
      if (id != null) await cancelVaccinationReminder(id);
    }
    await prefs.remove(_pendingCancelVaccinationIdsKey);
  }

}
