import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/app_logger.dart';
import '../services/notification_service.dart';
import '../services/schedule_occurrence_calculator.dart';
import '../../data/db/app_database.dart';

// Генерує записи intakes для конкретного дня на основі schedules і налаштувань повтору
class IntakeGenerator {
  final AppDatabase _db;
  final Ref _ref;
  IntakeGenerator(this._db, this._ref);

  Future<void> generateForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final meds = await _db.select(_db.medications).get();

    for (final med in meds) {
      // Одна невдала спроба (напр. зіпсований JSON у phases, чи виняток від
      // zonedSchedule — брак дозволу на точні будильники тощо) не повинна
      // обривати генерацію для решти ліків — інакше одні погані ліки мовчки
      // "з'їдають" нагадування для всіх наступних ліків/членів сім'ї в
      // цьому ж виклику (решта цикла нижче по списку просто не виконалась б).
      try {
        await _generateForMedication(med, day, cutoff);
      } catch (e, st) {
        AppLogger.logError('IntakeGenerator.medication(id=${med.id})', e, st);
      }
    }
  }

  Future<void> _generateForMedication(
    Medication med,
    DateTime day,
    DateTime cutoff,
  ) async {
    if (!med.isActive) return;
    if (!medicationOccursOnDate(med, day)) return;

    final member = await (_db.select(_db.members)
          ..where((t) => t.id.equals(med.memberId)))
        .getSingleOrNull();
    final memberName = member?.name ?? '';

    // Determine times to generate — та сама логіка, що й для пірів
    // (schedule_occurrence_calculator.dart), лише schedules тут читаються з
    // локальної БД, а не з синхронізованого кешу.
    final schedules = med.phases != null
        ? const <Schedule>[]
        : await (_db.select(_db.schedules)
                ..where((t) => t.medicationId.equals(med.id)))
              .get();
    final times = medicationTimesForDate(med, schedules, day);

    // Generate intakes for each time
    for (final timeStr in times) {
      // Так само, як і в зовнішньому try/catch — одна погана позиція часу
      // не повинна обривати генерацію решти прийомів для цих же ліків.
      try {
        final parts = timeStr.split(':');
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        // Не створюємо записи більш ніж на годину в минулому —
        // це заважає щойно доданим лікам одразу заповнити
        // сьогоднішній розклад пропущеними прийомами.
        // Виняток — сам день створення запису: інакше ліки, додані
        // сьогодні з часом прийому, що вже минув, взагалі не отримують
        // жодного інтейку на сьогодні — і зникають з календарного виду
        // Розкладу (#312), хоча в списковому вигляді (курс) видно одразу.
        final isCreationDay = day.year == med.createdAt.year &&
            day.month == med.createdAt.month &&
            day.day == med.createdAt.day;
        if (scheduledAt.isBefore(cutoff) && !isCreationDay) continue;

        // Check duplicate using medication + scheduledAt
        final exists =
            await (_db.select(_db.intakes)..where(
                  (t) =>
                      t.medicationId.equals(med.id) &
                      t.scheduledAt.equals(scheduledAt),
                ))
                .getSingleOrNull();
        if (exists != null) continue;

        // For phase-based meds, use scheduleId = 0
        final scheduleId = med.phases != null
            ? 0
            : (await (_db.select(_db.schedules)
                            ..where((t) => t.medicationId.equals(med.id))
                            ..limit(1))
                          .getSingleOrNull())
                      ?.id ??
                  0;

        final intakeId = await _db
            .into(_db.intakes)
            .insert(
              IntakesCompanion.insert(
                scheduleId: scheduleId,
                medicationId: med.id,
                memberId: med.memberId,
                scheduledAt: scheduledAt,
              ),
            );

        final settings = _ref.read(notificationSettingsProvider);
        final dose = '${med.doseAmount} ${med.doseUnit}';
        final remindAt = settings.adjust(scheduledAt, memberId: med.memberId);
        if (remindAt != null) {
          await NotificationService.scheduleIntakeReminder(
            intakeId: intakeId,
            memberName: memberName,
            medName: med.name,
            dose: dose,
            scheduledAt: remindAt,
            vibrationEnabled: settings.vibrationEnabled,
            repeatMinutes: settings.repeatMinutes,
          );
        }
      } catch (e, st) {
        AppLogger.logError(
          'IntakeGenerator.time(medicationId=${med.id}, time=$timeStr)',
          e,
          st,
        );
      }
    }
  }

}

final intakeGeneratorProvider = Provider<IntakeGenerator>((ref) {
  return IntakeGenerator(ref.watch(databaseProvider), ref);
});
