// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MedKit';

  @override
  String get navToday => 'Today';

  @override
  String get navMeds => 'Meds';

  @override
  String get navFamily => 'Family';

  @override
  String get navProfile => 'Profile';

  @override
  String get todayGreeting => 'Hello! 👋';

  @override
  String todayLegendTaken(int count) {
    return '$count taken';
  }

  @override
  String todayLegendPending(int count) {
    return '$count pending';
  }

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
  String get todayAllDone => 'All medications taken 🎉';

  @override
  String get todayNothingPlanned => 'Nothing planned for today';

  @override
  String get sectionFamily => 'Family';

  @override
  String get sectionScheduled => 'Scheduled';

  @override
  String get sectionDone => 'Done';

  @override
  String get actionAll => 'All';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get intakeTaken => 'Taken';

  @override
  String get intakeSkipped => 'Skipped';

  @override
  String get intakeTake => 'Take';

  @override
  String get intakeSkip => 'Skip';

  @override
  String get medsTitle => 'My Medications';

  @override
  String get medsEmpty => 'No medications added yet';

  @override
  String get medsEmptyHint => 'Tap + to add your first medication';

  @override
  String medsRemaining(int count) {
    return 'Remaining: $count pcs.';
  }

  @override
  String medsDaysLeft(int days) {
    return '$days days';
  }

  @override
  String get medsActive => 'Active';

  @override
  String get medsArchived => 'Archived';

  @override
  String get medsFreeLimitTitle => 'Free plan limit';

  @override
  String medsFreeLimitBody(int max) {
    return 'Free plan allows up to $max medications. Upgrade to Pro for unlimited.';
  }

  @override
  String get addMedTitle => 'New Medication';

  @override
  String get addMedName => 'Medication name';

  @override
  String get addMedNameHint => 'E.g.: Enalapril';

  @override
  String get addMedDose => 'Dose';

  @override
  String get addMedDoseHint => 'E.g.: 10 mg';

  @override
  String get addMedForm => 'Form';

  @override
  String get addMedFood => 'Food relation';

  @override
  String get addMedTotal => 'Package quantity';

  @override
  String get addMedInstructions => 'Instructions (optional)';

  @override
  String get addMedInstructionsHint => 'Special doctor instructions';

  @override
  String get medFormTablet => 'Tablets';

  @override
  String get medFormCapsule => 'Capsules';

  @override
  String get medFormSyrup => 'Syrup';

  @override
  String get medFormDrops => 'Drops';

  @override
  String get medFormCream => 'Cream / ointment';

  @override
  String get medFormInhaler => 'Inhaler';

  @override
  String get medFormInjection => 'Injection';

  @override
  String get medFormOther => 'Other';

  @override
  String get foodBefore => 'Before meal';

  @override
  String get foodAfter => 'After meal';

  @override
  String get foodWith => 'With meal';

  @override
  String get foodAny => 'Any time';

  @override
  String get familyTitle => 'Family';

  @override
  String get familyAdherenceToday => 'Today\'s adherence';

  @override
  String get familyAddMember => 'Add family member';

  @override
  String get familyProRequired => 'Family mode';

  @override
  String get familyProBody =>
      'Track medications for all family members. Available in Pro plan.';

  @override
  String get familyMemberOwner => 'Owner';

  @override
  String get familyMemberMember => 'Member';

  @override
  String get familyMemberDependent => 'Dependent';

  @override
  String familyMedsToday(int taken, int total) {
    return '$taken/$total meds';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileMyProfile => 'My Profile';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageUk => 'Ukrainian';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsHint => 'Medication reminders';

  @override
  String get profileExportData => 'Export data';

  @override
  String get profileExportDataHint => 'Save as CSV or PDF';

  @override
  String get profileAnalytics => 'Adherence analytics';

  @override
  String get profileAnalyticsHint => 'Charts and statistics';

  @override
  String get profileAbout => 'About';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get proTitle => 'MedKit Pro';

  @override
  String get proSubtitle => 'Unlock all features';

  @override
  String get proFeatureFamily => 'Unlimited family members';

  @override
  String get proFeatureReminders => 'Smart reminders';

  @override
  String get proFeatureExport => 'Data export';

  @override
  String get proFeatureAnalytics => 'Detailed analytics';

  @override
  String get proUpgradeButton => 'Upgrade to Pro';

  @override
  String get proBadge => 'PRO';

  @override
  String get proLockedHint => 'Available in Pro plan';

  @override
  String get wellbeingTitle => 'Wellbeing';

  @override
  String get wellbeingQuestion => '💜 How are you feeling right now?';

  @override
  String get wellbeingBad => 'Bad';

  @override
  String get wellbeingMeh => 'So-so';

  @override
  String get wellbeingOk => 'Okay';

  @override
  String get wellbeingGood => 'Good';

  @override
  String get wellbeingGreat => 'Great';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get errorRequired => 'Required field';

  @override
  String errorMinLength(int min) {
    return 'Minimum $min characters';
  }
}
