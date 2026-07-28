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
  /// **'Архів'**
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
  /// **'Оцініть настрій і, за бажанням, додайте нотатку'**
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
  /// **'Нагадування'**
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
  /// **'Нагадування'**
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

  /// No description provided for @noSimpleTasksHint.
  ///
  /// In uk, this message translates to:
  /// **'Немає простих завдань'**
  String get noSimpleTasksHint;

  /// No description provided for @noRoutineTasksHint.
  ///
  /// In uk, this message translates to:
  /// **'Немає рутинних справ'**
  String get noRoutineTasksHint;

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

  /// No description provided for @allTagsFilter.
  ///
  /// In uk, this message translates to:
  /// **'Усі теги'**
  String get allTagsFilter;

  /// No description provided for @medCardTitle.
  ///
  /// In uk, this message translates to:
  /// **'Архів'**
  String get medCardTitle;

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
  /// **'Нагадування'**
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
  /// **'Настрій за весь час'**
  String get medCardWellbeingHistorySubtitle;

  /// No description provided for @customSectionsHeader.
  ///
  /// In uk, this message translates to:
  /// **'Ваші розділи'**
  String get customSectionsHeader;

  /// No description provided for @addSectionAction.
  ///
  /// In uk, this message translates to:
  /// **'Додати розділ'**
  String get addSectionAction;

  /// No description provided for @newSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Новий розділ'**
  String get newSectionTitle;

  /// No description provided for @editSectionTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати розділ'**
  String get editSectionTitle;

  /// No description provided for @sectionNameFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get sectionNameFieldLabel;

  /// No description provided for @sectionNameHint.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть назву розділу для нотаток'**
  String get sectionNameHint;

  /// No description provided for @enterSectionNameError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву'**
  String get enterSectionNameError;

  /// No description provided for @sectionIconFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Іконка'**
  String get sectionIconFieldLabel;

  /// No description provided for @chooseIconLabel.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть іконку'**
  String get chooseIconLabel;

  /// No description provided for @sectionCommentFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Короткий опис'**
  String get sectionCommentFieldLabel;

  /// No description provided for @sectionCommentHint.
  ///
  /// In uk, this message translates to:
  /// **'До 30 символів (необов\'язково)'**
  String get sectionCommentHint;

  /// No description provided for @deleteSectionConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Видалити розділ?'**
  String get deleteSectionConfirmTitle;

  /// No description provided for @deleteSectionConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Розділ і всі записи в ньому буде видалено.'**
  String get deleteSectionConfirmBody;

  /// No description provided for @sectionEmptyHint.
  ///
  /// In uk, this message translates to:
  /// **'Тут порожньо. Додайте перший запис через плюсик'**
  String get sectionEmptyHint;

  /// No description provided for @spaceFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Простір'**
  String get spaceFieldLabel;

  /// No description provided for @spacePickerTitle.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть простір'**
  String get spacePickerTitle;

  /// No description provided for @noSpaceOption.
  ///
  /// In uk, this message translates to:
  /// **'Без простору'**
  String get noSpaceOption;

  /// No description provided for @createNewSpaceAction.
  ///
  /// In uk, this message translates to:
  /// **'Створити новий розділ'**
  String get createNewSpaceAction;

  /// No description provided for @newEntryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Новий запис'**
  String get newEntryTitle;

  /// No description provided for @editEntryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати запис'**
  String get editEntryTitle;

  /// No description provided for @entryTitleFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get entryTitleFieldLabel;

  /// No description provided for @entryTitleHint.
  ///
  /// In uk, this message translates to:
  /// **'Назва запису'**
  String get entryTitleHint;

  /// No description provided for @enterEntryTitleError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву'**
  String get enterEntryTitleError;

  /// No description provided for @entryDateFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Дата запису'**
  String get entryDateFieldLabel;

  /// No description provided for @entryNotesHint.
  ///
  /// In uk, this message translates to:
  /// **'Довільні нотатки…'**
  String get entryNotesHint;

  /// No description provided for @deleteEntryConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Запис буде видалено.'**
  String get deleteEntryConfirmBody;

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

  /// No description provided for @sectionPast.
  ///
  /// In uk, this message translates to:
  /// **'Минулі'**
  String get sectionPast;

  /// No description provided for @emptyStateNoneYetTitle.
  ///
  /// In uk, this message translates to:
  /// **'Ще нічого не додано'**
  String get emptyStateNoneYetTitle;

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

  /// No description provided for @notSpecifiedValue.
  ///
  /// In uk, this message translates to:
  /// **'Не вказано'**
  String get notSpecifiedValue;

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

  /// No description provided for @removeAction.
  ///
  /// In uk, this message translates to:
  /// **'Прибрати'**
  String get removeAction;

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
  /// **'Ви приєднуєтесь як рівноправний учасник — ваш власний профіль (ім\'я й аватар) стане видимим \"{name}\". Це не скасовує і не змінює жодних ваших даних, уже внесених у застосунок. Ваш архів НІКОМУ автоматично не показується — які саме дані бачитимуть інші учасники, ви налаштуєте окремо, вже після приєднання.'**
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
  /// **'Короткі вправи на кілька хвилин'**
  String get antiStressPickerSubtitle;

  /// No description provided for @breathingExerciseTitle.
  ///
  /// In uk, this message translates to:
  /// **'Дихаймо разом'**
  String get breathingExerciseTitle;

  /// No description provided for @breathingExerciseSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Повільне дихання у своєму темпі — 2 хвилини'**
  String get breathingExerciseSubtitle;

  /// No description provided for @grounding54321Title.
  ///
  /// In uk, this message translates to:
  /// **'5-4-3-2-1'**
  String get grounding54321Title;

  /// No description provided for @grounding54321Subtitle.
  ///
  /// In uk, this message translates to:
  /// **'Коротка вправа на 5 кроків із органами чуття'**
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
  /// **'Якщо вимкнено, нагадування цього профілю (разом із вкладеннями) не передаються на інші пристрої сім\'ї, підключені через пейринг. Ліки й розклад прийому синхронізуються незалежно від цього перемикача.'**
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
  /// **'Вправу завершено'**
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
  /// **'Керує мовою інтерфейсу та диктування коментарів. Поки доступні українська, англійська та російська — інші мови з\'являться після перекладів.'**
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
  /// **'Нагадування'**
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
  /// **'Немає нагадувань з цим тегом'**
  String get noAppointmentsForSpecialty;

  /// No description provided for @tryDifferentSpecialtyHint.
  ///
  /// In uk, this message translates to:
  /// **'Спробуйте обрати інший тег або скиньте фільтр'**
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
  /// **'Нагадування буде видалено.'**
  String get deleteAppointmentBody;

  /// No description provided for @newAppointmentTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нова зустріч'**
  String get newAppointmentTitle;

  /// No description provided for @fieldWhere.
  ///
  /// In uk, this message translates to:
  /// **'Де'**
  String get fieldWhere;

  /// No description provided for @locationHint.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть адресу або назву'**
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

  /// No description provided for @noteSingularLabel.
  ///
  /// In uk, this message translates to:
  /// **'Нотатка'**
  String get noteSingularLabel;

  /// No description provided for @reminderNoteHint.
  ///
  /// In uk, this message translates to:
  /// **'Додаткові деталі…'**
  String get reminderNoteHint;

  /// No description provided for @saveReminderAction.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти нагадування'**
  String get saveReminderAction;

  /// No description provided for @reminderTitleFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get reminderTitleFieldLabel;

  /// No description provided for @reminderTitleHint.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть, про що нагадати'**
  String get reminderTitleHint;

  /// No description provided for @enterReminderTitleError.
  ///
  /// In uk, this message translates to:
  /// **'Введіть назву'**
  String get enterReminderTitleError;

  /// No description provided for @reminderTagsFieldLabel.
  ///
  /// In uk, this message translates to:
  /// **'Теги'**
  String get reminderTagsFieldLabel;

  /// No description provided for @reminderTagsHint.
  ///
  /// In uk, this message translates to:
  /// **'Теги для структурування, через кому'**
  String get reminderTagsHint;

  /// No description provided for @reminderTagsPickerTitle.
  ///
  /// In uk, this message translates to:
  /// **'Оберіть теги'**
  String get reminderTagsPickerTitle;

  /// No description provided for @addNewTagHint.
  ///
  /// In uk, this message translates to:
  /// **'Новий тег'**
  String get addNewTagHint;

  /// No description provided for @noTagsYetLabel.
  ///
  /// In uk, this message translates to:
  /// **'Поки немає жодного тега'**
  String get noTagsYetLabel;

  /// No description provided for @reminderPhotoLabel.
  ///
  /// In uk, this message translates to:
  /// **'Фото'**
  String get reminderPhotoLabel;

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
  /// **'Поділитися підсумком'**
  String get sendDiaryToDoctorLabel;

  /// No description provided for @diarySummaryHint.
  ///
  /// In uk, this message translates to:
  /// **'Зрізи самопочуття та прийоми за місяць'**
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
  /// **'Теги'**
  String get anySymptomsLabel;

  /// No description provided for @chooseFromListOrAddLabel.
  ///
  /// In uk, this message translates to:
  /// **'Додайте власні теги (необов\'язково)'**
  String get chooseFromListOrAddLabel;

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
  /// **'Додайте ліки, які приймаєте зараз'**
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

  /// No description provided for @refFoodAnyLabel.
  ///
  /// In uk, this message translates to:
  /// **'Незалежно від їжі'**
  String get refFoodAnyLabel;

  /// No description provided for @backupScreenTitle.
  ///
  /// In uk, this message translates to:
  /// **'Резервна копія'**
  String get backupScreenTitle;

  /// No description provided for @backupIntroBody.
  ///
  /// In uk, this message translates to:
  /// **'Ліки, розклад, архів (фото) і всі інші дані — обирайте, де зберігати резервну копію.'**
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
  /// **'Турбота про родину'**
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
  /// **'Необмежено нагадувань'**
  String get freeFeatureUnlimitedMeds;

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

  /// No description provided for @plusFeatureUnlimitedProfiles.
  ///
  /// In uk, this message translates to:
  /// **'Необмежена кількість профілів родини — керуєте тільки ви'**
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
  /// **'Оплата списується з вашого облікового запису {store}. Підписка автоматично продовжується на новий період за тією самою ціною, якщо не скасувати щонайменше за 24 години до завершення періоду. Керувати підпискою та скасувати автопродовження можна в налаштуваннях облікового запису {store}.'**
  String billingTermsDisclaimer(String store);

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
  /// **'Розклад, дозування, повторення'**
  String get addTypeMedsSub;

  /// No description provided for @addTypeActivitySub.
  ///
  /// In uk, this message translates to:
  /// **'Прогулянка, зарядка, вправи, ЛФК'**
  String get addTypeActivitySub;

  /// No description provided for @addTypeAppointmentSub.
  ///
  /// In uk, this message translates to:
  /// **'Дата, час і нагадування про будь-яку подію'**
  String get addTypeAppointmentSub;

  /// No description provided for @addTypeWellbeingSub.
  ///
  /// In uk, this message translates to:
  /// **'Зробити зріз — настрій, теги, коментар'**
  String get addTypeWellbeingSub;

  /// No description provided for @taskTypeSport.
  ///
  /// In uk, this message translates to:
  /// **'Спорт'**
  String get taskTypeSport;

  /// No description provided for @taskTypeSportSub.
  ///
  /// In uk, this message translates to:
  /// **'Прогулянка, тренування, вправи'**
  String get taskTypeSportSub;

  /// No description provided for @taskTypeMeeting.
  ///
  /// In uk, this message translates to:
  /// **'Зустрічі'**
  String get taskTypeMeeting;

  /// No description provided for @taskTypeMeetingSub.
  ///
  /// In uk, this message translates to:
  /// **'Дата, час і нагадування про будь-яку подію'**
  String get taskTypeMeetingSub;

  /// No description provided for @taskTypeSimple.
  ///
  /// In uk, this message translates to:
  /// **'Прості завдання'**
  String get taskTypeSimple;

  /// No description provided for @taskTypeSimpleSub.
  ///
  /// In uk, this message translates to:
  /// **'Одноразове чи просте нагадування'**
  String get taskTypeSimpleSub;

  /// No description provided for @taskTypeRoutine.
  ///
  /// In uk, this message translates to:
  /// **'Рутинні справи'**
  String get taskTypeRoutine;

  /// No description provided for @taskTypeRoutineSub.
  ///
  /// In uk, this message translates to:
  /// **'Щоденні справи по дому'**
  String get taskTypeRoutineSub;

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

  /// No description provided for @disableWellbeingConfirmTitle.
  ///
  /// In uk, this message translates to:
  /// **'Вимкнути збір самопочуття?'**
  String get disableWellbeingConfirmTitle;

  /// No description provided for @disableWellbeingConfirmBody.
  ///
  /// In uk, this message translates to:
  /// **'Нагадування зникнуть з Розкладу і Сьогодні. Налаштування збережуться — можна ввімкнути знову пізніше.'**
  String get disableWellbeingConfirmBody;

  /// No description provided for @applyAction.
  ///
  /// In uk, this message translates to:
  /// **'Готово'**
  String get applyAction;

  /// No description provided for @noDaysSelectedHint.
  ///
  /// In uk, this message translates to:
  /// **'Дні не обрані'**
  String get noDaysSelectedHint;

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

  /// No description provided for @chooseAction.
  ///
  /// In uk, this message translates to:
  /// **'Обрати'**
  String get chooseAction;

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

  /// No description provided for @documentsPrivacyHint.
  ///
  /// In uk, this message translates to:
  /// **'Зберігається лише на пристрої (і в хмарі, якщо ввімкнено резервну копію) — застосунок не переглядає й не аналізує ці файли.'**
  String get documentsPrivacyHint;

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
  /// **'🔔 Нагадування'**
  String get notifAppointmentTitle;

  /// No description provided for @notifAppointmentNoResponseTitle.
  ///
  /// In uk, this message translates to:
  /// **'🔔 Не забудьте про нагадування'**
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
  /// **'Чи відбулось нагадування (\"{doctorType}\") о {timeStr}? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.'**
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
  /// **'Керування підпискою відкрито в {store} — завершіть скасування там.'**
  String manageSubscriptionExternallyHint(String store);

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
  /// **'Активних покупок не знайдено на цьому обліковому записі'**
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
