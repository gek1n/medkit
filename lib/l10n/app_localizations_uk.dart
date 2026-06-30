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
  String get todayGreeting => 'Привіт! 👋';

  @override
  String todayLegendTaken(int count) {
    return '$count прийнято';
  }

  @override
  String todayLegendPending(int count) {
    return '$count очікує';
  }

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
  String get todayAllDone => 'Всі ліки прийнято 🎉';

  @override
  String get todayNothingPlanned => 'На сьогодні нічого не заплановано';

  @override
  String get sectionFamily => 'Сім\'я';

  @override
  String get sectionScheduled => 'Заплановано';

  @override
  String get sectionDone => 'Виконано';

  @override
  String get actionAll => 'Всі';

  @override
  String get actionAdd => 'Додати';

  @override
  String get actionSave => 'Зберегти';

  @override
  String get actionCancel => 'Скасувати';

  @override
  String get actionDelete => 'Видалити';

  @override
  String get actionEdit => 'Редагувати';

  @override
  String get intakeTaken => 'Прийнято';

  @override
  String get intakeSkipped => 'Пропущено';

  @override
  String get intakeTake => 'Прийняти';

  @override
  String get intakeSkip => 'Пропустити';

  @override
  String get medsTitle => 'Мої ліки';

  @override
  String get medsEmpty => 'Ліки ще не додані';

  @override
  String get medsEmptyHint => 'Натисніть + щоб додати перший препарат';

  @override
  String medsRemaining(int count) {
    return 'Залишилось: $count шт.';
  }

  @override
  String medsDaysLeft(int days) {
    return '$days дн.';
  }

  @override
  String get medsActive => 'Активні';

  @override
  String get medsArchived => 'Архів';

  @override
  String get medsFreeLimitTitle => 'Ліміт безкоштовного тарифу';

  @override
  String medsFreeLimitBody(int max) {
    return 'У безкоштовному тарифі можна додати до $max препаратів. Перейдіть на Pro для необмеженої кількості.';
  }

  @override
  String get addMedTitle => 'Новий препарат';

  @override
  String get addMedName => 'Назва препарату';

  @override
  String get addMedNameHint => 'Наприклад: Еналаприл';

  @override
  String get addMedDose => 'Доза';

  @override
  String get addMedDoseHint => 'Наприклад: 10 мг';

  @override
  String get addMedForm => 'Форма випуску';

  @override
  String get addMedFood => 'Відношення до їжі';

  @override
  String get addMedTotal => 'Кількість у упаковці';

  @override
  String get addMedInstructions => 'Інструкції (необов\'язково)';

  @override
  String get addMedInstructionsHint => 'Особливі вказівки лікаря';

  @override
  String get medFormTablet => 'Таблетки';

  @override
  String get medFormCapsule => 'Капсули';

  @override
  String get medFormSyrup => 'Сироп';

  @override
  String get medFormDrops => 'Краплі';

  @override
  String get medFormCream => 'Мазь / крем';

  @override
  String get medFormInhaler => 'Інгалятор';

  @override
  String get medFormInjection => 'Ін\'єкція';

  @override
  String get medFormOther => 'Інше';

  @override
  String get foodBefore => 'До їжі';

  @override
  String get foodAfter => 'Після їжі';

  @override
  String get foodWith => 'Під час їжі';

  @override
  String get foodAny => 'Незалежно від їжі';

  @override
  String get familyTitle => 'Сім\'я';

  @override
  String get familyAdherenceToday => 'Виконання сьогодні';

  @override
  String get familyAddMember => 'Додати члена сім\'ї';

  @override
  String get familyProRequired => 'Сімейний режим';

  @override
  String get familyProBody =>
      'Відстежуйте прийом ліків для всіх членів сім\'ї. Доступно в Pro-тарифі.';

  @override
  String get familyMemberOwner => 'Власник';

  @override
  String get familyMemberMember => 'Член сім\'ї';

  @override
  String get familyMemberDependent => 'Під опікою';

  @override
  String familyMedsToday(int taken, int total) {
    return '$taken/$total ліків';
  }

  @override
  String get profileTitle => 'Профіль';

  @override
  String get profileMyProfile => 'Мій профіль';

  @override
  String get profileLanguage => 'Мова';

  @override
  String get profileLanguageUk => 'Українська';

  @override
  String get profileLanguageEn => 'English';

  @override
  String get profileNotifications => 'Сповіщення';

  @override
  String get profileNotificationsHint => 'Нагадування про прийом ліків';

  @override
  String get profileExportData => 'Експорт даних';

  @override
  String get profileExportDataHint => 'Зберегти у CSV або PDF';

  @override
  String get profileAnalytics => 'Аналітика прийому';

  @override
  String get profileAnalyticsHint => 'Графіки та статистика';

  @override
  String get profileAbout => 'Про застосунок';

  @override
  String profileVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get proTitle => 'MedKit Pro';

  @override
  String get proSubtitle => 'Розблокуйте всі можливості';

  @override
  String get proFeatureFamily => 'Необмежена кількість членів сім\'ї';

  @override
  String get proFeatureReminders => 'Розумні нагадування';

  @override
  String get proFeatureExport => 'Експорт даних';

  @override
  String get proFeatureAnalytics => 'Детальна аналітика';

  @override
  String get proUpgradeButton => 'Перейти на Pro';

  @override
  String get proBadge => 'PRO';

  @override
  String get proLockedHint => 'Функція доступна в Pro-тарифі';

  @override
  String get wellbeingTitle => 'Самочуття';

  @override
  String get wellbeingQuestion => '💜 Як ви себе почуваєте зараз?';

  @override
  String get wellbeingBad => 'Погано';

  @override
  String get wellbeingMeh => 'Так собі';

  @override
  String get wellbeingOk => 'Нормально';

  @override
  String get wellbeingGood => 'Добре';

  @override
  String get wellbeingGreat => 'Відмінно';

  @override
  String get comingSoon => 'Незабаром';

  @override
  String get errorRequired => 'Обов\'язкове поле';

  @override
  String errorMinLength(int min) {
    return 'Мінімум $min символи';
  }
}
