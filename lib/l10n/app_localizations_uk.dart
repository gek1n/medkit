// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appName => 'Elly';

  @override
  String get navAdd => 'Додати';

  @override
  String get navToday => 'Сьогодні';

  @override
  String get navMeds => 'Розклад';

  @override
  String get navFamily => 'Сім\'я';

  @override
  String get navProfile => 'Профіль';

  @override
  String get navMedCard => 'Медкартка';

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

  @override
  String errorGeneric(String error) {
    return 'Помилка: $error';
  }

  @override
  String get todaySectionFamily => 'Сім\'я';

  @override
  String get todayScheduleForToday => 'Розклад на сьогодні';

  @override
  String get todayScheduleForTomorrow => 'Коротко про завтра';

  @override
  String get todayNothingToday => 'На сьогодні нічого немає';

  @override
  String get todayTapToAdd => 'Натисніть + щоб додати';

  @override
  String get todayAllDoneChip => 'Все виконано';

  @override
  String get todayNextNow => 'зараз';

  @override
  String todayNextInMinutes(int minutes) {
    return 'через $minutes хв';
  }

  @override
  String get todayAllDoneTitle => 'Все виконано на сьогодні!';

  @override
  String get todayAllDoneSubtitle => 'Чудова робота — так тримати';

  @override
  String get todayHurtsNow => 'Зараз\nболить';

  @override
  String get todayMissedSection => 'Ви пропустили';

  @override
  String get todayActiveNowSection => 'Зараз потрібно';

  @override
  String get dayPartMorning => 'Ранок';

  @override
  String get dayPartAfternoon => 'День';

  @override
  String get dayPartEvening => 'Вечір';

  @override
  String get dayPartNight => 'Ніч';

  @override
  String get defaultMedName => 'Ліки';

  @override
  String get defaultActivityName => 'Активність';

  @override
  String get wellbeingTitle => 'Самопочуття';

  @override
  String get detailLabelTime => 'Час';

  @override
  String get detailLabelDuration => 'Тривалість';

  @override
  String durationMinutes(int minutes) {
    return '$minutes хв';
  }

  @override
  String get detailLabelLocation => 'Місце';

  @override
  String get detailLabelNotes => 'Нотатки';

  @override
  String todayDoneCount(int count) {
    return 'Виконано · $count';
  }

  @override
  String get skipIntakeAction => 'Пропустити прийом';

  @override
  String get missedCaption => 'пропущено';

  @override
  String get videoPlaybackError => 'Не вдалося відтворити відео тут';

  @override
  String get openInYoutube => 'Відкрити в YouTube';

  @override
  String get missedWellbeingSlot => 'Пропущений зріз';

  @override
  String get wellbeingTimeToCheck => 'Час перевірити самопочуття';

  @override
  String get wellbeingCommentHint =>
      'Оцініть настрій і, за потреби, опишіть симптоми';

  @override
  String get skipGenericAction => 'Пропустити';

  @override
  String get snooze10 => 'Перенести на 10 хв';

  @override
  String get snooze30 => 'Перенести на 30 хв';

  @override
  String get snooze60 => 'Перенести на 1 год';

  @override
  String get doneAction => 'Виконати';

  @override
  String get welcomeTitle => 'Ласкаво просимо до Elly';

  @override
  String get welcomeSubtitle => 'Додайте свій профіль щоб розпочати';

  @override
  String get categoryAll => 'Усі';

  @override
  String get categoryMeds => 'Ліки';

  @override
  String get categoryActivities => 'Активності';

  @override
  String get categoryWellbeing => 'Самопочуття';

  @override
  String get categoryDoctors => 'Лікарі';

  @override
  String get scheduleTitle => 'Розклад';

  @override
  String get searchAllSections => 'Пошук по всіх розділах';

  @override
  String get sectionMeds => 'Ліки';

  @override
  String get noActiveMeds => 'Немає активних ліків';

  @override
  String get sectionAppointments => 'Прийоми лікарів';

  @override
  String get noScheduledAppointments => 'Немає запланованих прийомів';

  @override
  String get sectionActivities => 'Активності';

  @override
  String get noActiveActivities => 'Немає активних занять';

  @override
  String get sectionWellbeing => 'Самопочуття';

  @override
  String get wellbeingScheduleNotSet => 'Розклад не налаштовано';

  @override
  String get nothingFound => 'Нічого не знайдено';

  @override
  String get repeatDaily => 'щодня';

  @override
  String get repeatAlternate => 'через день';

  @override
  String get repeatWeekdays => 'певні дні';

  @override
  String get repeatEveryN => 'кожні N днів';

  @override
  String get repeatCycle => 'циклом';

  @override
  String get courseOngoing => 'постійний курс';

  @override
  String get courseFinished => 'курс завершено';

  @override
  String courseDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів курсу',
      few: '$count дні курсу',
      one: '$count день курсу',
    );
    return '$_temp0';
  }

  @override
  String get noLocation => 'Без місця проведення';

  @override
  String timesPerDayLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count разів на день',
      few: '$count рази на день',
      one: '$count раз на день',
    );
    return '$_temp0';
  }

  @override
  String get addAction => 'Додати';

  @override
  String get profileNotFound => 'Профіль не знайдено';

  @override
  String get dayMon => 'Пн';

  @override
  String get dayTue => 'Вт';

  @override
  String get dayWed => 'Ср';

  @override
  String get dayThu => 'Чт';

  @override
  String get dayFri => 'Пт';

  @override
  String get daySat => 'Сб';

  @override
  String get daySun => 'Нд';

  @override
  String get editAction => 'Редагувати';

  @override
  String get fieldName => 'Назва';

  @override
  String get fieldDate => 'Дата';

  @override
  String get fieldNotes => 'Нотатки';

  @override
  String get surgeryTitle => 'Операція';

  @override
  String get chronicConditionTitle => 'Хронічне захворювання';

  @override
  String get labResultTitle => 'Аналіз';

  @override
  String get vaccinationTitle => 'Щеплення';

  @override
  String get allergyTitle => 'Алергія';

  @override
  String get fieldDiagnosis => 'Діагноз';

  @override
  String get fieldSpecialty => 'Напрямок';

  @override
  String get fieldDiagnosisDate => 'Дата діагнозу';

  @override
  String get fieldDateGiven => 'Дата введення';

  @override
  String get fieldNextDose => 'Наступна ревакцинація';

  @override
  String get fieldAllergen => 'Алерген';

  @override
  String get fieldSeverity => 'Тяжкість';

  @override
  String get fieldReaction => 'Реакція';

  @override
  String get severityMild => 'Легка';

  @override
  String get severityModerate => 'Середня';

  @override
  String get severitySevere => 'Тяжка';

  @override
  String get dayToday => 'Сьогодні';

  @override
  String get dayTomorrow => 'Завтра';

  @override
  String get dayYesterday => 'Вчора';

  @override
  String get surgeriesSectionTitle => 'Операції та госпіталізації';

  @override
  String get surgeriesEmptyHint =>
      'Натисніть \"+ Додати\" щоб додати перший запис';

  @override
  String get chronicConditionsSectionTitle => 'Хронічні захворювання';

  @override
  String get chronicConditionsEmptyHint =>
      'Натисніть \"+ Додати\" щоб додати перший діагноз';

  @override
  String get allergiesTitle => 'Алергії';

  @override
  String get allergiesEmptyHint =>
      'Натисніть \"+ Додати\" щоб додати першу алергію';

  @override
  String get vaccinationsTitle => 'Щеплення';

  @override
  String get vaccinationsEmptyHint =>
      'Натисніть \"+ Додати\" щоб додати перше щеплення';

  @override
  String vaccinationGivenOn(String date) {
    return 'Введено $date';
  }

  @override
  String get vaccinationOverdue => 'Прострочено';

  @override
  String get labResultsTitle => 'Аналізи';

  @override
  String get allSpecialtiesFilter => 'Усі напрямки';

  @override
  String get allTestTypesFilter => 'Усі типи аналізів';

  @override
  String get labResultsEmptyFilteredTitle => 'Немає аналізів за цим фільтром';

  @override
  String get labResultsEmptyNoneTitle => 'Ще нічого не додано';

  @override
  String get labResultsEmptyFilteredHint =>
      'Спробуйте змінити фільтри або скиньте їх';

  @override
  String get labResultsEmptyHint =>
      'Натисніть \"+ Додати\" щоб додати перший аналіз';

  @override
  String get medCardTitle => 'Медкартка';

  @override
  String get medCardHistoryByDoctorTitle => 'Історія лікування за напрямками';

  @override
  String get medCardHistoryByDoctorSubtitle =>
      'Візити й аналізи одного лікаря — все в одному місці';

  @override
  String get medCardLabResultsSubtitle => 'Результати за напрямками';

  @override
  String get medCardArchiveTitle => 'Архів ліків';

  @override
  String get medCardArchiveSubtitle => 'Усі препарати й статус лікування';

  @override
  String get medCardAppointmentsTitle => 'Візити до лікарів';

  @override
  String get medCardAppointmentsSubtitle => 'Записи обраного профілю';

  @override
  String get medCardWellbeingHistoryTitle => 'Історія самопочуття';

  @override
  String get medCardWellbeingHistorySubtitle =>
      'Настрій та симптоми за весь час';

  @override
  String get medCardAllergiesSubtitle => 'Реакції на препарати й речовини';

  @override
  String get medCardChronicConditionsSubtitle => 'Діагнози, дата встановлення';

  @override
  String get medCardVaccinationsSubtitle => 'Історія й наступні ревакцинації';

  @override
  String get medicationArchiveEmptyHint =>
      'Тут з\'являться всі ліки, які ви колись додавали';

  @override
  String get medStatusOngoing => 'Триває';

  @override
  String get medStatusFinished => 'Завершено';

  @override
  String get medStatusCancelled => 'Відмінено';

  @override
  String medArchiveDateRangeOngoing(String start) {
    return '$start — досі';
  }

  @override
  String get specialtyHistoryTitle => 'Історія за напрямком';

  @override
  String get sectionUpcoming => 'Заплановані';

  @override
  String get sectionPast => 'Минулі';

  @override
  String visitPrefix(String type) {
    return 'Візит · $type';
  }

  @override
  String labPrefix(String name) {
    return 'Аналіз · $name';
  }

  @override
  String get emptyStateNoneYetTitle => 'Ще нічого не додано';

  @override
  String get specialtyHistoryEmptyHint => 'Візити й аналізи з\'являться тут';

  @override
  String get actionCancel => 'Скасувати';

  @override
  String get deleteAction => 'Видалити';

  @override
  String get documentsLabel => 'Документи';

  @override
  String get notSelectedValue => 'Не обрано';

  @override
  String get notSpecifiedValue => 'Не вказано';

  @override
  String get deleteRecordBody => 'Запис буде видалено.';

  @override
  String get deleteWithDocsBody =>
      'Запис і всі прикріплені документи буде видалено.';

  @override
  String get deleteSurgeryConfirmTitle => 'Видалити запис?';

  @override
  String get editSurgeryTitle => 'Редагувати запис';

  @override
  String get newSurgeryTitle => 'Нова операція чи госпіталізація';

  @override
  String get surgeryNameHint => 'Апендектомія, госпіталізація…';

  @override
  String get enterSurgeryNameError => 'Введіть назву операції';

  @override
  String get surgeryNotesHint => 'Лікарня, ускладнення, рекомендації…';

  @override
  String get deleteConditionConfirmTitle => 'Видалити діагноз?';

  @override
  String get editConditionTitle => 'Редагувати діагноз';

  @override
  String get newConditionTitle => 'Новий діагноз';

  @override
  String get conditionNameHint => 'Астма, діабет, гіпертонія…';

  @override
  String get enterConditionNameError => 'Введіть назву діагнозу';

  @override
  String get fieldDoctorSpecialty => 'Напрямок лікаря';

  @override
  String get conditionNotesHint => 'Схема лікування, дозування…';

  @override
  String get deleteAllergyConfirmTitle => 'Видалити алергію?';

  @override
  String get editAllergyTitle => 'Редагувати алергію';

  @override
  String get newAllergyTitle => 'Нова алергія';

  @override
  String get allergenHint => 'Пеніцилін, горіхи, пилок…';

  @override
  String get enterAllergenError => 'Введіть назву алергену';

  @override
  String get reactionHint => 'Висип, набряк, задишка…';

  @override
  String get allergyNotesHint => 'Додаткові деталі…';

  @override
  String get deleteLabResultConfirmTitle => 'Видалити аналіз?';

  @override
  String get editLabResultTitle => 'Редагувати аналіз';

  @override
  String get newLabResultTitle => 'Новий аналіз';

  @override
  String get chooseSpecialtyValue => 'Оберіть напрямок';

  @override
  String get fieldTestName => 'Назва аналізу';

  @override
  String get chooseTestNameValue => 'Оберіть назву аналізу';

  @override
  String get labResultNotesHint => 'Результати, коментар лікаря…';

  @override
  String get deleteVaccinationConfirmTitle => 'Видалити щеплення?';

  @override
  String get editVaccinationTitle => 'Редагувати щеплення';

  @override
  String get newVaccinationTitle => 'Нове щеплення';

  @override
  String get vaccinationNameField => 'Назва щеплення';

  @override
  String get vaccinationNameHint => 'Правець, грип, COVID-19…';

  @override
  String get enterVaccinationNameError => 'Введіть назву щеплення';

  @override
  String get removeAction => 'Прибрати';

  @override
  String get notScheduledValue => 'Не заплановано';

  @override
  String get vaccinationNotesHint => 'Реакція, серія вакцини…';

  @override
  String get medsTitle => 'Ліки';

  @override
  String activeMedsCountSection(int count) {
    return 'Активні ($count)';
  }

  @override
  String finishedMedsCountSection(int count) {
    return 'Завершені ($count)';
  }

  @override
  String get noMedsYetTitle => 'Ліків ще немає';

  @override
  String get noMedsYetHint => 'Натисніть + щоб додати перше лікарство';

  @override
  String get addMedicationAction => 'Додати лікарство';

  @override
  String get errorGenericShort => 'Помилка';

  @override
  String get sideEffectsSectionLabel => 'МОЖЛИВІ ПОБІЧНІ ЕФЕКТИ';

  @override
  String get sideEffectsAiDisclaimer =>
      'Визначено AI під час сканування — ця інформація може бути неточною. Обов\'язково звірте з інструкцією до препарату.';

  @override
  String get stockUnitTabletsCapsules => 'ТАБЛЕТКИ / КАПСУЛИ';

  @override
  String get stockUnitSyrup => 'СИРОП';

  @override
  String get stockUnitDrops => 'КРАПЛІ';

  @override
  String get stockUnitInjections => 'ІН\'ЄКЦІЇ';

  @override
  String get stockUnitSuppositories => 'СВІЧКИ';

  @override
  String get stockUnitVial => 'ФЛАКОН';

  @override
  String get stockUnitCream => 'КРЕМ';

  @override
  String get stockUnitInhaler => 'ІНГАЛЯТОР';

  @override
  String get stockUnitGeneric => 'ЗАЛИШОК';

  @override
  String perDoseLabel(String dose, String unit) {
    return '$dose $unit на прийом';
  }

  @override
  String timesPerDaySlash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count разів/день',
      few: '$count рази/день',
      one: '$count раз/день',
    );
    return '$_temp0';
  }

  @override
  String get stockSectionLabel => 'Залишок';

  @override
  String get untilCourseEndLabel => 'до кінця курсу';

  @override
  String get next30DaysLabel => 'на найближчі 30 днів';

  @override
  String get remainingColonLabel => 'Залишилось: ';

  @override
  String daysLeftShortLabel(String days) {
    return 'на $days дн.';
  }

  @override
  String get needToBuyLabel => 'Потрібно докупити: ';

  @override
  String get refillPackageAction => '+ Поповнити упаковку';

  @override
  String get refillPackageTitle => 'Поповнити упаковку';

  @override
  String get quantityHint => 'Кількість';

  @override
  String get okAction => 'OK';

  @override
  String remainingApproxPercent(int percent) {
    return 'Залишилось ~$percent%';
  }

  @override
  String daysLeftAtCurrentRate(String days) {
    return '~$days днів при поточній витраті';
  }

  @override
  String get updateStockEstimateLabel => 'Оновити оцінку залишку:';

  @override
  String get openedNewContainerAction => '+ Відкрив новий флакон';

  @override
  String get openedTodayLabel => 'Відкрито сьогодні';

  @override
  String openedDaysAgoLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів тому',
      few: '$count дні тому',
      one: '$count день тому',
    );
    return 'Відкрито $_temp0';
  }

  @override
  String phaseNumberLabel(int number) {
    return 'Етап $number';
  }

  @override
  String get nowLabel => 'зараз';

  @override
  String phaseFromOngoing(String date) {
    return 'з $date, постійно';
  }

  @override
  String get courseStagesLabel => 'Етапи курсу';

  @override
  String get foodBeforeLabel => '🕐 До їжі';

  @override
  String get foodAfterLabel => '🍽 Після їжі';

  @override
  String get foodWithLabel => '🥗 Під час їжі';

  @override
  String get foodAnytimeLabel => '✓ Незалежно від їжі';

  @override
  String untilDateLabel(String date) {
    return 'до $date';
  }

  @override
  String get ongoingLabel => 'постійно';

  @override
  String get detailsLabel => 'Деталі';

  @override
  String get intakeLabel => 'Прийом';

  @override
  String get withFoodLabel => 'З їжею';

  @override
  String get courseNounLabel => 'Курс';

  @override
  String get noteLabel => 'Примітка';

  @override
  String courseRangeLabel(String start, String endPart) {
    return 'з $start $endPart';
  }

  @override
  String get repeatDailyCap => 'Щодня';

  @override
  String get repeatAlternateCap => 'Через день';

  @override
  String repeatEveryNCap(String n) {
    return 'Кожні $n дні';
  }

  @override
  String repeatCycleCap(String on, String off) {
    return '$on днів / $off відпочинок';
  }

  @override
  String get stopAction => 'Зупинити';

  @override
  String get stopCourseConfirmTitle => 'Зупинити курс?';

  @override
  String stopCourseConfirmBody(String name) {
    return '«$name» буде видалено зі списку активних ліків.';
  }

  @override
  String get enterMedicationNameError => 'Введіть назву ліків';

  @override
  String get deleteMedicationConfirmTitle => 'Видалити ліки?';

  @override
  String get deleteMedicationConfirmBody => 'Ліки будуть вилучені з розкладу.';

  @override
  String get editMedicationTitle => 'Редагувати ліки';

  @override
  String get medicationNameHint => 'Назва препарату';

  @override
  String get medicationFormLabel => 'Форма випуску';

  @override
  String get coursePhasesLabel => 'Фази курсу';

  @override
  String get addPhaseAction => 'Додати фазу';

  @override
  String get repeatSectionLabel => 'Повтор';

  @override
  String get savingLabel => 'Зберігаємо...';

  @override
  String get saveChangesAction => 'Зберегти зміни';

  @override
  String get saveAndContinueAction => 'Зберегти і продовжити →';

  @override
  String get saveAndViewScheduleAction => 'Зберегти та переглянути розклад →';

  @override
  String get moreInEllyPlusLabel => 'Більше в Elly+';

  @override
  String get aiLabel => 'AI';

  @override
  String get scanPrescriptionTitle => 'Розпізнати рецепт за фото';

  @override
  String get scanPrescriptionSubtitle => 'Еллі внесе ліки у розклад';

  @override
  String scansRemainingLabel(int remaining) {
    return '$remaining сканувань залишилось для тарифу Elly Free';
  }

  @override
  String get orEnterManuallyLabel => 'або введіть вручну';

  @override
  String bulkSavedSnackbar(int count) {
    return 'Додано $count препаратів. Перевірте деталі в списку ліків.';
  }

  @override
  String phaseCardTitle(int number) {
    return 'Фаза $number';
  }

  @override
  String get removePhaseAction => 'видалити';

  @override
  String get doseAmountLabel => 'КІЛЬКІСТЬ НА ПРИЙОМ';

  @override
  String get foodRelationSectionLabel => 'ВІДНОСНО ЇЖІ';

  @override
  String get durationSectionLabel => 'ТРИВАЛІСТЬ';

  @override
  String get daysCountDashLabel => '— дн.';

  @override
  String daysCountLabel(int n) {
    return '$n дн.';
  }

  @override
  String get orLabel => 'або';

  @override
  String get permanentLabel => 'Постійно';

  @override
  String get intakeTimeSectionLabel => 'ЧАС ПРИЙОМУ';

  @override
  String get specificTimeLabel => 'Конкретний час';

  @override
  String get everyNHoursLabel => 'Кожні N годин';

  @override
  String get addTimeAction => 'Додати час';

  @override
  String get intervalLabel => 'ІНТЕРВАЛ';

  @override
  String hoursCountLabel(int n) {
    return '$n год';
  }

  @override
  String get startLabel => 'ПОЧАТОК';

  @override
  String get daysCountDialogTitle => 'Кількість днів';

  @override
  String get daysSuffix => 'дн.';

  @override
  String get intervalDialogTitle => 'Інтервал';

  @override
  String get hoursSuffix => 'год';

  @override
  String get doseCommentHint => 'Коментар до дози (необов\'язково)';

  @override
  String get doseAmountDialogTitle => 'Кількість на прийом';

  @override
  String get doseAmountExampleHint => 'наприклад 2.5';

  @override
  String get weekdayExampleLabel => 'Пн, Ср, Пт, Нд…';

  @override
  String get weekdaysOptionLabel => 'Певні дні тижня';

  @override
  String get everyNDaysOptionLabel => 'Кожні N днів';

  @override
  String get everyNDaysExampleLabel => 'Наприклад кожні 3 дні';

  @override
  String get everyLabel => 'Кожні';

  @override
  String get daysSuffixWord => 'днів';

  @override
  String get cycleOptionLabel => 'Циклом';

  @override
  String get cycleExampleLabel => 'N днів пити — M днів перерва';

  @override
  String get drinkLabel => 'Пити';

  @override
  String get breakLabel => 'Перерва';

  @override
  String get optionalParamsLabel => 'Додаткові параметри';

  @override
  String get optionalLabel => 'Необов\'язково';

  @override
  String get trackStockLabel => 'Відстежувати та нагадувати про залишок';

  @override
  String get vialPackageLabel => 'Флакон / упаковка';

  @override
  String get markAsOpenedHint =>
      'Позначимо як щойно відкриту (100%) — оновити оцінку залишку можна буде в картці ліків';

  @override
  String get inStockLabel => 'В наявності';

  @override
  String howManyNowLabel(String unit) {
    return 'Скільки $unit є зараз';
  }

  @override
  String courseAvailableLabel(int needed, int available) {
    return ' (курс: $needed, є: $available)';
  }

  @override
  String get enoughForCourseLabel => 'Вистачить на весь курс';

  @override
  String get noCameraAccessError =>
      'Немає доступу до камери. Дозвольте його в налаштуваннях телефону.';

  @override
  String get cameraOpenError => 'Не вдалося відкрити камеру';

  @override
  String get packagePhotoLabel => 'Фото упаковки';

  @override
  String get addPhotoAction => 'Додати фото';

  @override
  String get addPhotoHint => 'щоб не переплутати ліки';

  @override
  String inviteMemberTitle(String name) {
    return 'Запросити $name';
  }

  @override
  String get inviteToFamilyTitle => 'Запросити до сім\'ї';

  @override
  String get inviteCreateErrorTitle => 'Не вдалося створити запрошення';

  @override
  String get tryAgainAction => 'Спробувати ще раз';

  @override
  String inviteDependentBody(String name) {
    return 'Нехай $name введе цей код у застосунку на своєму телефоні. Профіль перетвориться на незалежний: уся наявна історія перенесеться як стартові дані, а ви автоматично отримаєте повний доступ до нього, як і раніше.';
  }

  @override
  String get inviteMemberBody =>
      'Той, хто введе цей код, приєднається як рівноправний учасник вашої сімейної групи — зі своїм профілем і своїми даними. Що саме він побачить із ваших даних, ви налаштуєте окремо.';

  @override
  String get inviteScanOrEnterHint =>
      'Відскануйте цей код на іншому пристрої\nабо введіть його вручну';

  @override
  String get codeCopiedSnackbar => 'Код скопійовано';

  @override
  String get inviteCodeExpiryNotice =>
      'Код діє 30 хвилин і працює лише один раз. Дані на сервері зашифровані — там немає нічого, крім коду доступу.';

  @override
  String alreadyJoinedFamilyError(String name) {
    return 'Ви вже приєднані до сім\'ї \"$name\"';
  }

  @override
  String get joinInvalidCodeError =>
      'Не вдалося приєднатись: невірний або прострочений код';

  @override
  String get joinFamilyTitle => 'Приєднатись до сім\'ї';

  @override
  String get confirmationTitle => 'Підтвердження';

  @override
  String get doneTitle => 'Готово';

  @override
  String get scanQrOrEnterHint =>
      'Наведіть камеру на QR-код\nабо введіть код вручну';

  @override
  String get codeInputHint => '________';

  @override
  String get checkingLabel => 'Перевірка…';

  @override
  String get continueAction => 'Продовжити';

  @override
  String get invitesYouToFamilyGroup => 'запрошує вас до сімейної групи';

  @override
  String joinConsentBody(String name) {
    return 'Ви приєднуєтесь як рівноправний учасник — ваш власний профіль (ім\'я й аватар) стане видимим \"$name\". Це не скасовує і не змінює жодних ваших даних, уже внесених у застосунок. Ваша медкартка НІКОМУ автоматично не показується — які саме дані бачитимуть інші учасники, ви налаштуєте окремо, вже після приєднання.';
  }

  @override
  String joinConsentCheckbox(String name) {
    return 'Я погоджуюсь приєднатись до сімейної групи \"$name\"';
  }

  @override
  String get joiningLabel => 'Приєднуємось…';

  @override
  String get joinAction => 'Приєднатись';

  @override
  String get joinedFamilyTitle => 'Ви в сім\'ї!';

  @override
  String joinedFamilyBody(String name) {
    return 'Тепер ви й \"$name\" бачите одне одного в розділі \"Сім\'я\".';
  }

  @override
  String get scanQrCodeLabel => 'Сканувати QR-код';

  @override
  String get tapToEnableCameraHint => 'Натисніть, щоб увімкнути камеру';

  @override
  String get doctorVisitLabel => 'Візит до лікаря';

  @override
  String get recordFallbackLabel => 'Запис';

  @override
  String dataFromPeerTitle(String name) {
    return 'Дані від $name';
  }

  @override
  String peerNothingSharedYet(String name) {
    return '$name ще нічого не поділив(-ла) з вами — або доступ ще не надано.';
  }

  @override
  String get noViewableDataLabel => 'Немає даних, доступних для перегляду';

  @override
  String get fileRequestSentSnackbar =>
      'Запит надіслано — файл ще потрібно дочекатись';

  @override
  String fileRequestFailedError(String error) {
    return 'Не вдалося надіслати запит: $error';
  }

  @override
  String get pdfReceivedSavedSnackbar => 'PDF отримано та збережено';

  @override
  String fileOpenFailedError(String error) {
    return 'Не вдалося відкрити файл: $error';
  }

  @override
  String get loadingEllipsis => '…';

  @override
  String get pdfLabel => 'PDF';

  @override
  String get photoLabel => 'Фото';

  @override
  String get awaitingFileLabel => 'Очікуємо файл…';

  @override
  String get requestFileAction => 'Запросити файл';

  @override
  String get editNotesTitle => 'Редагувати нотатки';

  @override
  String get editNotesDisclaimer =>
      'Правку побачить власник даних — застосується, лише якщо він тим часом сам не змінював цей запис.';

  @override
  String get notesHintEllipsis => 'Нотатки…';

  @override
  String get editSentSnackbar => 'Правку надіслано';

  @override
  String sendFailedError(String error) {
    return 'Не вдалося надіслати: $error';
  }

  @override
  String get sendEditAction => 'Надіслати правку';

  @override
  String get familyLabel => 'Сімʼя';

  @override
  String familyMembersCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count членів',
      few: '$count члени',
      one: '$count член',
    );
    return '$_temp0';
  }

  @override
  String get noMedsTodayLabel => 'Немає ліків на сьогодні';

  @override
  String get allDoneTodayLabel => 'Усе виконано сьогодні';

  @override
  String takenOfTotalIntakesLabel(int taken, int total) {
    return '$taken з $total прийомів';
  }

  @override
  String missedRemindersLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нагадувань',
      few: '$count нагадування',
      one: '$count нагадування',
    );
    return 'Пропущено $_temp0';
  }

  @override
  String nextIntakeLabel(String medName, String time) {
    return 'Наступне: $medName о $time';
  }

  @override
  String get meLabel => 'я';

  @override
  String get localLabel => 'Локальний';

  @override
  String notTakenSuffixLabel(String time) {
    return '$time · не прийнято';
  }

  @override
  String get autonomousProfilesPlusOnly =>
      'Автономні профілі — лише на Elly Family';

  @override
  String get inviteAction => 'Запросити';

  @override
  String get awaitingJoinLabel => 'Очікуємо приєднання';

  @override
  String get inviteToAppLabel => 'Запросити в застосунок';

  @override
  String viewAsLabel(String name) {
    return 'Переглянути як $name';
  }

  @override
  String get deleteForeverAction => 'Видалити назавжди';

  @override
  String get areYouSureTitle => 'Ви впевнені?';

  @override
  String deleteMemberConfirmBody(String name) {
    return 'Будуть видалені весь розклад та медичні картки, прив\'язані до профілю $name';
  }

  @override
  String careSummaryLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count близьких',
      few: '$count близьких',
      one: '$count близького',
    );
    return 'Ви піклуєтесь про $_temp0. Еллі надішле сповіщення, якщо хтось пропустить прийом.';
  }

  @override
  String get addFamilyMemberLabel => 'Додати члена сімʼї';

  @override
  String get addMemberHint => 'Батьки, діти, партнер…';

  @override
  String get profileLimitReachedTitle => 'Ліміт профілів досягнуто';

  @override
  String get profileLimitReachedSubtitle =>
      'Перейдіть на Elly Plus — необмежена кількість локальних профілів';

  @override
  String get localProfilesTitle => 'Профілі локальні';

  @override
  String get familyUpgradeSubtitle =>
      'Щоб сім\'я теж могла керувати — перейдіть на Elly Family';

  @override
  String leaveGroupConfirmTitle(String name) {
    return 'Покинути \"$name\"?';
  }

  @override
  String get leaveGroupConfirmBody =>
      'Учасники цієї групи втратять доступ до ваших даних, а ви — до того, чим вони з вами ділились. Інших сімейних груп це не торкнеться.';

  @override
  String get leaveAction => 'Покинути';

  @override
  String leftGroupSnackbar(String name) {
    return 'Ви покинули \"$name\"';
  }

  @override
  String get familyGroupSectionLabel => 'Сімейна група';

  @override
  String slotsUsedLabel(int used, int total) {
    return '$used з $total';
  }

  @override
  String get autonomousLimitReachedTitle =>
      'Ліміт автономних профілів досягнуто';

  @override
  String get autonomousLimitReachedSubtitle =>
      'Перейдіть на Elly Family, щоб запросити ще когось';

  @override
  String get myFamilyLabel => 'Моя сім\'я';

  @override
  String peerFamilyLabel(String name) {
    return 'Сім\'я $name';
  }

  @override
  String get doctorFallbackLabel => 'Лікар';

  @override
  String get reminderPushTitle => '🔔 Вам нагадують';

  @override
  String reminderTakeMedBody(String title, String detailSuffix, String time) {
    return 'Не забудьте прийняти \"$title\"$detailSuffix о $time';
  }

  @override
  String reminderDoActivityBody(String title, String time) {
    return 'Не забудьте виконати \"$title\" о $time';
  }

  @override
  String reminderDoctorVisitBody(String title, String detailSuffix) {
    return 'Не забудьте про прийом лікаря: $title$detailSuffix';
  }

  @override
  String get reminderWellbeingBody => 'Не забудьте відмітити самопочуття';

  @override
  String get reminderGenericBody => 'Перевірте розклад';

  @override
  String reminderSentSnackbar(String name) {
    return 'Нагадування для $name надіслано';
  }

  @override
  String get independentAccountLabel => 'Незалежний обліковий запис';

  @override
  String get missedLabel => 'Пропущено';

  @override
  String missedCountLabel(int count) {
    return 'Пропущено $count';
  }

  @override
  String get remindAction => '🔔 Нагадати';

  @override
  String removePeerConfirmTitle(String name) {
    return 'Прибрати \"$name\"?';
  }

  @override
  String get removePeerConfirmBody =>
      'Ви обидва втратите доступ до даних, якими ділились одне з одним.';

  @override
  String get confirmGuardianConsentSnackbar =>
      'Підтвердіть, що ви маєте право вести дані цієї людини';

  @override
  String get nameFieldLabel => 'ІМʼЯ';

  @override
  String get avatarFieldLabel => 'АВАТАР';

  @override
  String get memberNameHint => 'Мама, Тато, Бабуся…';

  @override
  String get guardianConsentCheckbox =>
      'Я є законним представником цієї людини або отримав(-ла) її згоду на ведення її даних у застосунку';

  @override
  String get debugLogTitle => 'Журнал подій';

  @override
  String get debugLogEmptyBody => 'Лог порожній.';

  @override
  String get debugLogEmptySnackbar => 'Лог порожній';

  @override
  String get debugLogShareSubject => 'Elly — журнал подій';

  @override
  String get clearAction => 'Очистити';

  @override
  String get shareAction => 'Поділитись';

  @override
  String get antiStressLabel => 'Антистрес-вправи';

  @override
  String get antiStressPickerSubtitle => 'Обери, що допоможе прямо зараз';

  @override
  String get breathingExerciseTitle => 'Дихаймо разом';

  @override
  String get breathingExerciseSubtitle =>
      'Повільне дихання за 2 хвилини заспокоює нервову систему';

  @override
  String get grounding54321Title => '5-4-3-2-1';

  @override
  String get grounding54321Subtitle =>
      'Техніка заземлення — повертає увагу в тут-і-зараз';

  @override
  String get clearMindTitle => 'Чистий розум';

  @override
  String get clearMindPickerSubtitle =>
      'Проведи пальцем по екрану — і туман розвіється';

  @override
  String get breathingScreenHeaderLabel => 'Хвилинка спокою';

  @override
  String get breathingDoneBody => 'Молодець! Ти впорався(-лась).';

  @override
  String breathingCyclesLeftBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count циклів',
      few: '$count цикли',
      one: '$count цикл',
    );
    return 'Повільний вдих... і видих. Ще $_temp0.';
  }

  @override
  String get restartAction => 'Ще раз';

  @override
  String get inhaleLabel => 'Вдих';

  @override
  String get exhaleLabel => 'Видих';

  @override
  String get safeYouTitle => 'Ти в безпеці';

  @override
  String get safeYouSubtitle => 'Тривога мине. Еллі поруч, поки тобі потрібно.';

  @override
  String get differentExerciseAction => 'Інша вправа';

  @override
  String get feelBetterAction => 'Мені краще';

  @override
  String get clearMindHeading => 'Розвій туман';

  @override
  String get clearMindInstructions =>
      'Проведи пальцем по екрану, щоб побачити, що ховається за туманом';

  @override
  String get clearMindTouchHint => '👆 Торкнись і веди пальцем';

  @override
  String get familyVisibilityLabel => 'Видимість для сім\'ї';

  @override
  String get familyVisibilityEmptyBody =>
      'Якщо до вашої сімейної групи приєднаються автономні учасники (зі своїм акаунтом), тут можна буде керувати їхнім доступом до вашого профілю';

  @override
  String get familyVisibilityIntro =>
      'Що бачать і можуть робити інші члени сім\'ї з вашим профілем';

  @override
  String get medcardSyncToggleLabel =>
      'Синхронізувати медкартку на інші пристрої';

  @override
  String get medcardSyncDescription =>
      'Якщо вимкнено, алергії, хронічні захворювання, щеплення, операції, аналізи й візити цього профілю (разом із вкладеннями) не передаються на інші пристрої сім\'ї, підключені через пейринг. Ліки й розклад прийому синхронізуються незалежно від цього перемикача.';

  @override
  String get pendingConnectionLabel => 'Очікуємо з\'єднання';

  @override
  String get viewerNotifyPermissionLabel => 'Отримує сповіщення';

  @override
  String get viewerEditPermissionLabel => 'Може редагувати профіль';

  @override
  String get viewerViewPermissionLabel =>
      'Бачить завдання, медкартку й розклад';

  @override
  String get permissionDeniedNotYoursBody =>
      'Не вдалося змінити — це не ваш профіль';

  @override
  String get voiceConsentTitle => 'Голосові команди';

  @override
  String get voiceConsentDescription =>
      'Розпізнавання голосу через Anthropic (Claude) — додавання ліків, відмітки прийому та інші голосові команди.';

  @override
  String get scanConsentTitle => 'Сканування рецептів';

  @override
  String get scanConsentDescription =>
      'Розпізнавання фото рецепта чи упаковки через Anthropic (Claude) — визначення назви, дозування, форми випуску.';

  @override
  String get privacyLabel => 'Конфіденційність';

  @override
  String get securityLabel => 'Безпека';

  @override
  String get privacyPolicyLabel => 'Політика конфіденційності';

  @override
  String get aiConsentSectionLabel => 'Згоди на обробку даних AI-функціями';

  @override
  String get consentRevokeNoteBody =>
      'Скасування згоди не видаляє вже оброблені дані — воно лише означає, що перед наступним використанням цієї функції застосунок знову запитає підтвердження.';

  @override
  String get dangerZoneLabel => 'Небезпечна зона';

  @override
  String get deleteProfileForeverLabel => 'Видалити профіль назавжди';

  @override
  String deleteProfileForeverBody(String name) {
    return 'Видалить усі дані профілю \"$name\" — локально і на сервері, якщо налаштований обмін';
  }

  @override
  String get appLockToggleLabel => 'Блокування застосунку';

  @override
  String get appLockDescription =>
      'Face ID, Touch ID або пароль пристрою при кожному відкритті Elly';

  @override
  String policyAcceptedLabel(String date, String version) {
    return 'Прийнято $date · версія $version';
  }

  @override
  String policyAcceptedOldVersionLabel(String version) {
    return 'Прийнято стару версію ($version) — буде запропоновано погодитись знову';
  }

  @override
  String get policyNotAcceptedLabel => 'Ще не прийнято';

  @override
  String get viewFullTextAction => 'Переглянути повний текст';

  @override
  String consentGivenLabel(String date) {
    return 'Надано $date';
  }

  @override
  String get consentNotGivenLabel => 'Згоду не надано';

  @override
  String get revokeConsentAction => 'Скасувати згоду';

  @override
  String get groundStep5Title => '5 речей, які ти бачиш';

  @override
  String get groundStep5Hint => 'Одна річ, напр. вікно';

  @override
  String get groundStep4Title => '4 речі, які можеш відчути на дотик';

  @override
  String get groundStep4Hint => 'Одна річ, напр. тканина светра';

  @override
  String get groundStep3Title => '3 звуки, які ти чуєш';

  @override
  String get groundStep3Hint => 'Один звук, напр. гудіння холодильника';

  @override
  String get groundStep2Title => '2 запахи, які відчуваєш';

  @override
  String get groundStep2Hint => 'Один запах, напр. кава';

  @override
  String get groundStep1Title => '1 смак, які відчуваєш';

  @override
  String get groundStep1Hint => 'Один смак, напр. м\'ята';

  @override
  String groundingNameStepLabel(String title) {
    return 'Назви $title';
  }

  @override
  String groundingProgressCounter(int count, int total) {
    return '$count / $total названо';
  }

  @override
  String get groundingListeningLabel => 'Слухаю…';

  @override
  String get groundingSkipStepAction => 'Пропустити цей крок';

  @override
  String get groundingCompletedTitle => 'Ти повернувся(-лась) у тут-і-зараз';

  @override
  String get groundingCompletedSubtitle =>
      'Чудова робота. Повертайся до цієї вправи, коли знадобиться.';

  @override
  String get healthSectionHeader => 'Здоров\'я та вправи';

  @override
  String get appSettingsSectionHeader => 'Налаштування додатку';

  @override
  String get accountSectionHeader => 'Акаунт';

  @override
  String get otherSectionHeader => 'Інше';

  @override
  String get backupDisabledTitle => 'Резервна копія вимкнена';

  @override
  String get backupDisabledBody =>
      'Дані зберігаються лише на цьому пристрої — увімкніть, щоб не втратити їх';

  @override
  String get connectFamilyTitle => 'Підключіть Сім\'я';

  @override
  String get connectFamilySubtitle => 'Турбуйтесь про всю родину';

  @override
  String get planFreeLabel => 'Безкоштовний план';

  @override
  String get planPlusLabel => 'Elly Plus';

  @override
  String get planFamilyLabel => 'Elly Family';

  @override
  String get languageLabel => 'Мова';

  @override
  String get voiceLanguageDescription =>
      'Керує мовою інтерфейсу та розпізнавання голосу (голосове управління, запис самопочуття). Поки доступні українська та англійська — інші мови з\'являться після перекладів.';

  @override
  String get fontSizeLabel => 'Розмір шрифту';

  @override
  String get fontSizeSampleLabel => 'Аа';

  @override
  String get notificationsLabel => 'Сповіщення';

  @override
  String get plansLabel => 'Тарифи';

  @override
  String get backupLabel => 'Резервна копія';

  @override
  String get rateAppLabel => 'Оцінити застосунок';

  @override
  String get helpFaqLabel => 'Допомога та FAQ';

  @override
  String get exportDataLabel => 'Експорт даних';

  @override
  String get logoutLabel => 'Вийти з акаунту';

  @override
  String get logoutConfirmTitle => 'Вийти з акаунту?';

  @override
  String get logoutConfirmBody =>
      'Усі дані будуть видалені з цього пристрою. Цю дію неможливо скасувати.';

  @override
  String get logoutConfirmAction => 'Вийти';

  @override
  String get editProfileTitle => 'Редагувати профіль';

  @override
  String get yourNameHint => 'Ваше ім\'я';

  @override
  String get saveAction => 'Зберегти';

  @override
  String get appointmentsHistoryTitle => 'Візити до лікарів';

  @override
  String get sectionFuture => 'Майбутні';

  @override
  String get visitPassedLabel => '✓ пройшло';

  @override
  String get arrowRightLabel => '→';

  @override
  String get noRecordsYetTitle => 'Записів ще немає';

  @override
  String get noAppointmentsForSpecialty => 'Немає візитів за цим напрямком';

  @override
  String get tryDifferentSpecialtyHint =>
      'Спробуйте обрати інший напрямок або скиньте фільтр';

  @override
  String get tapToAddFirstHint => 'Натисніть \"+ Додати\" щоб створити перший';

  @override
  String get meCapsLabel => 'Я';

  @override
  String get monthAbbrJan => 'СІЧ';

  @override
  String get monthAbbrFeb => 'ЛЮТ';

  @override
  String get monthAbbrMar => 'БЕР';

  @override
  String get monthAbbrApr => 'КВІ';

  @override
  String get monthAbbrMay => 'ТРА';

  @override
  String get monthAbbrJun => 'ЧЕР';

  @override
  String get monthAbbrJul => 'ЛИП';

  @override
  String get monthAbbrAug => 'СЕР';

  @override
  String get monthAbbrSep => 'ВЕР';

  @override
  String get monthAbbrOct => 'ЖОВ';

  @override
  String get monthAbbrNov => 'ЛИС';

  @override
  String get monthAbbrDec => 'ГРУ';

  @override
  String get remindBefore1Hour => 'За 1 годину';

  @override
  String get remindBefore1Day => 'За день';

  @override
  String get remindBefore2Days => 'За 2 дні';

  @override
  String get deleteAppointmentBody => 'Запис до лікаря буде видалено.';

  @override
  String get enterDoctorTypeError => 'Введіть тип лікаря';

  @override
  String get recordVisitTitle => 'Записати візит';

  @override
  String get newAppointmentTitle => 'Запис до лікаря';

  @override
  String get fieldWhere => 'Де';

  @override
  String get locationHint => 'Клініка, адреса або онлайн';

  @override
  String get fieldDateTime => 'Дата та час';

  @override
  String get dateCapsLabel => 'ДАТА';

  @override
  String get timeCapsLabel => 'ЧАС';

  @override
  String get remindBeforeLabel => 'Нагадати заздалегідь';

  @override
  String get doctorConclusionLabel => 'Висновок лікаря';

  @override
  String get noteSingularLabel => 'Нотатка';

  @override
  String get doctorConclusionHint =>
      'Що сказав лікар, рекомендації, призначення…';

  @override
  String get apptNoteHint => 'Що запитати, взяти з собою, номер поліса…';

  @override
  String get saveVisitAction => 'Зберегти візит';

  @override
  String get saveReminderAction => 'Зберегти нагадування';

  @override
  String get monthGenJan => 'січня';

  @override
  String get monthGenFeb => 'лютого';

  @override
  String get monthGenMar => 'березня';

  @override
  String get monthGenApr => 'квітня';

  @override
  String get monthGenMay => 'травня';

  @override
  String get monthGenJun => 'червня';

  @override
  String get monthGenJul => 'липня';

  @override
  String get monthGenAug => 'серпня';

  @override
  String get monthGenSep => 'вересня';

  @override
  String get monthGenOct => 'жовтня';

  @override
  String get monthGenNov => 'листопада';

  @override
  String get monthGenDec => 'грудня';

  @override
  String get symptomsTitle => 'Симптоми';

  @override
  String get symptomSearchHint => 'Пошук або нова назва…';

  @override
  String get symptomListEmptyLabel => 'Список порожній';

  @override
  String addCustomSymptomLabel(String query) {
    return 'Додати «$query»';
  }

  @override
  String get historyLabel => 'Історія';

  @override
  String get wellbeingScheduleInfoText =>
      'Налаштуйте розклад збору зрізів самопочуття. У призначений час на головному екрані з\'явиться картка для заповнення.';

  @override
  String get frequencyPerDayLabel => 'ЧАСТОТА НА ДЕНЬ';

  @override
  String get collectionTimeLabel => 'ЧАС ЗБОРУ';

  @override
  String wellbeingSlotNumberLabel(int index) {
    return 'Зріз $index';
  }

  @override
  String timesCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count разів',
      few: '$count рази',
      one: '$count раз',
    );
    return '$_temp0';
  }

  @override
  String get saveScheduleAction => 'Зберегти розклад';

  @override
  String get wellbeingByDaySubtitle => 'самопочуття по днях';

  @override
  String get addWellbeingSlotAction => '+ Зріз';

  @override
  String moodChartTitle(String month) {
    return 'Настрій — $month';
  }

  @override
  String get monthNomJan => 'січень';

  @override
  String get monthNomFeb => 'лютий';

  @override
  String get monthNomMar => 'березень';

  @override
  String get monthNomApr => 'квітень';

  @override
  String get monthNomMay => 'травень';

  @override
  String get monthNomJun => 'червень';

  @override
  String get monthNomJul => 'липень';

  @override
  String get monthNomAug => 'серпень';

  @override
  String get monthNomSep => 'вересень';

  @override
  String get monthNomOct => 'жовтень';

  @override
  String get monthNomNov => 'листопад';

  @override
  String get monthNomDec => 'грудень';

  @override
  String get weekdayFullMon => 'понеділок';

  @override
  String get weekdayFullTue => 'вівторок';

  @override
  String get weekdayFullWed => 'середа';

  @override
  String get weekdayFullThu => 'четвер';

  @override
  String get weekdayFullFri => 'пʼятниця';

  @override
  String get weekdayFullSat => 'субота';

  @override
  String get weekdayFullSun => 'неділя';

  @override
  String get todayLowerLabel => 'сьогодні';

  @override
  String get yesterdayLowerLabel => 'вчора';

  @override
  String quotedCommentLabel(String comment) {
    return '«$comment»';
  }

  @override
  String get noWellbeingLogsTitle => 'Зрізів ще немає';

  @override
  String get noWellbeingLogsHint => 'Натисніть \"+ Зріз\" щоб додати перший';

  @override
  String get comingSoonEllipsis => 'Скоро...';

  @override
  String get sendDiaryToDoctorLabel => 'Відправити щоденник лікарю';

  @override
  String get diarySummaryHint => 'Зрізи + симптоми + прийоми за місяць';

  @override
  String get moodBadLabel => 'Погано';

  @override
  String get moodMehLabel => 'Так собі';

  @override
  String get moodOkLabel => 'Норм';

  @override
  String get moodGoodLabel => 'Добре';

  @override
  String get moodGreatLabel => 'Відмінно';

  @override
  String get chooseWellbeingErrorSnackbar => 'Оберіть самопочуття';

  @override
  String get wellbeingSlotMorning => 'ранковий зріз';

  @override
  String get wellbeingSlotAfternoon => 'денний зріз';

  @override
  String get wellbeingSlotEvening => 'вечірній зріз';

  @override
  String get howAreYouFeelingLabel => 'Як ви себе почуваєте?';

  @override
  String get anySymptomsLabel => 'Є симптоми?';

  @override
  String get chooseFromListOrAddLabel =>
      'Оберіть зі списку поширених або додайте своє';

  @override
  String get symptomsNotSelectedLabel => 'Симптоми не обрано';

  @override
  String get commentLabel => 'Коментар';

  @override
  String get optionalSuffixLabel => '· необов\'язково';

  @override
  String get orTypeTextLabel => 'або введіть текстом';

  @override
  String get describeFeelingHint => 'Опишіть як себе почуваєте…';

  @override
  String get saveWellbeingCheckAction => 'Зберегти зріз';

  @override
  String get voiceTranscriptLabel => 'Розшифровка голосу';

  @override
  String get editableTextBelowHint => 'Текст можна редагувати нижче в полі';

  @override
  String get recordAgainAction => 'Записати знову';

  @override
  String get dictateCommentLabel => 'Надиктуйте коментар';

  @override
  String get micUnavailableLabel => 'Мікрофон недоступний';

  @override
  String get tapAndSpeakLabel => 'Натисніть і говоріть';

  @override
  String get speakNowLabel => 'Говоріть… натисніть щоб зупинити';

  @override
  String get preparingMicLabel => 'Готуємось… зачекайте секунду';

  @override
  String get symptomHeadache => 'головний біль';

  @override
  String get symptomNausea => 'нудота';

  @override
  String get symptomDizziness => 'запаморочення';

  @override
  String get symptomWeakness => 'слабість';

  @override
  String get symptomShortnessOfBreath => 'задишка';

  @override
  String get symptomRash => 'висип';

  @override
  String get symptomPain => 'біль';

  @override
  String get symptomFever => 'температура';

  @override
  String get symptomCough => 'кашель';

  @override
  String get symptomSoreThroat => 'біль у горлі';

  @override
  String get symptomRunnyNose => 'нежить';

  @override
  String get symptomStuffyNose => 'закладеність носа';

  @override
  String get symptomSneezing => 'чхання';

  @override
  String get symptomVomiting => 'блювота';

  @override
  String get symptomDiarrhea => 'діарея';

  @override
  String get symptomConstipation => 'запор';

  @override
  String get symptomBloating => 'здуття живота';

  @override
  String get symptomHeartburn => 'печія';

  @override
  String get symptomStomachPain => 'біль у животі';

  @override
  String get symptomLossOfAppetite => 'втрата апетиту';

  @override
  String get symptomIncreasedAppetite => 'підвищений апетит';

  @override
  String get symptomInsomnia => 'безсоння';

  @override
  String get symptomDrowsiness => 'сонливість';

  @override
  String get symptomFatigue => 'втома';

  @override
  String get symptomChestPain => 'біль у грудях';

  @override
  String get symptomPalpitations => 'прискорене серцебиття';

  @override
  String get symptomHighBloodPressure => 'підвищений тиск';

  @override
  String get symptomLowBloodPressure => 'знижений тиск';

  @override
  String get symptomBackPain => 'біль у спині';

  @override
  String get symptomJointPain => 'біль у суглобах';

  @override
  String get symptomMusclePain => 'біль у м\'язах';

  @override
  String get symptomCramps => 'судоми';

  @override
  String get symptomSwelling => 'набряки';

  @override
  String get symptomItching => 'свербіж';

  @override
  String get symptomDrySkin => 'сухість шкіри';

  @override
  String get symptomBruising => 'синці';

  @override
  String get symptomDryMouth => 'сухість у роті';

  @override
  String get symptomExcessiveSweating => 'підвищена пітливість';

  @override
  String get symptomChills => 'озноб';

  @override
  String get symptomBlurredVision => 'розмитий зір';

  @override
  String get symptomRingingInEars => 'дзвін у вухах';

  @override
  String get symptomNumbness => 'оніміння';

  @override
  String get symptomTremor => 'тремтіння';

  @override
  String get symptomMemoryIssues => 'проблеми з пам\'яттю';

  @override
  String get symptomConcentrationIssues => 'проблеми з концентрацією';

  @override
  String get symptomAnxiety => 'тривожність';

  @override
  String get symptomIrritability => 'дратівливість';

  @override
  String get symptomMoodSwings => 'перепади настрою';

  @override
  String get symptomWeightLoss => 'втрата ваги';

  @override
  String get symptomWeightGain => 'набір ваги';

  @override
  String get restoreErrorBody =>
      'Не вдалося відновити: перевірте пароль і з\'єднання, спробуйте ще раз';

  @override
  String get backupPasswordDialogTitle => 'Пароль резервної копії';

  @override
  String get backupPasswordDialogBody =>
      'Введіть пароль, який ви вказали при створенні резервної копії.';

  @override
  String get passwordFieldLabel => 'Пароль';

  @override
  String get restoreAccountTitle => 'Відновити акаунт';

  @override
  String get restoreAccountSubtitle =>
      'Підключіться до сховища, де зберігається ваша резервна копія';

  @override
  String get googleDriveLabel => 'Google Drive';

  @override
  String get iCloudLabel => 'iCloud';

  @override
  String get doneExclamationTitle => 'Готово!';

  @override
  String get setupCompleteBody =>
      'Все налаштовано. Відкрийте дашборд і почніть стежити за здоров\'ям.';

  @override
  String get firstReminderTodayLabel => 'Перше нагадування — сьогодні';

  @override
  String get noRemindersYetLabel => 'Нагадувань поки немає';

  @override
  String get reminderWillArriveLabel =>
      'Нагадування прийде за розкладом, який ви щойно додали';

  @override
  String get setupMedsToActivateLabel =>
      'Налаштуйте ліки щоб активувати нагадування';

  @override
  String get privacyConsentPrefix => 'Я ознайомлений(-а) і згоден(-а) з ';

  @override
  String get privacyConsentSuffix => ' застосунку';

  @override
  String get openDashboardAction => 'Відкрити дашборд →';

  @override
  String get joinFailedCheckCodeError =>
      'Не вдалося приєднатись: перевірте код';

  @override
  String get connectToFamilyTitle => 'Підключення до сім\'ї';

  @override
  String get enterAccessCodeHint =>
      'Введіть код доступу, який вам надіслали рідні';

  @override
  String get checkingEllipsisLabel => 'Перевірка...';

  @override
  String get scheduleAlreadyReadyTitle => 'Розклад уже готовий';

  @override
  String scheduleSetByInviterBody(String name) {
    return '$name уже склав(-ла) для вас розклад прийому ліків. Ви зможете відредагувати його будь-коли після підключення.';
  }

  @override
  String get agreeUseFamilyScheduleCheckbox =>
      'Я погоджуюсь використати розклад, складений моєю сім\'єю';

  @override
  String get startAction => 'Почати';

  @override
  String get creatingEllipsisLabel => 'Створюємо...';

  @override
  String get declineScheduleCreateOwnAction =>
      'Не згоден, створити свій розклад';

  @override
  String get familyFallbackName => 'Родина';

  @override
  String get profileFallbackName => 'Профіль';

  @override
  String get enterYourNameError => 'Введіть своє ім\'я';

  @override
  String get walkActivityName => 'Прогулянка';

  @override
  String onboardingFinishError(String error) {
    return 'Помилка при завершенні: $error';
  }

  @override
  String get welcomeGreeting => 'Привіт! 👋';

  @override
  String get welcomeDescription =>
      'Elly допоможе не забути про ліки,\nактивність і самопочуття — для вас\nі всієї родини';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Крок $step з $total';
  }

  @override
  String get accountChoiceTitle => 'Як почнемо?';

  @override
  String get accountChoiceSubtitle => 'Оберіть варіант, який вам підходить';

  @override
  String get createAccountTitle => 'Створити акаунт';

  @override
  String get createAccountSubtitle => 'Налаштую ліки та розклад для себе';

  @override
  String get joinFamilyChoiceTitle => 'Підключитися до сім\'ї';

  @override
  String get joinFamilyChoiceSubtitle => 'У мене є код доступу від рідних';

  @override
  String get restoreAccountChoiceSubtitle =>
      'Я вже користувався(-лась) Elly раніше';

  @override
  String get tellAboutYourselfTitle => 'Розкажіть про себе';

  @override
  String get tellAboutYourselfSubtitle =>
      'Вкажіть своє ім\'я та оберіть аватар профілю';

  @override
  String get nextToMedsAction => 'Далі — ліки →';

  @override
  String get scanOrEnterManuallyHint =>
      'Скануйте фото рецепта або введіть вручну';

  @override
  String get addMedsShortAction => 'Додати ліки';

  @override
  String get addMoreMedsAction => 'Додати ще ліки';

  @override
  String get addMedsHint =>
      'Скан фото рецепта або назва, доза і розклад вручну';

  @override
  String get addMedsLaterInfo =>
      'Ліки можна додати пізніше через розділ «Ліки» в головному меню';

  @override
  String get nextAction => 'Далі →';

  @override
  String get skipAddLaterAction => 'Пропустити — додам пізніше';

  @override
  String get activityWellbeingTitle => 'Активність та самопочуття';

  @override
  String get activityWellbeingSubtitle =>
      'Увімкніть одним перемикачем — налаштування можна змінити пізніше';

  @override
  String get activitySectionLabel => 'Активність';

  @override
  String get walkActivitySub => '30 хв · щодня · 08:30';

  @override
  String get wellbeingDiaryLabel => 'Щоденник самопочуття';

  @override
  String get wellbeingDiaryDescription =>
      'Короткі відмітки самопочуття допоможуть побачити звʼязок між прийомом ліків і тим, як ви почуваєтесь';

  @override
  String get wellbeingSlotsTitle => 'Зрізи самопочуття';

  @override
  String get wellbeingSlotsSub => '2–3 рази на день · 08:00, 14:00, 20:00';

  @override
  String get almostDoneAction => 'Майже готово →';

  @override
  String get scanNoResultsError =>
      'Не вдалося розпізнати ліки на фото. Спробуйте зробити чіткіше фото.';

  @override
  String scanErrorWithMessage(String error) {
    return 'Помилка сканування: $error';
  }

  @override
  String get scanPrescriptionScreenTitle => 'Сканувати рецепт';

  @override
  String get beforeYouStartTitle => 'Перш ніж почати';

  @override
  String get scanConsentDisclaimerBody =>
      'Щоб розпізнати ліки, фото рецепта чи упаковки надсилається сервісу Anthropic (Claude). Фото використовується лише для розпізнавання і ніде не зберігається після відповіді.';

  @override
  String get scanDosageWarningPrefix =>
      '⚠️ Дозування, розклад і довідкова інформація про побічні ефекти — орієнтовні. ';

  @override
  String get alwaysCheckInstructionsLabel =>
      'Завжди звіряйте з інструкцією до препарату.';

  @override
  String get understoodAgreeAction => 'Зрозуміло, погоджуюсь';

  @override
  String get takePhotoInstructionsBody =>
      'Сфотографуйте рецепт або упаковку. Можна додати кілька фото, якщо ліків декілька.';

  @override
  String get cameraLabel => 'Камера';

  @override
  String get galleryLabel => 'Галерея';

  @override
  String get scanAction => 'Сканувати';

  @override
  String scanRecognizedCountLabel(int count) {
    return 'Розпізнано $count. Перевірте перед додаванням:';
  }

  @override
  String get expandAndConfirmHint =>
      'Розгорніть препарат, перевірте дані і поставте галочку, щоб підтвердити додавання.';

  @override
  String get chooseMedsAction => 'Оберіть препарати';

  @override
  String addSelectedCountAction(int count) {
    return 'Додати обрані ($count)';
  }

  @override
  String get scheduleTimeMorning => 'Вранці';

  @override
  String get scheduleTimeAfternoon => 'Вдень';

  @override
  String get scheduleTimeEvening => 'Ввечері';

  @override
  String get scheduleTimeNight => 'Вночі';

  @override
  String get unnamedMedLabel => 'Без назви';

  @override
  String get medNameCapsLabel => 'НАЗВА';

  @override
  String get releaseFormCapsLabel => 'ФОРМА ВИПУСКУ';

  @override
  String get doseCapsLabel => 'ДОЗА';

  @override
  String get courseDurationCapsLabel => 'ТРИВАЛІСТЬ КУРСУ';

  @override
  String get foodRelationCapsLabel => 'ЗВ\'ЯЗОК З ЇЖЕЮ';

  @override
  String possibleSideEffectsPrefix(String list) {
    return '⚡ Можливі побічні ефекти: $list. ';
  }

  @override
  String get checkInstructionsShortLabel =>
      'Звірте з інструкцією до препарату.';

  @override
  String get confirmedCheckLabel => 'Підтверджено ✓';

  @override
  String get confirmAllCorrectAction => 'Все вірно, підтвердити';

  @override
  String get somethingWentWrongTitle => 'Щось пішло не так';

  @override
  String sttErrorLabel(String error) {
    return 'STT помилка: $error';
  }

  @override
  String get speechNotAvailableError =>
      'Розпізнавання мови недоступне на цьому пристрої';

  @override
  String get nothingHeardError => 'Нічого не почуто. Спробуй ще раз.';

  @override
  String analysisErrorWithMessage(String error) {
    return 'Помилка аналізу: $error';
  }

  @override
  String get commandNotRecognizedError => 'Не вдалося розпізнати команду';

  @override
  String get voiceControlTitle => 'Голосове управління';

  @override
  String get voiceConsentDisclaimerBody =>
      'Розпізнавання голосу відбувається на пристрої. Але щоб зрозуміти команду, текст твоєї фрази надсилається сервісу Anthropic (Claude). Ця функція розпізнає лише 3 команди: додати ліки, додати активність або запис до лікаря — вільний опис самопочуття чи симптомів сюди ніколи не відправляється, для цього є окреме поле в щоденнику самопочуття, яке лишається тільки на пристрої.';

  @override
  String get voiceExampleMedQuote =>
      '\"Додай Еналаприл 10 мг вранці та ввечері\"';

  @override
  String get voiceExampleMedDesc =>
      'Відкриє форму ліків із заповненими полями. Розпізнає не всі препарати — перевірте поля перед збереженням.';

  @override
  String get voiceExampleActivityQuote =>
      '\"Додай зарядку двічі на день вранці і ввечері\"';

  @override
  String get voiceExampleActivityDesc =>
      'Відкриє форму активності із заповненими полями';

  @override
  String get voiceExampleApptQuote => '\"Запис до кардіолога у пʼятницю о 10\"';

  @override
  String get voiceExampleApptDesc => 'Відкриє форму запису до лікаря';

  @override
  String get whatToDoTitle => 'Що хочеш зробити?';

  @override
  String get tapAndSayCommandHint =>
      'Натисни і скажи команду\nабо почни говорити';

  @override
  String dictateLanguageHint(String language) {
    return 'Диктуйте мовою $language. Змінити можна в Профіль → Мова.';
  }

  @override
  String get commandExamplesCapsLabel => 'ПРИКЛАДИ КОМАНД';

  @override
  String get experimentalFeatureNotice =>
      'Це експериментальна функція — розпізнавання може заповнити дані неточно, завжди перевіряйте форму перед збереженням.';

  @override
  String get holdAndSpeakAction => 'Утримуй і говори';

  @override
  String get listeningEllipsisLabel => 'Слухаю...';

  @override
  String get preparingEllipsisLabel => 'Готуємось...';

  @override
  String get tapMicToStopHint => 'Натисни на мікрофон щоб зупинити';

  @override
  String get waitBeforeSpeakingHint =>
      'Зачекайте секунду перед тим, як говорити';

  @override
  String quotedTextLabel(String text) {
    return '\"$text\"';
  }

  @override
  String get analyzingCommandLabel => 'Аналізую команду...';

  @override
  String get actionCapsLabel => 'ДІЯ';

  @override
  String get drugCapsLabel => 'ПРЕПАРАТ';

  @override
  String get activityCapsLabel => 'АКТИВНІСТЬ';

  @override
  String get scheduleCapsLabel => 'РОЗКЛАД';

  @override
  String get doctorCapsLabel => 'ЛІКАР';

  @override
  String get addActivityActionLabel => 'Додати активність';

  @override
  String get unknownCommandLabel => 'Невідома команда';

  @override
  String get youSaidCapsLabel => 'ТИ СКАЗАВ';

  @override
  String get iUnderstoodLabel => 'Я зрозумів так:';

  @override
  String get clarifyOneMoreLabel => 'Уточни ще одне';

  @override
  String get foodRelationClarifyHint =>
      'Ти не сказав, до чи після їжі. Вибери нижче або пропусти';

  @override
  String get foodOptBefore => 'До їжі';

  @override
  String get foodOptAfter => 'Після їжі';

  @override
  String get foodOptNotImportant => 'Не важливо';

  @override
  String get refFoodAnyLabel => 'Незалежно від їжі';

  @override
  String possibleSideEffectsLabel(String list) {
    return '⚡ Можливі побічні ефекти: $list';
  }

  @override
  String get referenceInfoDisclaimer =>
      '⚠️ Довідково, не гарантовано. Звірте з інструкцією до препарату.';

  @override
  String get nextShortAction => 'Далі';

  @override
  String get backupScreenTitle => 'Резервна копія';

  @override
  String get backupIntroBody =>
      'Ліки, розклад, медкартка (фото/PDF) і всі інші дані — обирайте, де зберігати резервну копію.';

  @override
  String get backupModeLocalTitle => 'Тільки на пристрої';

  @override
  String get backupModeLocalSubtitle =>
      'При перевстановленні застосунку всі дані буде втрачено';

  @override
  String get backupModeGoogleDriveSubtitle =>
      'Зашифровано на пристрої — Elly і Google не бачать ваші дані';

  @override
  String get backupModeICloudSubtitle =>
      'Зашифровано на пристрої — Elly і Apple не бачать ваші дані';

  @override
  String get backupFrequencyCapsLabel => 'ЧАСТОТА АВТОБЕКАПУ';

  @override
  String get backupFrequencyDailyLabel => 'Раз на день';

  @override
  String get backupFrequencyWeeklyLabel => 'Раз на тиждень';

  @override
  String get backupFrequencyExplainerBody =>
      'Спрацьовує, коли ви відкриваєте застосунок чи повертаєтесь у нього — це не справжній фоновий розклад. Якщо не відкривати Elly довше обраної частоти, бекап зробиться одразу при наступному відкритті.';

  @override
  String get backupNeverDoneLabel => 'Резервної копії ще не було';

  @override
  String lastBackupAtLabel(String date) {
    return 'Останній бекап: $date';
  }

  @override
  String get createBackupNowAction => 'Створити резервну копію зараз';

  @override
  String get restoreFromBackupAction => 'Відновити з резервної копії';

  @override
  String get changeBackupPassphraseAction => 'Змінити пароль резервної копії';

  @override
  String get backupPassphraseDialogTitle => 'Пароль для резервної копії';

  @override
  String get backupPassphraseDialogSubtitle =>
      'Придумайте пароль. Без нього відновити дані буде неможливо — навіть нам.';

  @override
  String backupSavedSnackbar(String target) {
    return 'Резервну копію збережено у $target';
  }

  @override
  String get restorePassphraseDialogTitle => 'Пароль резервної копії';

  @override
  String get restorePassphraseDialogSubtitle =>
      'Введіть пароль, який ви вказали при створенні копії.';

  @override
  String get restoreDoneBody => 'Дані відновлено.';

  @override
  String get restoreFailedError =>
      'Не вдалося відновити: невірний пароль або копія відсутня';

  @override
  String get changePassphraseDialogTitle => 'Новий пароль резервної копії';

  @override
  String get changePassphraseDialogSubtitle =>
      'Одразу після зміни буде створено нову резервну копію з цим паролем — запам\'ятайте його, стару резервну копію під старим паролем більше не можна буде використати.';

  @override
  String get passphraseChangedSnackbar =>
      'Пароль змінено, нову резервну копію збережено';

  @override
  String get confirmRestoreTitle => 'Відновити з резервної копії?';

  @override
  String get confirmRestoreBody =>
      'Поточні дані на цьому пристрої буде замінено даними з резервної копії. Цю дію не можна скасувати.';

  @override
  String get restoreAction => 'Відновити';

  @override
  String get confirmPasswordFieldLabel => 'Повторіть пароль';

  @override
  String get passwordTooShortError =>
      'Пароль має бути не коротшим за 6 символів';

  @override
  String get passwordsMismatchError => 'Паролі не збігаються';

  @override
  String get gotItAction => 'Гаразд';

  @override
  String get choosePlanTitle => 'Обери план';

  @override
  String get choosePlanSubtitle => 'Турбота про здоров\'я всієї сім\'ї';

  @override
  String get monthToggleLabel => 'Місяць';

  @override
  String get yearToggleDiscountLabel => 'Рік −20%';

  @override
  String get familyTiesBrokenTitle => 'Зв\'язки з родиною розірвуться';

  @override
  String get familyTiesBrokenBody =>
      'Учасники вашої сімейної групи одразу втратять доступ до плюшок Family і перестануть бачити одне одного. Це станеться миттєво, без грейс-періоду — ви вже попереджені зараз.';

  @override
  String get breakAndChangePlanAction => 'Розірвати і змінити план';

  @override
  String planActivatedTestSnackbar(String plan) {
    return '$plan активовано (тестовий режим, без реальної оплати)';
  }

  @override
  String actionFailedError(String error) {
    return 'Не вдалося: $error';
  }

  @override
  String get planForeverPeriod => 'назавжди';

  @override
  String get planPerMonthYearlyPeriod => 'на місяць (рік)';

  @override
  String get planPerMonthPeriod => 'щомісяця';

  @override
  String get freeFeatureAllSections => 'Всі розділи без обмежень';

  @override
  String get freeFeatureUnlimitedMeds => 'Необмежено ліків і медкарток';

  @override
  String get freeFeatureScanLimit => '3 сканування фото рецепта';

  @override
  String get freeFeatureVoiceLimit => '5 голосових команд';

  @override
  String get freeFeatureLocalBackup => 'Локально + копія в Google Drive/iCloud';

  @override
  String get selectFreeAction => 'Обрати Безкоштовний';

  @override
  String get plusFeatureAllFree => 'Все з безкоштовного';

  @override
  String get plusFeatureUnlimitedScans => 'Необмежені сканування фото';

  @override
  String get plusFeatureUnlimitedVoice => 'Необмежені голосові команди';

  @override
  String get plusFeatureServerSync => 'Синхронізація з сервером (зашифровано)';

  @override
  String get plusFeatureUnlimitedProfiles =>
      'Необмежена кількість локальних профілів';

  @override
  String get selectPlusAction => 'Обрати Plus';

  @override
  String get familyFeatureAllPlus => 'Все з Elly Plus';

  @override
  String get familyFeatureAutonomousProfiles => 'Автономні профілі — до 8 осіб';

  @override
  String get familyFeatureSelfManaged => 'Кожен керує своїм профілем сам';

  @override
  String get selectFamilyAction => 'Обрати Family';

  @override
  String get billingTermsDisclaimer =>
      'Оплата списується з вашого облікового запису App Store чи Google Play. Підписка автоматично продовжується на новий період за тією самою ціною, якщо не скасувати щонайменше за 24 години до завершення періоду. Керувати підпискою та скасувати автопродовження можна в налаштуваннях облікового запису App Store · Google Play.';

  @override
  String get privacyPolicyLinkLabel => 'Політика конфіденційності';

  @override
  String get termsOfUseLinkLabel => 'Умови використання';

  @override
  String get currentPlanLabel => 'Поточний';

  @override
  String get tooManyProfilesForPlanTitle => 'Забагато профілів для цього плану';

  @override
  String get upgradeToEditSubtitle =>
      'Продовжіть Elly Plus або Elly Family, щоб редагувати';

  @override
  String get viewPlansAction => 'Переглянути тарифи';

  @override
  String get paymentFailedTitle => 'Не вдалось списати оплату';

  @override
  String gracePeriodRemainingBody(String timeLeft) {
    return 'Залишилось $timeLeft, щоб оновити спосіб оплати — доки що все працює без обмежень, і для вас, і для всіх учасників вашої сімейної групи.';
  }

  @override
  String get gracePeriodExpiredBody =>
      'Оновіть спосіб оплати негайно, інакше сімейна група розірветься.';

  @override
  String get laterAction => 'Пізніше';

  @override
  String get updatePaymentAction => 'Оновити оплату';

  @override
  String get accessChangedTitle => 'Доступ змінився';

  @override
  String get changePlanAction => 'Змінити план';

  @override
  String daysLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів',
      few: '$count дні',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String hoursLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count годин',
      few: '$count години',
      one: '$count годину',
    );
    return '$_temp0';
  }

  @override
  String minutesLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хвилин',
      few: '$count хвилини',
      one: '$count хвилину',
    );
    return '$_temp0';
  }

  @override
  String get planFreeShortLabel => 'Безкоштовний';

  @override
  String get exportShareSubject => 'Elly — експорт даних';

  @override
  String get exportCopyTitle => 'Копія всіх ваших даних';

  @override
  String get exportDescriptionBody =>
      'Файл у форматі JSON з усіма профілями, ліками, розкладом, прийомами, самопочуттям і записами до лікарів — усе, що зберігається на цьому пристрої. Ви можете відкрити його будь-де або передати кому завгодно.\n\nФото ліків у файл не входять (вони вже є у «Резервній копії») — лише текстові дані.';

  @override
  String get exportAction => 'Експортувати';

  @override
  String get appLockedTitle => 'Elly заблоковано';

  @override
  String get authFailedRetryBody =>
      'Не вдалося підтвердити особу — спробуйте ще раз';

  @override
  String get confirmIdentityBody => 'Підтвердіть особу, щоб продовжити';

  @override
  String get checkingDotsLabel => 'Перевірка...';

  @override
  String get unlockAction => 'Розблокувати';

  @override
  String get addTypeSheetTitle => 'Що хочете додати?';

  @override
  String get addTypeSheetSubtitle => 'Оберіть тип — форма підлаштується';

  @override
  String get addTypeMedsSub => 'Розклад, дозування, AI-скан рецепта';

  @override
  String get addTypeActivitySub => 'Прогулянка, зарядка, вправи, ЛФК';

  @override
  String get addTypeWellbeingSub =>
      'Зробити зріз — настрій, симптоми, коментар';

  @override
  String get addTypeAppointmentSub =>
      'Обрати спеціаліста, час та отримати нагадування';

  @override
  String get voiceCommandLabel => 'Голосова команда';

  @override
  String get faqGroupPrivacyTitle => 'Приватність і дані';

  @override
  String get faqPrivacyQ1 => 'Хто бачить мої дані?';

  @override
  String get faqPrivacyA1 =>
      'Ніхто, крім вас. Усе зберігається зашифрованим на вашому пристрої (SQLCipher, AES-256). Сервер Elly навмисно \"сліпий\": реєстрації через email чи пароль немає, а те, що все ж проходить через сервер (запрошення до сім\'ї, синхронізація, підтвердження підписки), бачить лише зашифровані блоки й технічні ідентифікатори — без ключа розшифрувати їх неможливо.';

  @override
  String get faqPrivacyQ2 =>
      'У чому різниця між Резервною копією і Запрошенням до сім\'ї?';

  @override
  String get faqPrivacyA2 =>
      'Резервна копія — знімок ваших власних даних у вашому Google Drive/iCloud на випадок втрати телефону чи перевстановлення застосунку. Запрошення до сім\'ї — живий обмін розкладом між РІЗНИМИ людьми (наприклад, дитина бачить розклад мами) через QR-код чи код запрошення. Це два різні механізми: перший — про вас самих, другий — про спільний доступ між кількома людьми.';

  @override
  String get faqPrivacyQ3 => 'Що буде, якщо я видалю застосунок без бекапу?';

  @override
  String get faqPrivacyA3 =>
      'Дані буде втрачено безповоротно — копії на сервері не існує. Обов\'язково зробіть резервну копію заздалегідь (Профіль → Резервна копія).';

  @override
  String get faqPrivacyQ4 => 'Як видалити свої дані повністю?';

  @override
  String get faqPrivacyA4 =>
      'Видаліть застосунок з пристрою (і резервну копію з Drive/iCloud вручну, якщо створювали). Профіль також можна видалити окремо — Профіль → Конфіденційність → Небезпечна зона.';

  @override
  String get faqGroupFamilyTitle => 'Сім\'я';

  @override
  String get faqFamilyQ1 => 'Як додати члена сім\'ї чи залежний профіль?';

  @override
  String get faqFamilyA1 =>
      'На вкладці \"Сім\'я\" — кнопка додавання профілю. Залежні профілі (діти, батьки похилого віку) не мають власного входу — ними керує власник пристрою.';

  @override
  String get faqFamilyQ2 =>
      'Як передати керування профілем іншій людині (наприклад, дорослій дитині)?';

  @override
  String get faqFamilyA2 =>
      'На картці локального профілю — кнопка \"Запросити в застосунок\": покажіть QR-код чи назвіть код запрошення людині, яка приєднується на своєму пристрої. Профіль перетвориться з локального на автономний — людина відтепер керуватиме ним сама, а вся історія даних збережеться. Дані шифруються ключем, похідним від коду запрошення, — сервер бачить лише зашифрований блок.';

  @override
  String get faqFamilyQ3 => 'Хто що бачить про інших членів сім\'ї?';

  @override
  String get faqFamilyA3 =>
      'Налаштовується в Профіль → Видимість для сім\'ї — окремо для кожного профілю.';

  @override
  String get faqGroupAiTitle => 'AI-функції';

  @override
  String get faqAiQ1 =>
      'Куди йдуть дані при голосовому вводі чи скані рецепта?';

  @override
  String get faqAiA1 =>
      'Розпізнавання відбувається через модель Claude від Anthropic — це явно вказується в запиті згоди перед першим використанням кожної функції. Вільний текстовий опис самопочуття чи симптомів у хмару ніколи не надсилається.';

  @override
  String get faqAiQ2 => 'Наскільки точна довідкова інформація про ліки від AI?';

  @override
  String get faqAiA2 =>
      'Це орієнтовна інформація із загальних знань моделі, а не перевірений медичний каталог. Завжди звіряйте з інструкцією до препарату чи лікарем.';

  @override
  String get faqNotificationsQ1 => 'Чому не приходять нагадування?';

  @override
  String get faqNotificationsA1 =>
      'Найчастіша причина — оптимізація батареї на Android обмежує фонову роботу застосунку. Додайте Elly у виключення в налаштуваннях енергозбереження пристрою. Також перевірте \"Тихі години\" в Профіль → Сповіщення.';

  @override
  String get faqNotificationsQ2 =>
      'Як налаштувати повторне нагадування, якщо не відмітив прийом?';

  @override
  String get faqNotificationsA2 =>
      'Профіль → Сповіщення → \"Повторити якщо нема відповіді\" — виберіть інтервал повзунком.';

  @override
  String get faqPlansQ1 => 'Чим відрізняються тарифи?';

  @override
  String get faqPlansA1 =>
      'Elly (безкоштовний) — базові функції з обмеженнями. Elly Plus і Elly Family знімають ліміти й додають розширені можливості. Деталі — Профіль → Тарифи.';

  @override
  String get faqGroupTechTitle => 'Технічні проблеми';

  @override
  String get faqTechQ1 =>
      'Не працює біометрія / забув пароль від резервної копії';

  @override
  String get faqTechA1 =>
      'Пароль резервної копії запам\'ятовується лише локально на цьому пристрої (щоб автоматичні копії за розкладом не питали його щоразу) — на наші сервери він ніколи не потрапляє. Якщо ви перевстановите застосунок чи зміните пристрій, доведеться ввести той самий пароль вручну; якщо забули його — відновити копію неможливо, доведеться створити нову. Біометрію можна переналаштувати в системних налаштуваннях пристрою.';

  @override
  String get faqTechQ2 => 'Не вдається відновити дані з резервної копії';

  @override
  String get faqTechA2 =>
      'Найчастіша причина — невірний пароль (той самий, який ви вказали при створенні копії) або відсутнє з\'єднання з інтернетом. Перевірте, що відновлюєте копію на відповідному типі пристрою (з iCloud — лише на iOS, з Google Drive — на Android чи iOS). Після успішного відновлення застосунок попросить перезапуститись.';

  @override
  String get faqNotFoundQuestionTitle => 'Не знайшли відповідь?';

  @override
  String get faqWriteUsSubtitle => 'Напишіть нам — відповімо особисто.';

  @override
  String get supportLabel => 'Підтримка';

  @override
  String get supportChatLabel => 'Чат підтримки';

  @override
  String get soonLabel => 'Скоро';

  @override
  String get notificationsMainSectionTitle => 'Основні';

  @override
  String get pushNotificationsLabel => 'Push-сповіщення';

  @override
  String get pushNotificationsSub => 'Нагадування про прийом ліків';

  @override
  String get vibrationLabel => 'Вібрація';

  @override
  String get vibrationSub => 'Разом зі звуком';

  @override
  String get reminderTimeSectionTitle => 'Час нагадувань';

  @override
  String get quietHoursSectionTitle => 'Тихі години';

  @override
  String get doNotDisturbLabel => 'Не турбувати';

  @override
  String get nightModeSub => 'Нічний режим';

  @override
  String get quietFromLabel => 'З';

  @override
  String get quietToLabel => 'До';

  @override
  String get memberMissedAlertsSectionTitle =>
      'Алерти при пропуску членів сімʼї';

  @override
  String get familyNotificationsSectionTitle => 'Сповіщення від сім\'ї';

  @override
  String get peerNotifyExplainerBody =>
      'Ці учасники дозволили надсилати вам сповіщення про себе. Тут ви вирішуєте, чи хочете їх отримувати.';

  @override
  String get reminderOffsetLabel => 'Зсув нагадування';

  @override
  String get reminderOffsetSub => 'Отримувати за N хв до прийому';

  @override
  String get noOffsetLabel => 'без зсуву';

  @override
  String minusMinutesLabel(int minutes) {
    return '−$minutes хв';
  }

  @override
  String get repeatIfNoResponseLabel => 'Повторити якщо нема відповіді';

  @override
  String repeatInLabel(String label) {
    return 'Через $label';
  }

  @override
  String get deleteActivityConfirmTitle => 'Видалити активність?';

  @override
  String get deleteActivityConfirmBody =>
      'Активність буде вилучена з розкладу.';

  @override
  String get chooseActivityTypeError => 'Оберіть тип активності';

  @override
  String get enterActivityNameError => 'Введіть назву активності';

  @override
  String get editActivityTitle => 'Редагувати активність';

  @override
  String get activityTypeLabel => 'Тип активності';

  @override
  String get activityTypeWorkout => 'Зарядка';

  @override
  String get activityTypeGym => 'Тренування';

  @override
  String get activityTypeYoga => 'Йога / ЛФК';

  @override
  String get activityTypeCycling => 'Велосипед';

  @override
  String get activityTypeCustom => 'Своє';

  @override
  String get activityNameHint => 'Назва активності';

  @override
  String get youtubeLinkLabel => 'Посилання на YouTube';

  @override
  String get youtubeLinkDescription =>
      'Відео тренування чи клип — прев\'ю показуватиметься у картці на сьогодні';

  @override
  String get addAnotherActivityAction => 'Додати ще заняття';

  @override
  String get weekdaysLabel => 'Дні тижня';

  @override
  String get reminderLabel => 'Нагадування';

  @override
  String get reminderActivityDescription => 'За 10 хвилин до кожного заняття';

  @override
  String get saveActivityAction => 'Зберегти активність';

  @override
  String activitySessionNumberLabel(int number) {
    return 'Заняття $number';
  }

  @override
  String get noDurationLabel => 'Без тривалості';

  @override
  String saveWithDurationLabel(String duration) {
    return 'Зберегти · $duration';
  }

  @override
  String durationHoursMinutesLabel(int hours, int minutes) {
    return '$hours год $minutes хв';
  }

  @override
  String minutesWithValueLabel(String value) {
    return '$value хв';
  }

  @override
  String get taskColorPickerLabel => 'КОЛІР КАРТКИ';

  @override
  String viewingProfileLabel(String name) {
    return 'Ви дивитесь профіль: $name';
  }

  @override
  String get returnAction => 'Повернутись';

  @override
  String get foodRelationUnspecified => 'Не вибрано';

  @override
  String get foodRelationWith => 'Під час їжі';

  @override
  String get foodRelationPickerTitle => 'Відносно їжі';

  @override
  String get recoveryKeyDialogTitle => 'Ваш recovery key';

  @override
  String get recoveryKeyDialogBody =>
      'Збережіть цей код у надійному місці. Це єдиний спосіб відновити дані на новому пристрої — без нього ми теж не зможемо допомогти.';

  @override
  String get copiedSnackbar => 'Скопійовано';

  @override
  String get recoveryKeySavedConfirmAction => 'Я зберіг(ла) код';

  @override
  String get buyAction => 'Купити';

  @override
  String get affiliateDisclaimerLabel =>
      'Реклама · партнерське посилання, Elly товар не продає';

  @override
  String get legalPageLoadError =>
      'Не вдалося завантажити сторінку. Перевірте з\'єднання з інтернетом.';

  @override
  String get medFormTablet => 'Таблетка';

  @override
  String get medFormCapsule => 'Капсула';

  @override
  String get medFormSuppository => 'Свічі';

  @override
  String get medFormVial => 'Флакон';

  @override
  String get medFormSyrup => 'Сироп';

  @override
  String get medFormDrops => 'Краплі';

  @override
  String get medFormCream => 'Крем';

  @override
  String get medFormInhaler => 'Інгалятор';

  @override
  String get medFormInjection => 'Ін\'єкція';

  @override
  String get medUnitTablet => 'табл.';

  @override
  String get medUnitCapsule => 'капс.';

  @override
  String get medUnitMl => 'мл';

  @override
  String get medUnitDrops => 'крап.';

  @override
  String get medUnitGram => 'г';

  @override
  String get medUnitInhale => 'вдих';

  @override
  String get medUnitSuppository => 'свіча';

  @override
  String get medUnitVial => 'фл.';

  @override
  String get medUnitPiece => 'шт.';

  @override
  String get chooseProfileLabel => 'Оберіть профіль';

  @override
  String get otherSpecialtyDialogTitle => 'Інший напрямок';

  @override
  String get otherSpecialtyHint => 'Напр. Гомеопат';

  @override
  String get chooseAction => 'Обрати';

  @override
  String get doctorSpecialtyPickerTitle => 'Напрямок лікаря';

  @override
  String get specialtySearchHint => 'Пошук…';

  @override
  String get specialtyTherapist => 'Терапевт';

  @override
  String get specialtyPediatrician => 'Педіатр';

  @override
  String get specialtyFamilyDoctor => 'Сімейний лікар';

  @override
  String get specialtyCardiologist => 'Кардіолог';

  @override
  String get specialtyNeurologist => 'Невролог';

  @override
  String get specialtyEndocrinologist => 'Ендокринолог';

  @override
  String get specialtyGastroenterologist => 'Гастроентеролог';

  @override
  String get specialtyDermatologist => 'Дерматолог';

  @override
  String get specialtyOphthalmologist => 'Офтальмолог';

  @override
  String get specialtyEnt => 'ЛОР (Отоларинголог)';

  @override
  String get specialtyDentist => 'Стоматолог';

  @override
  String get specialtyGynecologist => 'Гінеколог';

  @override
  String get specialtyUrologist => 'Уролог';

  @override
  String get specialtySurgeon => 'Хірург';

  @override
  String get specialtyOrthopedist => 'Ортопед';

  @override
  String get specialtyTraumatologist => 'Травматолог';

  @override
  String get specialtyAllergist => 'Алерголог';

  @override
  String get specialtyImmunologist => 'Імунолог';

  @override
  String get specialtyPsychiatrist => 'Психіатр';

  @override
  String get specialtyPsychotherapist => 'Психотерапевт';

  @override
  String get specialtyUltrasoundDiagnostics => 'УЗД-діагностика';

  @override
  String get specialtyOncologist => 'Онколог';

  @override
  String get specialtyRheumatologist => 'Ревматолог';

  @override
  String get specialtyPulmonologist => 'Пульмонолог';

  @override
  String get specialtyNephrologist => 'Нефролог';

  @override
  String get specialtyPhlebologist => 'Флеболог';

  @override
  String get specialtyMammologist => 'Мамолог';

  @override
  String get specialtyOther => 'Інше';

  @override
  String get noDocumentsLabel => 'Немає документів';

  @override
  String get addPhotoOrPdfLabel => 'Додати фото чи PDF';

  @override
  String get labTestCbc => 'Загальний аналіз крові';

  @override
  String get labTestUrinalysis => 'Загальний аналіз сечі';

  @override
  String get labTestBloodChemistry => 'Біохімічний аналіз крові';

  @override
  String get labTestBloodGlucose => 'Глюкоза крові';

  @override
  String get labTestLipidProfile => 'Ліпідний профіль (холестерин)';

  @override
  String get labTestTsh => 'Гормони щитоподібної залози (ТТГ)';

  @override
  String get labTestFreeT3 => 'Т3 вільний';

  @override
  String get labTestFreeT4 => 'Т4 вільний';

  @override
  String get labTestLiverEnzymes => 'Печінкові проби (АЛТ, АСТ)';

  @override
  String get labTestBilirubin => 'Білірубін';

  @override
  String get labTestCreatinine => 'Креатинін';

  @override
  String get labTestUrea => 'Сечовина';

  @override
  String get labTestUricAcid => 'Сечова кислота';

  @override
  String get labTestSerumIron => 'Залізо сироватки';

  @override
  String get labTestFerritin => 'Феритин';

  @override
  String get labTestVitaminD => 'Вітамін D';

  @override
  String get labTestVitaminB12 => 'Вітамін B12';

  @override
  String get labTestFolicAcid => 'Фолієва кислота';

  @override
  String get labTestCoagulogram => 'Коагулограма';

  @override
  String get labTestBloodType => 'Група крові та резус-фактор';

  @override
  String get labTestCrp => 'С-реактивний білок (СРБ)';

  @override
  String get labTestEsr => 'Швидкість осідання еритроцитів (ШОЕ)';

  @override
  String get labTestEstrogenProgesterone => 'Естроген, прогестерон';

  @override
  String get labTestTestosterone => 'Тестостерон';

  @override
  String get labTestProlactin => 'Пролактин';

  @override
  String get labTestInsulin => 'Інсулін';

  @override
  String get labTestHba1c => 'Глікований гемоглобін (HbA1c)';

  @override
  String get labTestPcr => 'ПЛР-тест';

  @override
  String get labTestAllergens => 'Аналіз на алергени';

  @override
  String get labTestCoprogram => 'Копрограма';

  @override
  String get labTestOccultBlood => 'Аналіз калу на приховану кров';

  @override
  String get labTestFloraSwab => 'Мазок на флору';

  @override
  String get labTestUrineCulture => 'Посів сечі на стерильність';

  @override
  String get labTestHepatitis => 'Аналіз на гепатити (B, C)';

  @override
  String get labTestHiv => 'ВІЛ-тест';

  @override
  String get labTestSyphilis => 'RW (сифіліс)';

  @override
  String get labTestCalcium => 'Кальцій';

  @override
  String get labTestMagnesium => 'Магній';

  @override
  String get labTestElectrolytesKNaCl => 'Калій, натрій, хлор';

  @override
  String get labTestAmylase => 'Амілаза';

  @override
  String get labTestLipase => 'Ліпаза';

  @override
  String get labTestPsa => 'ПСА (простатоспецифічний антиген)';

  @override
  String get labTestTumorMarkers => 'Онкомаркери (СА-125)';

  @override
  String get labTestParasites => 'Аналіз на паразитів (яйця гельмінтів)';

  @override
  String get labTestCortisol => 'Кортизол';

  @override
  String get labTestImmunogram => 'Імунограма';

  @override
  String get labTestSpermogram => 'Спермограма';

  @override
  String get labTestBloodElectrolytes => 'Електроліти крові';

  @override
  String get labTestTotalProtein => 'Загальний білок';

  @override
  String get labTestDDimer => 'Д-димер';

  @override
  String get notifChannelName => 'Нагадування Elly';

  @override
  String get notifChannelDesc =>
      'Нагадування про ліки, активності, візити та самопочуття';

  @override
  String get notifTakeMedTitle => '💊 Час прийняти ліки';

  @override
  String get notifIntakeNoResponseTitle => '🔔 Ви ще не відмітили прийом';

  @override
  String get notifBackupReminderTitle => 'Захистіть свої дані';

  @override
  String get notifBackupReminderBody =>
      'Резервна копія вимкнена — дані зберігаються лише на цьому пристрої. Увімкніть у Профілі, щоб не втратити їх.';

  @override
  String get notifLowStockTitle => '⚠️ Закінчуються ліки';

  @override
  String notifLowStockBody(String medName, int remaining, String unit) {
    return '$medName — залишилось $remaining $unit';
  }

  @override
  String get notifActivityTitle => '🚶 Час для активності';

  @override
  String get notifActivityNoResponseTitle => '🔔 Ви ще не відмітили активність';

  @override
  String get notifAppointmentTitle => '🩺 Прийом лікаря';

  @override
  String get notifAppointmentNoResponseTitle =>
      '🔔 Не забудьте про прийом лікаря';

  @override
  String get notifWellbeingTitle => '💜 Зріз самопочуття';

  @override
  String get notifWellbeingBody => 'Як ви себе почуваєте?';

  @override
  String get notifVaccinationTitle => '💉 Час ревакцинації';

  @override
  String notifPeerCheckTitle(String subjectName) {
    return '🔔 Перевірте $subjectName';
  }

  @override
  String notifPeerIntakeCheckBody(String medName, String dose, String timeStr) {
    return 'Чи прийнято \"$medName\" ($dose) о $timeStr? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.';
  }

  @override
  String notifPeerActivityCheckBody(String activityName, String timeStr) {
    return 'Чи виконано \"$activityName\" о $timeStr? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.';
  }

  @override
  String notifPeerAppointmentCheckBody(String doctorType, String timeStr) {
    return 'Чи відбувся прийом (\"$doctorType\") о $timeStr? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.';
  }

  @override
  String notifPeerWellbeingCheckBody(String timeStr) {
    return 'Чи зроблено зріз самопочуття о $timeStr? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.';
  }

  @override
  String forMemberSuffix(String name) {
    return ' для $name';
  }

  @override
  String get resetLocalDbConfirmTitle => 'Скинути локальну базу?';

  @override
  String get resetLocalDbConfirmBody =>
      'Ключ шифрування не збігається з файлом бази на цьому пристрої — розшифрувати наявні дані неможливо. Це видалить пошкоджений файл локально і дасть змогу почати заново. Дію неможливо скасувати.';

  @override
  String get resetAction => 'Скинути';

  @override
  String get dbLoadErrorTitle => 'Не вдалося завантажити дані';

  @override
  String get dbLoadErrorBody =>
      'Ваші дані нікуди не зникли — сталася технічна помилка при їх читанні.';

  @override
  String get dbErrorTryThisFirstLabel => 'Спробуйте це першим';

  @override
  String get dbErrorCloseReopenHint =>
      'Повністю закрийте застосунок (не просто згорніть — справді закрийте його через список запущених застосунків) і відкрийте знову. У переважній більшості випадків це вирішує проблему без втрати даних.';

  @override
  String get tryAgainButtonAction => 'Спробувати ще раз';

  @override
  String get dbErrorMoreActionHint =>
      'Якщо закриття й повторний запуск застосунку не допомогли — після кількох спроб тут з\'явиться додаткова дія.';

  @override
  String get resetLocalDbAction => 'Скинути локальну базу';

  @override
  String get hideDetailsAction => 'Сховати деталі';

  @override
  String get showErrorDetailsAction => 'Показати деталі помилки';

  @override
  String get copiedToClipboardSnackbar => 'Скопійовано';

  @override
  String get copyErrorTextAction => 'Копіювати текст помилки';

  @override
  String get unlockPhoneTitle => 'Розблокуйте телефон';

  @override
  String get unlockPhoneBody =>
      'Ваші дані в безпеці — нічого не пошкоджено і видаляти нічого не потрібно. Просто iOS тримає ключ шифрування заблокованим, поки телефон не розблоковано хоча б раз після перезавантаження.';

  @override
  String get unlockStep1 =>
      'Розблокуйте телефон (Face ID, Touch ID або код-пароль).';

  @override
  String get unlockStep2 =>
      'Поверніться в Elly — дані підвантажаться самі, нічого натискати не треба.';

  @override
  String get checkAgainAction => 'Перевірити знову';

  @override
  String get loadingEllipsisLabel => 'Завантажую...';

  @override
  String get familyDisbandedReason =>
      'Не вдалось поновити оплату Family вчасно, тож сімейна група розірвана. Ваші локальні дані нікуди не поділись.';
}
