// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Elly';

  @override
  String get navAdd => 'Добавить';

  @override
  String get navToday => 'Сегодня';

  @override
  String get navMeds => 'Расписание';

  @override
  String get navFamily => 'Семья';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navMedCard => 'Медкарта';

  @override
  String todayProgressTitle(int taken, int total) {
    return '$taken из $total';
  }

  @override
  String get todayProgressSubtitle => 'лекарств принято сегодня';

  @override
  String todayProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get sectionFamily => 'Семья';

  @override
  String get sectionScheduled => 'Запланировано';

  @override
  String get sectionDone => 'Выполнено';

  @override
  String get actionAll => 'Все';

  @override
  String get intakeTaken => 'Выполнено';

  @override
  String get intakeSkipped => 'Пропущено';

  @override
  String get intakeTake => '✓';

  @override
  String get intakeSkip => '✕';

  @override
  String get comingSoon => 'Скоро';

  @override
  String errorGeneric(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get todaySectionFamily => 'Семья';

  @override
  String get todayScheduleForToday => 'Расписание на сегодня';

  @override
  String get todayScheduleForTomorrow => 'Коротко о завтрашнем дне';

  @override
  String get todayNothingToday => 'На сегодня ничего нет';

  @override
  String get todayTapToAdd => 'Нажмите +, чтобы добавить';

  @override
  String get todayAllDoneChip => 'Всё выполнено';

  @override
  String get todayNextNow => 'сейчас';

  @override
  String todayNextInMinutes(int minutes) {
    return 'через $minutes мин';
  }

  @override
  String get todayAllDoneTitle => 'Всё выполнено на сегодня!';

  @override
  String get todayAllDoneSubtitle => 'Отличная работа — так держать';

  @override
  String get todayHurtsNow => 'Сейчас\nболит';

  @override
  String get todayMissedSection => 'Вы пропустили';

  @override
  String get todayActiveNowSection => 'Сейчас нужно';

  @override
  String get dayPartMorning => 'Утро';

  @override
  String get dayPartAfternoon => 'День';

  @override
  String get dayPartEvening => 'Вечер';

  @override
  String get dayPartNight => 'Ночь';

  @override
  String get defaultMedName => 'Лекарство';

  @override
  String get defaultActivityName => 'Активность';

  @override
  String get wellbeingTitle => 'Самочувствие';

  @override
  String get detailLabelTime => 'Время';

  @override
  String get detailLabelDuration => 'Длительность';

  @override
  String durationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get detailLabelLocation => 'Место';

  @override
  String get detailLabelNotes => 'Заметки';

  @override
  String todayDoneCount(int count) {
    return 'Выполнено · $count';
  }

  @override
  String get skipIntakeAction => 'Пропустить приём';

  @override
  String get missedCaption => 'пропущено';

  @override
  String get videoPlaybackError => 'Не удалось воспроизвести видео здесь';

  @override
  String get openInYoutube => 'Открыть в YouTube';

  @override
  String get missedWellbeingSlot => 'Пропущенный чек-ин';

  @override
  String get wellbeingTimeToCheck => 'Время проверить самочувствие';

  @override
  String get wellbeingCommentHint =>
      'Оцените настроение и, если нужно, опишите симптомы';

  @override
  String get skipGenericAction => 'Пропустить';

  @override
  String get snooze10 => 'Отложить на 10 мин';

  @override
  String get snooze30 => 'Отложить на 30 мин';

  @override
  String get snooze60 => 'Отложить на 1 ч';

  @override
  String get doneAction => 'Выполнить';

  @override
  String get welcomeTitle => 'Добро пожаловать в Elly';

  @override
  String get welcomeSubtitle => 'Добавьте свой профиль, чтобы начать';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryMeds => 'Лекарства';

  @override
  String get categoryActivities => 'Активности';

  @override
  String get categoryWellbeing => 'Самочувствие';

  @override
  String get categoryDoctors => 'Врачи';

  @override
  String get scheduleTitle => 'Расписание';

  @override
  String get searchAllSections => 'Поиск по всем разделам';

  @override
  String get sectionMeds => 'Лекарства';

  @override
  String get noActiveMeds => 'Нет активных лекарств';

  @override
  String get sectionAppointments => 'Приёмы врачей';

  @override
  String get noScheduledAppointments => 'Нет запланированных приёмов';

  @override
  String get sectionActivities => 'Активности';

  @override
  String get noActiveActivities => 'Нет активных занятий';

  @override
  String get sectionWellbeing => 'Самочувствие';

  @override
  String get wellbeingScheduleNotSet => 'Расписание не настроено';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get repeatDaily => 'ежедневно';

  @override
  String get repeatAlternate => 'через день';

  @override
  String get repeatWeekdays => 'определённые дни';

  @override
  String get repeatEveryN => 'каждые N дней';

  @override
  String get repeatCycle => 'циклом';

  @override
  String get courseOngoing => 'постоянный курс';

  @override
  String get courseFinished => 'курс завершён';

  @override
  String courseDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней курса',
      few: '$count дня курса',
      one: '$count день курса',
    );
    return '$_temp0';
  }

  @override
  String get noLocation => 'Без указания места';

  @override
  String timesPerDayLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раз в день',
      few: '$count раза в день',
      one: '$count раз в день',
    );
    return '$_temp0';
  }

  @override
  String get addAction => 'Добавить';

  @override
  String get profileNotFound => 'Профиль не найден';

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
  String get daySun => 'Вс';

  @override
  String get editAction => 'Редактировать';

  @override
  String get fieldName => 'Название';

  @override
  String get fieldDate => 'Дата';

  @override
  String get fieldNotes => 'Заметки';

  @override
  String get surgeryTitle => 'Операция';

  @override
  String get chronicConditionTitle => 'Хроническое заболевание';

  @override
  String get labResultTitle => 'Анализ';

  @override
  String get vaccinationTitle => 'Прививка';

  @override
  String get allergyTitle => 'Аллергия';

  @override
  String get fieldDiagnosis => 'Диагноз';

  @override
  String get fieldSpecialty => 'Направление';

  @override
  String get fieldDiagnosisDate => 'Дата диагноза';

  @override
  String get fieldDateGiven => 'Дата введения';

  @override
  String get fieldNextDose => 'Следующая ревакцинация';

  @override
  String get fieldAllergen => 'Аллерген';

  @override
  String get fieldSeverity => 'Тяжесть';

  @override
  String get fieldReaction => 'Реакция';

  @override
  String get severityMild => 'Лёгкая';

  @override
  String get severityModerate => 'Средняя';

  @override
  String get severitySevere => 'Тяжёлая';

  @override
  String get dayToday => 'Сегодня';

  @override
  String get dayTomorrow => 'Завтра';

  @override
  String get dayYesterday => 'Вчера';

  @override
  String get surgeriesSectionTitle => 'Операции и госпитализации';

  @override
  String get surgeriesEmptyHint =>
      'Нажмите \"+ Добавить\" чтобы добавить первую запись';

  @override
  String get chronicConditionsSectionTitle => 'Хронические заболевания';

  @override
  String get chronicConditionsEmptyHint =>
      'Нажмите \"+ Добавить\" чтобы добавить первый диагноз';

  @override
  String get allergiesTitle => 'Аллергии';

  @override
  String get allergiesEmptyHint =>
      'Нажмите \"+ Добавить\" чтобы добавить первую аллергию';

  @override
  String get vaccinationsTitle => 'Прививки';

  @override
  String get vaccinationsEmptyHint =>
      'Нажмите \"+ Добавить\" чтобы добавить первую прививку';

  @override
  String vaccinationGivenOn(String date) {
    return 'Введено $date';
  }

  @override
  String get vaccinationOverdue => 'Просрочено';

  @override
  String get labResultsTitle => 'Анализы';

  @override
  String get allSpecialtiesFilter => 'Все направления';

  @override
  String get allTestTypesFilter => 'Все типы анализов';

  @override
  String get labResultsEmptyFilteredTitle => 'Нет анализов по этому фильтру';

  @override
  String get labResultsEmptyNoneTitle => 'Пока ничего не добавлено';

  @override
  String get labResultsEmptyFilteredHint =>
      'Попробуйте изменить фильтры или сбросить их';

  @override
  String get labResultsEmptyHint =>
      'Нажмите \"+ Добавить\" чтобы добавить первый анализ';

  @override
  String get medCardTitle => 'Медкарта';

  @override
  String get medCardHistoryByDoctorTitle => 'История лечения по направлениям';

  @override
  String get medCardHistoryByDoctorSubtitle =>
      'Визиты и анализы одного врача — всё в одном месте';

  @override
  String get medCardLabResultsSubtitle => 'Результаты по направлениям';

  @override
  String get medCardArchiveTitle => 'Архив лекарств';

  @override
  String get medCardArchiveSubtitle => 'Все препараты и статус лечения';

  @override
  String get medCardAppointmentsTitle => 'Визиты к врачам';

  @override
  String get medCardAppointmentsSubtitle => 'Записи выбранного профиля';

  @override
  String get medCardWellbeingHistoryTitle => 'История самочувствия';

  @override
  String get medCardWellbeingHistorySubtitle =>
      'Настроение и симптомы за всё время';

  @override
  String get medCardAllergiesSubtitle => 'Реакции на препараты и вещества';

  @override
  String get medCardChronicConditionsSubtitle => 'Диагнозы, дата установления';

  @override
  String get medCardVaccinationsSubtitle => 'История и ближайшие ревакцинации';

  @override
  String get medicationArchiveEmptyHint =>
      'Здесь появятся все лекарства, которые вы когда-либо добавляли';

  @override
  String get medStatusOngoing => 'Продолжается';

  @override
  String get medStatusFinished => 'Завершено';

  @override
  String get medStatusCancelled => 'Отменено';

  @override
  String medArchiveDateRangeOngoing(String start) {
    return '$start — по настоящее время';
  }

  @override
  String get specialtyHistoryTitle => 'История по направлению';

  @override
  String get sectionUpcoming => 'Запланированные';

  @override
  String get sectionPast => 'Прошедшие';

  @override
  String visitPrefix(String type) {
    return 'Визит · $type';
  }

  @override
  String labPrefix(String name) {
    return 'Анализ · $name';
  }

  @override
  String get emptyStateNoneYetTitle => 'Пока ничего не добавлено';

  @override
  String get specialtyHistoryEmptyHint => 'Визиты и анализы появятся здесь';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get deleteAction => 'Удалить';

  @override
  String get documentsLabel => 'Документы';

  @override
  String get notSelectedValue => 'Не выбрано';

  @override
  String get notSpecifiedValue => 'Не указано';

  @override
  String get deleteRecordBody => 'Запись будет удалена.';

  @override
  String get deleteWithDocsBody =>
      'Запись и все прикреплённые документы будут удалены.';

  @override
  String get deleteSurgeryConfirmTitle => 'Удалить запись?';

  @override
  String get editSurgeryTitle => 'Редактировать запись';

  @override
  String get newSurgeryTitle => 'Новая операция или госпитализация';

  @override
  String get surgeryNameHint => 'Аппендэктомия, госпитализация…';

  @override
  String get enterSurgeryNameError => 'Введите название операции';

  @override
  String get surgeryNotesHint => 'Больница, осложнения, рекомендации…';

  @override
  String get deleteConditionConfirmTitle => 'Удалить диагноз?';

  @override
  String get editConditionTitle => 'Редактировать диагноз';

  @override
  String get newConditionTitle => 'Новый диагноз';

  @override
  String get conditionNameHint => 'Астма, диабет, гипертония…';

  @override
  String get enterConditionNameError => 'Введите название диагноза';

  @override
  String get fieldDoctorSpecialty => 'Направление врача';

  @override
  String get conditionNotesHint => 'Схема лечения, дозировка…';

  @override
  String get deleteAllergyConfirmTitle => 'Удалить аллергию?';

  @override
  String get editAllergyTitle => 'Редактировать аллергию';

  @override
  String get newAllergyTitle => 'Новая аллергия';

  @override
  String get allergenHint => 'Пенициллин, орехи, пыльца…';

  @override
  String get enterAllergenError => 'Введите название аллергена';

  @override
  String get reactionHint => 'Сыпь, отёк, одышка…';

  @override
  String get allergyNotesHint => 'Дополнительные детали…';

  @override
  String get deleteLabResultConfirmTitle => 'Удалить анализ?';

  @override
  String get editLabResultTitle => 'Редактировать анализ';

  @override
  String get newLabResultTitle => 'Новый анализ';

  @override
  String get chooseSpecialtyValue => 'Выберите направление';

  @override
  String get fieldTestName => 'Название анализа';

  @override
  String get chooseTestNameValue => 'Выберите название анализа';

  @override
  String get labResultNotesHint => 'Результаты, комментарий врача…';

  @override
  String get deleteVaccinationConfirmTitle => 'Удалить прививку?';

  @override
  String get editVaccinationTitle => 'Редактировать прививку';

  @override
  String get newVaccinationTitle => 'Новая прививка';

  @override
  String get vaccinationNameField => 'Название прививки';

  @override
  String get vaccinationNameHint => 'Столбняк, грипп, COVID-19…';

  @override
  String get enterVaccinationNameError => 'Введите название прививки';

  @override
  String get removeAction => 'Убрать';

  @override
  String get notScheduledValue => 'Не запланировано';

  @override
  String get vaccinationNotesHint => 'Реакция, серия вакцины…';

  @override
  String get medsTitle => 'Лекарства';

  @override
  String activeMedsCountSection(int count) {
    return 'Активные ($count)';
  }

  @override
  String finishedMedsCountSection(int count) {
    return 'Завершённые ($count)';
  }

  @override
  String get noMedsYetTitle => 'Лекарств ещё нет';

  @override
  String get noMedsYetHint => 'Нажмите +, чтобы добавить первое лекарство';

  @override
  String get addMedicationAction => 'Добавить лекарство';

  @override
  String get errorGenericShort => 'Ошибка';

  @override
  String get sideEffectsSectionLabel => 'ВОЗМОЖНЫЕ ПОБОЧНЫЕ ЭФФЕКТЫ';

  @override
  String get sideEffectsAiDisclaimer =>
      'Определено AI во время сканирования — эта информация может быть неточной. Обязательно сверьтесь с инструкцией к препарату.';

  @override
  String get stockUnitTabletsCapsules => 'ТАБЛЕТКИ / КАПСУЛЫ';

  @override
  String get stockUnitSyrup => 'СИРОП';

  @override
  String get stockUnitDrops => 'КАПЛИ';

  @override
  String get stockUnitInjections => 'ИНЪЕКЦИИ';

  @override
  String get stockUnitSuppositories => 'СВЕЧИ';

  @override
  String get stockUnitVial => 'ФЛАКОН';

  @override
  String get stockUnitCream => 'КРЕМ';

  @override
  String get stockUnitInhaler => 'ИНГАЛЯТОР';

  @override
  String get stockUnitGeneric => 'ОСТАТОК';

  @override
  String perDoseLabel(String dose, String unit) {
    return '$dose $unit на приём';
  }

  @override
  String timesPerDaySlash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раз/день',
      few: '$count раза/день',
      one: '$count раз/день',
    );
    return '$_temp0';
  }

  @override
  String get stockSectionLabel => 'Остаток';

  @override
  String get untilCourseEndLabel => 'до конца курса';

  @override
  String get next30DaysLabel => 'на ближайшие 30 дней';

  @override
  String get remainingColonLabel => 'Осталось: ';

  @override
  String daysLeftShortLabel(String days) {
    return 'на $days дн.';
  }

  @override
  String get needToBuyLabel => 'Нужно докупить: ';

  @override
  String get refillPackageAction => '+ Пополнить упаковку';

  @override
  String get refillPackageTitle => 'Пополнить упаковку';

  @override
  String get quantityHint => 'Количество';

  @override
  String get okAction => 'OK';

  @override
  String remainingApproxPercent(int percent) {
    return 'Осталось ~$percent%';
  }

  @override
  String daysLeftAtCurrentRate(String days) {
    return '~$days дней при текущем расходе';
  }

  @override
  String get updateStockEstimateLabel => 'Обновить оценку остатка:';

  @override
  String get openedNewContainerAction => '+ Открыл новый флакон';

  @override
  String get openedTodayLabel => 'Открыто сегодня';

  @override
  String openedDaysAgoLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return 'Открыто $_temp0';
  }

  @override
  String phaseNumberLabel(int number) {
    return 'Этап $number';
  }

  @override
  String get nowLabel => 'сейчас';

  @override
  String phaseFromOngoing(String date) {
    return 'с $date, постоянно';
  }

  @override
  String get courseStagesLabel => 'Этапы курса';

  @override
  String get foodBeforeLabel => '🕐 До еды';

  @override
  String get foodAfterLabel => '🍽 После еды';

  @override
  String get foodWithLabel => '🥗 Во время еды';

  @override
  String get foodAnytimeLabel => '✓ Не зависит от еды';

  @override
  String untilDateLabel(String date) {
    return 'до $date';
  }

  @override
  String get ongoingLabel => 'постоянно';

  @override
  String get detailsLabel => 'Детали';

  @override
  String get intakeLabel => 'Приём';

  @override
  String get withFoodLabel => 'С едой';

  @override
  String get courseNounLabel => 'Курс';

  @override
  String get noteLabel => 'Примечание';

  @override
  String courseRangeLabel(String start, String endPart) {
    return 'с $start $endPart';
  }

  @override
  String get repeatDailyCap => 'Ежедневно';

  @override
  String get repeatAlternateCap => 'Через день';

  @override
  String repeatEveryNCap(String n) {
    return 'Каждые $n дня';
  }

  @override
  String repeatCycleCap(String on, String off) {
    return '$on дней / $off отдых';
  }

  @override
  String get stopAction => 'Остановить';

  @override
  String get stopCourseConfirmTitle => 'Остановить курс?';

  @override
  String stopCourseConfirmBody(String name) {
    return '«$name» будет удалено из списка активных лекарств.';
  }

  @override
  String get enterMedicationNameError => 'Введите название лекарства';

  @override
  String get deleteMedicationConfirmTitle => 'Удалить лекарство?';

  @override
  String get deleteMedicationConfirmBody =>
      'Лекарство будет удалено из расписания.';

  @override
  String get editMedicationTitle => 'Редактировать лекарство';

  @override
  String get medicationNameHint => 'Название препарата';

  @override
  String get medicationFormLabel => 'Форма выпуска';

  @override
  String get coursePhasesLabel => 'Фазы курса';

  @override
  String get addPhaseAction => 'Добавить фазу';

  @override
  String get repeatSectionLabel => 'Повтор';

  @override
  String get savingLabel => 'Сохраняем...';

  @override
  String get saveChangesAction => 'Сохранить изменения';

  @override
  String get saveAndContinueAction => 'Сохранить и продолжить →';

  @override
  String get saveAndViewScheduleAction => 'Сохранить и посмотреть расписание →';

  @override
  String get moreInEllyPlusLabel => 'Больше в Elly+';

  @override
  String get aiLabel => 'AI';

  @override
  String get scanPrescriptionTitle => 'Распознать рецепт по фото';

  @override
  String get scanPrescriptionSubtitle => 'Элли внесёт лекарства в расписание';

  @override
  String scansRemainingLabel(int remaining) {
    return '$remaining сканирований осталось для тарифа Elly Free';
  }

  @override
  String get orEnterManuallyLabel => 'или введите вручную';

  @override
  String bulkSavedSnackbar(int count) {
    return 'Добавлено $count препаратов. Проверьте детали в списке лекарств.';
  }

  @override
  String phaseCardTitle(int number) {
    return 'Фаза $number';
  }

  @override
  String get removePhaseAction => 'удалить';

  @override
  String get doseAmountLabel => 'КОЛИЧЕСТВО НА ПРИЁМ';

  @override
  String get foodRelationSectionLabel => 'ОТНОСИТЕЛЬНО ЕДЫ';

  @override
  String get durationSectionLabel => 'ДЛИТЕЛЬНОСТЬ';

  @override
  String get daysCountDashLabel => '— дн.';

  @override
  String daysCountLabel(int n) {
    return '$n дн.';
  }

  @override
  String get orLabel => 'или';

  @override
  String get permanentLabel => 'Постоянно';

  @override
  String get intakeTimeSectionLabel => 'ВРЕМЯ ПРИЁМА';

  @override
  String get specificTimeLabel => 'Конкретное время';

  @override
  String get everyNHoursLabel => 'Каждые N часов';

  @override
  String get addTimeAction => 'Добавить время';

  @override
  String get intervalLabel => 'ИНТЕРВАЛ';

  @override
  String hoursCountLabel(int n) {
    return '$n ч';
  }

  @override
  String get startLabel => 'НАЧАЛО';

  @override
  String get daysCountDialogTitle => 'Количество дней';

  @override
  String get daysSuffix => 'дн.';

  @override
  String get intervalDialogTitle => 'Интервал';

  @override
  String get hoursSuffix => 'ч.';

  @override
  String get doseCommentHint => 'Комментарий к дозе (необязательно)';

  @override
  String get doseAmountDialogTitle => 'Количество на приём';

  @override
  String get doseAmountExampleHint => 'например 2.5';

  @override
  String get weekdayExampleLabel => 'Пн, Ср, Пт, Вс…';

  @override
  String get weekdaysOptionLabel => 'Определённые дни недели';

  @override
  String get everyNDaysOptionLabel => 'Каждые N дней';

  @override
  String get everyNDaysExampleLabel => 'Например каждые 3 дня';

  @override
  String get everyLabel => 'Каждые';

  @override
  String get daysSuffixWord => 'дней';

  @override
  String get cycleOptionLabel => 'Циклом';

  @override
  String get cycleExampleLabel => 'N дней принимать — M дней перерыв';

  @override
  String get drinkLabel => 'Принимать';

  @override
  String get breakLabel => 'Перерыв';

  @override
  String get optionalParamsLabel => 'Дополнительные параметры';

  @override
  String get optionalLabel => 'Необязательно';

  @override
  String get trackStockLabel => 'Отслеживать и напоминать об остатке';

  @override
  String get vialPackageLabel => 'Флакон / упаковка';

  @override
  String get markAsOpenedHint =>
      'Отметим как только что открытую (100%) — обновить оценку остатка можно будет в карточке лекарства';

  @override
  String get inStockLabel => 'В наличии';

  @override
  String howManyNowLabel(String unit) {
    return 'Сколько $unit есть сейчас';
  }

  @override
  String courseAvailableLabel(int needed, int available) {
    return ' (курс: $needed, есть: $available)';
  }

  @override
  String get enoughForCourseLabel => 'Хватит на весь курс';

  @override
  String get noCameraAccessError =>
      'Нет доступа к камере. Разрешите его в настройках телефона.';

  @override
  String get cameraOpenError => 'Не удалось открыть камеру';

  @override
  String get packagePhotoLabel => 'Фото упаковки';

  @override
  String get addPhotoAction => 'Добавить фото';

  @override
  String get addPhotoHint => 'чтобы не перепутать лекарства';

  @override
  String inviteMemberTitle(String name) {
    return 'Пригласить $name';
  }

  @override
  String get inviteToFamilyTitle => 'Пригласить в семью';

  @override
  String get inviteCreateErrorTitle => 'Не удалось создать приглашение';

  @override
  String get tryAgainAction => 'Попробовать ещё раз';

  @override
  String inviteDependentBody(String name) {
    return 'Пусть $name введёт этот код в приложении на своём телефоне. Профиль станет независимым: вся имеющаяся история перенесётся как стартовые данные, а вы автоматически получите полный доступ к нему, как и раньше.';
  }

  @override
  String get inviteMemberBody =>
      'Тот, кто введёт этот код, присоединится как равноправный участник вашей семейной группы — со своим профилем и своими данными. Что именно он увидит из ваших данных, вы настроите отдельно.';

  @override
  String get inviteScanOrEnterHint =>
      'Отсканируйте этот код на другом устройстве\nили введите его вручную';

  @override
  String get codeCopiedSnackbar => 'Код скопирован';

  @override
  String get inviteCodeExpiryNotice =>
      'Код действует 30 минут и работает только один раз. Данные на сервере зашифрованы — там нет ничего, кроме кода доступа.';

  @override
  String alreadyJoinedFamilyError(String name) {
    return 'Вы уже присоединены к семье \"$name\"';
  }

  @override
  String get joinInvalidCodeError =>
      'Не удалось присоединиться: неверный или просроченный код';

  @override
  String get joinFamilyTitle => 'Присоединиться к семье';

  @override
  String get confirmationTitle => 'Подтверждение';

  @override
  String get doneTitle => 'Готово';

  @override
  String get scanQrOrEnterHint =>
      'Наведите камеру на QR-код\nили введите код вручную';

  @override
  String get codeInputHint => '________';

  @override
  String get checkingLabel => 'Проверка…';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get invitesYouToFamilyGroup => 'приглашает вас в семейную группу';

  @override
  String joinConsentBody(String name) {
    return 'Вы присоединяетесь как равноправный участник — ваш собственный профиль (имя и аватар) станет видимым \"$name\". Это не отменяет и не изменяет никакие ваши данные, уже внесённые в приложение. Ваша медкарта НИКОМУ автоматически не показывается — какие именно данные будут видеть другие участники, вы настроите отдельно, уже после присоединения.';
  }

  @override
  String joinConsentCheckbox(String name) {
    return 'Я согласен(-на) присоединиться к семейной группе \"$name\"';
  }

  @override
  String get joiningLabel => 'Присоединяемся…';

  @override
  String get joinAction => 'Присоединиться';

  @override
  String get joinedFamilyTitle => 'Вы в семье!';

  @override
  String joinedFamilyBody(String name) {
    return 'Теперь вы и \"$name\" видите друг друга в разделе \"Семья\".';
  }

  @override
  String get scanQrCodeLabel => 'Сканировать QR-код';

  @override
  String get tapToEnableCameraHint => 'Нажмите, чтобы включить камеру';

  @override
  String get doctorVisitLabel => 'Визит к врачу';

  @override
  String get recordFallbackLabel => 'Запись';

  @override
  String dataFromPeerTitle(String name) {
    return 'Данные от $name';
  }

  @override
  String peerNothingSharedYet(String name) {
    return '$name ещё ничем не поделился(-лась) с вами — или доступ ещё не предоставлен.';
  }

  @override
  String get noViewableDataLabel => 'Нет данных, доступных для просмотра';

  @override
  String get fileRequestSentSnackbar =>
      'Запрос отправлен — файл ещё нужно дождаться';

  @override
  String fileRequestFailedError(String error) {
    return 'Не удалось отправить запрос: $error';
  }

  @override
  String get pdfReceivedSavedSnackbar => 'PDF получен и сохранён';

  @override
  String fileOpenFailedError(String error) {
    return 'Не удалось открыть файл: $error';
  }

  @override
  String get loadingEllipsis => '…';

  @override
  String get pdfLabel => 'PDF';

  @override
  String get photoLabel => 'Фото';

  @override
  String get awaitingFileLabel => 'Ожидаем файл…';

  @override
  String get requestFileAction => 'Запросить файл';

  @override
  String get editNotesTitle => 'Редактировать заметки';

  @override
  String get editNotesDisclaimer =>
      'Правку увидит владелец данных — она применится, только если он тем временем сам не изменял эту запись.';

  @override
  String get notesHintEllipsis => 'Заметки…';

  @override
  String get editSentSnackbar => 'Правка отправлена';

  @override
  String sendFailedError(String error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String get sendEditAction => 'Отправить правку';

  @override
  String get familyLabel => 'Семья';

  @override
  String familyMembersCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count членов',
      few: '$count члена',
      one: '$count член',
    );
    return '$_temp0';
  }

  @override
  String get noMedsTodayLabel => 'Нет лекарств на сегодня';

  @override
  String get allDoneTodayLabel => 'Всё выполнено сегодня';

  @override
  String takenOfTotalIntakesLabel(int taken, int total) {
    return '$taken из $total приёмов';
  }

  @override
  String missedRemindersLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count напоминаний',
      few: '$count напоминания',
      one: '$count напоминание',
    );
    return 'Пропущено $_temp0';
  }

  @override
  String nextIntakeLabel(String medName, String time) {
    return 'Следующее: $medName в $time';
  }

  @override
  String get meLabel => 'я';

  @override
  String get localLabel => 'Локальный';

  @override
  String notTakenSuffixLabel(String time) {
    return '$time · не принято';
  }

  @override
  String get autonomousProfilesPlusOnly =>
      'Автономные профили — только на Elly Family';

  @override
  String get inviteAction => 'Пригласить';

  @override
  String get awaitingJoinLabel => 'Ожидаем присоединения';

  @override
  String get inviteToAppLabel => 'Пригласить в приложение';

  @override
  String viewAsLabel(String name) {
    return 'Просмотреть как $name';
  }

  @override
  String get deleteForeverAction => 'Удалить навсегда';

  @override
  String get areYouSureTitle => 'Вы уверены?';

  @override
  String deleteMemberConfirmBody(String name) {
    return 'Будут удалены всё расписание и медицинские карты, привязанные к профилю $name';
  }

  @override
  String careSummaryLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count близких людях',
      few: '$count близких людях',
      one: '$count близком человеке',
    );
    return 'Вы заботитесь о $_temp0. Элли пришлёт уведомление, если кто-то пропустит приём.';
  }

  @override
  String get addFamilyMemberLabel => 'Добавить члена семьи';

  @override
  String get addMemberHint => 'Родители, дети, партнёр…';

  @override
  String get profileLimitReachedTitle => 'Лимит профилей достигнут';

  @override
  String get profileLimitReachedSubtitle =>
      'Перейдите на Elly Plus — неограниченное количество локальных профилей';

  @override
  String get localProfilesTitle => 'Локальные профили';

  @override
  String get familyUpgradeSubtitle =>
      'Чтобы семья тоже могла управлять — перейдите на Elly Family';

  @override
  String leaveGroupConfirmTitle(String name) {
    return 'Покинуть \"$name\"?';
  }

  @override
  String get leaveGroupConfirmBody =>
      'Участники этой группы потеряют доступ к вашим данным, а вы — к тому, чем они с вами делились. Других семейных групп это не коснётся.';

  @override
  String get leaveAction => 'Покинуть';

  @override
  String leftGroupSnackbar(String name) {
    return 'Вы покинули \"$name\"';
  }

  @override
  String get familyGroupSectionLabel => 'Семейная группа';

  @override
  String slotsUsedLabel(int used, int total) {
    return '$used из $total';
  }

  @override
  String get autonomousLimitReachedTitle =>
      'Лимит автономных профилей достигнут';

  @override
  String get autonomousLimitReachedSubtitle =>
      'Перейдите на Elly Family, чтобы пригласить ещё кого-то';

  @override
  String get myFamilyLabel => 'Моя семья';

  @override
  String peerFamilyLabel(String name) {
    return 'Семья $name';
  }

  @override
  String get doctorFallbackLabel => 'Врач';

  @override
  String get reminderPushTitle => '🔔 Вам напоминают';

  @override
  String reminderTakeMedBody(String title, String detailSuffix, String time) {
    return 'Не забудьте принять \"$title\"$detailSuffix в $time';
  }

  @override
  String reminderDoActivityBody(String title, String time) {
    return 'Не забудьте выполнить \"$title\" в $time';
  }

  @override
  String reminderDoctorVisitBody(String title, String detailSuffix) {
    return 'Не забудьте про приём врача: $title$detailSuffix';
  }

  @override
  String get reminderWellbeingBody => 'Не забудьте отметить самочувствие';

  @override
  String get reminderGenericBody => 'Проверьте расписание';

  @override
  String reminderSentSnackbar(String name) {
    return 'Напоминание для $name отправлено';
  }

  @override
  String get independentAccountLabel => 'Независимая учётная запись';

  @override
  String get missedLabel => 'Пропущено';

  @override
  String missedCountLabel(int count) {
    return 'Пропущено $count';
  }

  @override
  String get remindAction => '🔔 Напомнить';

  @override
  String removePeerConfirmTitle(String name) {
    return 'Убрать \"$name\"?';
  }

  @override
  String get removePeerConfirmBody =>
      'Вы оба потеряете доступ к данным, которыми делились друг с другом.';

  @override
  String get confirmGuardianConsentSnackbar =>
      'Подтвердите, что вы имеете право вести данные этого человека';

  @override
  String get nameFieldLabel => 'ИМЯ';

  @override
  String get avatarFieldLabel => 'АВАТАР';

  @override
  String get memberNameHint => 'Мама, Папа, Бабушка…';

  @override
  String get guardianConsentCheckbox =>
      'Я являюсь законным представителем этого человека или получил(-а) его согласие на ведение его данных в приложении';

  @override
  String get debugLogTitle => 'Журнал событий';

  @override
  String get debugLogEmptyBody => 'Лог пуст.';

  @override
  String get debugLogEmptySnackbar => 'Лог пуст';

  @override
  String get debugLogShareSubject => 'Elly — журнал событий';

  @override
  String get viewDebugLogAction => 'Просмотреть журнал событий';

  @override
  String get clearAction => 'Очистить';

  @override
  String get shareAction => 'Поделиться';

  @override
  String get antiStressLabel => 'Антистресс-упражнения';

  @override
  String get antiStressPickerSubtitle => 'Выбери, что поможет прямо сейчас';

  @override
  String get breathingExerciseTitle => 'Дышим вместе';

  @override
  String get breathingExerciseSubtitle =>
      'Медленное дыхание за 2 минуты успокаивает нервную систему';

  @override
  String get grounding54321Title => '5-4-3-2-1';

  @override
  String get grounding54321Subtitle =>
      'Техника заземления — возвращает внимание в здесь-и-сейчас';

  @override
  String get clearMindTitle => 'Ясный ум';

  @override
  String get clearMindPickerSubtitle =>
      'Проведи пальцем по экрану — и туман рассеется';

  @override
  String get breathingScreenHeaderLabel => 'Минутка спокойствия';

  @override
  String get breathingDoneBody => 'Молодец! Ты справился(-лась).';

  @override
  String breathingCyclesLeftBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count циклов',
      few: '$count цикла',
      one: '$count цикл',
    );
    return 'Медленный вдох... и выдох. Ещё $_temp0.';
  }

  @override
  String get restartAction => 'Ещё раз';

  @override
  String get inhaleLabel => 'Вдох';

  @override
  String get exhaleLabel => 'Выдох';

  @override
  String get safeYouTitle => 'Ты в безопасности';

  @override
  String get safeYouSubtitle => 'Тревога пройдёт. Элли рядом, пока тебе нужно.';

  @override
  String get differentExerciseAction => 'Другое упражнение';

  @override
  String get feelBetterAction => 'Мне лучше';

  @override
  String get clearMindHeading => 'Развей туман';

  @override
  String get clearMindInstructions =>
      'Проведи пальцем по экрану, чтобы увидеть, что скрывается за туманом';

  @override
  String get clearMindTouchHint => '👆 Коснись и веди пальцем';

  @override
  String get familyVisibilityLabel => 'Видимость для семьи';

  @override
  String get familyVisibilityEmptyBody =>
      'Если к вашей семейной группе присоединятся автономные участники (со своим аккаунтом), здесь можно будет управлять их доступом к вашему профилю';

  @override
  String get familyVisibilityIntro =>
      'Что видят и могут делать другие члены семьи с вашим профилем';

  @override
  String get medcardSyncToggleLabel =>
      'Синхронизировать медкарту на другие устройства';

  @override
  String get medcardSyncDescription =>
      'Если выключено, аллергии, хронические заболевания, прививки, операции, анализы и визиты этого профиля (вместе с вложениями) не передаются на другие устройства семьи, подключённые через пейринг. Лекарства и расписание приёма синхронизируются независимо от этого переключателя.';

  @override
  String get pendingConnectionLabel => 'Ожидаем соединения';

  @override
  String get viewerNotifyPermissionLabel => 'Получает уведомления';

  @override
  String get viewerEditPermissionLabel => 'Может редактировать профиль';

  @override
  String get viewerViewPermissionLabel => 'Видит задачи, медкарту и расписание';

  @override
  String get permissionDeniedNotYoursBody =>
      'Не удалось изменить — это не ваш профиль';

  @override
  String get voiceConsentTitle => 'Голосовые команды';

  @override
  String get voiceConsentDescription =>
      'Распознавание голоса через Anthropic (Claude) — добавление лекарств, отметки приёма и другие голосовые команды.';

  @override
  String get scanConsentTitle => 'Сканирование рецептов';

  @override
  String get scanConsentDescription =>
      'Распознавание фото рецепта или упаковки через Anthropic (Claude) — определение названия, дозировки, формы выпуска.';

  @override
  String get privacyLabel => 'Конфиденциальность';

  @override
  String get securityLabel => 'Безопасность';

  @override
  String get privacyPolicyLabel => 'Политика конфиденциальности';

  @override
  String get aiConsentSectionLabel =>
      'Согласия на обработку данных AI-функциями';

  @override
  String get consentRevokeNoteBody =>
      'Отзыв согласия не удаляет уже обработанные данные — он лишь означает, что перед следующим использованием этой функции приложение снова запросит подтверждение.';

  @override
  String get dangerZoneLabel => 'Опасная зона';

  @override
  String get deleteProfileForeverLabel => 'Удалить профиль навсегда';

  @override
  String deleteProfileForeverBody(String name) {
    return 'Удалит все данные профиля \"$name\" — локально и на сервере, если настроен обмен';
  }

  @override
  String get appLockToggleLabel => 'Блокировка приложения';

  @override
  String get appLockDescription =>
      'Face ID, Touch ID или пароль устройства при каждом открытии Elly';

  @override
  String policyAcceptedLabel(String date, String version) {
    return 'Принято $date · версия $version';
  }

  @override
  String policyAcceptedOldVersionLabel(String version) {
    return 'Принята старая версия ($version) — будет предложено согласиться снова';
  }

  @override
  String get policyNotAcceptedLabel => 'Ещё не принято';

  @override
  String get viewFullTextAction => 'Посмотреть полный текст';

  @override
  String consentGivenLabel(String date) {
    return 'Предоставлено $date';
  }

  @override
  String get consentNotGivenLabel => 'Согласие не предоставлено';

  @override
  String get revokeConsentAction => 'Отозвать согласие';

  @override
  String get groundStep5Title => '5 вещей, которые ты видишь';

  @override
  String get groundStep5Hint => 'Одна вещь, напр. окно';

  @override
  String get groundStep4Title =>
      '4 вещи, которые можешь почувствовать на ощупь';

  @override
  String get groundStep4Hint => 'Одна вещь, напр. ткань свитера';

  @override
  String get groundStep3Title => '3 звука, которые ты слышишь';

  @override
  String get groundStep3Hint => 'Один звук, напр. гудение холодильника';

  @override
  String get groundStep2Title => '2 запаха, которые ты чувствуешь';

  @override
  String get groundStep2Hint => 'Один запах, напр. кофе';

  @override
  String get groundStep1Title => '1 вкус, который ты чувствуешь';

  @override
  String get groundStep1Hint => 'Один вкус, напр. мята';

  @override
  String groundingNameStepLabel(String title) {
    return 'Назови $title';
  }

  @override
  String groundingProgressCounter(int count, int total) {
    return '$count / $total названо';
  }

  @override
  String get groundingListeningLabel => 'Слушаю…';

  @override
  String get groundingSkipStepAction => 'Пропустить этот шаг';

  @override
  String get groundingCompletedTitle => 'Ты вернулся(-лась) в здесь-и-сейчас';

  @override
  String get groundingCompletedSubtitle =>
      'Отличная работа. Возвращайся к этому упражнению, когда понадобится.';

  @override
  String get healthSectionHeader => 'Здоровье и упражнения';

  @override
  String get appSettingsSectionHeader => 'Настройки приложения';

  @override
  String get accountSectionHeader => 'Аккаунт';

  @override
  String get otherSectionHeader => 'Другое';

  @override
  String get backupDisabledTitle => 'Резервная копия отключена';

  @override
  String get backupDisabledBody =>
      'Данные хранятся только на этом устройстве — включите, чтобы не потерять их';

  @override
  String get connectFamilyTitle => 'Подключите Семью';

  @override
  String get connectFamilySubtitle => 'Заботьтесь обо всей семье';

  @override
  String get planFreeLabel => 'Бесплатный план';

  @override
  String get planPlusLabel => 'Elly Plus';

  @override
  String get planFamilyLabel => 'Elly Family';

  @override
  String get languageLabel => 'Язык';

  @override
  String get voiceLanguageDescription =>
      'Управляет языком интерфейса и распознавания голоса (голосовое управление, запись самочувствия). Пока доступны украинский, английский и русский — другие языки появятся после переводов.';

  @override
  String get fontSizeLabel => 'Размер шрифта';

  @override
  String get fontSizeSampleLabel => 'Аа';

  @override
  String get notificationsLabel => 'Уведомления';

  @override
  String get plansLabel => 'Тарифы';

  @override
  String get backupLabel => 'Резервная копия';

  @override
  String get rateAppLabel => 'Оценить приложение';

  @override
  String get helpFaqLabel => 'Помощь и FAQ';

  @override
  String get exportDataLabel => 'Экспорт данных';

  @override
  String get logoutLabel => 'Выйти из аккаунта';

  @override
  String get logoutConfirmTitle => 'Выйти из аккаунта?';

  @override
  String get logoutConfirmBody =>
      'Все данные будут удалены с этого устройства. Это действие невозможно отменить.';

  @override
  String get logoutConfirmAction => 'Выйти';

  @override
  String get editProfileTitle => 'Редактировать профиль';

  @override
  String get yourNameHint => 'Ваше имя';

  @override
  String get saveAction => 'Сохранить';

  @override
  String get appointmentsHistoryTitle => 'Визиты к врачам';

  @override
  String get sectionFuture => 'Будущие';

  @override
  String get visitPassedLabel => '✓ прошло';

  @override
  String get arrowRightLabel => '→';

  @override
  String get noRecordsYetTitle => 'Записей ещё нет';

  @override
  String get noAppointmentsForSpecialty => 'Нет визитов по этому направлению';

  @override
  String get tryDifferentSpecialtyHint =>
      'Попробуйте выбрать другое направление или сбросить фильтр';

  @override
  String get tapToAddFirstHint => 'Нажмите \"+ Добавить\" чтобы создать первый';

  @override
  String get meCapsLabel => 'Я';

  @override
  String get monthAbbrJan => 'ЯНВ';

  @override
  String get monthAbbrFeb => 'ФЕВ';

  @override
  String get monthAbbrMar => 'МАР';

  @override
  String get monthAbbrApr => 'АПР';

  @override
  String get monthAbbrMay => 'МАЙ';

  @override
  String get monthAbbrJun => 'ИЮН';

  @override
  String get monthAbbrJul => 'ИЮЛ';

  @override
  String get monthAbbrAug => 'АВГ';

  @override
  String get monthAbbrSep => 'СЕН';

  @override
  String get monthAbbrOct => 'ОКТ';

  @override
  String get monthAbbrNov => 'НОЯ';

  @override
  String get monthAbbrDec => 'ДЕК';

  @override
  String get remindBefore1Hour => 'За 1 час';

  @override
  String get remindBefore1Day => 'За день';

  @override
  String get remindBefore2Days => 'За 2 дня';

  @override
  String get deleteAppointmentBody => 'Запись к врачу будет удалена.';

  @override
  String get enterDoctorTypeError => 'Введите тип врача';

  @override
  String get recordVisitTitle => 'Записать визит';

  @override
  String get newAppointmentTitle => 'Запись к врачу';

  @override
  String get fieldWhere => 'Где';

  @override
  String get locationHint => 'Клиника, адрес или онлайн';

  @override
  String get fieldDateTime => 'Дата и время';

  @override
  String get dateCapsLabel => 'ДАТА';

  @override
  String get timeCapsLabel => 'ВРЕМЯ';

  @override
  String get remindBeforeLabel => 'Напомнить заранее';

  @override
  String get doctorConclusionLabel => 'Заключение врача';

  @override
  String get noteSingularLabel => 'Заметка';

  @override
  String get doctorConclusionHint =>
      'Что сказал врач, рекомендации, назначения…';

  @override
  String get apptNoteHint => 'Что спросить, взять с собой, номер полиса…';

  @override
  String get saveVisitAction => 'Сохранить визит';

  @override
  String get saveReminderAction => 'Сохранить напоминание';

  @override
  String get monthGenJan => 'января';

  @override
  String get monthGenFeb => 'февраля';

  @override
  String get monthGenMar => 'марта';

  @override
  String get monthGenApr => 'апреля';

  @override
  String get monthGenMay => 'мая';

  @override
  String get monthGenJun => 'июня';

  @override
  String get monthGenJul => 'июля';

  @override
  String get monthGenAug => 'августа';

  @override
  String get monthGenSep => 'сентября';

  @override
  String get monthGenOct => 'октября';

  @override
  String get monthGenNov => 'ноября';

  @override
  String get monthGenDec => 'декабря';

  @override
  String get symptomsTitle => 'Симптомы';

  @override
  String get symptomSearchHint => 'Поиск или новое название…';

  @override
  String get symptomListEmptyLabel => 'Список пуст';

  @override
  String addCustomSymptomLabel(String query) {
    return 'Добавить «$query»';
  }

  @override
  String get historyLabel => 'История';

  @override
  String get wellbeingScheduleInfoText =>
      'Настройте расписание чек-инов самочувствия. В назначенное время на главном экране появится карточка для заполнения.';

  @override
  String get frequencyPerDayLabel => 'ЧАСТОТА В ДЕНЬ';

  @override
  String get collectionTimeLabel => 'ВРЕМЯ СБОРА';

  @override
  String wellbeingSlotNumberLabel(int index) {
    return 'Чек-ин $index';
  }

  @override
  String timesCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раз',
      few: '$count раза',
      one: '$count раз',
    );
    return '$_temp0';
  }

  @override
  String get saveScheduleAction => 'Сохранить расписание';

  @override
  String get wellbeingByDaySubtitle => 'самочувствие по дням';

  @override
  String get addWellbeingSlotAction => '+ Чек-ин';

  @override
  String moodChartTitle(String month) {
    return 'Настроение — $month';
  }

  @override
  String get monthNomJan => 'январь';

  @override
  String get monthNomFeb => 'февраль';

  @override
  String get monthNomMar => 'март';

  @override
  String get monthNomApr => 'апрель';

  @override
  String get monthNomMay => 'май';

  @override
  String get monthNomJun => 'июнь';

  @override
  String get monthNomJul => 'июль';

  @override
  String get monthNomAug => 'август';

  @override
  String get monthNomSep => 'сентябрь';

  @override
  String get monthNomOct => 'октябрь';

  @override
  String get monthNomNov => 'ноябрь';

  @override
  String get monthNomDec => 'декабрь';

  @override
  String get weekdayFullMon => 'понедельник';

  @override
  String get weekdayFullTue => 'вторник';

  @override
  String get weekdayFullWed => 'среда';

  @override
  String get weekdayFullThu => 'четверг';

  @override
  String get weekdayFullFri => 'пятница';

  @override
  String get weekdayFullSat => 'суббота';

  @override
  String get weekdayFullSun => 'воскресенье';

  @override
  String get todayLowerLabel => 'сегодня';

  @override
  String get yesterdayLowerLabel => 'вчера';

  @override
  String quotedCommentLabel(String comment) {
    return '«$comment»';
  }

  @override
  String get noWellbeingLogsTitle => 'Чек-инов ещё нет';

  @override
  String get noWellbeingLogsHint =>
      'Нажмите \"+ Чек-ин\" чтобы добавить первый';

  @override
  String get comingSoonEllipsis => 'Скоро...';

  @override
  String get sendDiaryToDoctorLabel => 'Отправить дневник врачу';

  @override
  String get diarySummaryHint => 'Чек-ины + симптомы + приёмы за месяц';

  @override
  String get moodBadLabel => 'Плохо';

  @override
  String get moodMehLabel => 'Так себе';

  @override
  String get moodOkLabel => 'Норм';

  @override
  String get moodGoodLabel => 'Хорошо';

  @override
  String get moodGreatLabel => 'Отлично';

  @override
  String get chooseWellbeingErrorSnackbar => 'Выберите самочувствие';

  @override
  String get wellbeingSlotMorning => 'утренний чек-ин';

  @override
  String get wellbeingSlotAfternoon => 'дневной чек-ин';

  @override
  String get wellbeingSlotEvening => 'вечерний чек-ин';

  @override
  String get howAreYouFeelingLabel => 'Как вы себя чувствуете?';

  @override
  String get anySymptomsLabel => 'Есть симптомы?';

  @override
  String get chooseFromListOrAddLabel =>
      'Выберите из списка распространённых или добавьте своё';

  @override
  String get symptomsNotSelectedLabel => 'Симптомы не выбраны';

  @override
  String get commentLabel => 'Комментарий';

  @override
  String get optionalSuffixLabel => '· необязательно';

  @override
  String get orTypeTextLabel => 'или введите текстом';

  @override
  String get describeFeelingHint => 'Опишите, как себя чувствуете…';

  @override
  String get saveWellbeingCheckAction => 'Сохранить чек-ин';

  @override
  String get voiceTranscriptLabel => 'Расшифровка голоса';

  @override
  String get editableTextBelowHint => 'Текст можно редактировать ниже в поле';

  @override
  String get recordAgainAction => 'Записать снова';

  @override
  String get dictateCommentLabel => 'Надиктуйте комментарий';

  @override
  String get micUnavailableLabel => 'Микрофон недоступен';

  @override
  String get tapAndSpeakLabel => 'Нажмите и говорите';

  @override
  String get speakNowLabel => 'Говорите… нажмите, чтобы остановить';

  @override
  String get preparingMicLabel => 'Готовимся… подождите секунду';

  @override
  String get symptomHeadache => 'головная боль';

  @override
  String get symptomNausea => 'тошнота';

  @override
  String get symptomDizziness => 'головокружение';

  @override
  String get symptomWeakness => 'слабость';

  @override
  String get symptomShortnessOfBreath => 'одышка';

  @override
  String get symptomRash => 'сыпь';

  @override
  String get symptomPain => 'боль';

  @override
  String get symptomFever => 'температура';

  @override
  String get symptomCough => 'кашель';

  @override
  String get symptomSoreThroat => 'боль в горле';

  @override
  String get symptomRunnyNose => 'насморк';

  @override
  String get symptomStuffyNose => 'заложенность носа';

  @override
  String get symptomSneezing => 'чихание';

  @override
  String get symptomVomiting => 'рвота';

  @override
  String get symptomDiarrhea => 'диарея';

  @override
  String get symptomConstipation => 'запор';

  @override
  String get symptomBloating => 'вздутие живота';

  @override
  String get symptomHeartburn => 'изжога';

  @override
  String get symptomStomachPain => 'боль в животе';

  @override
  String get symptomLossOfAppetite => 'потеря аппетита';

  @override
  String get symptomIncreasedAppetite => 'повышенный аппетит';

  @override
  String get symptomInsomnia => 'бессонница';

  @override
  String get symptomDrowsiness => 'сонливость';

  @override
  String get symptomFatigue => 'усталость';

  @override
  String get symptomChestPain => 'боль в груди';

  @override
  String get symptomPalpitations => 'учащённое сердцебиение';

  @override
  String get symptomHighBloodPressure => 'повышенное давление';

  @override
  String get symptomLowBloodPressure => 'пониженное давление';

  @override
  String get symptomBackPain => 'боль в спине';

  @override
  String get symptomJointPain => 'боль в суставах';

  @override
  String get symptomMusclePain => 'боль в мышцах';

  @override
  String get symptomCramps => 'судороги';

  @override
  String get symptomSwelling => 'отёки';

  @override
  String get symptomItching => 'зуд';

  @override
  String get symptomDrySkin => 'сухость кожи';

  @override
  String get symptomBruising => 'синяки';

  @override
  String get symptomDryMouth => 'сухость во рту';

  @override
  String get symptomExcessiveSweating => 'повышенная потливость';

  @override
  String get symptomChills => 'озноб';

  @override
  String get symptomBlurredVision => 'нечёткое зрение';

  @override
  String get symptomRingingInEars => 'звон в ушах';

  @override
  String get symptomNumbness => 'онемение';

  @override
  String get symptomTremor => 'тремор';

  @override
  String get symptomMemoryIssues => 'проблемы с памятью';

  @override
  String get symptomConcentrationIssues => 'проблемы с концентрацией';

  @override
  String get symptomAnxiety => 'тревожность';

  @override
  String get symptomIrritability => 'раздражительность';

  @override
  String get symptomMoodSwings => 'перепады настроения';

  @override
  String get symptomWeightLoss => 'потеря веса';

  @override
  String get symptomWeightGain => 'набор веса';

  @override
  String get restoreErrorBody =>
      'Не удалось восстановить: проверьте пароль и соединение, попробуйте ещё раз';

  @override
  String get backupPasswordDialogTitle => 'Пароль резервной копии';

  @override
  String get backupPasswordDialogBody =>
      'Введите пароль, который вы указали при создании резервной копии.';

  @override
  String get passwordFieldLabel => 'Пароль';

  @override
  String get restoreAccountTitle => 'Восстановить аккаунт';

  @override
  String get restoreAccountSubtitle =>
      'Подключитесь к хранилищу, где хранится ваша резервная копия';

  @override
  String get googleDriveLabel => 'Google Drive';

  @override
  String get iCloudLabel => 'iCloud';

  @override
  String get doneExclamationTitle => 'Готово!';

  @override
  String get setupCompleteBody =>
      'Всё настроено. Откройте дашборд и начните следить за здоровьем.';

  @override
  String get firstReminderTodayLabel => 'Первое напоминание — сегодня';

  @override
  String get noRemindersYetLabel => 'Напоминаний пока нет';

  @override
  String get reminderWillArriveLabel =>
      'Напоминание придёт по расписанию, которое вы только что добавили';

  @override
  String get setupMedsToActivateLabel =>
      'Настройте лекарства, чтобы активировать напоминания';

  @override
  String get privacyConsentPrefix => 'Я ознакомлен(-а) и согласен(-на) с ';

  @override
  String get privacyConsentSuffix => ' приложения';

  @override
  String get openDashboardAction => 'Открыть дашборд →';

  @override
  String get joinFailedCheckCodeError =>
      'Не удалось присоединиться: проверьте код';

  @override
  String get connectToFamilyTitle => 'Подключение к семье';

  @override
  String get enterAccessCodeHint =>
      'Введите код доступа, который вам прислали родные';

  @override
  String get checkingEllipsisLabel => 'Проверка...';

  @override
  String get scheduleAlreadyReadyTitle => 'Расписание уже готово';

  @override
  String scheduleSetByInviterBody(String name) {
    return '$name уже составил(-а) для вас расписание приёма лекарств. Вы сможете отредактировать его в любой момент после подключения.';
  }

  @override
  String get agreeUseFamilyScheduleCheckbox =>
      'Я согласен(-на) использовать расписание, составленное моей семьёй';

  @override
  String get startAction => 'Начать';

  @override
  String get creatingEllipsisLabel => 'Создаём...';

  @override
  String get declineScheduleCreateOwnAction =>
      'Не согласен, создать своё расписание';

  @override
  String get familyFallbackName => 'Семья';

  @override
  String get profileFallbackName => 'Профиль';

  @override
  String get enterYourNameError => 'Введите своё имя';

  @override
  String get walkActivityName => 'Прогулка';

  @override
  String onboardingFinishError(String error) {
    return 'Ошибка при завершении: $error';
  }

  @override
  String get welcomeGreeting => 'Привет! 👋';

  @override
  String get welcomeDescription =>
      'Elly поможет не забыть о лекарствах,\nактивности и самочувствии — для вас\nи всей семьи';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Шаг $step из $total';
  }

  @override
  String get accountChoiceTitle => 'Как начнём?';

  @override
  String get accountChoiceSubtitle => 'Выберите вариант, который вам подходит';

  @override
  String get createAccountTitle => 'Создать аккаунт';

  @override
  String get createAccountSubtitle => 'Настрою лекарства и расписание для себя';

  @override
  String get joinFamilyChoiceTitle => 'Подключиться к семье';

  @override
  String get joinFamilyChoiceSubtitle => 'У меня есть код доступа от родных';

  @override
  String get restoreAccountChoiceSubtitle =>
      'Я уже пользовался(-лась) Elly раньше';

  @override
  String get tellAboutYourselfTitle => 'Расскажите о себе';

  @override
  String get tellAboutYourselfSubtitle =>
      'Укажите своё имя и выберите аватар профиля';

  @override
  String get nextToMedsAction => 'Далее — лекарства →';

  @override
  String get scanOrEnterManuallyHint =>
      'Сканируйте фото рецепта или введите вручную';

  @override
  String get addMedsShortAction => 'Добавить лекарства';

  @override
  String get addMoreMedsAction => 'Добавить ещё лекарства';

  @override
  String get addMedsHint =>
      'Скан фото рецепта или название, доза и расписание вручную';

  @override
  String get addMedsLaterInfo =>
      'Лекарства можно добавить позже через раздел «Лекарства» в главном меню';

  @override
  String get nextAction => 'Далее →';

  @override
  String get skipAddLaterAction => 'Пропустить — добавлю позже';

  @override
  String get activityWellbeingTitle => 'Активность и самочувствие';

  @override
  String get activityWellbeingSubtitle =>
      'Включите одним переключателем — настройки можно изменить позже';

  @override
  String get activitySectionLabel => 'Активность';

  @override
  String get walkActivitySub => '30 мин · ежедневно · 08:30';

  @override
  String get wellbeingDiaryLabel => 'Дневник самочувствия';

  @override
  String get wellbeingDiaryDescription =>
      'Короткие отметки самочувствия помогут увидеть связь между приёмом лекарств и тем, как вы себя чувствуете';

  @override
  String get wellbeingSlotsTitle => 'Чек-ины самочувствия';

  @override
  String get wellbeingSlotsSub => '2–3 раза в день · 08:00, 14:00, 20:00';

  @override
  String get almostDoneAction => 'Почти готово →';

  @override
  String get scanNoResultsError =>
      'Не удалось распознать лекарство на фото. Попробуйте сделать более чёткое фото.';

  @override
  String scanErrorWithMessage(String error) {
    return 'Ошибка сканирования: $error';
  }

  @override
  String get scanPrescriptionScreenTitle => 'Сканировать рецепт';

  @override
  String get beforeYouStartTitle => 'Прежде чем начать';

  @override
  String get scanConsentDisclaimerBody =>
      'Чтобы распознать лекарство, фото рецепта или упаковки отправляется сервису Anthropic (Claude). Фото используется только для распознавания и нигде не сохраняется после ответа.';

  @override
  String get scanDosageWarningPrefix =>
      '⚠️ Дозировка, расписание и справочная информация о побочных эффектах — ориентировочные. ';

  @override
  String get alwaysCheckInstructionsLabel =>
      'Всегда сверяйтесь с инструкцией к препарату.';

  @override
  String get understoodAgreeAction => 'Понятно, соглашаюсь';

  @override
  String get takePhotoInstructionsBody =>
      'Сфотографируйте рецепт или упаковку. Можно добавить несколько фото, если лекарств несколько.';

  @override
  String get cameraLabel => 'Камера';

  @override
  String get galleryLabel => 'Галерея';

  @override
  String get scanAction => 'Сканировать';

  @override
  String scanRecognizedCountLabel(int count) {
    return 'Распознано $count. Проверьте перед добавлением:';
  }

  @override
  String get expandAndConfirmHint =>
      'Разверните препарат, проверьте данные и поставьте галочку, чтобы подтвердить добавление.';

  @override
  String get chooseMedsAction => 'Выберите препараты';

  @override
  String addSelectedCountAction(int count) {
    return 'Добавить выбранные ($count)';
  }

  @override
  String get scheduleTimeMorning => 'Утром';

  @override
  String get scheduleTimeAfternoon => 'Днём';

  @override
  String get scheduleTimeEvening => 'Вечером';

  @override
  String get scheduleTimeNight => 'Ночью';

  @override
  String get unnamedMedLabel => 'Без названия';

  @override
  String get medNameCapsLabel => 'НАЗВАНИЕ';

  @override
  String get releaseFormCapsLabel => 'ФОРМА ВЫПУСКА';

  @override
  String get doseCapsLabel => 'ДОЗА';

  @override
  String get courseDurationCapsLabel => 'ДЛИТЕЛЬНОСТЬ КУРСА';

  @override
  String get foodRelationCapsLabel => 'СВЯЗЬ С ЕДОЙ';

  @override
  String possibleSideEffectsPrefix(String list) {
    return '⚡ Возможные побочные эффекты: $list. ';
  }

  @override
  String get checkInstructionsShortLabel =>
      'Сверьтесь с инструкцией к препарату.';

  @override
  String get confirmedCheckLabel => 'Подтверждено ✓';

  @override
  String get confirmAllCorrectAction => 'Всё верно, подтвердить';

  @override
  String get somethingWentWrongTitle => 'Что-то пошло не так';

  @override
  String sttErrorLabel(String error) {
    return 'Ошибка STT: $error';
  }

  @override
  String get speechNotAvailableError =>
      'Распознавание речи недоступно на этом устройстве';

  @override
  String get nothingHeardError => 'Ничего не услышано. Попробуй ещё раз.';

  @override
  String analysisErrorWithMessage(String error) {
    return 'Ошибка анализа: $error';
  }

  @override
  String get commandNotRecognizedError => 'Не удалось распознать команду';

  @override
  String get voiceControlTitle => 'Голосовое управление';

  @override
  String get voiceConsentDisclaimerBody =>
      'Распознавание голоса происходит на устройстве. Но чтобы понять команду, текст твоей фразы отправляется сервису Anthropic (Claude). Эта функция распознаёт только 3 команды: добавить лекарство, добавить активность или запись к врачу — свободное описание самочувствия или симптомов сюда никогда не отправляется, для этого есть отдельное поле в дневнике самочувствия, которое остаётся только на устройстве.';

  @override
  String get voiceExampleMedQuote =>
      '\"Добавь Эналаприл 10 мг утром и вечером\"';

  @override
  String get voiceExampleMedDesc =>
      'Откроет форму лекарства с заполненными полями. Распознаёт не все препараты — проверьте поля перед сохранением.';

  @override
  String get voiceExampleActivityQuote =>
      '\"Добавь зарядку дважды в день утром и вечером\"';

  @override
  String get voiceExampleActivityDesc =>
      'Откроет форму активности с заполненными полями';

  @override
  String get voiceExampleApptQuote => '\"Запись к кардиологу в пятницу в 10\"';

  @override
  String get voiceExampleApptDesc => 'Откроет форму записи к врачу';

  @override
  String get whatToDoTitle => 'Что хочешь сделать?';

  @override
  String get tapAndSayCommandHint =>
      'Нажми и скажи команду\nили начни говорить';

  @override
  String dictateLanguageHint(String language) {
    return 'Диктуйте на языке $language. Изменить можно в Профиль → Язык.';
  }

  @override
  String get commandExamplesCapsLabel => 'ПРИМЕРЫ КОМАНД';

  @override
  String get experimentalFeatureNotice =>
      'Это экспериментальная функция — распознавание может заполнить данные неточно, всегда проверяйте форму перед сохранением.';

  @override
  String get holdAndSpeakAction => 'Удерживай и говори';

  @override
  String get listeningEllipsisLabel => 'Слушаю...';

  @override
  String get preparingEllipsisLabel => 'Готовимся...';

  @override
  String get tapMicToStopHint => 'Нажми на микрофон, чтобы остановить';

  @override
  String get waitBeforeSpeakingHint =>
      'Подождите секунду перед тем, как говорить';

  @override
  String quotedTextLabel(String text) {
    return '\"$text\"';
  }

  @override
  String get analyzingCommandLabel => 'Анализирую команду...';

  @override
  String get actionCapsLabel => 'ДЕЙСТВИЕ';

  @override
  String get drugCapsLabel => 'ПРЕПАРАТ';

  @override
  String get activityCapsLabel => 'АКТИВНОСТЬ';

  @override
  String get scheduleCapsLabel => 'РАСПИСАНИЕ';

  @override
  String get doctorCapsLabel => 'ВРАЧ';

  @override
  String get addActivityActionLabel => 'Добавить активность';

  @override
  String get unknownCommandLabel => 'Неизвестная команда';

  @override
  String get youSaidCapsLabel => 'ТЫ СКАЗАЛ';

  @override
  String get iUnderstoodLabel => 'Я понял так:';

  @override
  String get clarifyOneMoreLabel => 'Уточни ещё кое-что';

  @override
  String get foodRelationClarifyHint =>
      'Ты не сказал, до или после еды. Выбери ниже или пропусти';

  @override
  String get foodOptBefore => 'До еды';

  @override
  String get foodOptAfter => 'После еды';

  @override
  String get foodOptNotImportant => 'Не важно';

  @override
  String get refFoodAnyLabel => 'Независимо от еды';

  @override
  String possibleSideEffectsLabel(String list) {
    return '⚡ Возможные побочные эффекты: $list';
  }

  @override
  String get referenceInfoDisclaimer =>
      '⚠️ Справочно, без гарантий. Сверьтесь с инструкцией к препарату.';

  @override
  String get nextShortAction => 'Далее';

  @override
  String get backupScreenTitle => 'Резервная копия';

  @override
  String get backupIntroBody =>
      'Лекарства, расписание, медкарта (фото/PDF) и все остальные данные — выбирайте, где хранить резервную копию.';

  @override
  String get backupModeLocalTitle => 'Только на устройстве';

  @override
  String get backupModeLocalSubtitle =>
      'При переустановке приложения все данные будут потеряны';

  @override
  String get backupModeGoogleDriveSubtitle =>
      'Зашифровано на устройстве — Elly и Google не видят ваши данные';

  @override
  String get backupModeICloudSubtitle =>
      'Зашифровано на устройстве — Elly и Apple не видят ваши данные';

  @override
  String get backupFrequencyCapsLabel => 'ЧАСТОТА АВТОБЭКАПА';

  @override
  String get backupFrequencyDailyLabel => 'Раз в день';

  @override
  String get backupFrequencyWeeklyLabel => 'Раз в неделю';

  @override
  String get backupFrequencyExplainerBody =>
      'Срабатывает, когда вы открываете приложение или возвращаетесь в него — это не настоящее фоновое расписание. Если не открывать Elly дольше выбранной частоты, бэкап будет сделан сразу при следующем открытии.';

  @override
  String get backupNeverDoneLabel => 'Резервной копии ещё не было';

  @override
  String lastBackupAtLabel(String date) {
    return 'Последний бэкап: $date';
  }

  @override
  String get createBackupNowAction => 'Создать резервную копию сейчас';

  @override
  String get restoreFromBackupAction => 'Восстановить из резервной копии';

  @override
  String get changeBackupPassphraseAction => 'Изменить пароль резервной копии';

  @override
  String get backupPassphraseDialogTitle => 'Пароль для резервной копии';

  @override
  String get backupPassphraseDialogSubtitle =>
      'Придумайте пароль. Без него восстановить данные будет невозможно — даже нам.';

  @override
  String backupSavedSnackbar(String target) {
    return 'Резервная копия сохранена в $target';
  }

  @override
  String get restorePassphraseDialogTitle => 'Пароль резервной копии';

  @override
  String get restorePassphraseDialogSubtitle =>
      'Введите пароль, который вы указали при создании копии.';

  @override
  String get restoreDoneBody => 'Данные восстановлены.';

  @override
  String get restoreFailedError =>
      'Не удалось восстановить: неверный пароль или копия отсутствует';

  @override
  String get changePassphraseDialogTitle => 'Новый пароль резервной копии';

  @override
  String get changePassphraseDialogSubtitle =>
      'Сразу после изменения будет создана новая резервная копия с этим паролем — запомните его, старую резервную копию под старым паролем больше нельзя будет использовать.';

  @override
  String get passphraseChangedSnackbar =>
      'Пароль изменён, новая резервная копия сохранена';

  @override
  String get confirmRestoreTitle => 'Восстановить из резервной копии?';

  @override
  String get confirmRestoreBody =>
      'Текущие данные на этом устройстве будут заменены данными из резервной копии. Это действие нельзя отменить.';

  @override
  String get restoreAction => 'Восстановить';

  @override
  String get confirmPasswordFieldLabel => 'Повторите пароль';

  @override
  String get passwordTooShortError => 'Пароль должен быть не короче 6 символов';

  @override
  String get passwordsMismatchError => 'Пароли не совпадают';

  @override
  String get gotItAction => 'Понятно';

  @override
  String get choosePlanTitle => 'Выбери план';

  @override
  String get choosePlanSubtitle => 'Забота о здоровье всей семьи';

  @override
  String get monthToggleLabel => 'Месяц';

  @override
  String get yearToggleDiscountLabel => 'Год −20%';

  @override
  String get familyTiesBrokenTitle => 'Связи с семьёй разорвутся';

  @override
  String get familyTiesBrokenBody =>
      'Участники вашей семейной группы сразу потеряют доступ к плюшкам Family и перестанут видеть друг друга. Это произойдёт мгновенно, без грейс-периода — вы уже предупреждены сейчас.';

  @override
  String get breakAndChangePlanAction => 'Разорвать и изменить план';

  @override
  String planActivatedTestSnackbar(String plan) {
    return '$plan активирован (тестовый режим, без реальной оплаты)';
  }

  @override
  String actionFailedError(String error) {
    return 'Не удалось: $error';
  }

  @override
  String get planForeverPeriod => 'навсегда';

  @override
  String get planPerMonthYearlyPeriod => 'в месяц (год)';

  @override
  String get planPerMonthPeriod => 'ежемесячно';

  @override
  String get freeFeatureAllSections => 'Все разделы без ограничений';

  @override
  String get freeFeatureUnlimitedMeds => 'Неограниченно лекарств и медкарт';

  @override
  String get freeFeatureScanLimit => '3 сканирования фото рецепта';

  @override
  String get freeFeatureVoiceLimit => '5 голосовых команд';

  @override
  String get freeFeatureLocalBackup => 'Локально + копия в Google Drive/iCloud';

  @override
  String get selectFreeAction => 'Выбрать Бесплатный';

  @override
  String get plusFeatureAllFree => 'Всё из бесплатного';

  @override
  String get plusFeatureUnlimitedScans => 'Неограниченные сканирования фото';

  @override
  String get plusFeatureUnlimitedVoice => 'Неограниченные голосовые команды';

  @override
  String get plusFeatureServerSync => 'Синхронизация с сервером (зашифровано)';

  @override
  String get plusFeatureUnlimitedProfiles =>
      'Неограниченное количество локальных профилей';

  @override
  String get selectPlusAction => 'Выбрать Plus';

  @override
  String get familyFeatureAllPlus => 'Всё из Elly Plus';

  @override
  String get familyFeatureAutonomousProfiles =>
      'Автономные профили — до 8 человек';

  @override
  String get familyFeatureSelfManaged => 'Каждый управляет своим профилем сам';

  @override
  String get selectFamilyAction => 'Выбрать Family';

  @override
  String get billingTermsDisclaimer =>
      'Оплата списывается с вашей учётной записи App Store или Google Play. Подписка автоматически продлевается на новый период по той же цене, если не отменить как минимум за 24 часа до окончания периода. Управлять подпиской и отменить автопродление можно в настройках учётной записи App Store · Google Play.';

  @override
  String get privacyPolicyLinkLabel => 'Политика конфиденциальности';

  @override
  String get termsOfUseLinkLabel => 'Условия использования';

  @override
  String get currentPlanLabel => 'Текущий';

  @override
  String get tooManyProfilesForPlanTitle =>
      'Слишком много профилей для этого плана';

  @override
  String get upgradeToEditSubtitle =>
      'Продлите Elly Plus или Elly Family, чтобы редактировать';

  @override
  String get viewPlansAction => 'Посмотреть тарифы';

  @override
  String get paymentFailedTitle => 'Не удалось списать оплату';

  @override
  String gracePeriodRemainingBody(String timeLeft) {
    return 'Осталось $timeLeft, чтобы обновить способ оплаты — пока всё работает без ограничений, и для вас, и для всех участников вашей семейной группы.';
  }

  @override
  String get gracePeriodExpiredBody =>
      'Обновите способ оплаты немедленно, иначе семейная группа разорвётся.';

  @override
  String get laterAction => 'Позже';

  @override
  String get updatePaymentAction => 'Обновить оплату';

  @override
  String get accessChangedTitle => 'Доступ изменился';

  @override
  String get changePlanAction => 'Изменить план';

  @override
  String daysLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String hoursLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String minutesLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return '$_temp0';
  }

  @override
  String get planFreeShortLabel => 'Бесплатный';

  @override
  String get exportShareSubject => 'Elly — экспорт данных';

  @override
  String get exportCopyTitle => 'Копия всех ваших данных';

  @override
  String get exportDescriptionBody =>
      'Файл в формате JSON со всеми профилями, лекарствами, расписанием, приёмами, самочувствием и записями к врачам — всё, что хранится на этом устройстве. Вы можете открыть его где угодно или передать кому угодно.\n\nФото лекарств в файл не входят (они уже есть в «Резервной копии») — только текстовые данные.';

  @override
  String get exportAction => 'Экспортировать';

  @override
  String get appLockedTitle => 'Elly заблокирован';

  @override
  String get authFailedRetryBody =>
      'Не удалось подтвердить личность — попробуйте ещё раз';

  @override
  String get confirmIdentityBody => 'Подтвердите личность, чтобы продолжить';

  @override
  String get checkingDotsLabel => 'Проверка...';

  @override
  String get unlockAction => 'Разблокировать';

  @override
  String get addTypeSheetTitle => 'Что хотите добавить?';

  @override
  String get addTypeSheetSubtitle => 'Выберите тип — форма подстроится';

  @override
  String get addTypeMedsSub => 'Расписание, дозировка, AI-скан рецепта';

  @override
  String get addTypeActivitySub => 'Прогулка, зарядка, упражнения, ЛФК';

  @override
  String get addTypeWellbeingSub =>
      'Сделать чек-ин — настроение, симптомы, комментарий';

  @override
  String get addTypeAppointmentSub =>
      'Выбрать специалиста, время и получить напоминание';

  @override
  String get voiceCommandLabel => 'Голосовая команда';

  @override
  String get faqGroupPrivacyTitle => 'Приватность и данные';

  @override
  String get faqPrivacyQ1 => 'Кто видит мои данные?';

  @override
  String get faqPrivacyA1 =>
      'Никто, кроме вас. Всё хранится зашифрованным на вашем устройстве (SQLCipher, AES-256). Сервер Elly намеренно \"слепой\": регистрации через email или пароль нет, а то, что всё же проходит через сервер (приглашения в семью, синхронизация, подтверждение подписки), видит только зашифрованные блоки и технические идентификаторы — без ключа расшифровать их невозможно.';

  @override
  String get faqPrivacyQ2 =>
      'В чём разница между Резервной копией и Приглашением в семью?';

  @override
  String get faqPrivacyA2 =>
      'Резервная копия — снимок ваших собственных данных в вашем Google Drive/iCloud на случай потери телефона или переустановки приложения. Приглашение в семью — живой обмен расписанием между РАЗНЫМИ людьми (например, ребёнок видит расписание мамы) через QR-код или код приглашения. Это два разных механизма: первый — про вас самих, второй — про совместный доступ между несколькими людьми.';

  @override
  String get faqPrivacyQ3 => 'Что будет, если я удалю приложение без бэкапа?';

  @override
  String get faqPrivacyA3 =>
      'Данные будут потеряны безвозвратно — копии на сервере не существует. Обязательно сделайте резервную копию заранее (Профиль → Резервная копия).';

  @override
  String get faqPrivacyQ4 => 'Как удалить свои данные полностью?';

  @override
  String get faqPrivacyA4 =>
      'Удалите приложение с устройства (и резервную копию с Drive/iCloud вручную, если создавали). Профиль также можно удалить отдельно — Профиль → Конфиденциальность → Опасная зона.';

  @override
  String get faqGroupFamilyTitle => 'Семья';

  @override
  String get faqFamilyQ1 => 'Как добавить члена семьи или зависимый профиль?';

  @override
  String get faqFamilyA1 =>
      'На вкладке \"Семья\" — кнопка добавления профиля. Зависимые профили (дети, пожилые родители) не имеют собственного входа — ими управляет владелец устройства.';

  @override
  String get faqFamilyQ2 =>
      'Как передать управление профилем другому человеку (например, взрослому ребёнку)?';

  @override
  String get faqFamilyA2 =>
      'На карточке локального профиля — кнопка \"Пригласить в приложение\": покажите QR-код или назовите код приглашения человеку, который присоединяется на своём устройстве. Профиль превратится из локального в автономный — человек отныне будет управлять им сам, а вся история данных сохранится. Данные шифруются ключом, производным от кода приглашения, — сервер видит только зашифрованный блок.';

  @override
  String get faqFamilyQ3 => 'Кто что видит о других членах семьи?';

  @override
  String get faqFamilyA3 =>
      'Настраивается в Профиль → Видимость для семьи — отдельно для каждого профиля.';

  @override
  String get faqGroupAiTitle => 'AI-функции';

  @override
  String get faqAiQ1 =>
      'Куда идут данные при голосовом вводе или скане рецепта?';

  @override
  String get faqAiA1 =>
      'Распознавание происходит через модель Claude от Anthropic — это явно указывается в запросе согласия перед первым использованием каждой функции. Свободное текстовое описание самочувствия или симптомов в облако никогда не отправляется.';

  @override
  String get faqAiQ2 =>
      'Насколько точна справочная информация о лекарствах от AI?';

  @override
  String get faqAiA2 =>
      'Это ориентировочная информация из общих знаний модели, а не проверенный медицинский каталог. Всегда сверяйтесь с инструкцией к препарату или врачом.';

  @override
  String get faqNotificationsQ1 => 'Почему не приходят напоминания?';

  @override
  String get faqNotificationsA1 =>
      'Самая частая причина — оптимизация батареи на Android ограничивает фоновую работу приложения. Добавьте Elly в исключения в настройках энергосбережения устройства. Также проверьте \"Тихие часы\" в Профиль → Уведомления.';

  @override
  String get faqNotificationsQ2 =>
      'Как настроить повторное напоминание, если не отметил приём?';

  @override
  String get faqNotificationsA2 =>
      'Профиль → Уведомления → \"Повторить, если нет ответа\" — выберите интервал ползунком.';

  @override
  String get faqPlansQ1 => 'Чем отличаются тарифы?';

  @override
  String get faqPlansA1 =>
      'Elly (бесплатный) — базовые функции с ограничениями. Elly Plus и Elly Family снимают лимиты и добавляют расширенные возможности. Подробности — Профиль → Тарифы.';

  @override
  String get faqGroupTechTitle => 'Технические проблемы';

  @override
  String get faqTechQ1 =>
      'Не работает биометрия / забыл пароль от резервной копии';

  @override
  String get faqTechA1 =>
      'Пароль резервной копии запоминается только локально на этом устройстве (чтобы автоматические копии по расписанию не спрашивали его каждый раз) — на наши серверы он никогда не попадает. Если вы переустановите приложение или смените устройство, придётся ввести тот же пароль вручную; если забыли его — восстановить копию невозможно, придётся создать новую. Биометрию можно перенастроить в системных настройках устройства.';

  @override
  String get faqTechQ2 => 'Не удаётся восстановить данные из резервной копии';

  @override
  String get faqTechA2 =>
      'Самая частая причина — неверный пароль (тот же, который вы указали при создании копии) или отсутствует соединение с интернетом. Проверьте, что восстанавливаете копию на соответствующем типе устройства (с iCloud — только на iOS, с Google Drive — на Android или iOS). После успешного восстановления приложение попросит перезапуститься.';

  @override
  String get faqNotFoundQuestionTitle => 'Не нашли ответ?';

  @override
  String get faqWriteUsSubtitle => 'Напишите нам — ответим лично.';

  @override
  String get supportLabel => 'Поддержка';

  @override
  String get supportChatLabel => 'Чат поддержки';

  @override
  String get soonLabel => 'Скоро';

  @override
  String get notificationsMainSectionTitle => 'Основные';

  @override
  String get pushNotificationsLabel => 'Push-уведомления';

  @override
  String get pushNotificationsSub => 'Напоминания о приёме лекарств';

  @override
  String get vibrationLabel => 'Вибрация';

  @override
  String get vibrationSub => 'Вместе со звуком';

  @override
  String get reminderTimeSectionTitle => 'Время напоминаний';

  @override
  String get quietHoursSectionTitle => 'Тихие часы';

  @override
  String get doNotDisturbLabel => 'Не беспокоить';

  @override
  String get nightModeSub => 'Ночной режим';

  @override
  String get quietFromLabel => 'С';

  @override
  String get quietToLabel => 'До';

  @override
  String get memberMissedAlertsSectionTitle =>
      'Алерты при пропуске у членов семьи';

  @override
  String get familyNotificationsSectionTitle => 'Уведомления от семьи';

  @override
  String get peerNotifyExplainerBody =>
      'Эти участники разрешили присылать вам уведомления о себе. Здесь вы решаете, хотите ли вы их получать.';

  @override
  String get reminderOffsetLabel => 'Смещение напоминания';

  @override
  String get reminderOffsetSub =>
      'Получать за N мин до запланированного времени';

  @override
  String get noOffsetLabel => 'без смещения';

  @override
  String minusMinutesLabel(int minutes) {
    return '−$minutes мин';
  }

  @override
  String get repeatIfNoResponseLabel => 'Повторить, если нет ответа';

  @override
  String repeatInLabel(String label) {
    return 'Через $label';
  }

  @override
  String get deleteActivityConfirmTitle => 'Удалить активность?';

  @override
  String get deleteActivityConfirmBody =>
      'Активность будет удалена из расписания.';

  @override
  String get chooseActivityTypeError => 'Выберите тип активности';

  @override
  String get enterActivityNameError => 'Введите название активности';

  @override
  String get editActivityTitle => 'Редактировать активность';

  @override
  String get activityTypeLabel => 'Тип активности';

  @override
  String get activityTypeWorkout => 'Зарядка';

  @override
  String get activityTypeGym => 'Тренировка';

  @override
  String get activityTypeYoga => 'Йога / ЛФК';

  @override
  String get activityTypeCycling => 'Велосипед';

  @override
  String get activityTypeCustom => 'Своё';

  @override
  String get activityNameHint => 'Название активности';

  @override
  String get youtubeLinkLabel => 'Ссылка на YouTube';

  @override
  String get youtubeLinkDescription =>
      'Видео тренировки или клип — превью будет показываться в карточке на сегодня';

  @override
  String get addAnotherActivityAction => 'Добавить ещё занятие';

  @override
  String get weekdaysLabel => 'Дни недели';

  @override
  String get reminderLabel => 'Напоминание';

  @override
  String get reminderActivityDescription => 'За 10 минут до каждого занятия';

  @override
  String get saveActivityAction => 'Сохранить активность';

  @override
  String activitySessionNumberLabel(int number) {
    return 'Занятие $number';
  }

  @override
  String get noDurationLabel => 'Без длительности';

  @override
  String saveWithDurationLabel(String duration) {
    return 'Сохранить · $duration';
  }

  @override
  String durationHoursMinutesLabel(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String minutesWithValueLabel(String value) {
    return '$value мин';
  }

  @override
  String get taskColorPickerLabel => 'ЦВЕТ КАРТОЧКИ';

  @override
  String viewingProfileLabel(String name) {
    return 'Вы просматриваете профиль: $name';
  }

  @override
  String get returnAction => 'Вернуться';

  @override
  String get foodRelationUnspecified => 'Не выбрано';

  @override
  String get foodRelationWith => 'Во время еды';

  @override
  String get foodRelationPickerTitle => 'Относительно еды';

  @override
  String get recoveryKeyDialogTitle => 'Ваш recovery key';

  @override
  String get recoveryKeyDialogBody =>
      'Сохраните этот код в надёжном месте. Это единственный способ восстановить данные на новом устройстве — без него мы тоже не сможем помочь.';

  @override
  String get copiedSnackbar => 'Скопировано';

  @override
  String get recoveryKeySavedConfirmAction => 'Я сохранил(-а) код';

  @override
  String get buyAction => 'Купить';

  @override
  String get affiliateDisclaimerLabel =>
      'Реклама · партнёрская ссылка, Elly товар не продаёт';

  @override
  String get legalPageLoadError =>
      'Не удалось загрузить страницу. Проверьте соединение с интернетом.';

  @override
  String get medFormTablet => 'Таблетка';

  @override
  String get medFormCapsule => 'Капсула';

  @override
  String get medFormSuppository => 'Свечи';

  @override
  String get medFormVial => 'Флакон';

  @override
  String get medFormSyrup => 'Сироп';

  @override
  String get medFormDrops => 'Капли';

  @override
  String get medFormCream => 'Крем';

  @override
  String get medFormInhaler => 'Ингалятор';

  @override
  String get medFormInjection => 'Инъекция';

  @override
  String get medUnitTablet => 'таб.';

  @override
  String get medUnitCapsule => 'капс.';

  @override
  String get medUnitMl => 'мл';

  @override
  String get medUnitDrops => 'кап.';

  @override
  String get medUnitGram => 'г';

  @override
  String get medUnitInhale => 'вдох';

  @override
  String get medUnitSuppository => 'свеча';

  @override
  String get medUnitVial => 'фл.';

  @override
  String get medUnitPiece => 'шт.';

  @override
  String get chooseProfileLabel => 'Выберите профиль';

  @override
  String get otherSpecialtyDialogTitle => 'Другое направление';

  @override
  String get otherSpecialtyHint => 'Напр. Гомеопат';

  @override
  String get chooseAction => 'Выбрать';

  @override
  String get doctorSpecialtyPickerTitle => 'Направление врача';

  @override
  String get specialtySearchHint => 'Поиск…';

  @override
  String get specialtyTherapist => 'Терапевт';

  @override
  String get specialtyPediatrician => 'Педиатр';

  @override
  String get specialtyFamilyDoctor => 'Семейный врач';

  @override
  String get specialtyCardiologist => 'Кардиолог';

  @override
  String get specialtyNeurologist => 'Невролог';

  @override
  String get specialtyEndocrinologist => 'Эндокринолог';

  @override
  String get specialtyGastroenterologist => 'Гастроэнтеролог';

  @override
  String get specialtyDermatologist => 'Дерматолог';

  @override
  String get specialtyOphthalmologist => 'Офтальмолог';

  @override
  String get specialtyEnt => 'ЛОР (Отоларинголог)';

  @override
  String get specialtyDentist => 'Стоматолог';

  @override
  String get specialtyGynecologist => 'Гинеколог';

  @override
  String get specialtyUrologist => 'Уролог';

  @override
  String get specialtySurgeon => 'Хирург';

  @override
  String get specialtyOrthopedist => 'Ортопед';

  @override
  String get specialtyTraumatologist => 'Травматолог';

  @override
  String get specialtyAllergist => 'Аллерголог';

  @override
  String get specialtyImmunologist => 'Иммунолог';

  @override
  String get specialtyPsychiatrist => 'Психиатр';

  @override
  String get specialtyPsychotherapist => 'Психотерапевт';

  @override
  String get specialtyUltrasoundDiagnostics => 'УЗИ-диагностика';

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
  String get specialtyMammologist => 'Маммолог';

  @override
  String get specialtyOther => 'Другое';

  @override
  String get noDocumentsLabel => 'Нет документов';

  @override
  String get addPhotoOrPdfLabel => 'Добавить фото или PDF';

  @override
  String get labTestCbc => 'Общий анализ крови';

  @override
  String get labTestUrinalysis => 'Общий анализ мочи';

  @override
  String get labTestBloodChemistry => 'Биохимический анализ крови';

  @override
  String get labTestBloodGlucose => 'Глюкоза крови';

  @override
  String get labTestLipidProfile => 'Липидный профиль (холестерин)';

  @override
  String get labTestTsh => 'Гормоны щитовидной железы (ТТГ)';

  @override
  String get labTestFreeT3 => 'Т3 свободный';

  @override
  String get labTestFreeT4 => 'Т4 свободный';

  @override
  String get labTestLiverEnzymes => 'Печёночные пробы (АЛТ, АСТ)';

  @override
  String get labTestBilirubin => 'Билирубин';

  @override
  String get labTestCreatinine => 'Креатинин';

  @override
  String get labTestUrea => 'Мочевина';

  @override
  String get labTestUricAcid => 'Мочевая кислота';

  @override
  String get labTestSerumIron => 'Железо сыворотки';

  @override
  String get labTestFerritin => 'Ферритин';

  @override
  String get labTestVitaminD => 'Витамин D';

  @override
  String get labTestVitaminB12 => 'Витамин B12';

  @override
  String get labTestFolicAcid => 'Фолиевая кислота';

  @override
  String get labTestCoagulogram => 'Коагулограмма';

  @override
  String get labTestBloodType => 'Группа крови и резус-фактор';

  @override
  String get labTestCrp => 'С-реактивный белок (СРБ)';

  @override
  String get labTestEsr => 'Скорость оседания эритроцитов (СОЭ)';

  @override
  String get labTestEstrogenProgesterone => 'Эстроген, прогестерон';

  @override
  String get labTestTestosterone => 'Тестостерон';

  @override
  String get labTestProlactin => 'Пролактин';

  @override
  String get labTestInsulin => 'Инсулин';

  @override
  String get labTestHba1c => 'Гликированный гемоглобин (HbA1c)';

  @override
  String get labTestPcr => 'ПЦР-тест';

  @override
  String get labTestAllergens => 'Анализ на аллергены';

  @override
  String get labTestCoprogram => 'Копрограмма';

  @override
  String get labTestOccultBlood => 'Анализ кала на скрытую кровь';

  @override
  String get labTestFloraSwab => 'Мазок на флору';

  @override
  String get labTestUrineCulture => 'Посев мочи на стерильность';

  @override
  String get labTestHepatitis => 'Анализ на гепатиты (B, C)';

  @override
  String get labTestHiv => 'ВИЧ-тест';

  @override
  String get labTestSyphilis => 'RW (сифилис)';

  @override
  String get labTestCalcium => 'Кальций';

  @override
  String get labTestMagnesium => 'Магний';

  @override
  String get labTestElectrolytesKNaCl => 'Калий, натрий, хлор';

  @override
  String get labTestAmylase => 'Амилаза';

  @override
  String get labTestLipase => 'Липаза';

  @override
  String get labTestPsa => 'ПСА (простатспецифический антиген)';

  @override
  String get labTestTumorMarkers => 'Онкомаркеры (СА-125)';

  @override
  String get labTestParasites => 'Анализ на паразитов (яйца гельминтов)';

  @override
  String get labTestCortisol => 'Кортизол';

  @override
  String get labTestImmunogram => 'Иммунограмма';

  @override
  String get labTestSpermogram => 'Спермограмма';

  @override
  String get labTestBloodElectrolytes => 'Электролиты крови';

  @override
  String get labTestTotalProtein => 'Общий белок';

  @override
  String get labTestDDimer => 'Д-димер';

  @override
  String get notifChannelName => 'Напоминания Elly';

  @override
  String get notifChannelDesc =>
      'Напоминания о лекарствах, активностях, визитах и самочувствии';

  @override
  String get notifTakeMedTitle => '💊 Время принять лекарство';

  @override
  String get notifIntakeNoResponseTitle => '🔔 Вы ещё не отметили приём';

  @override
  String get notifBackupReminderTitle => 'Защитите свои данные';

  @override
  String get notifBackupReminderBody =>
      'Резервная копия отключена — данные хранятся только на этом устройстве. Включите в Профиле, чтобы не потерять их.';

  @override
  String get notifLowStockTitle => '⚠️ Заканчиваются лекарства';

  @override
  String notifLowStockBody(String medName, int remaining, String unit) {
    return '$medName — осталось $remaining $unit';
  }

  @override
  String get notifActivityTitle => '🚶 Время для активности';

  @override
  String get notifActivityNoResponseTitle => '🔔 Вы ещё не отметили активность';

  @override
  String get notifAppointmentTitle => '🩺 Приём врача';

  @override
  String get notifAppointmentNoResponseTitle =>
      '🔔 Не забудьте про приём врача';

  @override
  String get notifWellbeingTitle => '💜 Чек-ин самочувствия';

  @override
  String get notifWellbeingBody => 'Как вы себя чувствуете?';

  @override
  String get notifVaccinationTitle => '💉 Время ревакцинации';

  @override
  String notifPeerCheckTitle(String subjectName) {
    return '🔔 Проверьте $subjectName';
  }

  @override
  String notifPeerIntakeCheckBody(String medName, String dose, String timeStr) {
    return 'Принято ли \"$medName\" ($dose) в $timeStr? Откройте приложение и дождитесь синхронизации, чтобы увидеть актуальное состояние.';
  }

  @override
  String notifPeerActivityCheckBody(String activityName, String timeStr) {
    return 'Выполнено ли \"$activityName\" в $timeStr? Откройте приложение и дождитесь синхронизации, чтобы увидеть актуальное состояние.';
  }

  @override
  String notifPeerAppointmentCheckBody(String doctorType, String timeStr) {
    return 'Состоялся ли приём (\"$doctorType\") в $timeStr? Откройте приложение и дождитесь синхронизации, чтобы увидеть актуальное состояние.';
  }

  @override
  String notifPeerWellbeingCheckBody(String timeStr) {
    return 'Сделан ли чек-ин самочувствия в $timeStr? Откройте приложение и дождитесь синхронизации, чтобы увидеть актуальное состояние.';
  }

  @override
  String forMemberSuffix(String name) {
    return ' для $name';
  }

  @override
  String get dbLoadErrorTitle => 'Нужно перезапустить Elly';

  @override
  String get dbLoadErrorBody =>
      'Закройте приложение полностью — проведите пальцем вверх от нижнего края экрана и смахните карточку Elly — а затем откройте снова. Ваши данные никуда не делись, через несколько секунд всё вернётся на место.';

  @override
  String get unlockPhoneTitle => 'Разблокируйте телефон';

  @override
  String get unlockPhoneBody =>
      'Ваши данные в безопасности — ничего не повреждено и удалять ничего не нужно. Просто iOS держит ключ шифрования заблокированным, пока телефон не разблокирован хотя бы раз после перезагрузки.';

  @override
  String get unlockStep1 =>
      'Разблокируйте телефон (Face ID, Touch ID или код-пароль).';

  @override
  String get unlockStep2 =>
      'Вернитесь в Elly — данные подгрузятся сами, ничего нажимать не нужно.';

  @override
  String get checkAgainAction => 'Проверить снова';

  @override
  String get loadingEllipsisLabel => 'Загружаю...';

  @override
  String get familyDisbandedReason =>
      'Не удалось вовремя продлить оплату Family, поэтому семейная группа расформирована. Ваши локальные данные никуда не делись.';

  @override
  String get manageSubscriptionExternallyHint =>
      'Управление подпиской открыто в App Store/Google Play — завершите отмену там.';

  @override
  String get restorePurchasesAction => 'Восстановить покупки';

  @override
  String get restorePurchasesSuccessSnackbar => 'Покупки восстановлены';

  @override
  String get restorePurchasesNothingFoundSnackbar =>
      'Активных покупок не найдено на этом Apple ID/Google-аккаунте';

  @override
  String get todayScheduleForMedLabel => 'Расписание на сегодня';

  @override
  String get intakeSnoozed => 'Перенесено';

  @override
  String get resetLocalDbConfirmTitle => 'Сбросить локальную базу данных?';

  @override
  String get resetLocalDbConfirmBody =>
      'Это удалит все данные на этом устройстве (лекарства, расписание, медкарту). Резервная копия не найдена — восстановить данные после этого будет невозможно.';

  @override
  String get resetAction => 'Сбросить';

  @override
  String get resetLocalDbAction => 'Сбросить локальную БД';

  @override
  String get petAvatarsSectionLabel => 'Домашние питомцы';
}
