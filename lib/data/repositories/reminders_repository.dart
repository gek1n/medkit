import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../db/creator_info.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/notification_service.dart';

class RemindersRepository {
  final AppDatabase _db;
  final Ref _ref;
  RemindersRepository(this._db, this._ref);

  Stream<List<Reminder>> watchAll() =>
      (_db.select(_db.reminders)
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .watch();

  Stream<Reminder?> watchById(int id) =>
      (_db.select(_db.reminders)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<Reminder>> watchByMember(int memberId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  // Для Простору — нагадування, прив'язані до конкретного розділу.
  Stream<List<Reminder>> watchBySection(int sectionId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  // Для Розкладу — на відміну від watchByMember (використовує й Архів, де
  // потрібна повна історія включно з виконаними/скасованими), тут лише
  // "живі" нагадування. Для daily/weekly/monthly/yearly status завжди
  // лишається 'pending' (нема стану "сьогоднішнього" виконання — див.
  // watchActiveOnDate), тож повторювані нагадування це не ховає, доки серія
  // не видалена цілком.
  Stream<List<Reminder>> watchActiveByMember(int memberId) {
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.memberId.equals(memberId) & t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchUpcoming(int memberId) {
    final now = DateTime.now();
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<Reminder>> watchByDate(int memberId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  // Час(и) спрацювання КОНКРЕТНОГО нагадування у вказаний день, або
  // порожній список, якщо воно неактивне цього дня — єдине джерело правди
  // для watchActiveOnDate (показ на Сьогодні/Розкладі) і
  // ReminderLogGenerator (per-occurrence лог виконання), щоб їхня логіка
  // не розходилась.
  Future<List<DateTime>> occurrencesOnDate(Reminder r, DateTime date) async {
    // slots потрібні лише для daily/weekly — не питаємо БД для решти типів.
    final needsSlots = r.repeatType == 'daily' || r.repeatType == 'weekly';
    final slots = needsSlots ? await getSlotsForReminder(r.id) : const <ReminderSlot>[];
    return occurrencesOnDateForSlots(r, date, slots);
  }

  // Той самий розрахунок, що й occurrencesOnDate вище, але слоти передаються
  // напряму — єдине джерело правди і для локальних нагадувань (через
  // occurrencesOnDate, БД), і для календарного вигляду піра (Крок 4.3-подібна
  // робота, schedule_calendar_data.dart), де слотів у локальній БД взагалі
  // нема — лише вже перекладений peerReminderSlotsProvider.
  List<DateTime> occurrencesOnDateForSlots(
      Reminder r, DateTime date, List<ReminderSlot> slots) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final anchorDay =
        DateTime(r.scheduledAt.year, r.scheduledAt.month, r.scheduledAt.day);
    switch (r.repeatType) {
      case 'daily':
        if (anchorDay.isAfter(dayStart)) return const [];
        if (slots.isEmpty) return [dayStart];
        return slots.map((s) => _atTimeOfDay(dayStart, s.timeOfDay)).toList();
      case 'weekly':
        if (anchorDay.isAfter(dayStart)) return const [];
        var days = <int>{};
        try {
          final cfg = jsonDecode(r.repeatConfig) as Map<String, dynamic>;
          days = Set<int>.from(cfg['days'] as List);
        } catch (_) {}
        if (!days.contains(date.weekday)) return const [];
        if (slots.isEmpty) return [dayStart];
        return slots.map((s) => _atTimeOfDay(dayStart, s.timeOfDay)).toList();
      case 'yearly':
        if (r.scheduledAt.month != date.month || r.scheduledAt.day != date.day) {
          return const [];
        }
        return [
          DateTime(date.year, date.month, date.day, r.scheduledAt.hour,
              r.scheduledAt.minute)
        ];
      case 'monthly':
        // scheduledAt.month завжди зафіксовано на січні (форма зберігає
        // якір саме так — див. AddAppointmentScreen), тож тут важливий
        // лише .day; для коротших місяців (напр. 31 у лютому) день
        // клемпиться до останнього дня місяця — так само, як і в
        // NotificationService.scheduleMonthlyReminder.
        final daysInTargetMonth = DateTime(date.year, date.month + 1, 0).day;
        final targetDay = r.scheduledAt.day > daysInTargetMonth
            ? daysInTargetMonth
            : r.scheduledAt.day;
        if (date.day != targetDay) return const [];
        return [
          DateTime(date.year, date.month, date.day, r.scheduledAt.hour,
              r.scheduledAt.minute)
        ];
      default:
        return anchorDay == dayStart ? [r.scheduledAt] : const [];
    }
  }

  // Нагадування, що фактично "спрацьовують" у вказаний день — на відміну
  // від watchByDate (буквальний збіг дати), тут враховуються daily/weekly/
  // monthly/yearly повтори (occurrencesOnDate). Мультислотові daily/weekly
  // розгортаються в окремий Reminder-об'єкт (copyWith) на кожен час —
  // scheduledAt кожної копії підмінюється на реальний час ЦЬОГО дня, щоб
  // існуючий UI (сортування/класифікація за scheduledAt) працював без змін.
  Stream<List<Reminder>> watchActiveOnDate(int memberId, DateTime date) {
    return watchByMember(memberId).asyncMap((reminders) async {
      final result = <Reminder>[];
      for (final r in reminders) {
        // Одне пошкоджене нагадування (напр. успадкований NULL у службовому
        // полі ReminderSlots зі старого запису) не повинно ховати з екрана
        // геть УСІ нагадування цього профілю — без цього try/catch один
        // такий запис обривав весь стрім (AsyncValue.error), і Сьогодні
        // мовчки показувало порожній список нагадувань замість здорових
        // решти. Той самий принцип, що й у ReminderLogGenerator.
        try {
          final occurrences = await occurrencesOnDate(r, date);
          for (final at in occurrences) {
            result.add(r.copyWith(scheduledAt: at));
          }
        } catch (e, st) {
          AppLogger.logError('RemindersRepository.watchActiveOnDate(reminderId=${r.id})', e, st);
        }
      }
      result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return result;
    });
  }

  DateTime _atTimeOfDay(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  // Планує сповіщення для вже вставленого нагадування (реальний id/memberId
  // обов'язкові) — спільна логіка для форми створення й фіналізації
  // онбординг-чернеток (де сповіщення відкладені до появи реального
  // профілю), щоб не дублювати цей switch у двох місцях.
  Future<void> scheduleNotificationsForReminder(
    Reminder reminder, {
    List<String> slotTimes = const [],
  }) async {
    final settings = _ref.read(notificationSettingsProvider);
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(reminder.memberId)))
        .getSingleOrNull();
    final memberName = member?.name ?? '';
    final scheduledAt = reminder.scheduledAt;

    List<(int, int)> adjustedSlots() {
      final adjusted = <(int, int)>[];
      for (final s in slotTimes) {
        final parts = s.split(':');
        final now = DateTime.now();
        final raw = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final at = settings.adjust(raw, memberId: reminder.memberId);
        if (at != null) adjusted.add((at.hour, at.minute));
      }
      // Реальний випадок (08.08): AddAppointmentScreen._save() спершу
      // скасовує ВСІ можливі варіанти (cancelRecurringReminder, до 80
      // сповіщень), потім планує заново — якщо slotTimes прийшли порожні
      // АБО adjust() відфільтрував усі (pushEnabled=false чи
      // isMemberEnabled(memberId)=false саме для цього профілю), нижче
      // (daily/weekly) просто НІЧОГО не планувалось — без жодного логу чи
      // помилки, виглядало як "нагадування зникло в нікуди". Тепер видно
      // причину замість здогадок по 10 білдах.
      if (adjusted.isEmpty && slotTimes.isNotEmpty) {
        AppLogger.log(
            'RemindersRepository.scheduleNotificationsForReminder(id=${reminder.id}): '
            'adjustedSlots() порожній — slotTimes=$slotTimes, pushEnabled=${settings.pushEnabled}, '
            'memberEnabled=${settings.isMemberEnabled(reminder.memberId)} — нічого не заплановано.');
      }
      return adjusted;
    }

    // Кожна гілка нижче СПЕРШУ планує нове (кожен NotificationService.*
    // виклик перезаписує свої id на місці й сам прибирає "хвости" в межах
    // своєї ж групи варіантів), і лише ПОТІМ, після успішного планування,
    // прибирається чуже: одноразові appointment-id мають сенс лише для
    // 'none', тож для решти типів вони застарілі й підлягають скасуванню;
    // а якщо для 'none'/'yearly'/'monthly' взагалі нічого не заплановано
    // (adjust() відфільтрував — settings), то й recurring-варіанти
    // (з попереднього daily/weekly) теж застарілі. Раніше було навпаки —
    // спершу скасовували ВСЕ, потім намагались перепланувати — і будь-яка
    // помилка чи порожній результат посередині лишав користувача без
    // жодного сповіщення (саме так зник алярм на 15:00 08.08).
    switch (reminder.repeatType) {
      case 'none':
        final rawReminderAt =
            scheduledAt.subtract(Duration(minutes: reminder.remindBeforeMin));
        final remindAt = settings.adjust(rawReminderAt, memberId: reminder.memberId);
        if (remindAt != null) {
          await NotificationService.scheduleAppointmentReminder(
            appointmentId: reminder.id,
            memberName: memberName,
            doctorType: reminder.doctorType,
            location: reminder.location,
            scheduledAt: remindAt,
            remindBeforeMin: 0,
            vibrationEnabled: settings.vibrationEnabled,
            repeatMinutes: settings.repeatMinutes,
          );
        } else {
          await NotificationService.cancelAppointmentReminder(reminder.id);
        }
        await NotificationService.cancelRecurringReminder(reminder.id);
        break;
      case 'yearly':
        {
          final rawReminderAt = scheduledAt
              .subtract(Duration(minutes: reminder.remindBeforeMin));
          final remindAt =
              settings.adjust(rawReminderAt, memberId: reminder.memberId);
          if (remindAt != null) {
            await NotificationService.scheduleYearlyReminder(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              location: reminder.location,
              date: remindAt,
              remindBeforeMin: 0,
              vibrationEnabled: settings.vibrationEnabled,
            );
          } else {
            await NotificationService.cancelRecurringReminder(reminder.id);
          }
          await NotificationService.cancelAppointmentReminder(reminder.id);
        }
        break;
      case 'monthly':
        {
          final rawReminderAt = scheduledAt
              .subtract(Duration(minutes: reminder.remindBeforeMin));
          final remindAt =
              settings.adjust(rawReminderAt, memberId: reminder.memberId);
          if (remindAt != null) {
            await NotificationService.scheduleMonthlyReminder(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              location: reminder.location,
              dayOfMonth: remindAt.day,
              hour: remindAt.hour,
              minute: remindAt.minute,
              vibrationEnabled: settings.vibrationEnabled,
            );
          } else {
            await NotificationService.cancelRecurringReminder(reminder.id);
          }
          await NotificationService.cancelAppointmentReminder(reminder.id);
        }
        break;
      case 'daily':
        {
          if (slotTimes.isEmpty) {
            AppLogger.log(
                'RemindersRepository.scheduleNotificationsForReminder(id=${reminder.id}, daily): '
                'slotTimes порожній на вході — нічого й планувати.');
          }
          final adjusted = adjustedSlots();
          if (adjusted.isNotEmpty) {
            await NotificationService.scheduleDailyReminderSlots(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              slots: adjusted,
              vibrationEnabled: settings.vibrationEnabled,
            );
          } else {
            await NotificationService.cancelRecurringReminder(reminder.id);
          }
          await NotificationService.cancelAppointmentReminder(reminder.id);
        }
        break;
      case 'weekly':
        {
          var weekdays = <int>[];
          try {
            final cfg =
                jsonDecode(reminder.repeatConfig) as Map<String, dynamic>;
            weekdays = List<int>.from(cfg['days'] as List);
          } catch (_) {}
          if (slotTimes.isEmpty) {
            AppLogger.log(
                'RemindersRepository.scheduleNotificationsForReminder(id=${reminder.id}, weekly): '
                'slotTimes порожній на вході — нічого й планувати.');
          }
          // weekdays порожній — scheduleWeeklyReminderSlots усе одно
          // викликається нижче (adjusted тут ні до чого), але його
          // подвійний цикл (weekday × slot) не зробить жодної ітерації —
          // так само тихо, як і adjustedSlots() вище, лише інша причина.
          if (weekdays.isEmpty) {
            AppLogger.log(
                'RemindersRepository.scheduleNotificationsForReminder(id=${reminder.id}, weekly): '
                'weekdays порожній (repeatConfig=${reminder.repeatConfig}) — жодного дня тижня не заплановано.');
          }
          final adjusted = adjustedSlots();
          if (adjusted.isNotEmpty && weekdays.isNotEmpty) {
            await NotificationService.scheduleWeeklyReminderSlots(
              reminderId: reminder.id,
              memberName: memberName,
              title: reminder.doctorType,
              weekdays: weekdays,
              slots: adjusted,
              vibrationEnabled: settings.vibrationEnabled,
            );
          } else {
            await NotificationService.cancelRecurringReminder(reminder.id);
          }
          await NotificationService.cancelAppointmentReminder(reminder.id);
        }
        break;
    }
  }

  // NotificationService.scheduleMonthlyReminder планує наперед лише
  // monthsAhead (12) окремих одноразових сповіщень — на відміну від
  // daily/weekly/yearly (там нативний matchDateTimeComponents-повтор, ОС сама
  // повторює безкінечно), тут вікно СКІНЧЕННЕ. Без цього методу нагадування
  // "раз на місяць", створене й жодного разу не відредаговане понад ~12
  // місяців, тихо переставало б спрацьовувати назавжди — саме так виглядав
  // реальний звіт "нагадування, створене давно, більше не приходить".
  // Викликається на холодному старті (main.dart) — просто перепланувати ще
  // раз (той самий scheduleNotificationsForReminder, що й при збереженні):
  // кожен варіант перезаписує свій id на місці (safe idempotent overwrite,
  // той самий принцип, що й rescheduleRecurringVariant), тож вікно
  // "від'їжджає" вперед за поточним "зараз" щоразу, коли користувач хоч раз
  // відкриває застосунок протягом 12 місяців — а не лише в момент
  // створення/редагування нагадування.
  Future<void> refreshMonthlyReminderWindows() async {
    final pending = await (_db.select(_db.reminders)
          ..where((t) => t.status.equals('pending') & t.repeatType.equals('monthly')))
        .get();
    for (final reminder in pending) {
      try {
        await scheduleNotificationsForReminder(reminder);
      } catch (e, st) {
        AppLogger.logError(
            'RemindersRepository.refreshMonthlyReminderWindows(id=${reminder.id})', e, st);
      }
    }
  }

  Future<int> insert(RemindersCompanion appointment) async {
    final creator = await ownCreatorInfo(_db);
    final id = await _db.into(_db.reminders).insert(appointment);
    await recordCreator(_db, 'doctor_appointment', id, creator);
    return id;
  }

  Future<List<ReminderSlot>> getSlotsForReminder(int reminderId) =>
      (_db.select(_db.reminderSlots)
            ..where((t) => t.reminderId.equals(reminderId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> replaceSlots(
    int reminderId,
    List<ReminderSlotsCompanion> slots,
  ) async {
    await (_db.delete(_db.reminderSlots)
          ..where((t) => t.reminderId.equals(reminderId)))
        .go();
    for (final s in slots) {
      await _db.into(_db.reminderSlots).insert(s);
    }
  }

  // ⚠️ НЕ .replace() — вимагає всі required-колонки (напр. memberId), а
  // екрани редагування передають лише змінені поля без memberId.
  Future<bool> update(RemindersCompanion appointment) async {
    final rows = await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(appointment.id.value)))
        .write(appointment);
    return rows > 0;
  }

  Future<int> delete(int id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  Future<void> markAttended(int id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      status: const Value('attended'),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);
  }

  Future<void> markSkipped(int id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      status: const Value('skipped'),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);
  }

  Future<void> reschedule(int id, DateTime newTime) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
        .write(RemindersCompanion(
      scheduledAt: Value(newTime),
      updatedAt: Value(DateTime.now()),
    ));
    await NotificationService.cancelAppointmentReminder(id);

    final appt = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (appt == null) return;
    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(appt.memberId)))
        .getSingleOrNull();

    final settings = _ref.read(notificationSettingsProvider);
    final rawReminderAt =
        newTime.subtract(Duration(minutes: appt.remindBeforeMin));
    final remindAt = settings.adjust(rawReminderAt, memberId: appt.memberId);
    if (remindAt != null) {
      await NotificationService.scheduleAppointmentReminder(
        appointmentId: id,
        memberName: member?.name ?? '',
        doctorType: appt.doctorType,
        location: appt.location,
        scheduledAt: remindAt,
        remindBeforeMin: 0,
        vibrationEnabled: settings.vibrationEnabled,
        repeatMinutes: settings.repeatMinutes,
      );
    }
  }

  // ── ReminderLogs: per-occurrence виконання для daily/weekly/monthly/
  // yearly (репетувані serії) — окремо від Reminders.status, який має сенс
  // лише для repeatType=='none'. #225: markLogDone/markLogSkipped нижче
  // тепер ЧІПАЄ й саме сповіщення (через _suppressTodayNotification) —
  // раніше не чіпало, лишаючи вже заплановане нативне спрацювання живим
  // навіть після позначення "зроблено" заздалегідь.

  Stream<List<ReminderLog>> watchLogsByMemberAndDate(
    int memberId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.reminderLogs)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.scheduledAt.isBiggerOrEqualValue(start) &
              t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Future<void> markLogDone(int logId) async {
    final log = await (_db.select(_db.reminderLogs)..where((t) => t.id.equals(logId))).getSingleOrNull();
    await (_db.update(_db.reminderLogs)..where((t) => t.id.equals(logId)))
        .write(ReminderLogsCompanion(
      status: const Value('done'),
      updatedAt: Value(DateTime.now()),
    ));
    if (log != null) await _suppressTodayNotification(log.reminderId, log.scheduledAt);
  }

  Future<void> markLogSkipped(int logId) async {
    final log = await (_db.select(_db.reminderLogs)..where((t) => t.id.equals(logId))).getSingleOrNull();
    await (_db.update(_db.reminderLogs)..where((t) => t.id.equals(logId)))
        .write(ReminderLogsCompanion(
      status: const Value('skipped'),
      updatedAt: Value(DateTime.now()),
    ));
    if (log != null) await _suppressTodayNotification(log.reminderId, log.scheduledAt);
  }

  // #225: реальний баг — позначити "зроблено"/"пропущено" ЗАЗДАЛЕГІДЬ (до
  // власного часу випадку) раніше ніяк не впливало на вже заплановане
  // нативно-повторюване сповіщення (воно й далі спрацьовувало на власний
  // час, попри те що на Сьогодні пункт уже показувався виконаним). Тепер
  // придушуємо саме сьогоднішнє спрацювання без ламання повтору на
  // майбутнє — деталі різні для кожного типу повтору:
  // - monthly: кожне майбутнє входження — окремий одноразовий варіант з
  //   ІНШИМ id (scheduleMonthlyReminder планує наперед на 12 місяців) —
  //   досить прибрати варіант 0 (найближче/сьогоднішнє входження),
  //   решта місяців лишаються незайманими.
  // - yearly: один нативно-повторюваний варіант (0) на весь запис —
  //   перепланувати його на той самий день/час, але вже НАСТУПНОГО року.
  // - daily: один варіант на слот (позиція = sortOrder серед
  //   RemindersSlots) — перепланувати ТОЙ САМИЙ варіант на завтра.
  // - weekly: варіант = індекс дня тижня (у порядку, збереженому в
  //   repeatConfig) × кількість слотів + індекс слоту (той самий порядок,
  //   що й у NotificationService.scheduleWeeklyReminderSlots) —
  //   перепланувати той самий варіант на наступний тиждень.
  // Якщо власний час випадку вже минув — придушувати нічого (сповіщення
  // або вже спрацювало, або природно не спрацює для минулого часу).
  Future<void> _suppressTodayNotification(int reminderId, DateTime scheduledAt) async {
    if (!scheduledAt.isAfter(DateTime.now())) return;
    final reminder =
        await (_db.select(_db.reminders)..where((t) => t.id.equals(reminderId))).getSingleOrNull();
    if (reminder == null) return;

    String hhmm(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    switch (reminder.repeatType) {
      case 'monthly':
        await NotificationService.cancel(NotificationService.recurringReminderNotificationId(reminderId, 0));
        break;
      case 'yearly':
        await NotificationService.rescheduleRecurringVariant(
          reminderId: reminderId,
          variant: 0,
          memberName: await _memberNameFor(reminder.memberId),
          title: reminder.doctorType,
          location: reminder.location,
          at: DateTime(scheduledAt.year + 1, scheduledAt.month, scheduledAt.day, scheduledAt.hour, scheduledAt.minute),
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        break;
      case 'daily':
        {
          final slots = await getSlotsForReminder(reminderId);
          final idx = slots.indexWhere((s) => s.timeOfDay == hhmm(scheduledAt));
          if (idx == -1) return;
          await NotificationService.rescheduleRecurringVariant(
            reminderId: reminderId,
            variant: idx,
            memberName: await _memberNameFor(reminder.memberId),
            title: reminder.doctorType,
            at: scheduledAt.add(const Duration(days: 1)),
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
        break;
      case 'weekly':
        {
          var weekdays = <int>[];
          try {
            final cfg = jsonDecode(reminder.repeatConfig) as Map<String, dynamic>;
            weekdays = List<int>.from(cfg['days'] as List);
          } catch (_) {}
          final weekdayIdx = weekdays.indexOf(scheduledAt.weekday);
          if (weekdayIdx == -1) return;
          final slots = await getSlotsForReminder(reminderId);
          final slotIdx = slots.indexWhere((s) => s.timeOfDay == hhmm(scheduledAt));
          if (slotIdx == -1) return;
          await NotificationService.rescheduleRecurringVariant(
            reminderId: reminderId,
            variant: weekdayIdx * slots.length + slotIdx,
            memberName: await _memberNameFor(reminder.memberId),
            title: reminder.doctorType,
            at: scheduledAt.add(const Duration(days: 7)),
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;
      default:
        // 'none' — обробляється markAttended (одноразове scheduleAppointmentReminder), не тут.
        break;
    }
  }

  Future<String> _memberNameFor(int memberId) async {
    final member = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingleOrNull();
    return member?.name ?? '';
  }

  // Лише переносить відображення на Сьогодні (сам натив-повторюваний алярм
  // ОС не можна перепланувати для "тільки цього випадку" — див. коментар
  // над ReminderLogs) — тому snoozedUntil суто локальний UI-стан.
  Future<void> snoozeLog(int logId, DateTime until) =>
      (_db.update(_db.reminderLogs)..where((t) => t.id.equals(logId))).write(
        ReminderLogsCompanion(
          snoozedUntil: Value(until),
          updatedAt: Value(DateTime.now()),
        ),
      );
}

final remindersRepositoryProvider =
    Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.watch(databaseProvider), ref);
});
