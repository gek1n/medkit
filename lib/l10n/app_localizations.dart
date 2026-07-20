import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// No description provided for @appName.
  ///
  /// In uk, this message translates to:
  /// **'Elly'**
  String get appName;

  /// No description provided for @navAdd.
  ///
  /// In uk, this message translates to:
  /// **'Додати'**
  String get navAdd;

  /// No description provided for @navToday.
  ///
  /// In uk, this message translates to:
  /// **'Сьогодні'**
  String get navToday;

  /// No description provided for @navMeds.
  ///
  /// In uk, this message translates to:
  /// **'Розклад'**
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

  /// No description provided for @navMedCard.
  ///
  /// In uk, this message translates to:
  /// **'Медкартка'**
  String get navMedCard;

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

  /// No description provided for @intakeTaken.
  ///
  /// In uk, this message translates to:
  /// **'Виконано'**
  String get intakeTaken;

  /// No description provided for @intakeSkipped.
  ///
  /// In uk, this message translates to:
  /// **'Пропущено'**
  String get intakeSkipped;

  /// No description provided for @intakeTake.
  ///
  /// In uk, this message translates to:
  /// **'✓'**
  String get intakeTake;

  /// No description provided for @intakeSkip.
  ///
  /// In uk, this message translates to:
  /// **'✕'**
  String get intakeSkip;

  /// No description provided for @comingSoon.
  ///
  /// In uk, this message translates to:
  /// **'Незабаром'**
  String get comingSoon;

  /// No description provided for @errorGeneric.
  ///
  /// In uk, this message translates to:
  /// **'Помилка: {error}'**
  String errorGeneric(String error);

  /// No description provided for @todaySectionFamily.
  ///
  /// In uk, this message translates to:
  /// **'Сім\'я'**
  String get todaySectionFamily;

  /// No description provided for @todayScheduleForToday.
  ///
  /// In uk, this message translates to:
  /// **'Розклад на сьогодні'**
  String get todayScheduleForToday;

  /// No description provided for @todayScheduleForTomorrow.
  ///
  /// In uk, this message translates to:
  /// **'Коротко про завтра'**
  String get todayScheduleForTomorrow;

  /// No description provided for @todayNothingToday.
  ///
  /// In uk, this message translates to:
  /// **'На сьогодні нічого немає'**
  String get todayNothingToday;

  /// No description provided for @todayTapToAdd.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть + щоб додати'**
  String get todayTapToAdd;

  /// No description provided for @todayAllDoneChip.
  ///
  /// In uk, this message translates to:
  /// **'Все виконано'**
  String get todayAllDoneChip;

  /// No description provided for @todayNextNow.
  ///
  /// In uk, this message translates to:
  /// **'зараз'**
  String get todayNextNow;

  /// No description provided for @todayNextInMinutes.
  ///
  /// In uk, this message translates to:
  /// **'через {minutes} хв'**
  String todayNextInMinutes(int minutes);

  /// No description provided for @todayAllDoneTitle.
  ///
  /// In uk, this message translates to:
  /// **'Все виконано на сьогодні!'**
  String get todayAllDoneTitle;

  /// No description provided for @todayAllDoneSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Чудова робота — так тримати'**
  String get todayAllDoneSubtitle;

  /// No description provided for @todayHurtsNow.
  ///
  /// In uk, this message translates to:
  /// **'Зараз\nболить'**
  String get todayHurtsNow;

  /// No description provided for @todayMissedSection.
  ///
  /// In uk, this message translates to:
  /// **'Ви пропустили'**
  String get todayMissedSection;

  /// No description provided for @todayActiveNowSection.
  ///
  /// In uk, this message translates to:
  /// **'Зараз потрібно'**
  String get todayActiveNowSection;

  /// No description provided for @dayPartMorning.
  ///
  /// In uk, this message translates to:
  /// **'Ранок'**
  String get dayPartMorning;

  /// No description provided for @dayPartAfternoon.
  ///
  /// In uk, this message translates to:
  /// **'День'**
  String get dayPartAfternoon;

  /// No description provided for @dayPartEvening.
  ///
  /// In uk, this message translates to:
  /// **'Вечір'**
  String get dayPartEvening;

  /// No description provided for @dayPartNight.
  ///
  /// In uk, this message translates to:
  /// **'Ніч'**
  String get dayPartNight;

  /// No description provided for @defaultMedName.
  ///
  /// In uk, this message translates to:
  /// **'Ліки'**
  String get defaultMedName;

  /// No description provided for @defaultActivityName.
  ///
  /// In uk, this message translates to:
  /// **'Активність'**
  String get defaultActivityName;

  /// No description provided for @wellbeingTitle.
  ///
  /// In uk, this message translates to:
  /// **'Самопочуття'**
  String get wellbeingTitle;

  /// No description provided for @detailLabelTime.
  ///
  /// In uk, this message translates to:
  /// **'Час'**
  String get detailLabelTime;

  /// No description provided for @detailLabelDuration.
  ///
  /// In uk, this message translates to:
  /// **'Тривалість'**
  String get detailLabelDuration;

  /// No description provided for @durationMinutes.
  ///
  /// In uk, this message translates to:
  /// **'{minutes} хв'**
  String durationMinutes(int minutes);

  /// No description provided for @detailLabelLocation.
  ///
  /// In uk, this message translates to:
  /// **'Місце'**
  String get detailLabelLocation;

  /// No description provided for @detailLabelNotes.
  ///
  /// In uk, this message translates to:
  /// **'Нотатки'**
  String get detailLabelNotes;

  /// No description provided for @todayDoneCount.
  ///
  /// In uk, this message translates to:
  /// **'Виконано · {count}'**
  String todayDoneCount(int count);

  /// No description provided for @skipIntakeAction.
  ///
  /// In uk, this message translates to:
  /// **'Пропустити прийом'**
  String get skipIntakeAction;

  /// No description provided for @missedCaption.
  ///
  /// In uk, this message translates to:
  /// **'пропущено'**
  String get missedCaption;

  /// No description provided for @videoPlaybackError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося відтворити відео тут'**
  String get videoPlaybackError;

  /// No description provided for @openInYoutube.
  ///
  /// In uk, this message translates to:
  /// **'Відкрити в YouTube'**
  String get openInYoutube;

  /// No description provided for @missedWellbeingSlot.
  ///
  /// In uk, this message translates to:
  /// **'Пропущений зріз'**
  String get missedWellbeingSlot;

  /// No description provided for @wellbeingTimeToCheck.
  ///
  /// In uk, this message translates to:
  /// **'Час перевірити самопочуття'**
  String get wellbeingTimeToCheck;

  /// No description provided for @wellbeingCommentHint.
  ///
  /// In uk, this message translates to:
  /// **'Оцініть настрій і, за потреби, опишіть симптоми'**
  String get wellbeingCommentHint;

  /// No description provided for @skipGenericAction.
  ///
  /// In uk, this message translates to:
  /// **'Пропустити'**
  String get skipGenericAction;

  /// No description provided for @snooze10.
  ///
  /// In uk, this message translates to:
  /// **'Перенести на 10 хв'**
  String get snooze10;

  /// No description provided for @snooze30.
  ///
  /// In uk, this message translates to:
  /// **'Перенести на 30 хв'**
  String get snooze30;

  /// No description provided for @snooze60.
  ///
  /// In uk, this message translates to:
  /// **'Перенести на 1 год'**
  String get snooze60;

  /// No description provided for @doneAction.
  ///
  /// In uk, this message translates to:
  /// **'Виконати'**
  String get doneAction;

  /// No description provided for @welcomeTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ласкаво просимо до Elly'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Додайте свій профіль щоб розпочати'**
  String get welcomeSubtitle;

  /// No description provided for @categoryAll.
  ///
  /// In uk, this message translates to:
  /// **'Усі'**
  String get categoryAll;

  /// No description provided for @categoryMeds.
  ///
  /// In uk, this message translates to:
  /// **'Ліки'**
  String get categoryMeds;

  /// No description provided for @categoryActivities.
  ///
  /// In uk, this message translates to:
  /// **'Активності'**
  String get categoryActivities;

  /// No description provided for @categoryWellbeing.
  ///
  /// In uk, this message translates to:
  /// **'Самопочуття'**
  String get categoryWellbeing;

  /// No description provided for @categoryDoctors.
  ///
  /// In uk, this message translates to:
  /// **'Лікарі'**
  String get categoryDoctors;

  /// No description provided for @scheduleTitle.
  ///
  /// In uk, this message translates to:
  /// **'Розклад'**
  String get scheduleTitle;

  /// No description provided for @searchAllSections.
  ///
  /// In uk, this message translates to:
  /// **'Пошук по всіх розділах'**
  String get searchAllSections;

  /// No description provided for @sectionMeds.
  ///
  /// In uk, this message translates to:
  /// **'Ліки'**
  String get sectionMeds;

  /// No description provided for @noActiveMeds.
  ///
  /// In uk, this message translates to:
  /// **'Немає активних ліків'**
  String get noActiveMeds;

  /// No description provided for @sectionAppointments.
  ///
  /// In uk, this message translates to:
  /// **'Прийоми лікарів'**
  String get sectionAppointments;

  /// No description provided for @noScheduledAppointments.
  ///
  /// In uk, this message translates to:
  /// **'Немає запланованих прийомів'**
  String get noScheduledAppointments;

  /// No description provided for @sectionActivities.
  ///
  /// In uk, this message translates to:
  /// **'Активності'**
  String get sectionActivities;

  /// No description provided for @noActiveActivities.
  ///
  /// In uk, this message translates to:
  /// **'Немає активних занять'**
  String get noActiveActivities;

  /// No description provided for @sectionWellbeing.
  ///
  /// In uk, this message translates to:
  /// **'Самопочуття'**
  String get sectionWellbeing;

  /// No description provided for @wellbeingScheduleNotSet.
  ///
  /// In uk, this message translates to:
  /// **'Розклад не налаштовано'**
  String get wellbeingScheduleNotSet;

  /// No description provided for @nothingFound.
  ///
  /// In uk, this message translates to:
  /// **'Нічого не знайдено'**
  String get nothingFound;

  /// No description provided for @repeatDaily.
  ///
  /// In uk, this message translates to:
  /// **'щодня'**
  String get repeatDaily;

  /// No description provided for @repeatAlternate.
  ///
  /// In uk, this message translates to:
  /// **'через день'**
  String get repeatAlternate;

  /// No description provided for @repeatWeekdays.
  ///
  /// In uk, this message translates to:
  /// **'певні дні'**
  String get repeatWeekdays;

  /// No description provided for @repeatEveryN.
  ///
  /// In uk, this message translates to:
  /// **'кожні N днів'**
  String get repeatEveryN;

  /// No description provided for @repeatCycle.
  ///
  /// In uk, this message translates to:
  /// **'циклом'**
  String get repeatCycle;

  /// No description provided for @courseOngoing.
  ///
  /// In uk, this message translates to:
  /// **'постійний курс'**
  String get courseOngoing;

  /// No description provided for @courseFinished.
  ///
  /// In uk, this message translates to:
  /// **'курс завершено'**
  String get courseFinished;

  /// No description provided for @courseDaysLeft.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} день курсу} few{{count} дні курсу} other{{count} днів курсу}}'**
  String courseDaysLeft(int count);

  /// No description provided for @noLocation.
  ///
  /// In uk, this message translates to:
  /// **'Без місця проведення'**
  String get noLocation;

  /// No description provided for @timesPerDayLabel.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} раз на день} few{{count} рази на день} other{{count} разів на день}}'**
  String timesPerDayLabel(int count);

  /// No description provided for @addAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати'**
  String get addAction;

  /// No description provided for @profileNotFound.
  ///
  /// In uk, this message translates to:
  /// **'Профіль не знайдено'**
  String get profileNotFound;

  /// No description provided for @dayMon.
  ///
  /// In uk, this message translates to:
  /// **'Пн'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In uk, this message translates to:
  /// **'Вт'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In uk, this message translates to:
  /// **'Ср'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In uk, this message translates to:
  /// **'Чт'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In uk, this message translates to:
  /// **'Пт'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In uk, this message translates to:
  /// **'Сб'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In uk, this message translates to:
  /// **'Нд'**
  String get daySun;

  /// No description provided for @editAction.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати'**
  String get editAction;

  /// No description provided for @fieldName.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get fieldName;

  /// No description provided for @fieldDate.
  ///
  /// In uk, this message translates to:
  /// **'Дата'**
  String get fieldDate;

  /// No description provided for @fieldNotes.
  ///
  /// In uk, this message translates to:
  /// **'Нотатки'**
  String get fieldNotes;

  /// No description provided for @surgeryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Операція'**
  String get surgeryTitle;

  /// No description provided for @chronicConditionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Хронічне захворювання'**
  String get chronicConditionTitle;

  /// No description provided for @labResultTitle.
  ///
  /// In uk, this message translates to:
  /// **'Аналіз'**
  String get labResultTitle;

  /// No description provided for @vaccinationTitle.
  ///
  /// In uk, this message translates to:
  /// **'Щеплення'**
  String get vaccinationTitle;

  /// No description provided for @allergyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Алергія'**
  String get allergyTitle;

  /// No description provided for @fieldDiagnosis.
  ///
  /// In uk, this message translates to:
  /// **'Діагноз'**
  String get fieldDiagnosis;

  /// No description provided for @fieldSpecialty.
  ///
  /// In uk, this message translates to:
  /// **'Напрямок'**
  String get fieldSpecialty;

  /// No description provided for @fieldDiagnosisDate.
  ///
  /// In uk, this message translates to:
  /// **'Дата діагнозу'**
  String get fieldDiagnosisDate;

  /// No description provided for @fieldDateGiven.
  ///
  /// In uk, this message translates to:
  /// **'Дата введення'**
  String get fieldDateGiven;

  /// No description provided for @fieldNextDose.
  ///
  /// In uk, this message translates to:
  /// **'Наступна ревакцинація'**
  String get fieldNextDose;

  /// No description provided for @fieldAllergen.
  ///
  /// In uk, this message translates to:
  /// **'Алерген'**
  String get fieldAllergen;

  /// No description provided for @fieldSeverity.
  ///
  /// In uk, this message translates to:
  /// **'Тяжкість'**
  String get fieldSeverity;

  /// No description provided for @fieldReaction.
  ///
  /// In uk, this message translates to:
  /// **'Реакція'**
  String get fieldReaction;

  /// No description provided for @severityMild.
  ///
  /// In uk, this message translates to:
  /// **'Легка'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In uk, this message translates to:
  /// **'Середня'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In uk, this message translates to:
  /// **'Тяжка'**
  String get severitySevere;

  /// No description provided for @dayToday.
  ///
  /// In uk, this message translates to:
  /// **'Сьогодні'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In uk, this message translates to:
  /// **'Завтра'**
  String get dayTomorrow;

  /// No description provided for @dayYesterday.
  ///
  /// In uk, this message translates to:
  /// **'Вчора'**
  String get dayYesterday;

  /// No description provided for @surgeriesSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Операції та госпіталізації'**
  String get surgeriesSectionTitle;

  /// No description provided for @surgeriesEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Додати\" щоб додати перший запис'**
  String get surgeriesEmptyHint;

  /// No description provided for @chronicConditionsSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Хронічні захворювання'**
  String get chronicConditionsSectionTitle;

  /// No description provided for @chronicConditionsEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Додати\" щоб додати перший діагноз'**
  String get chronicConditionsEmptyHint;

  /// No description provided for @allergiesTitle.
  ///
  /// In uk, this message translates to:
  /// **'Алергії'**
  String get allergiesTitle;

  /// No description provided for @allergiesEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Додати\" щоб додати першу алергію'**
  String get allergiesEmptyHint;

  /// No description provided for @vaccinationsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Щеплення'**
  String get vaccinationsTitle;

  /// No description provided for @vaccinationsEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Додати\" щоб додати перше щеплення'**
  String get vaccinationsEmptyHint;

  /// No description provided for @vaccinationGivenOn.
  ///
  /// In uk, this message translates to:
  /// **'Введено {date}'**
  String vaccinationGivenOn(String date);

  /// No description provided for @vaccinationOverdue.
  ///
  /// In uk, this message translates to:
  /// **'Прострочено'**
  String get vaccinationOverdue;

  /// No description provided for @labResultsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Аналізи'**
  String get labResultsTitle;

  /// No description provided for @allSpecialtiesFilter.
  ///
  /// In uk, this message translates to:
  /// **'Усі напрямки'**
  String get allSpecialtiesFilter;

  /// No description provided for @allTestTypesFilter.
  ///
  /// In uk, this message translates to:
  /// **'Усі типи аналізів'**
  String get allTestTypesFilter;

  /// No description provided for @labResultsEmptyFilteredTitle.
  ///
  /// In uk, this message translates to:
  /// **'Немає аналізів за цим фільтром'**
  String get labResultsEmptyFilteredTitle;

  /// No description provided for @labResultsEmptyNoneTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ще нічого не додано'**
  String get labResultsEmptyNoneTitle;

  /// No description provided for @labResultsEmptyFilteredHint.
  ///
  /// In uk, this message translates to:
  /// **'Спробуйте змінити фільтри або скиньте їх'**
  String get labResultsEmptyFilteredHint;

  /// No description provided for @labResultsEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Додати\" щоб додати перший аналіз'**
  String get labResultsEmptyHint;

  /// No description provided for @medCardTitle.
  ///
  /// In uk, this message translates to:
  /// **'Медкартка'**
  String get medCardTitle;

  /// No description provided for @medCardHistoryByDoctorTitle.
  ///
  /// In uk, this message translates to:
  /// **'Історія лікування за напрямками'**
  String get medCardHistoryByDoctorTitle;

  /// No description provided for @medCardHistoryByDoctorSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Візити й аналізи одного лікаря — все в одному місці'**
  String get medCardHistoryByDoctorSubtitle;

  /// No description provided for @medCardLabResultsSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Результати за напрямками'**
  String get medCardLabResultsSubtitle;

  /// No description provided for @medCardArchiveTitle.
  ///
  /// In uk, this message translates to:
  /// **'Архів ліків'**
  String get medCardArchiveTitle;

  /// No description provided for @medCardArchiveSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Усі препарати й статус лікування'**
  String get medCardArchiveSubtitle;

  /// No description provided for @medCardAppointmentsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Візити до лікарів'**
  String get medCardAppointmentsTitle;

  /// No description provided for @medCardAppointmentsSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Записи обраного профілю'**
  String get medCardAppointmentsSubtitle;

  /// No description provided for @medCardWellbeingHistoryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Історія самопочуття'**
  String get medCardWellbeingHistoryTitle;

  /// No description provided for @medCardWellbeingHistorySubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Настрій та симптоми за весь час'**
  String get medCardWellbeingHistorySubtitle;

  /// No description provided for @medCardAllergiesSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Реакції на препарати й речовини'**
  String get medCardAllergiesSubtitle;

  /// No description provided for @medCardChronicConditionsSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Діагнози, дата встановлення'**
  String get medCardChronicConditionsSubtitle;

  /// No description provided for @medCardVaccinationsSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Історія й наступні ревакцинації'**
  String get medCardVaccinationsSubtitle;

  /// No description provided for @medicationArchiveEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Тут з\'являться всі ліки, які ви колись додавали'**
  String get medicationArchiveEmptyHint;

  /// No description provided for @medStatusOngoing.
  ///
  /// In uk, this message translates to:
  /// **'Триває'**
  String get medStatusOngoing;

  /// No description provided for @medStatusFinished.
  ///
  /// In uk, this message translates to:
  /// **'Завершено'**
  String get medStatusFinished;

  /// No description provided for @medStatusCancelled.
  ///
  /// In uk, this message translates to:
  /// **'Відмінено'**
  String get medStatusCancelled;

  /// No description provided for @medArchiveDateRangeOngoing.
  ///
  /// In uk, this message translates to:
  /// **'{start} — досі'**
  String medArchiveDateRangeOngoing(String start);

  /// No description provided for @specialtyHistoryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Історія за напрямком'**
  String get specialtyHistoryTitle;

  /// No description provided for @sectionUpcoming.
  ///
  /// In uk, this message translates to:
  /// **'Заплановані'**
  String get sectionUpcoming;

  /// No description provided for @sectionPast.
  ///
  /// In uk, this message translates to:
  /// **'Минулі'**
  String get sectionPast;

  /// No description provided for @visitPrefix.
  ///
  /// In uk, this message translates to:
  /// **'Візит · {type}'**
  String visitPrefix(String type);

  /// No description provided for @labPrefix.
  ///
  /// In uk, this message translates to:
  /// **'Аналіз · {name}'**
  String labPrefix(String name);

  /// No description provided for @emptyStateNoneYetTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ще нічого не додано'**
  String get emptyStateNoneYetTitle;

  /// No description provided for @specialtyHistoryEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Візити й аналізи з\'являться тут'**
  String get specialtyHistoryEmptyHint;

  /// No description provided for @actionCancel.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати'**
  String get actionCancel;

  /// No description provided for @deleteAction.
  ///
  /// In uk, this message translates to:
  /// **'Видалити'**
  String get deleteAction;

  /// No description provided for @documentsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Документи'**
  String get documentsLabel;

  /// No description provided for @notSelectedValue.
  ///
  /// In uk, this message translates to:
  /// **'Не обрано'**
  String get notSelectedValue;

  /// No description provided for @notSpecifiedValue.
  ///
  /// In uk, this message translates to:
  /// **'Не вказано'**
  String get notSpecifiedValue;

  /// No description provided for @deleteRecordBody.
  ///
  /// In uk, this message translates to:
  /// **'Запис буде видалено.'**
  String get deleteRecordBody;

  /// No description provided for @deleteWithDocsBody.
  ///
  /// In uk, this message translates to:
  /// **'Запис і всі прикріплені документи буде видалено.'**
  String get deleteWithDocsBody;

  /// No description provided for @deleteSurgeryConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити запис?'**
  String get deleteSurgeryConfirmTitle;

  /// No description provided for @editSurgeryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати запис'**
  String get editSurgeryTitle;

  /// No description provided for @newSurgeryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нова операція чи госпіталізація'**
  String get newSurgeryTitle;

  /// No description provided for @surgeryNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Апендектомія, госпіталізація…'**
  String get surgeryNameHint;

  /// No description provided for @enterSurgeryNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву операції'**
  String get enterSurgeryNameError;

  /// No description provided for @surgeryNotesHint.
  ///
  /// In uk, this message translates to:
  /// **'Лікарня, ускладнення, рекомендації…'**
  String get surgeryNotesHint;

  /// No description provided for @deleteConditionConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити діагноз?'**
  String get deleteConditionConfirmTitle;

  /// No description provided for @editConditionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати діагноз'**
  String get editConditionTitle;

  /// No description provided for @newConditionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Новий діагноз'**
  String get newConditionTitle;

  /// No description provided for @conditionNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Астма, діабет, гіпертонія…'**
  String get conditionNameHint;

  /// No description provided for @enterConditionNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву діагнозу'**
  String get enterConditionNameError;

  /// No description provided for @fieldDoctorSpecialty.
  ///
  /// In uk, this message translates to:
  /// **'Напрямок лікаря'**
  String get fieldDoctorSpecialty;

  /// No description provided for @conditionNotesHint.
  ///
  /// In uk, this message translates to:
  /// **'Схема лікування, дозування…'**
  String get conditionNotesHint;

  /// No description provided for @deleteAllergyConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити алергію?'**
  String get deleteAllergyConfirmTitle;

  /// No description provided for @editAllergyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати алергію'**
  String get editAllergyTitle;

  /// No description provided for @newAllergyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нова алергія'**
  String get newAllergyTitle;

  /// No description provided for @allergenHint.
  ///
  /// In uk, this message translates to:
  /// **'Пеніцилін, горіхи, пилок…'**
  String get allergenHint;

  /// No description provided for @enterAllergenError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву алергену'**
  String get enterAllergenError;

  /// No description provided for @reactionHint.
  ///
  /// In uk, this message translates to:
  /// **'Висип, набряк, задишка…'**
  String get reactionHint;

  /// No description provided for @allergyNotesHint.
  ///
  /// In uk, this message translates to:
  /// **'Додаткові деталі…'**
  String get allergyNotesHint;

  /// No description provided for @deleteLabResultConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити аналіз?'**
  String get deleteLabResultConfirmTitle;

  /// No description provided for @editLabResultTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати аналіз'**
  String get editLabResultTitle;

  /// No description provided for @newLabResultTitle.
  ///
  /// In uk, this message translates to:
  /// **'Новий аналіз'**
  String get newLabResultTitle;

  /// No description provided for @chooseSpecialtyValue.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть напрямок'**
  String get chooseSpecialtyValue;

  /// No description provided for @fieldTestName.
  ///
  /// In uk, this message translates to:
  /// **'Назва аналізу'**
  String get fieldTestName;

  /// No description provided for @chooseTestNameValue.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть назву аналізу'**
  String get chooseTestNameValue;

  /// No description provided for @labResultNotesHint.
  ///
  /// In uk, this message translates to:
  /// **'Результати, коментар лікаря…'**
  String get labResultNotesHint;

  /// No description provided for @deleteVaccinationConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити щеплення?'**
  String get deleteVaccinationConfirmTitle;

  /// No description provided for @editVaccinationTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати щеплення'**
  String get editVaccinationTitle;

  /// No description provided for @newVaccinationTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нове щеплення'**
  String get newVaccinationTitle;

  /// No description provided for @vaccinationNameField.
  ///
  /// In uk, this message translates to:
  /// **'Назва щеплення'**
  String get vaccinationNameField;

  /// No description provided for @vaccinationNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Правець, грип, COVID-19…'**
  String get vaccinationNameHint;

  /// No description provided for @enterVaccinationNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву щеплення'**
  String get enterVaccinationNameError;

  /// No description provided for @removeAction.
  ///
  /// In uk, this message translates to:
  /// **'Прибрати'**
  String get removeAction;

  /// No description provided for @notScheduledValue.
  ///
  /// In uk, this message translates to:
  /// **'Не заплановано'**
  String get notScheduledValue;

  /// No description provided for @vaccinationNotesHint.
  ///
  /// In uk, this message translates to:
  /// **'Реакція, серія вакцини…'**
  String get vaccinationNotesHint;

  /// No description provided for @medsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ліки'**
  String get medsTitle;

  /// No description provided for @activeMedsCountSection.
  ///
  /// In uk, this message translates to:
  /// **'Активні ({count})'**
  String activeMedsCountSection(int count);

  /// No description provided for @finishedMedsCountSection.
  ///
  /// In uk, this message translates to:
  /// **'Завершені ({count})'**
  String finishedMedsCountSection(int count);

  /// No description provided for @noMedsYetTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ліків ще немає'**
  String get noMedsYetTitle;

  /// No description provided for @noMedsYetHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть + щоб додати перше лікарство'**
  String get noMedsYetHint;

  /// No description provided for @addMedicationAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати лікарство'**
  String get addMedicationAction;

  /// No description provided for @errorGenericShort.
  ///
  /// In uk, this message translates to:
  /// **'Помилка'**
  String get errorGenericShort;

  /// No description provided for @sideEffectsSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'МОЖЛИВІ ПОБІЧНІ ЕФЕКТИ'**
  String get sideEffectsSectionLabel;

  /// No description provided for @sideEffectsAiDisclaimer.
  ///
  /// In uk, this message translates to:
  /// **'Визначено AI під час сканування — ця інформація може бути неточною. Обов\'язково звірте з інструкцією до препарату.'**
  String get sideEffectsAiDisclaimer;

  /// No description provided for @stockUnitTabletsCapsules.
  ///
  /// In uk, this message translates to:
  /// **'ТАБЛЕТКИ / КАПСУЛИ'**
  String get stockUnitTabletsCapsules;

  /// No description provided for @stockUnitSyrup.
  ///
  /// In uk, this message translates to:
  /// **'СИРОП'**
  String get stockUnitSyrup;

  /// No description provided for @stockUnitDrops.
  ///
  /// In uk, this message translates to:
  /// **'КРАПЛІ'**
  String get stockUnitDrops;

  /// No description provided for @stockUnitInjections.
  ///
  /// In uk, this message translates to:
  /// **'ІН\'ЄКЦІЇ'**
  String get stockUnitInjections;

  /// No description provided for @stockUnitSuppositories.
  ///
  /// In uk, this message translates to:
  /// **'СВІЧКИ'**
  String get stockUnitSuppositories;

  /// No description provided for @stockUnitVial.
  ///
  /// In uk, this message translates to:
  /// **'ФЛАКОН'**
  String get stockUnitVial;

  /// No description provided for @stockUnitCream.
  ///
  /// In uk, this message translates to:
  /// **'КРЕМ'**
  String get stockUnitCream;

  /// No description provided for @stockUnitInhaler.
  ///
  /// In uk, this message translates to:
  /// **'ІНГАЛЯТОР'**
  String get stockUnitInhaler;

  /// No description provided for @stockUnitGeneric.
  ///
  /// In uk, this message translates to:
  /// **'ЗАЛИШОК'**
  String get stockUnitGeneric;

  /// No description provided for @perDoseLabel.
  ///
  /// In uk, this message translates to:
  /// **'{dose} {unit} на прийом'**
  String perDoseLabel(String dose, String unit);

  /// No description provided for @timesPerDaySlash.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} раз/день} few{{count} рази/день} other{{count} разів/день}}'**
  String timesPerDaySlash(int count);

  /// No description provided for @stockSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Залишок'**
  String get stockSectionLabel;

  /// No description provided for @untilCourseEndLabel.
  ///
  /// In uk, this message translates to:
  /// **'до кінця курсу'**
  String get untilCourseEndLabel;

  /// No description provided for @next30DaysLabel.
  ///
  /// In uk, this message translates to:
  /// **'на найближчі 30 днів'**
  String get next30DaysLabel;

  /// No description provided for @remainingColonLabel.
  ///
  /// In uk, this message translates to:
  /// **'Залишилось: '**
  String get remainingColonLabel;

  /// No description provided for @daysLeftShortLabel.
  ///
  /// In uk, this message translates to:
  /// **'на {days} дн.'**
  String daysLeftShortLabel(String days);

  /// No description provided for @needToBuyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Потрібно докупити: '**
  String get needToBuyLabel;

  /// No description provided for @refillPackageAction.
  ///
  /// In uk, this message translates to:
  /// **'+ Поповнити упаковку'**
  String get refillPackageAction;

  /// No description provided for @refillPackageTitle.
  ///
  /// In uk, this message translates to:
  /// **'Поповнити упаковку'**
  String get refillPackageTitle;

  /// No description provided for @quantityHint.
  ///
  /// In uk, this message translates to:
  /// **'Кількість'**
  String get quantityHint;

  /// No description provided for @okAction.
  ///
  /// In uk, this message translates to:
  /// **'OK'**
  String get okAction;

  /// No description provided for @remainingApproxPercent.
  ///
  /// In uk, this message translates to:
  /// **'Залишилось ~{percent}%'**
  String remainingApproxPercent(int percent);

  /// No description provided for @daysLeftAtCurrentRate.
  ///
  /// In uk, this message translates to:
  /// **'~{days} днів при поточній витраті'**
  String daysLeftAtCurrentRate(String days);

  /// No description provided for @updateStockEstimateLabel.
  ///
  /// In uk, this message translates to:
  /// **'Оновити оцінку залишку:'**
  String get updateStockEstimateLabel;

  /// No description provided for @openedNewContainerAction.
  ///
  /// In uk, this message translates to:
  /// **'+ Відкрив новий флакон'**
  String get openedNewContainerAction;

  /// No description provided for @openedTodayLabel.
  ///
  /// In uk, this message translates to:
  /// **'Відкрито сьогодні'**
  String get openedTodayLabel;

  /// No description provided for @openedDaysAgoLabel.
  ///
  /// In uk, this message translates to:
  /// **'Відкрито {count, plural, one{{count} день тому} few{{count} дні тому} other{{count} днів тому}}'**
  String openedDaysAgoLabel(int count);

  /// No description provided for @phaseNumberLabel.
  ///
  /// In uk, this message translates to:
  /// **'Етап {number}'**
  String phaseNumberLabel(int number);

  /// No description provided for @nowLabel.
  ///
  /// In uk, this message translates to:
  /// **'зараз'**
  String get nowLabel;

  /// No description provided for @phaseFromOngoing.
  ///
  /// In uk, this message translates to:
  /// **'з {date}, постійно'**
  String phaseFromOngoing(String date);

  /// No description provided for @courseStagesLabel.
  ///
  /// In uk, this message translates to:
  /// **'Етапи курсу'**
  String get courseStagesLabel;

  /// No description provided for @foodBeforeLabel.
  ///
  /// In uk, this message translates to:
  /// **'🕐 До їжі'**
  String get foodBeforeLabel;

  /// No description provided for @foodAfterLabel.
  ///
  /// In uk, this message translates to:
  /// **'🍽 Після їжі'**
  String get foodAfterLabel;

  /// No description provided for @foodWithLabel.
  ///
  /// In uk, this message translates to:
  /// **'🥗 Під час їжі'**
  String get foodWithLabel;

  /// No description provided for @foodAnytimeLabel.
  ///
  /// In uk, this message translates to:
  /// **'✓ Незалежно від їжі'**
  String get foodAnytimeLabel;

  /// No description provided for @untilDateLabel.
  ///
  /// In uk, this message translates to:
  /// **'до {date}'**
  String untilDateLabel(String date);

  /// No description provided for @ongoingLabel.
  ///
  /// In uk, this message translates to:
  /// **'постійно'**
  String get ongoingLabel;

  /// No description provided for @detailsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Деталі'**
  String get detailsLabel;

  /// No description provided for @intakeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Прийом'**
  String get intakeLabel;

  /// No description provided for @withFoodLabel.
  ///
  /// In uk, this message translates to:
  /// **'З їжею'**
  String get withFoodLabel;

  /// No description provided for @courseNounLabel.
  ///
  /// In uk, this message translates to:
  /// **'Курс'**
  String get courseNounLabel;

  /// No description provided for @noteLabel.
  ///
  /// In uk, this message translates to:
  /// **'Примітка'**
  String get noteLabel;

  /// No description provided for @courseRangeLabel.
  ///
  /// In uk, this message translates to:
  /// **'з {start} {endPart}'**
  String courseRangeLabel(String start, String endPart);

  /// No description provided for @repeatDailyCap.
  ///
  /// In uk, this message translates to:
  /// **'Щодня'**
  String get repeatDailyCap;

  /// No description provided for @repeatAlternateCap.
  ///
  /// In uk, this message translates to:
  /// **'Через день'**
  String get repeatAlternateCap;

  /// No description provided for @repeatEveryNCap.
  ///
  /// In uk, this message translates to:
  /// **'Кожні {n} дні'**
  String repeatEveryNCap(String n);

  /// No description provided for @repeatCycleCap.
  ///
  /// In uk, this message translates to:
  /// **'{on} днів / {off} відпочинок'**
  String repeatCycleCap(String on, String off);

  /// No description provided for @stopAction.
  ///
  /// In uk, this message translates to:
  /// **'Зупинити'**
  String get stopAction;

  /// No description provided for @stopCourseConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Зупинити курс?'**
  String get stopCourseConfirmTitle;

  /// No description provided for @stopCourseConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'«{name}» буде видалено зі списку активних ліків.'**
  String stopCourseConfirmBody(String name);

  /// No description provided for @enterMedicationNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву ліків'**
  String get enterMedicationNameError;

  /// No description provided for @deleteMedicationConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити ліки?'**
  String get deleteMedicationConfirmTitle;

  /// No description provided for @deleteMedicationConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Ліки будуть вилучені з розкладу.'**
  String get deleteMedicationConfirmBody;

  /// No description provided for @editMedicationTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати ліки'**
  String get editMedicationTitle;

  /// No description provided for @medicationNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Назва препарату'**
  String get medicationNameHint;

  /// No description provided for @medicationFormLabel.
  ///
  /// In uk, this message translates to:
  /// **'Форма випуску'**
  String get medicationFormLabel;

  /// No description provided for @coursePhasesLabel.
  ///
  /// In uk, this message translates to:
  /// **'Фази курсу'**
  String get coursePhasesLabel;

  /// No description provided for @addPhaseAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати фазу'**
  String get addPhaseAction;

  /// No description provided for @repeatSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Повтор'**
  String get repeatSectionLabel;

  /// No description provided for @savingLabel.
  ///
  /// In uk, this message translates to:
  /// **'Зберігаємо...'**
  String get savingLabel;

  /// No description provided for @saveChangesAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти зміни'**
  String get saveChangesAction;

  /// No description provided for @saveAndContinueAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти і продовжити →'**
  String get saveAndContinueAction;

  /// No description provided for @saveAndViewScheduleAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти та переглянути розклад →'**
  String get saveAndViewScheduleAction;

  /// No description provided for @moreInEllyPlusLabel.
  ///
  /// In uk, this message translates to:
  /// **'Більше в Elly+'**
  String get moreInEllyPlusLabel;

  /// No description provided for @aiLabel.
  ///
  /// In uk, this message translates to:
  /// **'AI'**
  String get aiLabel;

  /// No description provided for @scanPrescriptionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнати рецепт за фото'**
  String get scanPrescriptionTitle;

  /// No description provided for @scanPrescriptionSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Еллі внесе ліки у розклад'**
  String get scanPrescriptionSubtitle;

  /// No description provided for @scansRemainingLabel.
  ///
  /// In uk, this message translates to:
  /// **'{remaining} сканувань залишилось для тарифу Elly Free'**
  String scansRemainingLabel(int remaining);

  /// No description provided for @orEnterManuallyLabel.
  ///
  /// In uk, this message translates to:
  /// **'або введіть вручну'**
  String get orEnterManuallyLabel;

  /// No description provided for @bulkSavedSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Додано {count} препаратів. Перевірте деталі в списку ліків.'**
  String bulkSavedSnackbar(int count);

  /// No description provided for @phaseCardTitle.
  ///
  /// In uk, this message translates to:
  /// **'Фаза {number}'**
  String phaseCardTitle(int number);

  /// No description provided for @removePhaseAction.
  ///
  /// In uk, this message translates to:
  /// **'видалити'**
  String get removePhaseAction;

  /// No description provided for @doseAmountLabel.
  ///
  /// In uk, this message translates to:
  /// **'КІЛЬКІСТЬ НА ПРИЙОМ'**
  String get doseAmountLabel;

  /// No description provided for @foodRelationSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'ВІДНОСНО ЇЖІ'**
  String get foodRelationSectionLabel;

  /// No description provided for @durationSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'ТРИВАЛІСТЬ'**
  String get durationSectionLabel;

  /// No description provided for @daysCountDashLabel.
  ///
  /// In uk, this message translates to:
  /// **'— дн.'**
  String get daysCountDashLabel;

  /// No description provided for @daysCountLabel.
  ///
  /// In uk, this message translates to:
  /// **'{n} дн.'**
  String daysCountLabel(int n);

  /// No description provided for @orLabel.
  ///
  /// In uk, this message translates to:
  /// **'або'**
  String get orLabel;

  /// No description provided for @permanentLabel.
  ///
  /// In uk, this message translates to:
  /// **'Постійно'**
  String get permanentLabel;

  /// No description provided for @intakeTimeSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЧАС ПРИЙОМУ'**
  String get intakeTimeSectionLabel;

  /// No description provided for @specificTimeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Конкретний час'**
  String get specificTimeLabel;

  /// No description provided for @everyNHoursLabel.
  ///
  /// In uk, this message translates to:
  /// **'Кожні N годин'**
  String get everyNHoursLabel;

  /// No description provided for @addTimeAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати час'**
  String get addTimeAction;

  /// No description provided for @intervalLabel.
  ///
  /// In uk, this message translates to:
  /// **'ІНТЕРВАЛ'**
  String get intervalLabel;

  /// No description provided for @hoursCountLabel.
  ///
  /// In uk, this message translates to:
  /// **'{n} год'**
  String hoursCountLabel(int n);

  /// No description provided for @startLabel.
  ///
  /// In uk, this message translates to:
  /// **'ПОЧАТОК'**
  String get startLabel;

  /// No description provided for @daysCountDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Кількість днів'**
  String get daysCountDialogTitle;

  /// No description provided for @daysSuffix.
  ///
  /// In uk, this message translates to:
  /// **'дн.'**
  String get daysSuffix;

  /// No description provided for @intervalDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Інтервал'**
  String get intervalDialogTitle;

  /// No description provided for @hoursSuffix.
  ///
  /// In uk, this message translates to:
  /// **'год'**
  String get hoursSuffix;

  /// No description provided for @doseCommentHint.
  ///
  /// In uk, this message translates to:
  /// **'Коментар до дози (необов\'язково)'**
  String get doseCommentHint;

  /// No description provided for @doseAmountDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Кількість на прийом'**
  String get doseAmountDialogTitle;

  /// No description provided for @doseAmountExampleHint.
  ///
  /// In uk, this message translates to:
  /// **'наприклад 2.5'**
  String get doseAmountExampleHint;

  /// No description provided for @weekdayExampleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Пн, Ср, Пт, Нд…'**
  String get weekdayExampleLabel;

  /// No description provided for @weekdaysOptionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Певні дні тижня'**
  String get weekdaysOptionLabel;

  /// No description provided for @everyNDaysOptionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Кожні N днів'**
  String get everyNDaysOptionLabel;

  /// No description provided for @everyNDaysExampleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Наприклад кожні 3 дні'**
  String get everyNDaysExampleLabel;

  /// No description provided for @everyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Кожні'**
  String get everyLabel;

  /// No description provided for @daysSuffixWord.
  ///
  /// In uk, this message translates to:
  /// **'днів'**
  String get daysSuffixWord;

  /// No description provided for @cycleOptionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Циклом'**
  String get cycleOptionLabel;

  /// No description provided for @cycleExampleLabel.
  ///
  /// In uk, this message translates to:
  /// **'N днів пити — M днів перерва'**
  String get cycleExampleLabel;

  /// No description provided for @drinkLabel.
  ///
  /// In uk, this message translates to:
  /// **'Пити'**
  String get drinkLabel;

  /// No description provided for @breakLabel.
  ///
  /// In uk, this message translates to:
  /// **'Перерва'**
  String get breakLabel;

  /// No description provided for @optionalParamsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Додаткові параметри'**
  String get optionalParamsLabel;

  /// No description provided for @optionalLabel.
  ///
  /// In uk, this message translates to:
  /// **'Необов\'язково'**
  String get optionalLabel;

  /// No description provided for @trackStockLabel.
  ///
  /// In uk, this message translates to:
  /// **'Відстежувати та нагадувати про залишок'**
  String get trackStockLabel;

  /// No description provided for @vialPackageLabel.
  ///
  /// In uk, this message translates to:
  /// **'Флакон / упаковка'**
  String get vialPackageLabel;

  /// No description provided for @markAsOpenedHint.
  ///
  /// In uk, this message translates to:
  /// **'Позначимо як щойно відкриту (100%) — оновити оцінку залишку можна буде в картці ліків'**
  String get markAsOpenedHint;

  /// No description provided for @inStockLabel.
  ///
  /// In uk, this message translates to:
  /// **'В наявності'**
  String get inStockLabel;

  /// No description provided for @howManyNowLabel.
  ///
  /// In uk, this message translates to:
  /// **'Скільки {unit} є зараз'**
  String howManyNowLabel(String unit);

  /// No description provided for @courseAvailableLabel.
  ///
  /// In uk, this message translates to:
  /// **' (курс: {needed}, є: {available})'**
  String courseAvailableLabel(int needed, int available);

  /// No description provided for @enoughForCourseLabel.
  ///
  /// In uk, this message translates to:
  /// **'Вистачить на весь курс'**
  String get enoughForCourseLabel;

  /// No description provided for @noCameraAccessError.
  ///
  /// In uk, this message translates to:
  /// **'Немає доступу до камери. Дозвольте його в налаштуваннях телефону.'**
  String get noCameraAccessError;

  /// No description provided for @cameraOpenError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося відкрити камеру'**
  String get cameraOpenError;

  /// No description provided for @packagePhotoLabel.
  ///
  /// In uk, this message translates to:
  /// **'Фото упаковки'**
  String get packagePhotoLabel;

  /// No description provided for @addPhotoAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати фото'**
  String get addPhotoAction;

  /// No description provided for @addPhotoHint.
  ///
  /// In uk, this message translates to:
  /// **'щоб не переплутати ліки'**
  String get addPhotoHint;

  /// No description provided for @inviteMemberTitle.
  ///
  /// In uk, this message translates to:
  /// **'Запросити {name}'**
  String inviteMemberTitle(String name);

  /// No description provided for @inviteToFamilyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Запросити до сім\'ї'**
  String get inviteToFamilyTitle;

  /// No description provided for @inviteCreateErrorTitle.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося створити запрошення'**
  String get inviteCreateErrorTitle;

  /// No description provided for @tryAgainAction.
  ///
  /// In uk, this message translates to:
  /// **'Спробувати ще раз'**
  String get tryAgainAction;

  /// No description provided for @inviteDependentBody.
  ///
  /// In uk, this message translates to:
  /// **'Нехай {name} введе цей код у застосунку на своєму телефоні. Профіль перетвориться на незалежний: уся наявна історія перенесеться як стартові дані, а ви автоматично отримаєте повний доступ до нього, як і раніше.'**
  String inviteDependentBody(String name);

  /// No description provided for @inviteMemberBody.
  ///
  /// In uk, this message translates to:
  /// **'Той, хто введе цей код, приєднається як рівноправний учасник вашої сімейної групи — зі своїм профілем і своїми даними. Що саме він побачить із ваших даних, ви налаштуєте окремо.'**
  String get inviteMemberBody;

  /// No description provided for @inviteScanOrEnterHint.
  ///
  /// In uk, this message translates to:
  /// **'Відскануйте цей код на іншому пристрої\nабо введіть його вручну'**
  String get inviteScanOrEnterHint;

  /// No description provided for @codeCopiedSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Код скопійовано'**
  String get codeCopiedSnackbar;

  /// No description provided for @inviteCodeExpiryNotice.
  ///
  /// In uk, this message translates to:
  /// **'Код діє 30 хвилин і працює лише один раз. Дані на сервері зашифровані — там немає нічого, крім коду доступу.'**
  String get inviteCodeExpiryNotice;

  /// No description provided for @alreadyJoinedFamilyError.
  ///
  /// In uk, this message translates to:
  /// **'Ви вже приєднані до сім\'ї \"{name}\"'**
  String alreadyJoinedFamilyError(String name);

  /// No description provided for @joinInvalidCodeError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося приєднатись: невірний або прострочений код'**
  String get joinInvalidCodeError;

  /// No description provided for @joinFamilyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Приєднатись до сім\'ї'**
  String get joinFamilyTitle;

  /// No description provided for @confirmationTitle.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердження'**
  String get confirmationTitle;

  /// No description provided for @doneTitle.
  ///
  /// In uk, this message translates to:
  /// **'Готово'**
  String get doneTitle;

  /// No description provided for @scanQrOrEnterHint.
  ///
  /// In uk, this message translates to:
  /// **'Наведіть камеру на QR-код\nабо введіть код вручну'**
  String get scanQrOrEnterHint;

  /// No description provided for @codeInputHint.
  ///
  /// In uk, this message translates to:
  /// **'________'**
  String get codeInputHint;

  /// No description provided for @checkingLabel.
  ///
  /// In uk, this message translates to:
  /// **'Перевірка…'**
  String get checkingLabel;

  /// No description provided for @continueAction.
  ///
  /// In uk, this message translates to:
  /// **'Продовжити'**
  String get continueAction;

  /// No description provided for @invitesYouToFamilyGroup.
  ///
  /// In uk, this message translates to:
  /// **'запрошує вас до сімейної групи'**
  String get invitesYouToFamilyGroup;

  /// No description provided for @joinConsentBody.
  ///
  /// In uk, this message translates to:
  /// **'Ви приєднуєтесь як рівноправний учасник — ваш власний профіль (ім\'я й аватар) стане видимим \"{name}\". Це не скасовує і не змінює жодних ваших даних, уже внесених у застосунок. Ваша медкартка НІКОМУ автоматично не показується — які саме дані бачитимуть інші учасники, ви налаштуєте окремо, вже після приєднання.'**
  String joinConsentBody(String name);

  /// No description provided for @joinConsentCheckbox.
  ///
  /// In uk, this message translates to:
  /// **'Я погоджуюсь приєднатись до сімейної групи \"{name}\"'**
  String joinConsentCheckbox(String name);

  /// No description provided for @joiningLabel.
  ///
  /// In uk, this message translates to:
  /// **'Приєднуємось…'**
  String get joiningLabel;

  /// No description provided for @joinAction.
  ///
  /// In uk, this message translates to:
  /// **'Приєднатись'**
  String get joinAction;

  /// No description provided for @joinedFamilyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ви в сім\'ї!'**
  String get joinedFamilyTitle;

  /// No description provided for @joinedFamilyBody.
  ///
  /// In uk, this message translates to:
  /// **'Тепер ви й \"{name}\" бачите одне одного в розділі \"Сім\'я\".'**
  String joinedFamilyBody(String name);

  /// No description provided for @scanQrCodeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Сканувати QR-код'**
  String get scanQrCodeLabel;

  /// No description provided for @tapToEnableCameraHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть, щоб увімкнути камеру'**
  String get tapToEnableCameraHint;

  /// No description provided for @doctorVisitLabel.
  ///
  /// In uk, this message translates to:
  /// **'Візит до лікаря'**
  String get doctorVisitLabel;

  /// No description provided for @recordFallbackLabel.
  ///
  /// In uk, this message translates to:
  /// **'Запис'**
  String get recordFallbackLabel;

  /// No description provided for @dataFromPeerTitle.
  ///
  /// In uk, this message translates to:
  /// **'Дані від {name}'**
  String dataFromPeerTitle(String name);

  /// No description provided for @peerNothingSharedYet.
  ///
  /// In uk, this message translates to:
  /// **'{name} ще нічого не поділив(-ла) з вами — або доступ ще не надано.'**
  String peerNothingSharedYet(String name);

  /// No description provided for @noViewableDataLabel.
  ///
  /// In uk, this message translates to:
  /// **'Немає даних, доступних для перегляду'**
  String get noViewableDataLabel;

  /// No description provided for @fileRequestSentSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Запит надіслано — файл ще потрібно дочекатись'**
  String get fileRequestSentSnackbar;

  /// No description provided for @fileRequestFailedError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося надіслати запит: {error}'**
  String fileRequestFailedError(String error);

  /// No description provided for @pdfReceivedSavedSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'PDF отримано та збережено'**
  String get pdfReceivedSavedSnackbar;

  /// No description provided for @fileOpenFailedError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося відкрити файл: {error}'**
  String fileOpenFailedError(String error);

  /// No description provided for @loadingEllipsis.
  ///
  /// In uk, this message translates to:
  /// **'…'**
  String get loadingEllipsis;

  /// No description provided for @pdfLabel.
  ///
  /// In uk, this message translates to:
  /// **'PDF'**
  String get pdfLabel;

  /// No description provided for @photoLabel.
  ///
  /// In uk, this message translates to:
  /// **'Фото'**
  String get photoLabel;

  /// No description provided for @awaitingFileLabel.
  ///
  /// In uk, this message translates to:
  /// **'Очікуємо файл…'**
  String get awaitingFileLabel;

  /// No description provided for @requestFileAction.
  ///
  /// In uk, this message translates to:
  /// **'Запросити файл'**
  String get requestFileAction;

  /// No description provided for @editNotesTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати нотатки'**
  String get editNotesTitle;

  /// No description provided for @editNotesDisclaimer.
  ///
  /// In uk, this message translates to:
  /// **'Правку побачить власник даних — застосується, лише якщо він тим часом сам не змінював цей запис.'**
  String get editNotesDisclaimer;

  /// No description provided for @notesHintEllipsis.
  ///
  /// In uk, this message translates to:
  /// **'Нотатки…'**
  String get notesHintEllipsis;

  /// No description provided for @editSentSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Правку надіслано'**
  String get editSentSnackbar;

  /// No description provided for @sendFailedError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося надіслати: {error}'**
  String sendFailedError(String error);

  /// No description provided for @sendEditAction.
  ///
  /// In uk, this message translates to:
  /// **'Надіслати правку'**
  String get sendEditAction;

  /// No description provided for @familyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Сімʼя'**
  String get familyLabel;

  /// No description provided for @familyMembersCountLabel.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} член} few{{count} члени} other{{count} членів}}'**
  String familyMembersCountLabel(int count);

  /// No description provided for @noMedsTodayLabel.
  ///
  /// In uk, this message translates to:
  /// **'Немає ліків на сьогодні'**
  String get noMedsTodayLabel;

  /// No description provided for @allDoneTodayLabel.
  ///
  /// In uk, this message translates to:
  /// **'Усе виконано сьогодні'**
  String get allDoneTodayLabel;

  /// No description provided for @takenOfTotalIntakesLabel.
  ///
  /// In uk, this message translates to:
  /// **'{taken} з {total} прийомів'**
  String takenOfTotalIntakesLabel(int taken, int total);

  /// No description provided for @missedRemindersLabel.
  ///
  /// In uk, this message translates to:
  /// **'Пропущено {count, plural, one{{count} нагадування} few{{count} нагадування} other{{count} нагадувань}}'**
  String missedRemindersLabel(int count);

  /// No description provided for @nextIntakeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Наступне: {medName} о {time}'**
  String nextIntakeLabel(String medName, String time);

  /// No description provided for @meLabel.
  ///
  /// In uk, this message translates to:
  /// **'я'**
  String get meLabel;

  /// No description provided for @localLabel.
  ///
  /// In uk, this message translates to:
  /// **'Локальний'**
  String get localLabel;

  /// No description provided for @notTakenSuffixLabel.
  ///
  /// In uk, this message translates to:
  /// **'{time} · не прийнято'**
  String notTakenSuffixLabel(String time);

  /// No description provided for @autonomousProfilesPlusOnly.
  ///
  /// In uk, this message translates to:
  /// **'Автономні профілі — лише на Elly Family'**
  String get autonomousProfilesPlusOnly;

  /// No description provided for @inviteAction.
  ///
  /// In uk, this message translates to:
  /// **'Запросити'**
  String get inviteAction;

  /// No description provided for @awaitingJoinLabel.
  ///
  /// In uk, this message translates to:
  /// **'Очікуємо приєднання'**
  String get awaitingJoinLabel;

  /// No description provided for @inviteToAppLabel.
  ///
  /// In uk, this message translates to:
  /// **'Запросити в застосунок'**
  String get inviteToAppLabel;

  /// No description provided for @viewAsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Переглянути як {name}'**
  String viewAsLabel(String name);

  /// No description provided for @deleteForeverAction.
  ///
  /// In uk, this message translates to:
  /// **'Видалити назавжди'**
  String get deleteForeverAction;

  /// No description provided for @areYouSureTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ви впевнені?'**
  String get areYouSureTitle;

  /// No description provided for @deleteMemberConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Будуть видалені весь розклад та медичні картки, прив\'язані до профілю {name}'**
  String deleteMemberConfirmBody(String name);

  /// No description provided for @careSummaryLabel.
  ///
  /// In uk, this message translates to:
  /// **'Ви піклуєтесь про {count, plural, one{{count} близького} few{{count} близьких} other{{count} близьких}}. Еллі надішле сповіщення, якщо хтось пропустить прийом.'**
  String careSummaryLabel(int count);

  /// No description provided for @addFamilyMemberLabel.
  ///
  /// In uk, this message translates to:
  /// **'Додати члена сімʼї'**
  String get addFamilyMemberLabel;

  /// No description provided for @addMemberHint.
  ///
  /// In uk, this message translates to:
  /// **'Батьки, діти, партнер…'**
  String get addMemberHint;

  /// No description provided for @profileLimitReachedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ліміт профілів досягнуто'**
  String get profileLimitReachedTitle;

  /// No description provided for @profileLimitReachedSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Перейдіть на Elly Plus — необмежена кількість локальних профілів'**
  String get profileLimitReachedSubtitle;

  /// No description provided for @localProfilesTitle.
  ///
  /// In uk, this message translates to:
  /// **'Профілі локальні'**
  String get localProfilesTitle;

  /// No description provided for @familyUpgradeSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Щоб сім\'я теж могла керувати — перейдіть на Elly Family'**
  String get familyUpgradeSubtitle;

  /// No description provided for @leaveGroupConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Покинути \"{name}\"?'**
  String leaveGroupConfirmTitle(String name);

  /// No description provided for @leaveGroupConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Учасники цієї групи втратять доступ до ваших даних, а ви — до того, чим вони з вами ділились. Інших сімейних груп це не торкнеться.'**
  String get leaveGroupConfirmBody;

  /// No description provided for @leaveAction.
  ///
  /// In uk, this message translates to:
  /// **'Покинути'**
  String get leaveAction;

  /// No description provided for @leftGroupSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Ви покинули \"{name}\"'**
  String leftGroupSnackbar(String name);

  /// No description provided for @familyGroupSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Сімейна група'**
  String get familyGroupSectionLabel;

  /// No description provided for @slotsUsedLabel.
  ///
  /// In uk, this message translates to:
  /// **'{used} з {total}'**
  String slotsUsedLabel(int used, int total);

  /// No description provided for @autonomousLimitReachedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ліміт автономних профілів досягнуто'**
  String get autonomousLimitReachedTitle;

  /// No description provided for @autonomousLimitReachedSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Перейдіть на Elly Family, щоб запросити ще когось'**
  String get autonomousLimitReachedSubtitle;

  /// No description provided for @myFamilyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Моя сім\'я'**
  String get myFamilyLabel;

  /// No description provided for @peerFamilyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Сім\'я {name}'**
  String peerFamilyLabel(String name);

  /// No description provided for @doctorFallbackLabel.
  ///
  /// In uk, this message translates to:
  /// **'Лікар'**
  String get doctorFallbackLabel;

  /// No description provided for @reminderPushTitle.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Вам нагадують'**
  String get reminderPushTitle;

  /// No description provided for @reminderTakeMedBody.
  ///
  /// In uk, this message translates to:
  /// **'Не забудьте прийняти \"{title}\"{detailSuffix} о {time}'**
  String reminderTakeMedBody(String title, String detailSuffix, String time);

  /// No description provided for @reminderDoActivityBody.
  ///
  /// In uk, this message translates to:
  /// **'Не забудьте виконати \"{title}\" о {time}'**
  String reminderDoActivityBody(String title, String time);

  /// No description provided for @reminderDoctorVisitBody.
  ///
  /// In uk, this message translates to:
  /// **'Не забудьте про прийом лікаря: {title}{detailSuffix}'**
  String reminderDoctorVisitBody(String title, String detailSuffix);

  /// No description provided for @reminderWellbeingBody.
  ///
  /// In uk, this message translates to:
  /// **'Не забудьте відмітити самопочуття'**
  String get reminderWellbeingBody;

  /// No description provided for @reminderGenericBody.
  ///
  /// In uk, this message translates to:
  /// **'Перевірте розклад'**
  String get reminderGenericBody;

  /// No description provided for @reminderSentSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування для {name} надіслано'**
  String reminderSentSnackbar(String name);

  /// No description provided for @independentAccountLabel.
  ///
  /// In uk, this message translates to:
  /// **'Незалежний обліковий запис'**
  String get independentAccountLabel;

  /// No description provided for @missedLabel.
  ///
  /// In uk, this message translates to:
  /// **'Пропущено'**
  String get missedLabel;

  /// No description provided for @missedCountLabel.
  ///
  /// In uk, this message translates to:
  /// **'Пропущено {count}'**
  String missedCountLabel(int count);

  /// No description provided for @remindAction.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Нагадати'**
  String get remindAction;

  /// No description provided for @removePeerConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Прибрати \"{name}\"?'**
  String removePeerConfirmTitle(String name);

  /// No description provided for @removePeerConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Ви обидва втратите доступ до даних, якими ділились одне з одним.'**
  String get removePeerConfirmBody;

  /// No description provided for @confirmGuardianConsentSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердіть, що ви маєте право вести дані цієї людини'**
  String get confirmGuardianConsentSnackbar;

  /// No description provided for @nameFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'ІМʼЯ'**
  String get nameFieldLabel;

  /// No description provided for @avatarFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'АВАТАР'**
  String get avatarFieldLabel;

  /// No description provided for @memberNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Мама, Тато, Бабуся…'**
  String get memberNameHint;

  /// No description provided for @guardianConsentCheckbox.
  ///
  /// In uk, this message translates to:
  /// **'Я є законним представником цієї людини або отримав(-ла) її згоду на ведення її даних у застосунку'**
  String get guardianConsentCheckbox;

  /// No description provided for @debugLogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Журнал подій'**
  String get debugLogTitle;

  /// No description provided for @debugLogEmptyBody.
  ///
  /// In uk, this message translates to:
  /// **'Лог порожній.'**
  String get debugLogEmptyBody;

  /// No description provided for @debugLogEmptySnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Лог порожній'**
  String get debugLogEmptySnackbar;

  /// No description provided for @debugLogShareSubject.
  ///
  /// In uk, this message translates to:
  /// **'Elly — журнал подій'**
  String get debugLogShareSubject;

  /// No description provided for @viewDebugLogAction.
  ///
  /// In uk, this message translates to:
  /// **'Переглянути журнал подій'**
  String get viewDebugLogAction;

  /// No description provided for @shareDbFileAction.
  ///
  /// In uk, this message translates to:
  /// **'Поділитись файлом БД'**
  String get shareDbFileAction;

  /// No description provided for @shareDbFileEmptySnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Файл БД не знайдено'**
  String get shareDbFileEmptySnackbar;

  /// No description provided for @clearAction.
  ///
  /// In uk, this message translates to:
  /// **'Очистити'**
  String get clearAction;

  /// No description provided for @shareAction.
  ///
  /// In uk, this message translates to:
  /// **'Поділитись'**
  String get shareAction;

  /// No description provided for @antiStressLabel.
  ///
  /// In uk, this message translates to:
  /// **'Антистрес-вправи'**
  String get antiStressLabel;

  /// No description provided for @antiStressPickerSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Обери, що допоможе прямо зараз'**
  String get antiStressPickerSubtitle;

  /// No description provided for @breathingExerciseTitle.
  ///
  /// In uk, this message translates to:
  /// **'Дихаймо разом'**
  String get breathingExerciseTitle;

  /// No description provided for @breathingExerciseSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Повільне дихання за 2 хвилини заспокоює нервову систему'**
  String get breathingExerciseSubtitle;

  /// No description provided for @grounding54321Title.
  ///
  /// In uk, this message translates to:
  /// **'5-4-3-2-1'**
  String get grounding54321Title;

  /// No description provided for @grounding54321Subtitle.
  ///
  /// In uk, this message translates to:
  /// **'Техніка заземлення — повертає увагу в тут-і-зараз'**
  String get grounding54321Subtitle;

  /// No description provided for @clearMindTitle.
  ///
  /// In uk, this message translates to:
  /// **'Чистий розум'**
  String get clearMindTitle;

  /// No description provided for @clearMindPickerSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Проведи пальцем по екрану — і туман розвіється'**
  String get clearMindPickerSubtitle;

  /// No description provided for @breathingScreenHeaderLabel.
  ///
  /// In uk, this message translates to:
  /// **'Хвилинка спокою'**
  String get breathingScreenHeaderLabel;

  /// No description provided for @breathingDoneBody.
  ///
  /// In uk, this message translates to:
  /// **'Молодець! Ти впорався(-лась).'**
  String get breathingDoneBody;

  /// No description provided for @breathingCyclesLeftBody.
  ///
  /// In uk, this message translates to:
  /// **'Повільний вдих... і видих. Ще {count, plural, one{{count} цикл} few{{count} цикли} other{{count} циклів}}.'**
  String breathingCyclesLeftBody(int count);

  /// No description provided for @restartAction.
  ///
  /// In uk, this message translates to:
  /// **'Ще раз'**
  String get restartAction;

  /// No description provided for @inhaleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Вдих'**
  String get inhaleLabel;

  /// No description provided for @exhaleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Видих'**
  String get exhaleLabel;

  /// No description provided for @safeYouTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ти в безпеці'**
  String get safeYouTitle;

  /// No description provided for @safeYouSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Тривога мине. Еллі поруч, поки тобі потрібно.'**
  String get safeYouSubtitle;

  /// No description provided for @differentExerciseAction.
  ///
  /// In uk, this message translates to:
  /// **'Інша вправа'**
  String get differentExerciseAction;

  /// No description provided for @feelBetterAction.
  ///
  /// In uk, this message translates to:
  /// **'Мені краще'**
  String get feelBetterAction;

  /// No description provided for @clearMindHeading.
  ///
  /// In uk, this message translates to:
  /// **'Розвій туман'**
  String get clearMindHeading;

  /// No description provided for @clearMindInstructions.
  ///
  /// In uk, this message translates to:
  /// **'Проведи пальцем по екрану, щоб побачити, що ховається за туманом'**
  String get clearMindInstructions;

  /// No description provided for @clearMindTouchHint.
  ///
  /// In uk, this message translates to:
  /// **'👆 Торкнись і веди пальцем'**
  String get clearMindTouchHint;

  /// No description provided for @familyVisibilityLabel.
  ///
  /// In uk, this message translates to:
  /// **'Видимість для сім\'ї'**
  String get familyVisibilityLabel;

  /// No description provided for @familyVisibilityEmptyBody.
  ///
  /// In uk, this message translates to:
  /// **'Якщо до вашої сімейної групи приєднаються автономні учасники (зі своїм акаунтом), тут можна буде керувати їхнім доступом до вашого профілю'**
  String get familyVisibilityEmptyBody;

  /// No description provided for @familyVisibilityIntro.
  ///
  /// In uk, this message translates to:
  /// **'Що бачать і можуть робити інші члени сім\'ї з вашим профілем'**
  String get familyVisibilityIntro;

  /// No description provided for @medcardSyncToggleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Синхронізувати медкартку на інші пристрої'**
  String get medcardSyncToggleLabel;

  /// No description provided for @medcardSyncDescription.
  ///
  /// In uk, this message translates to:
  /// **'Якщо вимкнено, алергії, хронічні захворювання, щеплення, операції, аналізи й візити цього профілю (разом із вкладеннями) не передаються на інші пристрої сім\'ї, підключені через пейринг. Ліки й розклад прийому синхронізуються незалежно від цього перемикача.'**
  String get medcardSyncDescription;

  /// No description provided for @pendingConnectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Очікуємо з\'єднання'**
  String get pendingConnectionLabel;

  /// No description provided for @viewerNotifyPermissionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Отримує сповіщення'**
  String get viewerNotifyPermissionLabel;

  /// No description provided for @viewerEditPermissionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Може редагувати профіль'**
  String get viewerEditPermissionLabel;

  /// No description provided for @viewerViewPermissionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Бачить завдання, медкартку й розклад'**
  String get viewerViewPermissionLabel;

  /// No description provided for @permissionDeniedNotYoursBody.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося змінити — це не ваш профіль'**
  String get permissionDeniedNotYoursBody;

  /// No description provided for @voiceConsentTitle.
  ///
  /// In uk, this message translates to:
  /// **'Голосові команди'**
  String get voiceConsentTitle;

  /// No description provided for @voiceConsentDescription.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнавання голосу через Anthropic (Claude) — додавання ліків, відмітки прийому та інші голосові команди.'**
  String get voiceConsentDescription;

  /// No description provided for @scanConsentTitle.
  ///
  /// In uk, this message translates to:
  /// **'Сканування рецептів'**
  String get scanConsentTitle;

  /// No description provided for @scanConsentDescription.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнавання фото рецепта чи упаковки через Anthropic (Claude) — визначення назви, дозування, форми випуску.'**
  String get scanConsentDescription;

  /// No description provided for @privacyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Конфіденційність'**
  String get privacyLabel;

  /// No description provided for @securityLabel.
  ///
  /// In uk, this message translates to:
  /// **'Безпека'**
  String get securityLabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Політика конфіденційності'**
  String get privacyPolicyLabel;

  /// No description provided for @aiConsentSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Згоди на обробку даних AI-функціями'**
  String get aiConsentSectionLabel;

  /// No description provided for @consentRevokeNoteBody.
  ///
  /// In uk, this message translates to:
  /// **'Скасування згоди не видаляє вже оброблені дані — воно лише означає, що перед наступним використанням цієї функції застосунок знову запитає підтвердження.'**
  String get consentRevokeNoteBody;

  /// No description provided for @dangerZoneLabel.
  ///
  /// In uk, this message translates to:
  /// **'Небезпечна зона'**
  String get dangerZoneLabel;

  /// No description provided for @deleteProfileForeverLabel.
  ///
  /// In uk, this message translates to:
  /// **'Видалити профіль назавжди'**
  String get deleteProfileForeverLabel;

  /// No description provided for @deleteProfileForeverBody.
  ///
  /// In uk, this message translates to:
  /// **'Видалить усі дані профілю \"{name}\" — локально і на сервері, якщо налаштований обмін'**
  String deleteProfileForeverBody(String name);

  /// No description provided for @appLockToggleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Блокування застосунку'**
  String get appLockToggleLabel;

  /// No description provided for @appLockDescription.
  ///
  /// In uk, this message translates to:
  /// **'Face ID, Touch ID або пароль пристрою при кожному відкритті Elly'**
  String get appLockDescription;

  /// No description provided for @policyAcceptedLabel.
  ///
  /// In uk, this message translates to:
  /// **'Прийнято {date} · версія {version}'**
  String policyAcceptedLabel(String date, String version);

  /// No description provided for @policyAcceptedOldVersionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Прийнято стару версію ({version}) — буде запропоновано погодитись знову'**
  String policyAcceptedOldVersionLabel(String version);

  /// No description provided for @policyNotAcceptedLabel.
  ///
  /// In uk, this message translates to:
  /// **'Ще не прийнято'**
  String get policyNotAcceptedLabel;

  /// No description provided for @viewFullTextAction.
  ///
  /// In uk, this message translates to:
  /// **'Переглянути повний текст'**
  String get viewFullTextAction;

  /// No description provided for @consentGivenLabel.
  ///
  /// In uk, this message translates to:
  /// **'Надано {date}'**
  String consentGivenLabel(String date);

  /// No description provided for @consentNotGivenLabel.
  ///
  /// In uk, this message translates to:
  /// **'Згоду не надано'**
  String get consentNotGivenLabel;

  /// No description provided for @revokeConsentAction.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати згоду'**
  String get revokeConsentAction;

  /// No description provided for @groundStep5Title.
  ///
  /// In uk, this message translates to:
  /// **'5 речей, які ти бачиш'**
  String get groundStep5Title;

  /// No description provided for @groundStep5Hint.
  ///
  /// In uk, this message translates to:
  /// **'Одна річ, напр. вікно'**
  String get groundStep5Hint;

  /// No description provided for @groundStep4Title.
  ///
  /// In uk, this message translates to:
  /// **'4 речі, які можеш відчути на дотик'**
  String get groundStep4Title;

  /// No description provided for @groundStep4Hint.
  ///
  /// In uk, this message translates to:
  /// **'Одна річ, напр. тканина светра'**
  String get groundStep4Hint;

  /// No description provided for @groundStep3Title.
  ///
  /// In uk, this message translates to:
  /// **'3 звуки, які ти чуєш'**
  String get groundStep3Title;

  /// No description provided for @groundStep3Hint.
  ///
  /// In uk, this message translates to:
  /// **'Один звук, напр. гудіння холодильника'**
  String get groundStep3Hint;

  /// No description provided for @groundStep2Title.
  ///
  /// In uk, this message translates to:
  /// **'2 запахи, які відчуваєш'**
  String get groundStep2Title;

  /// No description provided for @groundStep2Hint.
  ///
  /// In uk, this message translates to:
  /// **'Один запах, напр. кава'**
  String get groundStep2Hint;

  /// No description provided for @groundStep1Title.
  ///
  /// In uk, this message translates to:
  /// **'1 смак, які відчуваєш'**
  String get groundStep1Title;

  /// No description provided for @groundStep1Hint.
  ///
  /// In uk, this message translates to:
  /// **'Один смак, напр. м\'ята'**
  String get groundStep1Hint;

  /// No description provided for @groundingNameStepLabel.
  ///
  /// In uk, this message translates to:
  /// **'Назви {title}'**
  String groundingNameStepLabel(String title);

  /// No description provided for @groundingProgressCounter.
  ///
  /// In uk, this message translates to:
  /// **'{count} / {total} названо'**
  String groundingProgressCounter(int count, int total);

  /// No description provided for @groundingListeningLabel.
  ///
  /// In uk, this message translates to:
  /// **'Слухаю…'**
  String get groundingListeningLabel;

  /// No description provided for @groundingSkipStepAction.
  ///
  /// In uk, this message translates to:
  /// **'Пропустити цей крок'**
  String get groundingSkipStepAction;

  /// No description provided for @groundingCompletedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ти повернувся(-лась) у тут-і-зараз'**
  String get groundingCompletedTitle;

  /// No description provided for @groundingCompletedSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Чудова робота. Повертайся до цієї вправи, коли знадобиться.'**
  String get groundingCompletedSubtitle;

  /// No description provided for @healthSectionHeader.
  ///
  /// In uk, this message translates to:
  /// **'Здоров\'я та вправи'**
  String get healthSectionHeader;

  /// No description provided for @appSettingsSectionHeader.
  ///
  /// In uk, this message translates to:
  /// **'Налаштування додатку'**
  String get appSettingsSectionHeader;

  /// No description provided for @accountSectionHeader.
  ///
  /// In uk, this message translates to:
  /// **'Акаунт'**
  String get accountSectionHeader;

  /// No description provided for @otherSectionHeader.
  ///
  /// In uk, this message translates to:
  /// **'Інше'**
  String get otherSectionHeader;

  /// No description provided for @backupDisabledTitle.
  ///
  /// In uk, this message translates to:
  /// **'Резервна копія вимкнена'**
  String get backupDisabledTitle;

  /// No description provided for @backupDisabledBody.
  ///
  /// In uk, this message translates to:
  /// **'Дані зберігаються лише на цьому пристрої — увімкніть, щоб не втратити їх'**
  String get backupDisabledBody;

  /// No description provided for @connectFamilyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Підключіть Сім\'я'**
  String get connectFamilyTitle;

  /// No description provided for @connectFamilySubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Турбуйтесь про всю родину'**
  String get connectFamilySubtitle;

  /// No description provided for @planFreeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Безкоштовний план'**
  String get planFreeLabel;

  /// No description provided for @planPlusLabel.
  ///
  /// In uk, this message translates to:
  /// **'Elly Plus'**
  String get planPlusLabel;

  /// No description provided for @planFamilyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Elly Family'**
  String get planFamilyLabel;

  /// No description provided for @languageLabel.
  ///
  /// In uk, this message translates to:
  /// **'Мова'**
  String get languageLabel;

  /// No description provided for @voiceLanguageDescription.
  ///
  /// In uk, this message translates to:
  /// **'Керує мовою інтерфейсу та розпізнавання голосу (голосове управління, запис самопочуття). Поки доступні українська, англійська та російська — інші мови з\'являться після перекладів.'**
  String get voiceLanguageDescription;

  /// No description provided for @fontSizeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Розмір шрифту'**
  String get fontSizeLabel;

  /// No description provided for @fontSizeSampleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Аа'**
  String get fontSizeSampleLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Сповіщення'**
  String get notificationsLabel;

  /// No description provided for @plansLabel.
  ///
  /// In uk, this message translates to:
  /// **'Тарифи'**
  String get plansLabel;

  /// No description provided for @backupLabel.
  ///
  /// In uk, this message translates to:
  /// **'Резервна копія'**
  String get backupLabel;

  /// No description provided for @rateAppLabel.
  ///
  /// In uk, this message translates to:
  /// **'Оцінити застосунок'**
  String get rateAppLabel;

  /// No description provided for @helpFaqLabel.
  ///
  /// In uk, this message translates to:
  /// **'Допомога та FAQ'**
  String get helpFaqLabel;

  /// No description provided for @exportDataLabel.
  ///
  /// In uk, this message translates to:
  /// **'Експорт даних'**
  String get exportDataLabel;

  /// No description provided for @logoutLabel.
  ///
  /// In uk, this message translates to:
  /// **'Вийти з акаунту'**
  String get logoutLabel;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Вийти з акаунту?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Усі дані будуть видалені з цього пристрою. Цю дію неможливо скасувати.'**
  String get logoutConfirmBody;

  /// No description provided for @logoutConfirmAction.
  ///
  /// In uk, this message translates to:
  /// **'Вийти'**
  String get logoutConfirmAction;

  /// No description provided for @editProfileTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати профіль'**
  String get editProfileTitle;

  /// No description provided for @yourNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Ваше ім\'я'**
  String get yourNameHint;

  /// No description provided for @saveAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти'**
  String get saveAction;

  /// No description provided for @appointmentsHistoryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Візити до лікарів'**
  String get appointmentsHistoryTitle;

  /// No description provided for @sectionFuture.
  ///
  /// In uk, this message translates to:
  /// **'Майбутні'**
  String get sectionFuture;

  /// No description provided for @visitPassedLabel.
  ///
  /// In uk, this message translates to:
  /// **'✓ пройшло'**
  String get visitPassedLabel;

  /// No description provided for @arrowRightLabel.
  ///
  /// In uk, this message translates to:
  /// **'→'**
  String get arrowRightLabel;

  /// No description provided for @noRecordsYetTitle.
  ///
  /// In uk, this message translates to:
  /// **'Записів ще немає'**
  String get noRecordsYetTitle;

  /// No description provided for @noAppointmentsForSpecialty.
  ///
  /// In uk, this message translates to:
  /// **'Немає візитів за цим напрямком'**
  String get noAppointmentsForSpecialty;

  /// No description provided for @tryDifferentSpecialtyHint.
  ///
  /// In uk, this message translates to:
  /// **'Спробуйте обрати інший напрямок або скиньте фільтр'**
  String get tryDifferentSpecialtyHint;

  /// No description provided for @tapToAddFirstHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Додати\" щоб створити перший'**
  String get tapToAddFirstHint;

  /// No description provided for @meCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Я'**
  String get meCapsLabel;

  /// No description provided for @monthAbbrJan.
  ///
  /// In uk, this message translates to:
  /// **'СІЧ'**
  String get monthAbbrJan;

  /// No description provided for @monthAbbrFeb.
  ///
  /// In uk, this message translates to:
  /// **'ЛЮТ'**
  String get monthAbbrFeb;

  /// No description provided for @monthAbbrMar.
  ///
  /// In uk, this message translates to:
  /// **'БЕР'**
  String get monthAbbrMar;

  /// No description provided for @monthAbbrApr.
  ///
  /// In uk, this message translates to:
  /// **'КВІ'**
  String get monthAbbrApr;

  /// No description provided for @monthAbbrMay.
  ///
  /// In uk, this message translates to:
  /// **'ТРА'**
  String get monthAbbrMay;

  /// No description provided for @monthAbbrJun.
  ///
  /// In uk, this message translates to:
  /// **'ЧЕР'**
  String get monthAbbrJun;

  /// No description provided for @monthAbbrJul.
  ///
  /// In uk, this message translates to:
  /// **'ЛИП'**
  String get monthAbbrJul;

  /// No description provided for @monthAbbrAug.
  ///
  /// In uk, this message translates to:
  /// **'СЕР'**
  String get monthAbbrAug;

  /// No description provided for @monthAbbrSep.
  ///
  /// In uk, this message translates to:
  /// **'ВЕР'**
  String get monthAbbrSep;

  /// No description provided for @monthAbbrOct.
  ///
  /// In uk, this message translates to:
  /// **'ЖОВ'**
  String get monthAbbrOct;

  /// No description provided for @monthAbbrNov.
  ///
  /// In uk, this message translates to:
  /// **'ЛИС'**
  String get monthAbbrNov;

  /// No description provided for @monthAbbrDec.
  ///
  /// In uk, this message translates to:
  /// **'ГРУ'**
  String get monthAbbrDec;

  /// No description provided for @remindBefore1Hour.
  ///
  /// In uk, this message translates to:
  /// **'За 1 годину'**
  String get remindBefore1Hour;

  /// No description provided for @remindBefore1Day.
  ///
  /// In uk, this message translates to:
  /// **'За день'**
  String get remindBefore1Day;

  /// No description provided for @remindBefore2Days.
  ///
  /// In uk, this message translates to:
  /// **'За 2 дні'**
  String get remindBefore2Days;

  /// No description provided for @deleteAppointmentBody.
  ///
  /// In uk, this message translates to:
  /// **'Запис до лікаря буде видалено.'**
  String get deleteAppointmentBody;

  /// No description provided for @enterDoctorTypeError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть тип лікаря'**
  String get enterDoctorTypeError;

  /// No description provided for @recordVisitTitle.
  ///
  /// In uk, this message translates to:
  /// **'Записати візит'**
  String get recordVisitTitle;

  /// No description provided for @newAppointmentTitle.
  ///
  /// In uk, this message translates to:
  /// **'Запис до лікаря'**
  String get newAppointmentTitle;

  /// No description provided for @fieldWhere.
  ///
  /// In uk, this message translates to:
  /// **'Де'**
  String get fieldWhere;

  /// No description provided for @locationHint.
  ///
  /// In uk, this message translates to:
  /// **'Клініка, адреса або онлайн'**
  String get locationHint;

  /// No description provided for @fieldDateTime.
  ///
  /// In uk, this message translates to:
  /// **'Дата та час'**
  String get fieldDateTime;

  /// No description provided for @dateCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ДАТА'**
  String get dateCapsLabel;

  /// No description provided for @timeCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЧАС'**
  String get timeCapsLabel;

  /// No description provided for @remindBeforeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Нагадати заздалегідь'**
  String get remindBeforeLabel;

  /// No description provided for @doctorConclusionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Висновок лікаря'**
  String get doctorConclusionLabel;

  /// No description provided for @noteSingularLabel.
  ///
  /// In uk, this message translates to:
  /// **'Нотатка'**
  String get noteSingularLabel;

  /// No description provided for @doctorConclusionHint.
  ///
  /// In uk, this message translates to:
  /// **'Що сказав лікар, рекомендації, призначення…'**
  String get doctorConclusionHint;

  /// No description provided for @apptNoteHint.
  ///
  /// In uk, this message translates to:
  /// **'Що запитати, взяти з собою, номер поліса…'**
  String get apptNoteHint;

  /// No description provided for @saveVisitAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти візит'**
  String get saveVisitAction;

  /// No description provided for @saveReminderAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти нагадування'**
  String get saveReminderAction;

  /// No description provided for @monthGenJan.
  ///
  /// In uk, this message translates to:
  /// **'січня'**
  String get monthGenJan;

  /// No description provided for @monthGenFeb.
  ///
  /// In uk, this message translates to:
  /// **'лютого'**
  String get monthGenFeb;

  /// No description provided for @monthGenMar.
  ///
  /// In uk, this message translates to:
  /// **'березня'**
  String get monthGenMar;

  /// No description provided for @monthGenApr.
  ///
  /// In uk, this message translates to:
  /// **'квітня'**
  String get monthGenApr;

  /// No description provided for @monthGenMay.
  ///
  /// In uk, this message translates to:
  /// **'травня'**
  String get monthGenMay;

  /// No description provided for @monthGenJun.
  ///
  /// In uk, this message translates to:
  /// **'червня'**
  String get monthGenJun;

  /// No description provided for @monthGenJul.
  ///
  /// In uk, this message translates to:
  /// **'липня'**
  String get monthGenJul;

  /// No description provided for @monthGenAug.
  ///
  /// In uk, this message translates to:
  /// **'серпня'**
  String get monthGenAug;

  /// No description provided for @monthGenSep.
  ///
  /// In uk, this message translates to:
  /// **'вересня'**
  String get monthGenSep;

  /// No description provided for @monthGenOct.
  ///
  /// In uk, this message translates to:
  /// **'жовтня'**
  String get monthGenOct;

  /// No description provided for @monthGenNov.
  ///
  /// In uk, this message translates to:
  /// **'листопада'**
  String get monthGenNov;

  /// No description provided for @monthGenDec.
  ///
  /// In uk, this message translates to:
  /// **'грудня'**
  String get monthGenDec;

  /// No description provided for @symptomsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Симптоми'**
  String get symptomsTitle;

  /// No description provided for @symptomSearchHint.
  ///
  /// In uk, this message translates to:
  /// **'Пошук або нова назва…'**
  String get symptomSearchHint;

  /// No description provided for @symptomListEmptyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Список порожній'**
  String get symptomListEmptyLabel;

  /// No description provided for @addCustomSymptomLabel.
  ///
  /// In uk, this message translates to:
  /// **'Додати «{query}»'**
  String addCustomSymptomLabel(String query);

  /// No description provided for @historyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Історія'**
  String get historyLabel;

  /// No description provided for @wellbeingScheduleInfoText.
  ///
  /// In uk, this message translates to:
  /// **'Налаштуйте розклад збору зрізів самопочуття. У призначений час на головному екрані з\'явиться картка для заповнення.'**
  String get wellbeingScheduleInfoText;

  /// No description provided for @frequencyPerDayLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЧАСТОТА НА ДЕНЬ'**
  String get frequencyPerDayLabel;

  /// No description provided for @collectionTimeLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЧАС ЗБОРУ'**
  String get collectionTimeLabel;

  /// No description provided for @wellbeingSlotNumberLabel.
  ///
  /// In uk, this message translates to:
  /// **'Зріз {index}'**
  String wellbeingSlotNumberLabel(int index);

  /// No description provided for @timesCountShort.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} раз} few{{count} рази} other{{count} разів}}'**
  String timesCountShort(int count);

  /// No description provided for @saveScheduleAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти розклад'**
  String get saveScheduleAction;

  /// No description provided for @wellbeingByDaySubtitle.
  ///
  /// In uk, this message translates to:
  /// **'самопочуття по днях'**
  String get wellbeingByDaySubtitle;

  /// No description provided for @addWellbeingSlotAction.
  ///
  /// In uk, this message translates to:
  /// **'+ Зріз'**
  String get addWellbeingSlotAction;

  /// No description provided for @moodChartTitle.
  ///
  /// In uk, this message translates to:
  /// **'Настрій — {month}'**
  String moodChartTitle(String month);

  /// No description provided for @monthNomJan.
  ///
  /// In uk, this message translates to:
  /// **'січень'**
  String get monthNomJan;

  /// No description provided for @monthNomFeb.
  ///
  /// In uk, this message translates to:
  /// **'лютий'**
  String get monthNomFeb;

  /// No description provided for @monthNomMar.
  ///
  /// In uk, this message translates to:
  /// **'березень'**
  String get monthNomMar;

  /// No description provided for @monthNomApr.
  ///
  /// In uk, this message translates to:
  /// **'квітень'**
  String get monthNomApr;

  /// No description provided for @monthNomMay.
  ///
  /// In uk, this message translates to:
  /// **'травень'**
  String get monthNomMay;

  /// No description provided for @monthNomJun.
  ///
  /// In uk, this message translates to:
  /// **'червень'**
  String get monthNomJun;

  /// No description provided for @monthNomJul.
  ///
  /// In uk, this message translates to:
  /// **'липень'**
  String get monthNomJul;

  /// No description provided for @monthNomAug.
  ///
  /// In uk, this message translates to:
  /// **'серпень'**
  String get monthNomAug;

  /// No description provided for @monthNomSep.
  ///
  /// In uk, this message translates to:
  /// **'вересень'**
  String get monthNomSep;

  /// No description provided for @monthNomOct.
  ///
  /// In uk, this message translates to:
  /// **'жовтень'**
  String get monthNomOct;

  /// No description provided for @monthNomNov.
  ///
  /// In uk, this message translates to:
  /// **'листопад'**
  String get monthNomNov;

  /// No description provided for @monthNomDec.
  ///
  /// In uk, this message translates to:
  /// **'грудень'**
  String get monthNomDec;

  /// No description provided for @weekdayFullMon.
  ///
  /// In uk, this message translates to:
  /// **'понеділок'**
  String get weekdayFullMon;

  /// No description provided for @weekdayFullTue.
  ///
  /// In uk, this message translates to:
  /// **'вівторок'**
  String get weekdayFullTue;

  /// No description provided for @weekdayFullWed.
  ///
  /// In uk, this message translates to:
  /// **'середа'**
  String get weekdayFullWed;

  /// No description provided for @weekdayFullThu.
  ///
  /// In uk, this message translates to:
  /// **'четвер'**
  String get weekdayFullThu;

  /// No description provided for @weekdayFullFri.
  ///
  /// In uk, this message translates to:
  /// **'пʼятниця'**
  String get weekdayFullFri;

  /// No description provided for @weekdayFullSat.
  ///
  /// In uk, this message translates to:
  /// **'субота'**
  String get weekdayFullSat;

  /// No description provided for @weekdayFullSun.
  ///
  /// In uk, this message translates to:
  /// **'неділя'**
  String get weekdayFullSun;

  /// No description provided for @todayLowerLabel.
  ///
  /// In uk, this message translates to:
  /// **'сьогодні'**
  String get todayLowerLabel;

  /// No description provided for @yesterdayLowerLabel.
  ///
  /// In uk, this message translates to:
  /// **'вчора'**
  String get yesterdayLowerLabel;

  /// No description provided for @quotedCommentLabel.
  ///
  /// In uk, this message translates to:
  /// **'«{comment}»'**
  String quotedCommentLabel(String comment);

  /// No description provided for @noWellbeingLogsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Зрізів ще немає'**
  String get noWellbeingLogsTitle;

  /// No description provided for @noWellbeingLogsHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть \"+ Зріз\" щоб додати перший'**
  String get noWellbeingLogsHint;

  /// No description provided for @comingSoonEllipsis.
  ///
  /// In uk, this message translates to:
  /// **'Скоро...'**
  String get comingSoonEllipsis;

  /// No description provided for @sendDiaryToDoctorLabel.
  ///
  /// In uk, this message translates to:
  /// **'Відправити щоденник лікарю'**
  String get sendDiaryToDoctorLabel;

  /// No description provided for @diarySummaryHint.
  ///
  /// In uk, this message translates to:
  /// **'Зрізи + симптоми + прийоми за місяць'**
  String get diarySummaryHint;

  /// No description provided for @moodBadLabel.
  ///
  /// In uk, this message translates to:
  /// **'Погано'**
  String get moodBadLabel;

  /// No description provided for @moodMehLabel.
  ///
  /// In uk, this message translates to:
  /// **'Так собі'**
  String get moodMehLabel;

  /// No description provided for @moodOkLabel.
  ///
  /// In uk, this message translates to:
  /// **'Норм'**
  String get moodOkLabel;

  /// No description provided for @moodGoodLabel.
  ///
  /// In uk, this message translates to:
  /// **'Добре'**
  String get moodGoodLabel;

  /// No description provided for @moodGreatLabel.
  ///
  /// In uk, this message translates to:
  /// **'Відмінно'**
  String get moodGreatLabel;

  /// No description provided for @chooseWellbeingErrorSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть самопочуття'**
  String get chooseWellbeingErrorSnackbar;

  /// No description provided for @wellbeingSlotMorning.
  ///
  /// In uk, this message translates to:
  /// **'ранковий зріз'**
  String get wellbeingSlotMorning;

  /// No description provided for @wellbeingSlotAfternoon.
  ///
  /// In uk, this message translates to:
  /// **'денний зріз'**
  String get wellbeingSlotAfternoon;

  /// No description provided for @wellbeingSlotEvening.
  ///
  /// In uk, this message translates to:
  /// **'вечірній зріз'**
  String get wellbeingSlotEvening;

  /// No description provided for @howAreYouFeelingLabel.
  ///
  /// In uk, this message translates to:
  /// **'Як ви себе почуваєте?'**
  String get howAreYouFeelingLabel;

  /// No description provided for @anySymptomsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Є симптоми?'**
  String get anySymptomsLabel;

  /// No description provided for @chooseFromListOrAddLabel.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть зі списку поширених або додайте своє'**
  String get chooseFromListOrAddLabel;

  /// No description provided for @symptomsNotSelectedLabel.
  ///
  /// In uk, this message translates to:
  /// **'Симптоми не обрано'**
  String get symptomsNotSelectedLabel;

  /// No description provided for @commentLabel.
  ///
  /// In uk, this message translates to:
  /// **'Коментар'**
  String get commentLabel;

  /// No description provided for @optionalSuffixLabel.
  ///
  /// In uk, this message translates to:
  /// **'· необов\'язково'**
  String get optionalSuffixLabel;

  /// No description provided for @orTypeTextLabel.
  ///
  /// In uk, this message translates to:
  /// **'або введіть текстом'**
  String get orTypeTextLabel;

  /// No description provided for @describeFeelingHint.
  ///
  /// In uk, this message translates to:
  /// **'Опишіть як себе почуваєте…'**
  String get describeFeelingHint;

  /// No description provided for @saveWellbeingCheckAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти зріз'**
  String get saveWellbeingCheckAction;

  /// No description provided for @voiceTranscriptLabel.
  ///
  /// In uk, this message translates to:
  /// **'Розшифровка голосу'**
  String get voiceTranscriptLabel;

  /// No description provided for @editableTextBelowHint.
  ///
  /// In uk, this message translates to:
  /// **'Текст можна редагувати нижче в полі'**
  String get editableTextBelowHint;

  /// No description provided for @recordAgainAction.
  ///
  /// In uk, this message translates to:
  /// **'Записати знову'**
  String get recordAgainAction;

  /// No description provided for @dictateCommentLabel.
  ///
  /// In uk, this message translates to:
  /// **'Надиктуйте коментар'**
  String get dictateCommentLabel;

  /// No description provided for @micUnavailableLabel.
  ///
  /// In uk, this message translates to:
  /// **'Мікрофон недоступний'**
  String get micUnavailableLabel;

  /// No description provided for @tapAndSpeakLabel.
  ///
  /// In uk, this message translates to:
  /// **'Натисніть і говоріть'**
  String get tapAndSpeakLabel;

  /// No description provided for @speakNowLabel.
  ///
  /// In uk, this message translates to:
  /// **'Говоріть… натисніть щоб зупинити'**
  String get speakNowLabel;

  /// No description provided for @preparingMicLabel.
  ///
  /// In uk, this message translates to:
  /// **'Готуємось… зачекайте секунду'**
  String get preparingMicLabel;

  /// No description provided for @symptomHeadache.
  ///
  /// In uk, this message translates to:
  /// **'головний біль'**
  String get symptomHeadache;

  /// No description provided for @symptomNausea.
  ///
  /// In uk, this message translates to:
  /// **'нудота'**
  String get symptomNausea;

  /// No description provided for @symptomDizziness.
  ///
  /// In uk, this message translates to:
  /// **'запаморочення'**
  String get symptomDizziness;

  /// No description provided for @symptomWeakness.
  ///
  /// In uk, this message translates to:
  /// **'слабість'**
  String get symptomWeakness;

  /// No description provided for @symptomShortnessOfBreath.
  ///
  /// In uk, this message translates to:
  /// **'задишка'**
  String get symptomShortnessOfBreath;

  /// No description provided for @symptomRash.
  ///
  /// In uk, this message translates to:
  /// **'висип'**
  String get symptomRash;

  /// No description provided for @symptomPain.
  ///
  /// In uk, this message translates to:
  /// **'біль'**
  String get symptomPain;

  /// No description provided for @symptomFever.
  ///
  /// In uk, this message translates to:
  /// **'температура'**
  String get symptomFever;

  /// No description provided for @symptomCough.
  ///
  /// In uk, this message translates to:
  /// **'кашель'**
  String get symptomCough;

  /// No description provided for @symptomSoreThroat.
  ///
  /// In uk, this message translates to:
  /// **'біль у горлі'**
  String get symptomSoreThroat;

  /// No description provided for @symptomRunnyNose.
  ///
  /// In uk, this message translates to:
  /// **'нежить'**
  String get symptomRunnyNose;

  /// No description provided for @symptomStuffyNose.
  ///
  /// In uk, this message translates to:
  /// **'закладеність носа'**
  String get symptomStuffyNose;

  /// No description provided for @symptomSneezing.
  ///
  /// In uk, this message translates to:
  /// **'чхання'**
  String get symptomSneezing;

  /// No description provided for @symptomVomiting.
  ///
  /// In uk, this message translates to:
  /// **'блювота'**
  String get symptomVomiting;

  /// No description provided for @symptomDiarrhea.
  ///
  /// In uk, this message translates to:
  /// **'діарея'**
  String get symptomDiarrhea;

  /// No description provided for @symptomConstipation.
  ///
  /// In uk, this message translates to:
  /// **'запор'**
  String get symptomConstipation;

  /// No description provided for @symptomBloating.
  ///
  /// In uk, this message translates to:
  /// **'здуття живота'**
  String get symptomBloating;

  /// No description provided for @symptomHeartburn.
  ///
  /// In uk, this message translates to:
  /// **'печія'**
  String get symptomHeartburn;

  /// No description provided for @symptomStomachPain.
  ///
  /// In uk, this message translates to:
  /// **'біль у животі'**
  String get symptomStomachPain;

  /// No description provided for @symptomLossOfAppetite.
  ///
  /// In uk, this message translates to:
  /// **'втрата апетиту'**
  String get symptomLossOfAppetite;

  /// No description provided for @symptomIncreasedAppetite.
  ///
  /// In uk, this message translates to:
  /// **'підвищений апетит'**
  String get symptomIncreasedAppetite;

  /// No description provided for @symptomInsomnia.
  ///
  /// In uk, this message translates to:
  /// **'безсоння'**
  String get symptomInsomnia;

  /// No description provided for @symptomDrowsiness.
  ///
  /// In uk, this message translates to:
  /// **'сонливість'**
  String get symptomDrowsiness;

  /// No description provided for @symptomFatigue.
  ///
  /// In uk, this message translates to:
  /// **'втома'**
  String get symptomFatigue;

  /// No description provided for @symptomChestPain.
  ///
  /// In uk, this message translates to:
  /// **'біль у грудях'**
  String get symptomChestPain;

  /// No description provided for @symptomPalpitations.
  ///
  /// In uk, this message translates to:
  /// **'прискорене серцебиття'**
  String get symptomPalpitations;

  /// No description provided for @symptomHighBloodPressure.
  ///
  /// In uk, this message translates to:
  /// **'підвищений тиск'**
  String get symptomHighBloodPressure;

  /// No description provided for @symptomLowBloodPressure.
  ///
  /// In uk, this message translates to:
  /// **'знижений тиск'**
  String get symptomLowBloodPressure;

  /// No description provided for @symptomBackPain.
  ///
  /// In uk, this message translates to:
  /// **'біль у спині'**
  String get symptomBackPain;

  /// No description provided for @symptomJointPain.
  ///
  /// In uk, this message translates to:
  /// **'біль у суглобах'**
  String get symptomJointPain;

  /// No description provided for @symptomMusclePain.
  ///
  /// In uk, this message translates to:
  /// **'біль у м\'язах'**
  String get symptomMusclePain;

  /// No description provided for @symptomCramps.
  ///
  /// In uk, this message translates to:
  /// **'судоми'**
  String get symptomCramps;

  /// No description provided for @symptomSwelling.
  ///
  /// In uk, this message translates to:
  /// **'набряки'**
  String get symptomSwelling;

  /// No description provided for @symptomItching.
  ///
  /// In uk, this message translates to:
  /// **'свербіж'**
  String get symptomItching;

  /// No description provided for @symptomDrySkin.
  ///
  /// In uk, this message translates to:
  /// **'сухість шкіри'**
  String get symptomDrySkin;

  /// No description provided for @symptomBruising.
  ///
  /// In uk, this message translates to:
  /// **'синці'**
  String get symptomBruising;

  /// No description provided for @symptomDryMouth.
  ///
  /// In uk, this message translates to:
  /// **'сухість у роті'**
  String get symptomDryMouth;

  /// No description provided for @symptomExcessiveSweating.
  ///
  /// In uk, this message translates to:
  /// **'підвищена пітливість'**
  String get symptomExcessiveSweating;

  /// No description provided for @symptomChills.
  ///
  /// In uk, this message translates to:
  /// **'озноб'**
  String get symptomChills;

  /// No description provided for @symptomBlurredVision.
  ///
  /// In uk, this message translates to:
  /// **'розмитий зір'**
  String get symptomBlurredVision;

  /// No description provided for @symptomRingingInEars.
  ///
  /// In uk, this message translates to:
  /// **'дзвін у вухах'**
  String get symptomRingingInEars;

  /// No description provided for @symptomNumbness.
  ///
  /// In uk, this message translates to:
  /// **'оніміння'**
  String get symptomNumbness;

  /// No description provided for @symptomTremor.
  ///
  /// In uk, this message translates to:
  /// **'тремтіння'**
  String get symptomTremor;

  /// No description provided for @symptomMemoryIssues.
  ///
  /// In uk, this message translates to:
  /// **'проблеми з пам\'яттю'**
  String get symptomMemoryIssues;

  /// No description provided for @symptomConcentrationIssues.
  ///
  /// In uk, this message translates to:
  /// **'проблеми з концентрацією'**
  String get symptomConcentrationIssues;

  /// No description provided for @symptomAnxiety.
  ///
  /// In uk, this message translates to:
  /// **'тривожність'**
  String get symptomAnxiety;

  /// No description provided for @symptomIrritability.
  ///
  /// In uk, this message translates to:
  /// **'дратівливість'**
  String get symptomIrritability;

  /// No description provided for @symptomMoodSwings.
  ///
  /// In uk, this message translates to:
  /// **'перепади настрою'**
  String get symptomMoodSwings;

  /// No description provided for @symptomWeightLoss.
  ///
  /// In uk, this message translates to:
  /// **'втрата ваги'**
  String get symptomWeightLoss;

  /// No description provided for @symptomWeightGain.
  ///
  /// In uk, this message translates to:
  /// **'набір ваги'**
  String get symptomWeightGain;

  /// No description provided for @restoreErrorBody.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося відновити: перевірте пароль і з\'єднання, спробуйте ще раз'**
  String get restoreErrorBody;

  /// No description provided for @backupPasswordDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Пароль резервної копії'**
  String get backupPasswordDialogTitle;

  /// No description provided for @backupPasswordDialogBody.
  ///
  /// In uk, this message translates to:
  /// **'Введіть пароль, який ви вказали при створенні резервної копії.'**
  String get backupPasswordDialogBody;

  /// No description provided for @passwordFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Пароль'**
  String get passwordFieldLabel;

  /// No description provided for @restoreAccountTitle.
  ///
  /// In uk, this message translates to:
  /// **'Відновити акаунт'**
  String get restoreAccountTitle;

  /// No description provided for @restoreAccountSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Підключіться до сховища, де зберігається ваша резервна копія'**
  String get restoreAccountSubtitle;

  /// No description provided for @googleDriveLabel.
  ///
  /// In uk, this message translates to:
  /// **'Google Drive'**
  String get googleDriveLabel;

  /// No description provided for @iCloudLabel.
  ///
  /// In uk, this message translates to:
  /// **'iCloud'**
  String get iCloudLabel;

  /// No description provided for @doneExclamationTitle.
  ///
  /// In uk, this message translates to:
  /// **'Готово!'**
  String get doneExclamationTitle;

  /// No description provided for @setupCompleteBody.
  ///
  /// In uk, this message translates to:
  /// **'Все налаштовано. Відкрийте дашборд і почніть стежити за здоров\'ям.'**
  String get setupCompleteBody;

  /// No description provided for @firstReminderTodayLabel.
  ///
  /// In uk, this message translates to:
  /// **'Перше нагадування — сьогодні'**
  String get firstReminderTodayLabel;

  /// No description provided for @noRemindersYetLabel.
  ///
  /// In uk, this message translates to:
  /// **'Нагадувань поки немає'**
  String get noRemindersYetLabel;

  /// No description provided for @reminderWillArriveLabel.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування прийде за розкладом, який ви щойно додали'**
  String get reminderWillArriveLabel;

  /// No description provided for @setupMedsToActivateLabel.
  ///
  /// In uk, this message translates to:
  /// **'Налаштуйте ліки щоб активувати нагадування'**
  String get setupMedsToActivateLabel;

  /// No description provided for @privacyConsentPrefix.
  ///
  /// In uk, this message translates to:
  /// **'Я ознайомлений(-а) і згоден(-а) з '**
  String get privacyConsentPrefix;

  /// No description provided for @privacyConsentSuffix.
  ///
  /// In uk, this message translates to:
  /// **' застосунку'**
  String get privacyConsentSuffix;

  /// No description provided for @openDashboardAction.
  ///
  /// In uk, this message translates to:
  /// **'Відкрити дашборд →'**
  String get openDashboardAction;

  /// No description provided for @joinFailedCheckCodeError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося приєднатись: перевірте код'**
  String get joinFailedCheckCodeError;

  /// No description provided for @connectToFamilyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Підключення до сім\'ї'**
  String get connectToFamilyTitle;

  /// No description provided for @enterAccessCodeHint.
  ///
  /// In uk, this message translates to:
  /// **'Введіть код доступу, який вам надіслали рідні'**
  String get enterAccessCodeHint;

  /// No description provided for @checkingEllipsisLabel.
  ///
  /// In uk, this message translates to:
  /// **'Перевірка...'**
  String get checkingEllipsisLabel;

  /// No description provided for @scheduleAlreadyReadyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Розклад уже готовий'**
  String get scheduleAlreadyReadyTitle;

  /// No description provided for @scheduleSetByInviterBody.
  ///
  /// In uk, this message translates to:
  /// **'{name} уже склав(-ла) для вас розклад прийому ліків. Ви зможете відредагувати його будь-коли після підключення.'**
  String scheduleSetByInviterBody(String name);

  /// No description provided for @agreeUseFamilyScheduleCheckbox.
  ///
  /// In uk, this message translates to:
  /// **'Я погоджуюсь використати розклад, складений моєю сім\'єю'**
  String get agreeUseFamilyScheduleCheckbox;

  /// No description provided for @startAction.
  ///
  /// In uk, this message translates to:
  /// **'Почати'**
  String get startAction;

  /// No description provided for @creatingEllipsisLabel.
  ///
  /// In uk, this message translates to:
  /// **'Створюємо...'**
  String get creatingEllipsisLabel;

  /// No description provided for @declineScheduleCreateOwnAction.
  ///
  /// In uk, this message translates to:
  /// **'Не згоден, створити свій розклад'**
  String get declineScheduleCreateOwnAction;

  /// No description provided for @familyFallbackName.
  ///
  /// In uk, this message translates to:
  /// **'Родина'**
  String get familyFallbackName;

  /// No description provided for @profileFallbackName.
  ///
  /// In uk, this message translates to:
  /// **'Профіль'**
  String get profileFallbackName;

  /// No description provided for @enterYourNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть своє ім\'я'**
  String get enterYourNameError;

  /// No description provided for @walkActivityName.
  ///
  /// In uk, this message translates to:
  /// **'Прогулянка'**
  String get walkActivityName;

  /// No description provided for @onboardingFinishError.
  ///
  /// In uk, this message translates to:
  /// **'Помилка при завершенні: {error}'**
  String onboardingFinishError(String error);

  /// No description provided for @welcomeGreeting.
  ///
  /// In uk, this message translates to:
  /// **'Привіт! 👋'**
  String get welcomeGreeting;

  /// No description provided for @welcomeDescription.
  ///
  /// In uk, this message translates to:
  /// **'Elly допоможе не забути про ліки,\nактивність і самопочуття — для вас\nі всієї родини'**
  String get welcomeDescription;

  /// No description provided for @onboardingStepLabel.
  ///
  /// In uk, this message translates to:
  /// **'Крок {step} з {total}'**
  String onboardingStepLabel(int step, int total);

  /// No description provided for @accountChoiceTitle.
  ///
  /// In uk, this message translates to:
  /// **'Як почнемо?'**
  String get accountChoiceTitle;

  /// No description provided for @accountChoiceSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть варіант, який вам підходить'**
  String get accountChoiceSubtitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In uk, this message translates to:
  /// **'Створити акаунт'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Налаштую ліки та розклад для себе'**
  String get createAccountSubtitle;

  /// No description provided for @joinFamilyChoiceTitle.
  ///
  /// In uk, this message translates to:
  /// **'Підключитися до сім\'ї'**
  String get joinFamilyChoiceTitle;

  /// No description provided for @joinFamilyChoiceSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'У мене є код доступу від рідних'**
  String get joinFamilyChoiceSubtitle;

  /// No description provided for @restoreAccountChoiceSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Я вже користувався(-лась) Elly раніше'**
  String get restoreAccountChoiceSubtitle;

  /// No description provided for @tellAboutYourselfTitle.
  ///
  /// In uk, this message translates to:
  /// **'Розкажіть про себе'**
  String get tellAboutYourselfTitle;

  /// No description provided for @tellAboutYourselfSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть своє ім\'я та оберіть аватар профілю'**
  String get tellAboutYourselfSubtitle;

  /// No description provided for @nextToMedsAction.
  ///
  /// In uk, this message translates to:
  /// **'Далі — ліки →'**
  String get nextToMedsAction;

  /// No description provided for @scanOrEnterManuallyHint.
  ///
  /// In uk, this message translates to:
  /// **'Скануйте фото рецепта або введіть вручну'**
  String get scanOrEnterManuallyHint;

  /// No description provided for @addMedsShortAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати ліки'**
  String get addMedsShortAction;

  /// No description provided for @addMoreMedsAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати ще ліки'**
  String get addMoreMedsAction;

  /// No description provided for @addMedsHint.
  ///
  /// In uk, this message translates to:
  /// **'Скан фото рецепта або назва, доза і розклад вручну'**
  String get addMedsHint;

  /// No description provided for @addMedsLaterInfo.
  ///
  /// In uk, this message translates to:
  /// **'Ліки можна додати пізніше через розділ «Ліки» в головному меню'**
  String get addMedsLaterInfo;

  /// No description provided for @nextAction.
  ///
  /// In uk, this message translates to:
  /// **'Далі →'**
  String get nextAction;

  /// No description provided for @skipAddLaterAction.
  ///
  /// In uk, this message translates to:
  /// **'Пропустити — додам пізніше'**
  String get skipAddLaterAction;

  /// No description provided for @activityWellbeingTitle.
  ///
  /// In uk, this message translates to:
  /// **'Активність та самопочуття'**
  String get activityWellbeingTitle;

  /// No description provided for @activityWellbeingSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Увімкніть одним перемикачем — налаштування можна змінити пізніше'**
  String get activityWellbeingSubtitle;

  /// No description provided for @activitySectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Активність'**
  String get activitySectionLabel;

  /// No description provided for @walkActivitySub.
  ///
  /// In uk, this message translates to:
  /// **'30 хв · щодня · 08:30'**
  String get walkActivitySub;

  /// No description provided for @wellbeingDiaryLabel.
  ///
  /// In uk, this message translates to:
  /// **'Щоденник самопочуття'**
  String get wellbeingDiaryLabel;

  /// No description provided for @wellbeingDiaryDescription.
  ///
  /// In uk, this message translates to:
  /// **'Короткі відмітки самопочуття допоможуть побачити звʼязок між прийомом ліків і тим, як ви почуваєтесь'**
  String get wellbeingDiaryDescription;

  /// No description provided for @wellbeingSlotsTitle.
  ///
  /// In uk, this message translates to:
  /// **'Зрізи самопочуття'**
  String get wellbeingSlotsTitle;

  /// No description provided for @wellbeingSlotsSub.
  ///
  /// In uk, this message translates to:
  /// **'2–3 рази на день · 08:00, 14:00, 20:00'**
  String get wellbeingSlotsSub;

  /// No description provided for @almostDoneAction.
  ///
  /// In uk, this message translates to:
  /// **'Майже готово →'**
  String get almostDoneAction;

  /// No description provided for @scanNoResultsError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося розпізнати ліки на фото. Спробуйте зробити чіткіше фото.'**
  String get scanNoResultsError;

  /// No description provided for @scanErrorWithMessage.
  ///
  /// In uk, this message translates to:
  /// **'Помилка сканування: {error}'**
  String scanErrorWithMessage(String error);

  /// No description provided for @scanPrescriptionScreenTitle.
  ///
  /// In uk, this message translates to:
  /// **'Сканувати рецепт'**
  String get scanPrescriptionScreenTitle;

  /// No description provided for @beforeYouStartTitle.
  ///
  /// In uk, this message translates to:
  /// **'Перш ніж почати'**
  String get beforeYouStartTitle;

  /// No description provided for @scanConsentDisclaimerBody.
  ///
  /// In uk, this message translates to:
  /// **'Щоб розпізнати ліки, фото рецепта чи упаковки надсилається сервісу Anthropic (Claude). Фото використовується лише для розпізнавання і ніде не зберігається після відповіді.'**
  String get scanConsentDisclaimerBody;

  /// No description provided for @scanDosageWarningPrefix.
  ///
  /// In uk, this message translates to:
  /// **'⚠️ Дозування, розклад і довідкова інформація про побічні ефекти — орієнтовні. '**
  String get scanDosageWarningPrefix;

  /// No description provided for @alwaysCheckInstructionsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Завжди звіряйте з інструкцією до препарату.'**
  String get alwaysCheckInstructionsLabel;

  /// No description provided for @understoodAgreeAction.
  ///
  /// In uk, this message translates to:
  /// **'Зрозуміло, погоджуюсь'**
  String get understoodAgreeAction;

  /// No description provided for @takePhotoInstructionsBody.
  ///
  /// In uk, this message translates to:
  /// **'Сфотографуйте рецепт або упаковку. Можна додати кілька фото, якщо ліків декілька.'**
  String get takePhotoInstructionsBody;

  /// No description provided for @cameraLabel.
  ///
  /// In uk, this message translates to:
  /// **'Камера'**
  String get cameraLabel;

  /// No description provided for @galleryLabel.
  ///
  /// In uk, this message translates to:
  /// **'Галерея'**
  String get galleryLabel;

  /// No description provided for @scanAction.
  ///
  /// In uk, this message translates to:
  /// **'Сканувати'**
  String get scanAction;

  /// No description provided for @scanRecognizedCountLabel.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнано {count}. Перевірте перед додаванням:'**
  String scanRecognizedCountLabel(int count);

  /// No description provided for @expandAndConfirmHint.
  ///
  /// In uk, this message translates to:
  /// **'Розгорніть препарат, перевірте дані і поставте галочку, щоб підтвердити додавання.'**
  String get expandAndConfirmHint;

  /// No description provided for @chooseMedsAction.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть препарати'**
  String get chooseMedsAction;

  /// No description provided for @addSelectedCountAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати обрані ({count})'**
  String addSelectedCountAction(int count);

  /// No description provided for @scheduleTimeMorning.
  ///
  /// In uk, this message translates to:
  /// **'Вранці'**
  String get scheduleTimeMorning;

  /// No description provided for @scheduleTimeAfternoon.
  ///
  /// In uk, this message translates to:
  /// **'Вдень'**
  String get scheduleTimeAfternoon;

  /// No description provided for @scheduleTimeEvening.
  ///
  /// In uk, this message translates to:
  /// **'Ввечері'**
  String get scheduleTimeEvening;

  /// No description provided for @scheduleTimeNight.
  ///
  /// In uk, this message translates to:
  /// **'Вночі'**
  String get scheduleTimeNight;

  /// No description provided for @unnamedMedLabel.
  ///
  /// In uk, this message translates to:
  /// **'Без назви'**
  String get unnamedMedLabel;

  /// No description provided for @medNameCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'НАЗВА'**
  String get medNameCapsLabel;

  /// No description provided for @releaseFormCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ФОРМА ВИПУСКУ'**
  String get releaseFormCapsLabel;

  /// No description provided for @doseCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ДОЗА'**
  String get doseCapsLabel;

  /// No description provided for @courseDurationCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ТРИВАЛІСТЬ КУРСУ'**
  String get courseDurationCapsLabel;

  /// No description provided for @foodRelationCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЗВ\'ЯЗОК З ЇЖЕЮ'**
  String get foodRelationCapsLabel;

  /// No description provided for @possibleSideEffectsPrefix.
  ///
  /// In uk, this message translates to:
  /// **'⚡ Можливі побічні ефекти: {list}. '**
  String possibleSideEffectsPrefix(String list);

  /// No description provided for @checkInstructionsShortLabel.
  ///
  /// In uk, this message translates to:
  /// **'Звірте з інструкцією до препарату.'**
  String get checkInstructionsShortLabel;

  /// No description provided for @confirmedCheckLabel.
  ///
  /// In uk, this message translates to:
  /// **'Підтверджено ✓'**
  String get confirmedCheckLabel;

  /// No description provided for @confirmAllCorrectAction.
  ///
  /// In uk, this message translates to:
  /// **'Все вірно, підтвердити'**
  String get confirmAllCorrectAction;

  /// No description provided for @somethingWentWrongTitle.
  ///
  /// In uk, this message translates to:
  /// **'Щось пішло не так'**
  String get somethingWentWrongTitle;

  /// No description provided for @sttErrorLabel.
  ///
  /// In uk, this message translates to:
  /// **'STT помилка: {error}'**
  String sttErrorLabel(String error);

  /// No description provided for @speechNotAvailableError.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнавання мови недоступне на цьому пристрої'**
  String get speechNotAvailableError;

  /// No description provided for @nothingHeardError.
  ///
  /// In uk, this message translates to:
  /// **'Нічого не почуто. Спробуй ще раз.'**
  String get nothingHeardError;

  /// No description provided for @analysisErrorWithMessage.
  ///
  /// In uk, this message translates to:
  /// **'Помилка аналізу: {error}'**
  String analysisErrorWithMessage(String error);

  /// No description provided for @commandNotRecognizedError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося розпізнати команду'**
  String get commandNotRecognizedError;

  /// No description provided for @voiceControlTitle.
  ///
  /// In uk, this message translates to:
  /// **'Голосове управління'**
  String get voiceControlTitle;

  /// No description provided for @voiceConsentDisclaimerBody.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнавання голосу відбувається на пристрої. Але щоб зрозуміти команду, текст твоєї фрази надсилається сервісу Anthropic (Claude). Ця функція розпізнає лише 3 команди: додати ліки, додати активність або запис до лікаря — вільний опис самопочуття чи симптомів сюди ніколи не відправляється, для цього є окреме поле в щоденнику самопочуття, яке лишається тільки на пристрої.'**
  String get voiceConsentDisclaimerBody;

  /// No description provided for @voiceExampleMedQuote.
  ///
  /// In uk, this message translates to:
  /// **'\"Додай Еналаприл 10 мг вранці та ввечері\"'**
  String get voiceExampleMedQuote;

  /// No description provided for @voiceExampleMedDesc.
  ///
  /// In uk, this message translates to:
  /// **'Відкриє форму ліків із заповненими полями. Розпізнає не всі препарати — перевірте поля перед збереженням.'**
  String get voiceExampleMedDesc;

  /// No description provided for @voiceExampleActivityQuote.
  ///
  /// In uk, this message translates to:
  /// **'\"Додай зарядку двічі на день вранці і ввечері\"'**
  String get voiceExampleActivityQuote;

  /// No description provided for @voiceExampleActivityDesc.
  ///
  /// In uk, this message translates to:
  /// **'Відкриє форму активності із заповненими полями'**
  String get voiceExampleActivityDesc;

  /// No description provided for @voiceExampleApptQuote.
  ///
  /// In uk, this message translates to:
  /// **'\"Запис до кардіолога у пʼятницю о 10\"'**
  String get voiceExampleApptQuote;

  /// No description provided for @voiceExampleApptDesc.
  ///
  /// In uk, this message translates to:
  /// **'Відкриє форму запису до лікаря'**
  String get voiceExampleApptDesc;

  /// No description provided for @whatToDoTitle.
  ///
  /// In uk, this message translates to:
  /// **'Що хочеш зробити?'**
  String get whatToDoTitle;

  /// No description provided for @tapAndSayCommandHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисни і скажи команду\nабо почни говорити'**
  String get tapAndSayCommandHint;

  /// No description provided for @dictateLanguageHint.
  ///
  /// In uk, this message translates to:
  /// **'Диктуйте мовою {language}. Змінити можна в Профіль → Мова.'**
  String dictateLanguageHint(String language);

  /// No description provided for @commandExamplesCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ПРИКЛАДИ КОМАНД'**
  String get commandExamplesCapsLabel;

  /// No description provided for @experimentalFeatureNotice.
  ///
  /// In uk, this message translates to:
  /// **'Це експериментальна функція — розпізнавання може заповнити дані неточно, завжди перевіряйте форму перед збереженням.'**
  String get experimentalFeatureNotice;

  /// No description provided for @holdAndSpeakAction.
  ///
  /// In uk, this message translates to:
  /// **'Утримуй і говори'**
  String get holdAndSpeakAction;

  /// No description provided for @listeningEllipsisLabel.
  ///
  /// In uk, this message translates to:
  /// **'Слухаю...'**
  String get listeningEllipsisLabel;

  /// No description provided for @preparingEllipsisLabel.
  ///
  /// In uk, this message translates to:
  /// **'Готуємось...'**
  String get preparingEllipsisLabel;

  /// No description provided for @tapMicToStopHint.
  ///
  /// In uk, this message translates to:
  /// **'Натисни на мікрофон щоб зупинити'**
  String get tapMicToStopHint;

  /// No description provided for @waitBeforeSpeakingHint.
  ///
  /// In uk, this message translates to:
  /// **'Зачекайте секунду перед тим, як говорити'**
  String get waitBeforeSpeakingHint;

  /// No description provided for @quotedTextLabel.
  ///
  /// In uk, this message translates to:
  /// **'\"{text}\"'**
  String quotedTextLabel(String text);

  /// No description provided for @analyzingCommandLabel.
  ///
  /// In uk, this message translates to:
  /// **'Аналізую команду...'**
  String get analyzingCommandLabel;

  /// No description provided for @actionCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ДІЯ'**
  String get actionCapsLabel;

  /// No description provided for @drugCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ПРЕПАРАТ'**
  String get drugCapsLabel;

  /// No description provided for @activityCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'АКТИВНІСТЬ'**
  String get activityCapsLabel;

  /// No description provided for @scheduleCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'РОЗКЛАД'**
  String get scheduleCapsLabel;

  /// No description provided for @doctorCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЛІКАР'**
  String get doctorCapsLabel;

  /// No description provided for @addActivityActionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Додати активність'**
  String get addActivityActionLabel;

  /// No description provided for @unknownCommandLabel.
  ///
  /// In uk, this message translates to:
  /// **'Невідома команда'**
  String get unknownCommandLabel;

  /// No description provided for @youSaidCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ТИ СКАЗАВ'**
  String get youSaidCapsLabel;

  /// No description provided for @iUnderstoodLabel.
  ///
  /// In uk, this message translates to:
  /// **'Я зрозумів так:'**
  String get iUnderstoodLabel;

  /// No description provided for @clarifyOneMoreLabel.
  ///
  /// In uk, this message translates to:
  /// **'Уточни ще одне'**
  String get clarifyOneMoreLabel;

  /// No description provided for @foodRelationClarifyHint.
  ///
  /// In uk, this message translates to:
  /// **'Ти не сказав, до чи після їжі. Вибери нижче або пропусти'**
  String get foodRelationClarifyHint;

  /// No description provided for @foodOptBefore.
  ///
  /// In uk, this message translates to:
  /// **'До їжі'**
  String get foodOptBefore;

  /// No description provided for @foodOptAfter.
  ///
  /// In uk, this message translates to:
  /// **'Після їжі'**
  String get foodOptAfter;

  /// No description provided for @foodOptNotImportant.
  ///
  /// In uk, this message translates to:
  /// **'Не важливо'**
  String get foodOptNotImportant;

  /// No description provided for @refFoodAnyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Незалежно від їжі'**
  String get refFoodAnyLabel;

  /// No description provided for @possibleSideEffectsLabel.
  ///
  /// In uk, this message translates to:
  /// **'⚡ Можливі побічні ефекти: {list}'**
  String possibleSideEffectsLabel(String list);

  /// No description provided for @referenceInfoDisclaimer.
  ///
  /// In uk, this message translates to:
  /// **'⚠️ Довідково, не гарантовано. Звірте з інструкцією до препарату.'**
  String get referenceInfoDisclaimer;

  /// No description provided for @nextShortAction.
  ///
  /// In uk, this message translates to:
  /// **'Далі'**
  String get nextShortAction;

  /// No description provided for @backupScreenTitle.
  ///
  /// In uk, this message translates to:
  /// **'Резервна копія'**
  String get backupScreenTitle;

  /// No description provided for @backupIntroBody.
  ///
  /// In uk, this message translates to:
  /// **'Ліки, розклад, медкартка (фото/PDF) і всі інші дані — обирайте, де зберігати резервну копію.'**
  String get backupIntroBody;

  /// No description provided for @backupModeLocalTitle.
  ///
  /// In uk, this message translates to:
  /// **'Тільки на пристрої'**
  String get backupModeLocalTitle;

  /// No description provided for @backupModeLocalSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'При перевстановленні застосунку всі дані буде втрачено'**
  String get backupModeLocalSubtitle;

  /// No description provided for @backupModeGoogleDriveSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Зашифровано на пристрої — Elly і Google не бачать ваші дані'**
  String get backupModeGoogleDriveSubtitle;

  /// No description provided for @backupModeICloudSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Зашифровано на пристрої — Elly і Apple не бачать ваші дані'**
  String get backupModeICloudSubtitle;

  /// No description provided for @backupFrequencyCapsLabel.
  ///
  /// In uk, this message translates to:
  /// **'ЧАСТОТА АВТОБЕКАПУ'**
  String get backupFrequencyCapsLabel;

  /// No description provided for @backupFrequencyDailyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Раз на день'**
  String get backupFrequencyDailyLabel;

  /// No description provided for @backupFrequencyWeeklyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Раз на тиждень'**
  String get backupFrequencyWeeklyLabel;

  /// No description provided for @backupFrequencyExplainerBody.
  ///
  /// In uk, this message translates to:
  /// **'Спрацьовує, коли ви відкриваєте застосунок чи повертаєтесь у нього — це не справжній фоновий розклад. Якщо не відкривати Elly довше обраної частоти, бекап зробиться одразу при наступному відкритті.'**
  String get backupFrequencyExplainerBody;

  /// No description provided for @backupNeverDoneLabel.
  ///
  /// In uk, this message translates to:
  /// **'Резервної копії ще не було'**
  String get backupNeverDoneLabel;

  /// No description provided for @lastBackupAtLabel.
  ///
  /// In uk, this message translates to:
  /// **'Останній бекап: {date}'**
  String lastBackupAtLabel(String date);

  /// No description provided for @createBackupNowAction.
  ///
  /// In uk, this message translates to:
  /// **'Створити резервну копію зараз'**
  String get createBackupNowAction;

  /// No description provided for @restoreFromBackupAction.
  ///
  /// In uk, this message translates to:
  /// **'Відновити з резервної копії'**
  String get restoreFromBackupAction;

  /// No description provided for @changeBackupPassphraseAction.
  ///
  /// In uk, this message translates to:
  /// **'Змінити пароль резервної копії'**
  String get changeBackupPassphraseAction;

  /// No description provided for @backupPassphraseDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Пароль для резервної копії'**
  String get backupPassphraseDialogTitle;

  /// No description provided for @backupPassphraseDialogSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Придумайте пароль. Без нього відновити дані буде неможливо — навіть нам.'**
  String get backupPassphraseDialogSubtitle;

  /// No description provided for @backupSavedSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Резервну копію збережено у {target}'**
  String backupSavedSnackbar(String target);

  /// No description provided for @restorePassphraseDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Пароль резервної копії'**
  String get restorePassphraseDialogTitle;

  /// No description provided for @restorePassphraseDialogSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Введіть пароль, який ви вказали при створенні копії.'**
  String get restorePassphraseDialogSubtitle;

  /// No description provided for @restoreDoneBody.
  ///
  /// In uk, this message translates to:
  /// **'Дані відновлено.'**
  String get restoreDoneBody;

  /// No description provided for @restoreFailedError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося відновити: невірний пароль або копія відсутня'**
  String get restoreFailedError;

  /// No description provided for @changePassphraseDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Новий пароль резервної копії'**
  String get changePassphraseDialogTitle;

  /// No description provided for @changePassphraseDialogSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Одразу після зміни буде створено нову резервну копію з цим паролем — запам\'ятайте його, стару резервну копію під старим паролем більше не можна буде використати.'**
  String get changePassphraseDialogSubtitle;

  /// No description provided for @passphraseChangedSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Пароль змінено, нову резервну копію збережено'**
  String get passphraseChangedSnackbar;

  /// No description provided for @confirmRestoreTitle.
  ///
  /// In uk, this message translates to:
  /// **'Відновити з резервної копії?'**
  String get confirmRestoreTitle;

  /// No description provided for @confirmRestoreBody.
  ///
  /// In uk, this message translates to:
  /// **'Поточні дані на цьому пристрої буде замінено даними з резервної копії. Цю дію не можна скасувати.'**
  String get confirmRestoreBody;

  /// No description provided for @restoreAction.
  ///
  /// In uk, this message translates to:
  /// **'Відновити'**
  String get restoreAction;

  /// No description provided for @confirmPasswordFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Повторіть пароль'**
  String get confirmPasswordFieldLabel;

  /// No description provided for @passwordTooShortError.
  ///
  /// In uk, this message translates to:
  /// **'Пароль має бути не коротшим за 6 символів'**
  String get passwordTooShortError;

  /// No description provided for @passwordsMismatchError.
  ///
  /// In uk, this message translates to:
  /// **'Паролі не збігаються'**
  String get passwordsMismatchError;

  /// No description provided for @gotItAction.
  ///
  /// In uk, this message translates to:
  /// **'Гаразд'**
  String get gotItAction;

  /// No description provided for @choosePlanTitle.
  ///
  /// In uk, this message translates to:
  /// **'Обери план'**
  String get choosePlanTitle;

  /// No description provided for @choosePlanSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Турбота про здоров\'я всієї сім\'ї'**
  String get choosePlanSubtitle;

  /// No description provided for @monthToggleLabel.
  ///
  /// In uk, this message translates to:
  /// **'Місяць'**
  String get monthToggleLabel;

  /// No description provided for @yearToggleDiscountLabel.
  ///
  /// In uk, this message translates to:
  /// **'Рік −20%'**
  String get yearToggleDiscountLabel;

  /// No description provided for @familyTiesBrokenTitle.
  ///
  /// In uk, this message translates to:
  /// **'Зв\'язки з родиною розірвуться'**
  String get familyTiesBrokenTitle;

  /// No description provided for @familyTiesBrokenBody.
  ///
  /// In uk, this message translates to:
  /// **'Учасники вашої сімейної групи одразу втратять доступ до плюшок Family і перестануть бачити одне одного. Це станеться миттєво, без грейс-періоду — ви вже попереджені зараз.'**
  String get familyTiesBrokenBody;

  /// No description provided for @breakAndChangePlanAction.
  ///
  /// In uk, this message translates to:
  /// **'Розірвати і змінити план'**
  String get breakAndChangePlanAction;

  /// No description provided for @planActivatedTestSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'{plan} активовано (тестовий режим, без реальної оплати)'**
  String planActivatedTestSnackbar(String plan);

  /// No description provided for @actionFailedError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося: {error}'**
  String actionFailedError(String error);

  /// No description provided for @planForeverPeriod.
  ///
  /// In uk, this message translates to:
  /// **'назавжди'**
  String get planForeverPeriod;

  /// No description provided for @planPerMonthYearlyPeriod.
  ///
  /// In uk, this message translates to:
  /// **'на місяць (рік)'**
  String get planPerMonthYearlyPeriod;

  /// No description provided for @planPerMonthPeriod.
  ///
  /// In uk, this message translates to:
  /// **'щомісяця'**
  String get planPerMonthPeriod;

  /// No description provided for @freeFeatureAllSections.
  ///
  /// In uk, this message translates to:
  /// **'Всі розділи без обмежень'**
  String get freeFeatureAllSections;

  /// No description provided for @freeFeatureUnlimitedMeds.
  ///
  /// In uk, this message translates to:
  /// **'Необмежено ліків і медкарток'**
  String get freeFeatureUnlimitedMeds;

  /// No description provided for @freeFeatureScanLimit.
  ///
  /// In uk, this message translates to:
  /// **'3 сканування фото рецепта'**
  String get freeFeatureScanLimit;

  /// No description provided for @freeFeatureVoiceLimit.
  ///
  /// In uk, this message translates to:
  /// **'5 голосових команд'**
  String get freeFeatureVoiceLimit;

  /// No description provided for @freeFeatureLocalBackup.
  ///
  /// In uk, this message translates to:
  /// **'Локально + копія в Google Drive/iCloud'**
  String get freeFeatureLocalBackup;

  /// No description provided for @selectFreeAction.
  ///
  /// In uk, this message translates to:
  /// **'Обрати Безкоштовний'**
  String get selectFreeAction;

  /// No description provided for @plusFeatureAllFree.
  ///
  /// In uk, this message translates to:
  /// **'Все з безкоштовного'**
  String get plusFeatureAllFree;

  /// No description provided for @plusFeatureUnlimitedScans.
  ///
  /// In uk, this message translates to:
  /// **'Необмежені сканування фото'**
  String get plusFeatureUnlimitedScans;

  /// No description provided for @plusFeatureUnlimitedVoice.
  ///
  /// In uk, this message translates to:
  /// **'Необмежені голосові команди'**
  String get plusFeatureUnlimitedVoice;

  /// No description provided for @plusFeatureServerSync.
  ///
  /// In uk, this message translates to:
  /// **'Синхронізація з сервером (зашифровано)'**
  String get plusFeatureServerSync;

  /// No description provided for @plusFeatureUnlimitedProfiles.
  ///
  /// In uk, this message translates to:
  /// **'Необмежена кількість локальних профілів'**
  String get plusFeatureUnlimitedProfiles;

  /// No description provided for @selectPlusAction.
  ///
  /// In uk, this message translates to:
  /// **'Обрати Plus'**
  String get selectPlusAction;

  /// No description provided for @familyFeatureAllPlus.
  ///
  /// In uk, this message translates to:
  /// **'Все з Elly Plus'**
  String get familyFeatureAllPlus;

  /// No description provided for @familyFeatureAutonomousProfiles.
  ///
  /// In uk, this message translates to:
  /// **'Автономні профілі — до 8 осіб'**
  String get familyFeatureAutonomousProfiles;

  /// No description provided for @familyFeatureSelfManaged.
  ///
  /// In uk, this message translates to:
  /// **'Кожен керує своїм профілем сам'**
  String get familyFeatureSelfManaged;

  /// No description provided for @selectFamilyAction.
  ///
  /// In uk, this message translates to:
  /// **'Обрати Family'**
  String get selectFamilyAction;

  /// No description provided for @billingTermsDisclaimer.
  ///
  /// In uk, this message translates to:
  /// **'Оплата списується з вашого облікового запису App Store чи Google Play. Підписка автоматично продовжується на новий період за тією самою ціною, якщо не скасувати щонайменше за 24 години до завершення періоду. Керувати підпискою та скасувати автопродовження можна в налаштуваннях облікового запису App Store · Google Play.'**
  String get billingTermsDisclaimer;

  /// No description provided for @privacyPolicyLinkLabel.
  ///
  /// In uk, this message translates to:
  /// **'Політика конфіденційності'**
  String get privacyPolicyLinkLabel;

  /// No description provided for @termsOfUseLinkLabel.
  ///
  /// In uk, this message translates to:
  /// **'Умови використання'**
  String get termsOfUseLinkLabel;

  /// No description provided for @currentPlanLabel.
  ///
  /// In uk, this message translates to:
  /// **'Поточний'**
  String get currentPlanLabel;

  /// No description provided for @tooManyProfilesForPlanTitle.
  ///
  /// In uk, this message translates to:
  /// **'Забагато профілів для цього плану'**
  String get tooManyProfilesForPlanTitle;

  /// No description provided for @upgradeToEditSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Продовжіть Elly Plus або Elly Family, щоб редагувати'**
  String get upgradeToEditSubtitle;

  /// No description provided for @viewPlansAction.
  ///
  /// In uk, this message translates to:
  /// **'Переглянути тарифи'**
  String get viewPlansAction;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалось списати оплату'**
  String get paymentFailedTitle;

  /// No description provided for @gracePeriodRemainingBody.
  ///
  /// In uk, this message translates to:
  /// **'Залишилось {timeLeft}, щоб оновити спосіб оплати — доки що все працює без обмежень, і для вас, і для всіх учасників вашої сімейної групи.'**
  String gracePeriodRemainingBody(String timeLeft);

  /// No description provided for @gracePeriodExpiredBody.
  ///
  /// In uk, this message translates to:
  /// **'Оновіть спосіб оплати негайно, інакше сімейна група розірветься.'**
  String get gracePeriodExpiredBody;

  /// No description provided for @laterAction.
  ///
  /// In uk, this message translates to:
  /// **'Пізніше'**
  String get laterAction;

  /// No description provided for @updatePaymentAction.
  ///
  /// In uk, this message translates to:
  /// **'Оновити оплату'**
  String get updatePaymentAction;

  /// No description provided for @accessChangedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Доступ змінився'**
  String get accessChangedTitle;

  /// No description provided for @changePlanAction.
  ///
  /// In uk, this message translates to:
  /// **'Змінити план'**
  String get changePlanAction;

  /// No description provided for @daysLeftLabel.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} день} few{{count} дні} other{{count} днів}}'**
  String daysLeftLabel(int count);

  /// No description provided for @hoursLeftLabel.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} годину} few{{count} години} other{{count} годин}}'**
  String hoursLeftLabel(int count);

  /// No description provided for @minutesLeftLabel.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} хвилину} few{{count} хвилини} other{{count} хвилин}}'**
  String minutesLeftLabel(int count);

  /// No description provided for @planFreeShortLabel.
  ///
  /// In uk, this message translates to:
  /// **'Безкоштовний'**
  String get planFreeShortLabel;

  /// No description provided for @exportShareSubject.
  ///
  /// In uk, this message translates to:
  /// **'Elly — експорт даних'**
  String get exportShareSubject;

  /// No description provided for @exportCopyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Копія всіх ваших даних'**
  String get exportCopyTitle;

  /// No description provided for @exportDescriptionBody.
  ///
  /// In uk, this message translates to:
  /// **'Файл у форматі JSON з усіма профілями, ліками, розкладом, прийомами, самопочуттям і записами до лікарів — усе, що зберігається на цьому пристрої. Ви можете відкрити його будь-де або передати кому завгодно.\n\nФото ліків у файл не входять (вони вже є у «Резервній копії») — лише текстові дані.'**
  String get exportDescriptionBody;

  /// No description provided for @exportAction.
  ///
  /// In uk, this message translates to:
  /// **'Експортувати'**
  String get exportAction;

  /// No description provided for @appLockedTitle.
  ///
  /// In uk, this message translates to:
  /// **'Elly заблоковано'**
  String get appLockedTitle;

  /// No description provided for @authFailedRetryBody.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося підтвердити особу — спробуйте ще раз'**
  String get authFailedRetryBody;

  /// No description provided for @confirmIdentityBody.
  ///
  /// In uk, this message translates to:
  /// **'Підтвердіть особу, щоб продовжити'**
  String get confirmIdentityBody;

  /// No description provided for @checkingDotsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Перевірка...'**
  String get checkingDotsLabel;

  /// No description provided for @unlockAction.
  ///
  /// In uk, this message translates to:
  /// **'Розблокувати'**
  String get unlockAction;

  /// No description provided for @addTypeSheetTitle.
  ///
  /// In uk, this message translates to:
  /// **'Що хочете додати?'**
  String get addTypeSheetTitle;

  /// No description provided for @addTypeSheetSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть тип — форма підлаштується'**
  String get addTypeSheetSubtitle;

  /// No description provided for @addTypeMedsSub.
  ///
  /// In uk, this message translates to:
  /// **'Розклад, дозування, AI-скан рецепта'**
  String get addTypeMedsSub;

  /// No description provided for @addTypeActivitySub.
  ///
  /// In uk, this message translates to:
  /// **'Прогулянка, зарядка, вправи, ЛФК'**
  String get addTypeActivitySub;

  /// No description provided for @addTypeWellbeingSub.
  ///
  /// In uk, this message translates to:
  /// **'Зробити зріз — настрій, симптоми, коментар'**
  String get addTypeWellbeingSub;

  /// No description provided for @addTypeAppointmentSub.
  ///
  /// In uk, this message translates to:
  /// **'Обрати спеціаліста, час та отримати нагадування'**
  String get addTypeAppointmentSub;

  /// No description provided for @voiceCommandLabel.
  ///
  /// In uk, this message translates to:
  /// **'Голосова команда'**
  String get voiceCommandLabel;

  /// No description provided for @faqGroupPrivacyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Приватність і дані'**
  String get faqGroupPrivacyTitle;

  /// No description provided for @faqPrivacyQ1.
  ///
  /// In uk, this message translates to:
  /// **'Хто бачить мої дані?'**
  String get faqPrivacyQ1;

  /// No description provided for @faqPrivacyA1.
  ///
  /// In uk, this message translates to:
  /// **'Ніхто, крім вас. Усе зберігається зашифрованим на вашому пристрої (SQLCipher, AES-256). Сервер Elly навмисно \"сліпий\": реєстрації через email чи пароль немає, а те, що все ж проходить через сервер (запрошення до сім\'ї, синхронізація, підтвердження підписки), бачить лише зашифровані блоки й технічні ідентифікатори — без ключа розшифрувати їх неможливо.'**
  String get faqPrivacyA1;

  /// No description provided for @faqPrivacyQ2.
  ///
  /// In uk, this message translates to:
  /// **'У чому різниця між Резервною копією і Запрошенням до сім\'ї?'**
  String get faqPrivacyQ2;

  /// No description provided for @faqPrivacyA2.
  ///
  /// In uk, this message translates to:
  /// **'Резервна копія — знімок ваших власних даних у вашому Google Drive/iCloud на випадок втрати телефону чи перевстановлення застосунку. Запрошення до сім\'ї — живий обмін розкладом між РІЗНИМИ людьми (наприклад, дитина бачить розклад мами) через QR-код чи код запрошення. Це два різні механізми: перший — про вас самих, другий — про спільний доступ між кількома людьми.'**
  String get faqPrivacyA2;

  /// No description provided for @faqPrivacyQ3.
  ///
  /// In uk, this message translates to:
  /// **'Що буде, якщо я видалю застосунок без бекапу?'**
  String get faqPrivacyQ3;

  /// No description provided for @faqPrivacyA3.
  ///
  /// In uk, this message translates to:
  /// **'Дані буде втрачено безповоротно — копії на сервері не існує. Обов\'язково зробіть резервну копію заздалегідь (Профіль → Резервна копія).'**
  String get faqPrivacyA3;

  /// No description provided for @faqPrivacyQ4.
  ///
  /// In uk, this message translates to:
  /// **'Як видалити свої дані повністю?'**
  String get faqPrivacyQ4;

  /// No description provided for @faqPrivacyA4.
  ///
  /// In uk, this message translates to:
  /// **'Видаліть застосунок з пристрою (і резервну копію з Drive/iCloud вручну, якщо створювали). Профіль також можна видалити окремо — Профіль → Конфіденційність → Небезпечна зона.'**
  String get faqPrivacyA4;

  /// No description provided for @faqGroupFamilyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Сім\'я'**
  String get faqGroupFamilyTitle;

  /// No description provided for @faqFamilyQ1.
  ///
  /// In uk, this message translates to:
  /// **'Як додати члена сім\'ї чи залежний профіль?'**
  String get faqFamilyQ1;

  /// No description provided for @faqFamilyA1.
  ///
  /// In uk, this message translates to:
  /// **'На вкладці \"Сім\'я\" — кнопка додавання профілю. Залежні профілі (діти, батьки похилого віку) не мають власного входу — ними керує власник пристрою.'**
  String get faqFamilyA1;

  /// No description provided for @faqFamilyQ2.
  ///
  /// In uk, this message translates to:
  /// **'Як передати керування профілем іншій людині (наприклад, дорослій дитині)?'**
  String get faqFamilyQ2;

  /// No description provided for @faqFamilyA2.
  ///
  /// In uk, this message translates to:
  /// **'На картці локального профілю — кнопка \"Запросити в застосунок\": покажіть QR-код чи назвіть код запрошення людині, яка приєднується на своєму пристрої. Профіль перетвориться з локального на автономний — людина відтепер керуватиме ним сама, а вся історія даних збережеться. Дані шифруються ключем, похідним від коду запрошення, — сервер бачить лише зашифрований блок.'**
  String get faqFamilyA2;

  /// No description provided for @faqFamilyQ3.
  ///
  /// In uk, this message translates to:
  /// **'Хто що бачить про інших членів сім\'ї?'**
  String get faqFamilyQ3;

  /// No description provided for @faqFamilyA3.
  ///
  /// In uk, this message translates to:
  /// **'Налаштовується в Профіль → Видимість для сім\'ї — окремо для кожного профілю.'**
  String get faqFamilyA3;

  /// No description provided for @faqGroupAiTitle.
  ///
  /// In uk, this message translates to:
  /// **'AI-функції'**
  String get faqGroupAiTitle;

  /// No description provided for @faqAiQ1.
  ///
  /// In uk, this message translates to:
  /// **'Куди йдуть дані при голосовому вводі чи скані рецепта?'**
  String get faqAiQ1;

  /// No description provided for @faqAiA1.
  ///
  /// In uk, this message translates to:
  /// **'Розпізнавання відбувається через модель Claude від Anthropic — це явно вказується в запиті згоди перед першим використанням кожної функції. Вільний текстовий опис самопочуття чи симптомів у хмару ніколи не надсилається.'**
  String get faqAiA1;

  /// No description provided for @faqAiQ2.
  ///
  /// In uk, this message translates to:
  /// **'Наскільки точна довідкова інформація про ліки від AI?'**
  String get faqAiQ2;

  /// No description provided for @faqAiA2.
  ///
  /// In uk, this message translates to:
  /// **'Це орієнтовна інформація із загальних знань моделі, а не перевірений медичний каталог. Завжди звіряйте з інструкцією до препарату чи лікарем.'**
  String get faqAiA2;

  /// No description provided for @faqNotificationsQ1.
  ///
  /// In uk, this message translates to:
  /// **'Чому не приходять нагадування?'**
  String get faqNotificationsQ1;

  /// No description provided for @faqNotificationsA1.
  ///
  /// In uk, this message translates to:
  /// **'Найчастіша причина — оптимізація батареї на Android обмежує фонову роботу застосунку. Додайте Elly у виключення в налаштуваннях енергозбереження пристрою. Також перевірте \"Тихі години\" в Профіль → Сповіщення.'**
  String get faqNotificationsA1;

  /// No description provided for @faqNotificationsQ2.
  ///
  /// In uk, this message translates to:
  /// **'Як налаштувати повторне нагадування, якщо не відмітив прийом?'**
  String get faqNotificationsQ2;

  /// No description provided for @faqNotificationsA2.
  ///
  /// In uk, this message translates to:
  /// **'Профіль → Сповіщення → \"Повторити якщо нема відповіді\" — виберіть інтервал повзунком.'**
  String get faqNotificationsA2;

  /// No description provided for @faqPlansQ1.
  ///
  /// In uk, this message translates to:
  /// **'Чим відрізняються тарифи?'**
  String get faqPlansQ1;

  /// No description provided for @faqPlansA1.
  ///
  /// In uk, this message translates to:
  /// **'Elly (безкоштовний) — базові функції з обмеженнями. Elly Plus і Elly Family знімають ліміти й додають розширені можливості. Деталі — Профіль → Тарифи.'**
  String get faqPlansA1;

  /// No description provided for @faqGroupTechTitle.
  ///
  /// In uk, this message translates to:
  /// **'Технічні проблеми'**
  String get faqGroupTechTitle;

  /// No description provided for @faqTechQ1.
  ///
  /// In uk, this message translates to:
  /// **'Не працює біометрія / забув пароль від резервної копії'**
  String get faqTechQ1;

  /// No description provided for @faqTechA1.
  ///
  /// In uk, this message translates to:
  /// **'Пароль резервної копії запам\'ятовується лише локально на цьому пристрої (щоб автоматичні копії за розкладом не питали його щоразу) — на наші сервери він ніколи не потрапляє. Якщо ви перевстановите застосунок чи зміните пристрій, доведеться ввести той самий пароль вручну; якщо забули його — відновити копію неможливо, доведеться створити нову. Біометрію можна переналаштувати в системних налаштуваннях пристрою.'**
  String get faqTechA1;

  /// No description provided for @faqTechQ2.
  ///
  /// In uk, this message translates to:
  /// **'Не вдається відновити дані з резервної копії'**
  String get faqTechQ2;

  /// No description provided for @faqTechA2.
  ///
  /// In uk, this message translates to:
  /// **'Найчастіша причина — невірний пароль (той самий, який ви вказали при створенні копії) або відсутнє з\'єднання з інтернетом. Перевірте, що відновлюєте копію на відповідному типі пристрою (з iCloud — лише на iOS, з Google Drive — на Android чи iOS). Після успішного відновлення застосунок попросить перезапуститись.'**
  String get faqTechA2;

  /// No description provided for @faqNotFoundQuestionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Не знайшли відповідь?'**
  String get faqNotFoundQuestionTitle;

  /// No description provided for @faqWriteUsSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Напишіть нам — відповімо особисто.'**
  String get faqWriteUsSubtitle;

  /// No description provided for @supportLabel.
  ///
  /// In uk, this message translates to:
  /// **'Підтримка'**
  String get supportLabel;

  /// No description provided for @supportChatLabel.
  ///
  /// In uk, this message translates to:
  /// **'Чат підтримки'**
  String get supportChatLabel;

  /// No description provided for @soonLabel.
  ///
  /// In uk, this message translates to:
  /// **'Скоро'**
  String get soonLabel;

  /// No description provided for @notificationsMainSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Основні'**
  String get notificationsMainSectionTitle;

  /// No description provided for @pushNotificationsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Push-сповіщення'**
  String get pushNotificationsLabel;

  /// No description provided for @pushNotificationsSub.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування про прийом ліків'**
  String get pushNotificationsSub;

  /// No description provided for @vibrationLabel.
  ///
  /// In uk, this message translates to:
  /// **'Вібрація'**
  String get vibrationLabel;

  /// No description provided for @vibrationSub.
  ///
  /// In uk, this message translates to:
  /// **'Разом зі звуком'**
  String get vibrationSub;

  /// No description provided for @reminderTimeSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Час нагадувань'**
  String get reminderTimeSectionTitle;

  /// No description provided for @quietHoursSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Тихі години'**
  String get quietHoursSectionTitle;

  /// No description provided for @doNotDisturbLabel.
  ///
  /// In uk, this message translates to:
  /// **'Не турбувати'**
  String get doNotDisturbLabel;

  /// No description provided for @nightModeSub.
  ///
  /// In uk, this message translates to:
  /// **'Нічний режим'**
  String get nightModeSub;

  /// No description provided for @quietFromLabel.
  ///
  /// In uk, this message translates to:
  /// **'З'**
  String get quietFromLabel;

  /// No description provided for @quietToLabel.
  ///
  /// In uk, this message translates to:
  /// **'До'**
  String get quietToLabel;

  /// No description provided for @memberMissedAlertsSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Алерти при пропуску членів сімʼї'**
  String get memberMissedAlertsSectionTitle;

  /// No description provided for @familyNotificationsSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Сповіщення від сім\'ї'**
  String get familyNotificationsSectionTitle;

  /// No description provided for @peerNotifyExplainerBody.
  ///
  /// In uk, this message translates to:
  /// **'Ці учасники дозволили надсилати вам сповіщення про себе. Тут ви вирішуєте, чи хочете їх отримувати.'**
  String get peerNotifyExplainerBody;

  /// No description provided for @reminderOffsetLabel.
  ///
  /// In uk, this message translates to:
  /// **'Зсув нагадування'**
  String get reminderOffsetLabel;

  /// No description provided for @reminderOffsetSub.
  ///
  /// In uk, this message translates to:
  /// **'Отримувати за N хв до прийому'**
  String get reminderOffsetSub;

  /// No description provided for @noOffsetLabel.
  ///
  /// In uk, this message translates to:
  /// **'без зсуву'**
  String get noOffsetLabel;

  /// No description provided for @minusMinutesLabel.
  ///
  /// In uk, this message translates to:
  /// **'−{minutes} хв'**
  String minusMinutesLabel(int minutes);

  /// No description provided for @repeatIfNoResponseLabel.
  ///
  /// In uk, this message translates to:
  /// **'Повторити якщо нема відповіді'**
  String get repeatIfNoResponseLabel;

  /// No description provided for @repeatInLabel.
  ///
  /// In uk, this message translates to:
  /// **'Через {label}'**
  String repeatInLabel(String label);

  /// No description provided for @deleteActivityConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити активність?'**
  String get deleteActivityConfirmTitle;

  /// No description provided for @deleteActivityConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Активність буде вилучена з розкладу.'**
  String get deleteActivityConfirmBody;

  /// No description provided for @chooseActivityTypeError.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть тип активності'**
  String get chooseActivityTypeError;

  /// No description provided for @enterActivityNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву активності'**
  String get enterActivityNameError;

  /// No description provided for @editActivityTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати активність'**
  String get editActivityTitle;

  /// No description provided for @activityTypeLabel.
  ///
  /// In uk, this message translates to:
  /// **'Тип активності'**
  String get activityTypeLabel;

  /// No description provided for @activityTypeWorkout.
  ///
  /// In uk, this message translates to:
  /// **'Зарядка'**
  String get activityTypeWorkout;

  /// No description provided for @activityTypeGym.
  ///
  /// In uk, this message translates to:
  /// **'Тренування'**
  String get activityTypeGym;

  /// No description provided for @activityTypeYoga.
  ///
  /// In uk, this message translates to:
  /// **'Йога / ЛФК'**
  String get activityTypeYoga;

  /// No description provided for @activityTypeCycling.
  ///
  /// In uk, this message translates to:
  /// **'Велосипед'**
  String get activityTypeCycling;

  /// No description provided for @activityTypeCustom.
  ///
  /// In uk, this message translates to:
  /// **'Своє'**
  String get activityTypeCustom;

  /// No description provided for @activityNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Назва активності'**
  String get activityNameHint;

  /// No description provided for @youtubeLinkLabel.
  ///
  /// In uk, this message translates to:
  /// **'Посилання на YouTube'**
  String get youtubeLinkLabel;

  /// No description provided for @youtubeLinkDescription.
  ///
  /// In uk, this message translates to:
  /// **'Відео тренування чи клип — прев\'ю показуватиметься у картці на сьогодні'**
  String get youtubeLinkDescription;

  /// No description provided for @addAnotherActivityAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати ще заняття'**
  String get addAnotherActivityAction;

  /// No description provided for @weekdaysLabel.
  ///
  /// In uk, this message translates to:
  /// **'Дні тижня'**
  String get weekdaysLabel;

  /// No description provided for @reminderLabel.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування'**
  String get reminderLabel;

  /// No description provided for @reminderActivityDescription.
  ///
  /// In uk, this message translates to:
  /// **'За 10 хвилин до кожного заняття'**
  String get reminderActivityDescription;

  /// No description provided for @saveActivityAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти активність'**
  String get saveActivityAction;

  /// No description provided for @activitySessionNumberLabel.
  ///
  /// In uk, this message translates to:
  /// **'Заняття {number}'**
  String activitySessionNumberLabel(int number);

  /// No description provided for @noDurationLabel.
  ///
  /// In uk, this message translates to:
  /// **'Без тривалості'**
  String get noDurationLabel;

  /// No description provided for @saveWithDurationLabel.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти · {duration}'**
  String saveWithDurationLabel(String duration);

  /// No description provided for @durationHoursMinutesLabel.
  ///
  /// In uk, this message translates to:
  /// **'{hours} год {minutes} хв'**
  String durationHoursMinutesLabel(int hours, int minutes);

  /// No description provided for @minutesWithValueLabel.
  ///
  /// In uk, this message translates to:
  /// **'{value} хв'**
  String minutesWithValueLabel(String value);

  /// No description provided for @taskColorPickerLabel.
  ///
  /// In uk, this message translates to:
  /// **'КОЛІР КАРТКИ'**
  String get taskColorPickerLabel;

  /// No description provided for @viewingProfileLabel.
  ///
  /// In uk, this message translates to:
  /// **'Ви дивитесь профіль: {name}'**
  String viewingProfileLabel(String name);

  /// No description provided for @returnAction.
  ///
  /// In uk, this message translates to:
  /// **'Повернутись'**
  String get returnAction;

  /// No description provided for @foodRelationUnspecified.
  ///
  /// In uk, this message translates to:
  /// **'Не вибрано'**
  String get foodRelationUnspecified;

  /// No description provided for @foodRelationWith.
  ///
  /// In uk, this message translates to:
  /// **'Під час їжі'**
  String get foodRelationWith;

  /// No description provided for @foodRelationPickerTitle.
  ///
  /// In uk, this message translates to:
  /// **'Відносно їжі'**
  String get foodRelationPickerTitle;

  /// No description provided for @recoveryKeyDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ваш recovery key'**
  String get recoveryKeyDialogTitle;

  /// No description provided for @recoveryKeyDialogBody.
  ///
  /// In uk, this message translates to:
  /// **'Збережіть цей код у надійному місці. Це єдиний спосіб відновити дані на новому пристрої — без нього ми теж не зможемо допомогти.'**
  String get recoveryKeyDialogBody;

  /// No description provided for @copiedSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Скопійовано'**
  String get copiedSnackbar;

  /// No description provided for @recoveryKeySavedConfirmAction.
  ///
  /// In uk, this message translates to:
  /// **'Я зберіг(ла) код'**
  String get recoveryKeySavedConfirmAction;

  /// No description provided for @buyAction.
  ///
  /// In uk, this message translates to:
  /// **'Купити'**
  String get buyAction;

  /// No description provided for @affiliateDisclaimerLabel.
  ///
  /// In uk, this message translates to:
  /// **'Реклама · партнерське посилання, Elly товар не продає'**
  String get affiliateDisclaimerLabel;

  /// No description provided for @legalPageLoadError.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося завантажити сторінку. Перевірте з\'єднання з інтернетом.'**
  String get legalPageLoadError;

  /// No description provided for @medFormTablet.
  ///
  /// In uk, this message translates to:
  /// **'Таблетка'**
  String get medFormTablet;

  /// No description provided for @medFormCapsule.
  ///
  /// In uk, this message translates to:
  /// **'Капсула'**
  String get medFormCapsule;

  /// No description provided for @medFormSuppository.
  ///
  /// In uk, this message translates to:
  /// **'Свічі'**
  String get medFormSuppository;

  /// No description provided for @medFormVial.
  ///
  /// In uk, this message translates to:
  /// **'Флакон'**
  String get medFormVial;

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
  /// **'Крем'**
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

  /// No description provided for @medUnitTablet.
  ///
  /// In uk, this message translates to:
  /// **'табл.'**
  String get medUnitTablet;

  /// No description provided for @medUnitCapsule.
  ///
  /// In uk, this message translates to:
  /// **'капс.'**
  String get medUnitCapsule;

  /// No description provided for @medUnitMl.
  ///
  /// In uk, this message translates to:
  /// **'мл'**
  String get medUnitMl;

  /// No description provided for @medUnitDrops.
  ///
  /// In uk, this message translates to:
  /// **'крап.'**
  String get medUnitDrops;

  /// No description provided for @medUnitGram.
  ///
  /// In uk, this message translates to:
  /// **'г'**
  String get medUnitGram;

  /// No description provided for @medUnitInhale.
  ///
  /// In uk, this message translates to:
  /// **'вдих'**
  String get medUnitInhale;

  /// No description provided for @medUnitSuppository.
  ///
  /// In uk, this message translates to:
  /// **'свіча'**
  String get medUnitSuppository;

  /// No description provided for @medUnitVial.
  ///
  /// In uk, this message translates to:
  /// **'фл.'**
  String get medUnitVial;

  /// No description provided for @medUnitPiece.
  ///
  /// In uk, this message translates to:
  /// **'шт.'**
  String get medUnitPiece;

  /// No description provided for @chooseProfileLabel.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть профіль'**
  String get chooseProfileLabel;

  /// No description provided for @otherSpecialtyDialogTitle.
  ///
  /// In uk, this message translates to:
  /// **'Інший напрямок'**
  String get otherSpecialtyDialogTitle;

  /// No description provided for @otherSpecialtyHint.
  ///
  /// In uk, this message translates to:
  /// **'Напр. Гомеопат'**
  String get otherSpecialtyHint;

  /// No description provided for @chooseAction.
  ///
  /// In uk, this message translates to:
  /// **'Обрати'**
  String get chooseAction;

  /// No description provided for @doctorSpecialtyPickerTitle.
  ///
  /// In uk, this message translates to:
  /// **'Напрямок лікаря'**
  String get doctorSpecialtyPickerTitle;

  /// No description provided for @specialtySearchHint.
  ///
  /// In uk, this message translates to:
  /// **'Пошук…'**
  String get specialtySearchHint;

  /// No description provided for @specialtyTherapist.
  ///
  /// In uk, this message translates to:
  /// **'Терапевт'**
  String get specialtyTherapist;

  /// No description provided for @specialtyPediatrician.
  ///
  /// In uk, this message translates to:
  /// **'Педіатр'**
  String get specialtyPediatrician;

  /// No description provided for @specialtyFamilyDoctor.
  ///
  /// In uk, this message translates to:
  /// **'Сімейний лікар'**
  String get specialtyFamilyDoctor;

  /// No description provided for @specialtyCardiologist.
  ///
  /// In uk, this message translates to:
  /// **'Кардіолог'**
  String get specialtyCardiologist;

  /// No description provided for @specialtyNeurologist.
  ///
  /// In uk, this message translates to:
  /// **'Невролог'**
  String get specialtyNeurologist;

  /// No description provided for @specialtyEndocrinologist.
  ///
  /// In uk, this message translates to:
  /// **'Ендокринолог'**
  String get specialtyEndocrinologist;

  /// No description provided for @specialtyGastroenterologist.
  ///
  /// In uk, this message translates to:
  /// **'Гастроентеролог'**
  String get specialtyGastroenterologist;

  /// No description provided for @specialtyDermatologist.
  ///
  /// In uk, this message translates to:
  /// **'Дерматолог'**
  String get specialtyDermatologist;

  /// No description provided for @specialtyOphthalmologist.
  ///
  /// In uk, this message translates to:
  /// **'Офтальмолог'**
  String get specialtyOphthalmologist;

  /// No description provided for @specialtyEnt.
  ///
  /// In uk, this message translates to:
  /// **'ЛОР (Отоларинголог)'**
  String get specialtyEnt;

  /// No description provided for @specialtyDentist.
  ///
  /// In uk, this message translates to:
  /// **'Стоматолог'**
  String get specialtyDentist;

  /// No description provided for @specialtyGynecologist.
  ///
  /// In uk, this message translates to:
  /// **'Гінеколог'**
  String get specialtyGynecologist;

  /// No description provided for @specialtyUrologist.
  ///
  /// In uk, this message translates to:
  /// **'Уролог'**
  String get specialtyUrologist;

  /// No description provided for @specialtySurgeon.
  ///
  /// In uk, this message translates to:
  /// **'Хірург'**
  String get specialtySurgeon;

  /// No description provided for @specialtyOrthopedist.
  ///
  /// In uk, this message translates to:
  /// **'Ортопед'**
  String get specialtyOrthopedist;

  /// No description provided for @specialtyTraumatologist.
  ///
  /// In uk, this message translates to:
  /// **'Травматолог'**
  String get specialtyTraumatologist;

  /// No description provided for @specialtyAllergist.
  ///
  /// In uk, this message translates to:
  /// **'Алерголог'**
  String get specialtyAllergist;

  /// No description provided for @specialtyImmunologist.
  ///
  /// In uk, this message translates to:
  /// **'Імунолог'**
  String get specialtyImmunologist;

  /// No description provided for @specialtyPsychiatrist.
  ///
  /// In uk, this message translates to:
  /// **'Психіатр'**
  String get specialtyPsychiatrist;

  /// No description provided for @specialtyPsychotherapist.
  ///
  /// In uk, this message translates to:
  /// **'Психотерапевт'**
  String get specialtyPsychotherapist;

  /// No description provided for @specialtyUltrasoundDiagnostics.
  ///
  /// In uk, this message translates to:
  /// **'УЗД-діагностика'**
  String get specialtyUltrasoundDiagnostics;

  /// No description provided for @specialtyOncologist.
  ///
  /// In uk, this message translates to:
  /// **'Онколог'**
  String get specialtyOncologist;

  /// No description provided for @specialtyRheumatologist.
  ///
  /// In uk, this message translates to:
  /// **'Ревматолог'**
  String get specialtyRheumatologist;

  /// No description provided for @specialtyPulmonologist.
  ///
  /// In uk, this message translates to:
  /// **'Пульмонолог'**
  String get specialtyPulmonologist;

  /// No description provided for @specialtyNephrologist.
  ///
  /// In uk, this message translates to:
  /// **'Нефролог'**
  String get specialtyNephrologist;

  /// No description provided for @specialtyPhlebologist.
  ///
  /// In uk, this message translates to:
  /// **'Флеболог'**
  String get specialtyPhlebologist;

  /// No description provided for @specialtyMammologist.
  ///
  /// In uk, this message translates to:
  /// **'Мамолог'**
  String get specialtyMammologist;

  /// No description provided for @specialtyOther.
  ///
  /// In uk, this message translates to:
  /// **'Інше'**
  String get specialtyOther;

  /// No description provided for @noDocumentsLabel.
  ///
  /// In uk, this message translates to:
  /// **'Немає документів'**
  String get noDocumentsLabel;

  /// No description provided for @addPhotoOrPdfLabel.
  ///
  /// In uk, this message translates to:
  /// **'Додати фото чи PDF'**
  String get addPhotoOrPdfLabel;

  /// No description provided for @labTestCbc.
  ///
  /// In uk, this message translates to:
  /// **'Загальний аналіз крові'**
  String get labTestCbc;

  /// No description provided for @labTestUrinalysis.
  ///
  /// In uk, this message translates to:
  /// **'Загальний аналіз сечі'**
  String get labTestUrinalysis;

  /// No description provided for @labTestBloodChemistry.
  ///
  /// In uk, this message translates to:
  /// **'Біохімічний аналіз крові'**
  String get labTestBloodChemistry;

  /// No description provided for @labTestBloodGlucose.
  ///
  /// In uk, this message translates to:
  /// **'Глюкоза крові'**
  String get labTestBloodGlucose;

  /// No description provided for @labTestLipidProfile.
  ///
  /// In uk, this message translates to:
  /// **'Ліпідний профіль (холестерин)'**
  String get labTestLipidProfile;

  /// No description provided for @labTestTsh.
  ///
  /// In uk, this message translates to:
  /// **'Гормони щитоподібної залози (ТТГ)'**
  String get labTestTsh;

  /// No description provided for @labTestFreeT3.
  ///
  /// In uk, this message translates to:
  /// **'Т3 вільний'**
  String get labTestFreeT3;

  /// No description provided for @labTestFreeT4.
  ///
  /// In uk, this message translates to:
  /// **'Т4 вільний'**
  String get labTestFreeT4;

  /// No description provided for @labTestLiverEnzymes.
  ///
  /// In uk, this message translates to:
  /// **'Печінкові проби (АЛТ, АСТ)'**
  String get labTestLiverEnzymes;

  /// No description provided for @labTestBilirubin.
  ///
  /// In uk, this message translates to:
  /// **'Білірубін'**
  String get labTestBilirubin;

  /// No description provided for @labTestCreatinine.
  ///
  /// In uk, this message translates to:
  /// **'Креатинін'**
  String get labTestCreatinine;

  /// No description provided for @labTestUrea.
  ///
  /// In uk, this message translates to:
  /// **'Сечовина'**
  String get labTestUrea;

  /// No description provided for @labTestUricAcid.
  ///
  /// In uk, this message translates to:
  /// **'Сечова кислота'**
  String get labTestUricAcid;

  /// No description provided for @labTestSerumIron.
  ///
  /// In uk, this message translates to:
  /// **'Залізо сироватки'**
  String get labTestSerumIron;

  /// No description provided for @labTestFerritin.
  ///
  /// In uk, this message translates to:
  /// **'Феритин'**
  String get labTestFerritin;

  /// No description provided for @labTestVitaminD.
  ///
  /// In uk, this message translates to:
  /// **'Вітамін D'**
  String get labTestVitaminD;

  /// No description provided for @labTestVitaminB12.
  ///
  /// In uk, this message translates to:
  /// **'Вітамін B12'**
  String get labTestVitaminB12;

  /// No description provided for @labTestFolicAcid.
  ///
  /// In uk, this message translates to:
  /// **'Фолієва кислота'**
  String get labTestFolicAcid;

  /// No description provided for @labTestCoagulogram.
  ///
  /// In uk, this message translates to:
  /// **'Коагулограма'**
  String get labTestCoagulogram;

  /// No description provided for @labTestBloodType.
  ///
  /// In uk, this message translates to:
  /// **'Група крові та резус-фактор'**
  String get labTestBloodType;

  /// No description provided for @labTestCrp.
  ///
  /// In uk, this message translates to:
  /// **'С-реактивний білок (СРБ)'**
  String get labTestCrp;

  /// No description provided for @labTestEsr.
  ///
  /// In uk, this message translates to:
  /// **'Швидкість осідання еритроцитів (ШОЕ)'**
  String get labTestEsr;

  /// No description provided for @labTestEstrogenProgesterone.
  ///
  /// In uk, this message translates to:
  /// **'Естроген, прогестерон'**
  String get labTestEstrogenProgesterone;

  /// No description provided for @labTestTestosterone.
  ///
  /// In uk, this message translates to:
  /// **'Тестостерон'**
  String get labTestTestosterone;

  /// No description provided for @labTestProlactin.
  ///
  /// In uk, this message translates to:
  /// **'Пролактин'**
  String get labTestProlactin;

  /// No description provided for @labTestInsulin.
  ///
  /// In uk, this message translates to:
  /// **'Інсулін'**
  String get labTestInsulin;

  /// No description provided for @labTestHba1c.
  ///
  /// In uk, this message translates to:
  /// **'Глікований гемоглобін (HbA1c)'**
  String get labTestHba1c;

  /// No description provided for @labTestPcr.
  ///
  /// In uk, this message translates to:
  /// **'ПЛР-тест'**
  String get labTestPcr;

  /// No description provided for @labTestAllergens.
  ///
  /// In uk, this message translates to:
  /// **'Аналіз на алергени'**
  String get labTestAllergens;

  /// No description provided for @labTestCoprogram.
  ///
  /// In uk, this message translates to:
  /// **'Копрограма'**
  String get labTestCoprogram;

  /// No description provided for @labTestOccultBlood.
  ///
  /// In uk, this message translates to:
  /// **'Аналіз калу на приховану кров'**
  String get labTestOccultBlood;

  /// No description provided for @labTestFloraSwab.
  ///
  /// In uk, this message translates to:
  /// **'Мазок на флору'**
  String get labTestFloraSwab;

  /// No description provided for @labTestUrineCulture.
  ///
  /// In uk, this message translates to:
  /// **'Посів сечі на стерильність'**
  String get labTestUrineCulture;

  /// No description provided for @labTestHepatitis.
  ///
  /// In uk, this message translates to:
  /// **'Аналіз на гепатити (B, C)'**
  String get labTestHepatitis;

  /// No description provided for @labTestHiv.
  ///
  /// In uk, this message translates to:
  /// **'ВІЛ-тест'**
  String get labTestHiv;

  /// No description provided for @labTestSyphilis.
  ///
  /// In uk, this message translates to:
  /// **'RW (сифіліс)'**
  String get labTestSyphilis;

  /// No description provided for @labTestCalcium.
  ///
  /// In uk, this message translates to:
  /// **'Кальцій'**
  String get labTestCalcium;

  /// No description provided for @labTestMagnesium.
  ///
  /// In uk, this message translates to:
  /// **'Магній'**
  String get labTestMagnesium;

  /// No description provided for @labTestElectrolytesKNaCl.
  ///
  /// In uk, this message translates to:
  /// **'Калій, натрій, хлор'**
  String get labTestElectrolytesKNaCl;

  /// No description provided for @labTestAmylase.
  ///
  /// In uk, this message translates to:
  /// **'Амілаза'**
  String get labTestAmylase;

  /// No description provided for @labTestLipase.
  ///
  /// In uk, this message translates to:
  /// **'Ліпаза'**
  String get labTestLipase;

  /// No description provided for @labTestPsa.
  ///
  /// In uk, this message translates to:
  /// **'ПСА (простатоспецифічний антиген)'**
  String get labTestPsa;

  /// No description provided for @labTestTumorMarkers.
  ///
  /// In uk, this message translates to:
  /// **'Онкомаркери (СА-125)'**
  String get labTestTumorMarkers;

  /// No description provided for @labTestParasites.
  ///
  /// In uk, this message translates to:
  /// **'Аналіз на паразитів (яйця гельмінтів)'**
  String get labTestParasites;

  /// No description provided for @labTestCortisol.
  ///
  /// In uk, this message translates to:
  /// **'Кортизол'**
  String get labTestCortisol;

  /// No description provided for @labTestImmunogram.
  ///
  /// In uk, this message translates to:
  /// **'Імунограма'**
  String get labTestImmunogram;

  /// No description provided for @labTestSpermogram.
  ///
  /// In uk, this message translates to:
  /// **'Спермограма'**
  String get labTestSpermogram;

  /// No description provided for @labTestBloodElectrolytes.
  ///
  /// In uk, this message translates to:
  /// **'Електроліти крові'**
  String get labTestBloodElectrolytes;

  /// No description provided for @labTestTotalProtein.
  ///
  /// In uk, this message translates to:
  /// **'Загальний білок'**
  String get labTestTotalProtein;

  /// No description provided for @labTestDDimer.
  ///
  /// In uk, this message translates to:
  /// **'Д-димер'**
  String get labTestDDimer;

  /// No description provided for @notifChannelName.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування Elly'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування про ліки, активності, візити та самопочуття'**
  String get notifChannelDesc;

  /// No description provided for @notifTakeMedTitle.
  ///
  /// In uk, this message translates to:
  /// **'💊 Час прийняти ліки'**
  String get notifTakeMedTitle;

  /// No description provided for @notifIntakeNoResponseTitle.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Ви ще не відмітили прийом'**
  String get notifIntakeNoResponseTitle;

  /// No description provided for @notifBackupReminderTitle.
  ///
  /// In uk, this message translates to:
  /// **'Захистіть свої дані'**
  String get notifBackupReminderTitle;

  /// No description provided for @notifBackupReminderBody.
  ///
  /// In uk, this message translates to:
  /// **'Резервна копія вимкнена — дані зберігаються лише на цьому пристрої. Увімкніть у Профілі, щоб не втратити їх.'**
  String get notifBackupReminderBody;

  /// No description provided for @notifLowStockTitle.
  ///
  /// In uk, this message translates to:
  /// **'⚠️ Закінчуються ліки'**
  String get notifLowStockTitle;

  /// No description provided for @notifLowStockBody.
  ///
  /// In uk, this message translates to:
  /// **'{medName} — залишилось {remaining} {unit}'**
  String notifLowStockBody(String medName, int remaining, String unit);

  /// No description provided for @notifActivityTitle.
  ///
  /// In uk, this message translates to:
  /// **'🚶 Час для активності'**
  String get notifActivityTitle;

  /// No description provided for @notifActivityNoResponseTitle.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Ви ще не відмітили активність'**
  String get notifActivityNoResponseTitle;

  /// No description provided for @notifAppointmentTitle.
  ///
  /// In uk, this message translates to:
  /// **'🩺 Прийом лікаря'**
  String get notifAppointmentTitle;

  /// No description provided for @notifAppointmentNoResponseTitle.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Не забудьте про прийом лікаря'**
  String get notifAppointmentNoResponseTitle;

  /// No description provided for @notifWellbeingTitle.
  ///
  /// In uk, this message translates to:
  /// **'💜 Зріз самопочуття'**
  String get notifWellbeingTitle;

  /// No description provided for @notifWellbeingBody.
  ///
  /// In uk, this message translates to:
  /// **'Як ви себе почуваєте?'**
  String get notifWellbeingBody;

  /// No description provided for @notifVaccinationTitle.
  ///
  /// In uk, this message translates to:
  /// **'💉 Час ревакцинації'**
  String get notifVaccinationTitle;

  /// No description provided for @notifPeerCheckTitle.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Перевірте {subjectName}'**
  String notifPeerCheckTitle(String subjectName);

  /// No description provided for @notifPeerIntakeCheckBody.
  ///
  /// In uk, this message translates to:
  /// **'Чи прийнято \"{medName}\" ({dose}) о {timeStr}? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.'**
  String notifPeerIntakeCheckBody(String medName, String dose, String timeStr);

  /// No description provided for @notifPeerActivityCheckBody.
  ///
  /// In uk, this message translates to:
  /// **'Чи виконано \"{activityName}\" о {timeStr}? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.'**
  String notifPeerActivityCheckBody(String activityName, String timeStr);

  /// No description provided for @notifPeerAppointmentCheckBody.
  ///
  /// In uk, this message translates to:
  /// **'Чи відбувся прийом (\"{doctorType}\") о {timeStr}? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.'**
  String notifPeerAppointmentCheckBody(String doctorType, String timeStr);

  /// No description provided for @notifPeerWellbeingCheckBody.
  ///
  /// In uk, this message translates to:
  /// **'Чи зроблено зріз самопочуття о {timeStr}? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.'**
  String notifPeerWellbeingCheckBody(String timeStr);

  /// No description provided for @forMemberSuffix.
  ///
  /// In uk, this message translates to:
  /// **' для {name}'**
  String forMemberSuffix(String name);

  /// No description provided for @dbLoadErrorTitle.
  ///
  /// In uk, this message translates to:
  /// **'Потрібно перезапустити Elly'**
  String get dbLoadErrorTitle;

  /// No description provided for @dbLoadErrorBody.
  ///
  /// In uk, this message translates to:
  /// **'Закрийте застосунок повністю — проведіть пальцем вгору з нижнього краю екрана й змахніть картку Elly — а тоді відкрийте знову. Ваші дані нікуди не зникли, за кілька секунд усе повернеться на місце.'**
  String get dbLoadErrorBody;

  /// No description provided for @unlockPhoneTitle.
  ///
  /// In uk, this message translates to:
  /// **'Розблокуйте телефон'**
  String get unlockPhoneTitle;

  /// No description provided for @unlockPhoneBody.
  ///
  /// In uk, this message translates to:
  /// **'Ваші дані в безпеці — нічого не пошкоджено і видаляти нічого не потрібно. Просто iOS тримає ключ шифрування заблокованим, поки телефон не розблоковано хоча б раз після перезавантаження.'**
  String get unlockPhoneBody;

  /// No description provided for @unlockStep1.
  ///
  /// In uk, this message translates to:
  /// **'Розблокуйте телефон (Face ID, Touch ID або код-пароль).'**
  String get unlockStep1;

  /// No description provided for @unlockStep2.
  ///
  /// In uk, this message translates to:
  /// **'Поверніться в Elly — дані підвантажаться самі, нічого натискати не треба.'**
  String get unlockStep2;

  /// No description provided for @checkAgainAction.
  ///
  /// In uk, this message translates to:
  /// **'Перевірити знову'**
  String get checkAgainAction;

  /// No description provided for @loadingEllipsisLabel.
  ///
  /// In uk, this message translates to:
  /// **'Завантажую...'**
  String get loadingEllipsisLabel;

  /// No description provided for @familyDisbandedReason.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалось поновити оплату Family вчасно, тож сімейна група розірвана. Ваші локальні дані нікуди не поділись.'**
  String get familyDisbandedReason;

  /// No description provided for @manageSubscriptionExternallyHint.
  ///
  /// In uk, this message translates to:
  /// **'Керування підпискою відкрито в App Store/Google Play — завершіть скасування там.'**
  String get manageSubscriptionExternallyHint;

  /// No description provided for @restorePurchasesAction.
  ///
  /// In uk, this message translates to:
  /// **'Відновити покупки'**
  String get restorePurchasesAction;

  /// No description provided for @restorePurchasesSuccessSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Покупки відновлено'**
  String get restorePurchasesSuccessSnackbar;

  /// No description provided for @restorePurchasesNothingFoundSnackbar.
  ///
  /// In uk, this message translates to:
  /// **'Активних покупок не знайдено на цьому Apple ID/Google-акаунті'**
  String get restorePurchasesNothingFoundSnackbar;

  /// No description provided for @todayScheduleForMedLabel.
  ///
  /// In uk, this message translates to:
  /// **'Розклад на сьогодні'**
  String get todayScheduleForMedLabel;

  /// No description provided for @intakeSnoozed.
  ///
  /// In uk, this message translates to:
  /// **'Перенесено'**
  String get intakeSnoozed;

  /// No description provided for @resetLocalDbConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Скинути локальну базу даних?'**
  String get resetLocalDbConfirmTitle;

  /// No description provided for @resetLocalDbConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Це видалить усі дані на цьому пристрої (ліки, розклад, медкартку). Резервної копії не знайдено — відновити дані після цього буде неможливо.'**
  String get resetLocalDbConfirmBody;

  /// No description provided for @resetAction.
  ///
  /// In uk, this message translates to:
  /// **'Скинути'**
  String get resetAction;

  /// No description provided for @resetLocalDbAction.
  ///
  /// In uk, this message translates to:
  /// **'Скинути локальну БД'**
  String get resetLocalDbAction;

  /// No description provided for @petAvatarsSectionLabel.
  ///
  /// In uk, this message translates to:
  /// **'Домашні улюбленці'**
  String get petAvatarsSectionLabel;
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
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
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
