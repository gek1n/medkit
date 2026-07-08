// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Elly';

  @override
  String get navAdd => 'Add';

  @override
  String get navToday => 'Today';

  @override
  String get navMeds => 'Schedule';

  @override
  String get navFamily => 'Family';

  @override
  String get navProfile => 'Profile';

  @override
  String get navMedCard => 'Med Card';

  @override
  String todayProgressTitle(int taken, int total) {
    return '$taken of $total';
  }

  @override
  String get todayProgressSubtitle => 'medications taken today';

  @override
  String todayProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get sectionFamily => 'Family';

  @override
  String get sectionScheduled => 'Scheduled';

  @override
  String get sectionDone => 'Done';

  @override
  String get actionAll => 'All';

  @override
  String get intakeTaken => 'Taken';

  @override
  String get intakeSkipped => 'Skipped';

  @override
  String get intakeTake => '✓';

  @override
  String get intakeSkip => '✕';

  @override
  String get comingSoon => 'Coming soon';
}
