// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appName => 'MedKit';

  @override
  String get navToday => 'Сьогодні';

  @override
  String get navMeds => 'Ліки';

  @override
  String get navFamily => 'Сім\'я';

  @override
  String get navProfile => 'Профіль';

  @override
  String todayProgressTitle(int taken, int total) {
    return '$taken з $total';
  }

  @override
  String get todayProgressSubtitle => 'ліків прийнято сьогодні';

  @override
  String todayProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get sectionFamily => 'Сім\'я';

  @override
  String get sectionScheduled => 'Заплановано';

  @override
  String get sectionDone => 'Виконано';

  @override
  String get actionAll => 'Всі';

  @override
  String get intakeTaken => 'Прийнято';

  @override
  String get intakeSkipped => 'Пропущено';

  @override
  String get intakeTake => '✓';

  @override
  String get intakeSkip => '✕';

  @override
  String get comingSoon => 'Незабаром';
}
