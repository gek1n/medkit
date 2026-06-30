import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('uk'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In uk, this message translates to:
  /// **'MedKit'**
  String get appName;

  /// No description provided for @navToday.
  ///
  /// In uk, this message translates to:
  /// **'Сьогодні'**
  String get navToday;

  /// No description provided for @navMeds.
  ///
  /// In uk, this message translates to:
  /// **'Ліки'**
  String get navMeds;

  /// No description provided for @navFamily.
  ///
  /// In uk, this message translates to:
  /// **'Сім\'я'**
  String get navFamily;

  /// No description provided for @navProfile.
  ///
  /// In uk, this message translates to:
  /// **'Профіль'**
  String get navProfile;

  /// No description provided for @todayGreeting.
  ///
  /// In uk, this message translates to:
  /// **'Привіт! 👋'**
  String get todayGreeting;

  /// No description provided for @todayLegendTaken.
  ///
  /// In uk, this message translates to:
  /// **'{count} прийнято'**
  String todayLegendTaken(int count);

  /// No description provided for @todayLegendPending.
  ///
  /// In uk, this message translates to:
  /// **'{count} очікує'**
  String todayLegendPending(int count);

  /// No description provided for @todayProgressTitle.
  ///
  /// In uk, this message translates to:
  /// **'{taken} з {total}'**
  String todayProgressTitle(int taken, int total);

  /// No description provided for @todayProgressSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'ліків прийнято сьогодні'**
  String get todayProgressSubtitle;

  /// No description provided for @todayProgressPercent.
  ///
  /// In uk, this message translates to:
  /// **'{percent}%'**
  String todayProgressPercent(int percent);

  /// No description provided for @todayAllDone.
  ///
  /// In uk, this message translates to:
  /// **'Всі ліки прийнято 🎉'**
  String get todayAllDone;

  /// No description provided for @todayNothingPlanned.
  ///
  /// In uk, this message translates to:
  /// **'На сьогодні нічого не заплановано'**
  String get todayNothingPlanned;

  /// No description provided for @sectionFamily.
  ///
  /// In uk, this message translates to:
  /// **'Сім\'я'**
  String get sectionFamily;

  /// No description provided for @sectionScheduled.
  ///
  /// In uk, this message translates to:
  /// **'Заплановано'**
  String get sectionScheduled;

  /// No description provided for @sectionDone.
  ///
  /// In uk, this message translates to:
  /// **'Виконано'**
  String get sectionDone;

  /// No description provided for @actionAll.
  ///
  /// In uk, this message translates to:
  /// **'Всі'**
  String get actionAll;

  /// No description provided for @actionAdd.
  ///
  /// In uk, this message translates to:
  /// **'Додати'**
  String get actionAdd;

  /// No description provided for @actionSave.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In uk, this message translates to:
  /// **'Видалити'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати'**
  String get actionEdit;

  /// No description provided for @intakeTaken.
  ///
  /// In uk, this message translates to:
  /// **'Прийнято'**
  String get intakeTaken;

  /// No description provided for @intakeSkipped.
  ///
  /// In uk, this message translates to:
  /// **'Пропущено'**
  String get intakeSkipped;

  /// No description provided for @intakeTake.
  ///
  /// In uk, this message translates to:
  /// **'Прийняти'**
  String get intakeTake;

  /// No description provided for @intakeSkip.
  ///
  /// In uk, this message translates to:
  /// **'Пропустити'**
  String get intakeSkip;

  /// No description provided for @medsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Мої ліки'**
  String get medsTitle;

  /// No description provided for @medsEmpty.
  ///
  /// In uk, this message translates to:
  /// **'Ліки ще не додані'**
  String get medsEmpty;

  /// No description provided for @medsEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть + щоб додати перший препарат'**
  String get medsEmptyHint;

  /// No description provided for @medsRemaining.
  ///
  /// In uk, this message translates to:
  /// **'Залишилось: {count} шт.'**
  String medsRemaining(int count);

  /// No description provided for @medsDaysLeft.
  ///
  /// In uk, this message translates to:
  /// **'{days} дн.'**
  String medsDaysLeft(int days);

  /// No description provided for @medsActive.
  ///
  /// In uk, this message translates to:
  /// **'Активні'**
  String get medsActive;

  /// No description provided for @medsArchived.
  ///
  /// In uk, this message translates to:
  /// **'Архів'**
  String get medsArchived;

  /// No description provided for @medsFreeLimitTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ліміт безкоштовного тарифу'**
  String get medsFreeLimitTitle;

  /// No description provided for @medsFreeLimitBody.
  ///
  /// In uk, this message translates to:
  /// **'У безкоштовному тарифі можна додати до {max} препаратів. Перейдіть на Pro для необмеженої кількості.'**
  String medsFreeLimitBody(int max);

  /// No description provided for @addMedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Новий препарат'**
  String get addMedTitle;

  /// No description provided for @addMedName.
  ///
  /// In uk, this message translates to:
  /// **'Назва препарату'**
  String get addMedName;

  /// No description provided for @addMedNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Наприклад: Еналаприл'**
  String get addMedNameHint;

  /// No description provided for @addMedDose.
  ///
  /// In uk, this message translates to:
  /// **'Доза'**
  String get addMedDose;

  /// No description provided for @addMedDoseHint.
  ///
  /// In uk, this message translates to:
  /// **'Наприклад: 10 мг'**
  String get addMedDoseHint;

  /// No description provided for @addMedForm.
  ///
  /// In uk, this message translates to:
  /// **'Форма випуску'**
  String get addMedForm;

  /// No description provided for @addMedFood.
  ///
  /// In uk, this message translates to:
  /// **'Відношення до їжі'**
  String get addMedFood;

  /// No description provided for @addMedTotal.
  ///
  /// In uk, this message translates to:
  /// **'Кількість у упаковці'**
  String get addMedTotal;

  /// No description provided for @addMedInstructions.
  ///
  /// In uk, this message translates to:
  /// **'Інструкції (необов\'язково)'**
  String get addMedInstructions;

  /// No description provided for @addMedInstructionsHint.
  ///
  /// In uk, this message translates to:
  /// **'Особливі вказівки лікаря'**
  String get addMedInstructionsHint;

  /// No description provided for @medFormTablet.
  ///
  /// In uk, this message translates to:
  /// **'Таблетки'**
  String get medFormTablet;

  /// No description provided for @medFormCapsule.
  ///
  /// In uk, this message translates to:
  /// **'Капсули'**
  String get medFormCapsule;

  /// No description provided for @medFormSyrup.
  ///
  /// In uk, this message translates to:
  /// **'Сироп'**
  String get medFormSyrup;

  /// No description provided for @medFormDrops.
  ///
  /// In uk, this message translates to:
  /// **'Краплі'**
  String get medFormDrops;

  /// No description provided for @medFormCream.
  ///
  /// In uk, this message translates to:
  /// **'Мазь / крем'**
  String get medFormCream;

  /// No description provided for @medFormInhaler.
  ///
  /// In uk, this message translates to:
  /// **'Інгалятор'**
  String get medFormInhaler;

  /// No description provided for @medFormInjection.
  ///
  /// In uk, this message translates to:
  /// **'Ін\'єкція'**
  String get medFormInjection;

  /// No description provided for @medFormOther.
  ///
  /// In uk, this message translates to:
  /// **'Інше'**
  String get medFormOther;

  /// No description provided for @foodBefore.
  ///
  /// In uk, this message translates to:
  /// **'До їжі'**
  String get foodBefore;

  /// No description provided for @foodAfter.
  ///
  /// In uk, this message translates to:
  /// **'Після їжі'**
  String get foodAfter;

  /// No description provided for @foodWith.
  ///
  /// In uk, this message translates to:
  /// **'Під час їжі'**
  String get foodWith;

  /// No description provided for @foodAny.
  ///
  /// In uk, this message translates to:
  /// **'Незалежно від їжі'**
  String get foodAny;

  /// No description provided for @familyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Сім\'я'**
  String get familyTitle;

  /// No description provided for @familyAdherenceToday.
  ///
  /// In uk, this message translates to:
  /// **'Виконання сьогодні'**
  String get familyAdherenceToday;

  /// No description provided for @familyAddMember.
  ///
  /// In uk, this message translates to:
  /// **'Додати члена сім\'ї'**
  String get familyAddMember;

  /// No description provided for @familyProRequired.
  ///
  /// In uk, this message translates to:
  /// **'Сімейний режим'**
  String get familyProRequired;

  /// No description provided for @familyProBody.
  ///
  /// In uk, this message translates to:
  /// **'Відстежуйте прийом ліків для всіх членів сім\'ї. Доступно в Pro-тарифі.'**
  String get familyProBody;

  /// No description provided for @familyMemberOwner.
  ///
  /// In uk, this message translates to:
  /// **'Власник'**
  String get familyMemberOwner;

  /// No description provided for @familyMemberMember.
  ///
  /// In uk, this message translates to:
  /// **'Член сім\'ї'**
  String get familyMemberMember;

  /// No description provided for @familyMemberDependent.
  ///
  /// In uk, this message translates to:
  /// **'Під опікою'**
  String get familyMemberDependent;

  /// No description provided for @familyMedsToday.
  ///
  /// In uk, this message translates to:
  /// **'{taken}/{total} ліків'**
  String familyMedsToday(int taken, int total);

  /// No description provided for @profileTitle.
  ///
  /// In uk, this message translates to:
  /// **'Профіль'**
  String get profileTitle;

  /// No description provided for @profileMyProfile.
  ///
  /// In uk, this message translates to:
  /// **'Мій профіль'**
  String get profileMyProfile;

  /// No description provided for @profileLanguage.
  ///
  /// In uk, this message translates to:
  /// **'Мова'**
  String get profileLanguage;

  /// No description provided for @profileLanguageUk.
  ///
  /// In uk, this message translates to:
  /// **'Українська'**
  String get profileLanguageUk;

  /// No description provided for @profileLanguageEn.
  ///
  /// In uk, this message translates to:
  /// **'English'**
  String get profileLanguageEn;

  /// No description provided for @profileNotifications.
  ///
  /// In uk, this message translates to:
  /// **'Сповіщення'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsHint.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування про прийом ліків'**
  String get profileNotificationsHint;

  /// No description provided for @profileExportData.
  ///
  /// In uk, this message translates to:
  /// **'Експорт даних'**
  String get profileExportData;

  /// No description provided for @profileExportDataHint.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти у CSV або PDF'**
  String get profileExportDataHint;

  /// No description provided for @profileAnalytics.
  ///
  /// In uk, this message translates to:
  /// **'Аналітика прийому'**
  String get profileAnalytics;

  /// No description provided for @profileAnalyticsHint.
  ///
  /// In uk, this message translates to:
  /// **'Графіки та статистика'**
  String get profileAnalyticsHint;

  /// No description provided for @profileAbout.
  ///
  /// In uk, this message translates to:
  /// **'Про застосунок'**
  String get profileAbout;

  /// No description provided for @profileVersion.
  ///
  /// In uk, this message translates to:
  /// **'Версія {version}'**
  String profileVersion(String version);

  /// No description provided for @proTitle.
  ///
  /// In uk, this message translates to:
  /// **'MedKit Pro'**
  String get proTitle;

  /// No description provided for @proSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Розблокуйте всі можливості'**
  String get proSubtitle;

  /// No description provided for @proFeatureFamily.
  ///
  /// In uk, this message translates to:
  /// **'Необмежена кількість членів сім\'ї'**
  String get proFeatureFamily;

  /// No description provided for @proFeatureReminders.
  ///
  /// In uk, this message translates to:
  /// **'Розумні нагадування'**
  String get proFeatureReminders;

  /// No description provided for @proFeatureExport.
  ///
  /// In uk, this message translates to:
  /// **'Експорт даних'**
  String get proFeatureExport;

  /// No description provided for @proFeatureAnalytics.
  ///
  /// In uk, this message translates to:
  /// **'Детальна аналітика'**
  String get proFeatureAnalytics;

  /// No description provided for @proUpgradeButton.
  ///
  /// In uk, this message translates to:
  /// **'Перейти на Pro'**
  String get proUpgradeButton;

  /// No description provided for @proBadge.
  ///
  /// In uk, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @proLockedHint.
  ///
  /// In uk, this message translates to:
  /// **'Функція доступна в Pro-тарифі'**
  String get proLockedHint;

  /// No description provided for @wellbeingTitle.
  ///
  /// In uk, this message translates to:
  /// **'Самочуття'**
  String get wellbeingTitle;

  /// No description provided for @wellbeingQuestion.
  ///
  /// In uk, this message translates to:
  /// **'💜 Як ви себе почуваєте зараз?'**
  String get wellbeingQuestion;

  /// No description provided for @wellbeingBad.
  ///
  /// In uk, this message translates to:
  /// **'Погано'**
  String get wellbeingBad;

  /// No description provided for @wellbeingMeh.
  ///
  /// In uk, this message translates to:
  /// **'Так собі'**
  String get wellbeingMeh;

  /// No description provided for @wellbeingOk.
  ///
  /// In uk, this message translates to:
  /// **'Нормально'**
  String get wellbeingOk;

  /// No description provided for @wellbeingGood.
  ///
  /// In uk, this message translates to:
  /// **'Добре'**
  String get wellbeingGood;

  /// No description provided for @wellbeingGreat.
  ///
  /// In uk, this message translates to:
  /// **'Відмінно'**
  String get wellbeingGreat;

  /// No description provided for @comingSoon.
  ///
  /// In uk, this message translates to:
  /// **'Незабаром'**
  String get comingSoon;

  /// No description provided for @errorRequired.
  ///
  /// In uk, this message translates to:
  /// **'Обов\'язкове поле'**
  String get errorRequired;

  /// No description provided for @errorMinLength.
  ///
  /// In uk, this message translates to:
  /// **'Мінімум {min} символи'**
  String errorMinLength(int min);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
