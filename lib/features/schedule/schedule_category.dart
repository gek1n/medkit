import 'package:flutter/material.dart';

import '../../core/utils/l10n_ext.dart';

// 4 типізовані категорії (той самий порядок, що й у пікері створення
// завдання) + "Всі". Нагадування — об'єднана форма (заміна Зустрічі/Спорт/
// Прості завдання), завжди з таблиці Reminders. Рутинні справи — окремо,
// це Activities зі службовим (прихованим від юзера) type == 'routine'.
//
// Окремий файл (не всередині schedule_screen.dart) — категорія потрібна і
// списковому, і календарному вигляду Розкладу, а вони імпортують одне
// одного (schedule_screen.dart -> ScheduleCalendarView, view -> дані), тож
// спільний тип виносимо, щоб не створювати циклічний імпорт.
enum ScheduleCategory { all, meds, reminders, routine, wellbeing }

extension ScheduleCategoryX on ScheduleCategory {
  IconData get icon => switch (this) {
        ScheduleCategory.all => Icons.grid_view_rounded,
        ScheduleCategory.meds => Icons.medication_rounded,
        ScheduleCategory.reminders => Icons.notifications_rounded,
        ScheduleCategory.routine => Icons.home_repair_service_rounded,
        ScheduleCategory.wellbeing => Icons.favorite_rounded,
      };

  // "Всі" не має власного task_*-асета (це не окремий тип, а перемикач
  // показу всіх одразу) — лишається на Material-іконці.
  String? get assetKey => switch (this) {
        ScheduleCategory.all => null,
        ScheduleCategory.meds => 'box',
        ScheduleCategory.reminders => 'task_reminder',
        ScheduleCategory.routine => 'task_routine',
        ScheduleCategory.wellbeing => 'task_wellbeing',
      };

  String label(BuildContext context) => switch (this) {
        ScheduleCategory.all => context.l10n.categoryAll,
        ScheduleCategory.meds => context.l10n.categoryMeds,
        ScheduleCategory.reminders => context.l10n.reminderCategoryTitle,
        ScheduleCategory.routine => context.l10n.taskTypeRoutine,
        ScheduleCategory.wellbeing => context.l10n.categoryWellbeing,
      };
}
