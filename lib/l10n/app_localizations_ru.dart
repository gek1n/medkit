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
  String get navMedCard => 'Полки';

  @override
  String todayProgressTitle(int taken, int total) {
    return '$taken из $total';
  }

  @override
  String get todayProgressSubtitle => 'позиций инвентаря использовано сегодня';

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
  String get todayHurtsNow => 'Добавить\nнастроение';

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
  String get defaultMedName => 'Инвентарь';

  @override
  String get defaultActivityName => 'Активность';

  @override
  String get wellbeingTitle => 'Настроение';

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
  String get wellbeingTimeToCheck => 'Время проверить настроение';

  @override
  String get wellbeingCommentHint =>
      'Оцените настроение и, при желании, добавьте заметку';

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
  String get categoryMeds => 'Инвентарь';

  @override
  String get categoryActivities => 'Активности';

  @override
  String get categoryWellbeing => 'Настроение';

  @override
  String get categoryDoctors => 'Напоминания';

  @override
  String get scheduleTitle => 'Расписание';

  @override
  String get scheduleCategoryPickerTitle => 'Раздел';

  @override
  String get calendarNoTimeLabel => 'Без времени';

  @override
  String get scheduleViewList => 'Список';

  @override
  String get scheduleViewCalendar => 'Календарь';

  @override
  String get scheduleViewPickerTitle => 'Формат просмотра';

  @override
  String get searchAllSections => 'Поиск по всем разделам';

  @override
  String get searchHint => 'Поиск';

  @override
  String get noResultsFoundHint => 'Ничего не найдено';

  @override
  String get sectionMeds => 'Инвентарь';

  @override
  String get noActiveMeds => 'Нет активного инвентаря';

  @override
  String get sectionAppointments => 'Напоминания';

  @override
  String get noScheduledAppointments => 'Нет запланированных приёмов';

  @override
  String get sectionActivities => 'Активности';

  @override
  String get noActiveActivities => 'Нет активных занятий';

  @override
  String get noSimpleTasksHint => 'Нет простых задач';

  @override
  String get noRoutineTasksHint => 'Нет рутинных дел';

  @override
  String get sectionWellbeing => 'Настроение';

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
  String get courseOngoing => 'используется постоянно';

  @override
  String get courseFinished => 'завершено';

  @override
  String courseDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней осталось',
      few: '$count дня осталось',
      one: '$count день осталось',
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
  String get dayToday => 'Сегодня';

  @override
  String get dayTomorrow => 'Завтра';

  @override
  String get dayYesterday => 'Вчера';

  @override
  String get allTagsFilter => 'Все теги';

  @override
  String get allStatusesFilter => 'Все статусы';

  @override
  String get medStatusFilterPickerTitle => 'Выберите статус';

  @override
  String get medCardTitle => 'Полки';

  @override
  String get medCardArchiveTitle => 'Архив инвентаря';

  @override
  String get medCardArchiveSubtitle => 'Весь инвентарь и его статус';

  @override
  String get medCardAppointmentsTitle => 'Архив напоминаний';

  @override
  String get medCardAppointmentsSubtitle =>
      'Встречи, простые задачи, рутинные дела';

  @override
  String get medCardWellbeingHistoryTitle => 'История настроения';

  @override
  String get medCardWellbeingHistorySubtitle => 'Настроение за всё время';

  @override
  String get customSectionsHeader => 'Ваши полочки';

  @override
  String get addSectionAction => 'Добавить полочку';

  @override
  String get shelfTypeTitle => 'Полочка';

  @override
  String get shelfTypeSub => 'Свой раздел со значком и цветом';

  @override
  String get newSectionTitle => 'Новый раздел';

  @override
  String get editSectionTitle => 'Редактировать раздел';

  @override
  String get sectionNameFieldLabel => 'Название';

  @override
  String get sectionNameHint => 'Укажите название раздела для заметок';

  @override
  String get enterSectionNameError => 'Введите название';

  @override
  String get sectionIconFieldLabel => 'Иконка';

  @override
  String get chooseIconLabel => 'Выберите иконку';

  @override
  String get sectionCommentFieldLabel => 'Короткое описание';

  @override
  String get sectionCommentHint => 'До 30 символов (необязательно)';

  @override
  String get deleteSectionConfirmTitle => 'Удалить раздел?';

  @override
  String get deleteSectionConfirmBody =>
      'Раздел и все записи в нём будут удалены.';

  @override
  String get sectionEmptyHint =>
      'Здесь пусто. Добавьте первую запись через плюсик';

  @override
  String get spaceFieldLabel => 'Полка';

  @override
  String get spacePickerTitle => 'Выберите полку';

  @override
  String get noSpaceOption => 'Без полки';

  @override
  String get createNewSpaceAction => 'Создать новый раздел';

  @override
  String get newEntryTitle => 'Новая запись';

  @override
  String get editEntryTitle => 'Редактировать запись';

  @override
  String get entryTitleFieldLabel => 'Название';

  @override
  String get entryTitleHint => 'Название записи';

  @override
  String get enterEntryTitleError => 'Введите название';

  @override
  String get entryDateFieldLabel => 'Дата записи';

  @override
  String get entryNotesHint => 'Произвольные заметки…';

  @override
  String get deleteEntryConfirmBody => 'Запись будет удалена.';

  @override
  String get medicationArchiveEmptyHint =>
      'Здесь появится весь инвентарь, который вы когда-либо добавляли';

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
  String get sectionPast => 'Прошедшие';

  @override
  String get emptyStateNoneYetTitle => 'Пока ничего не добавлено';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get deleteAction => 'Удалить';

  @override
  String get documentsLabel => 'Документы';

  @override
  String get notSpecifiedValue => 'Не указано';

  @override
  String get deleteSurgeryConfirmTitle => 'Удалить запись?';

  @override
  String get editSurgeryTitle => 'Редактировать запись';

  @override
  String get removeAction => 'Убрать';

  @override
  String get medsTitle => 'Инвентарь';

  @override
  String activeMedsCountSection(int count) {
    return 'Активные ($count)';
  }

  @override
  String finishedMedsCountSection(int count) {
    return 'Завершённые ($count)';
  }

  @override
  String get noMedsYetTitle => 'Инвентаря ещё нет';

  @override
  String get noMedsYetHint => 'Нажмите +, чтобы добавить первую запись';

  @override
  String get addMedicationAction => 'Добавить в инвентарь';

  @override
  String get errorGenericShort => 'Ошибка';

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
  String get untilCourseEndLabel => 'до окончания';

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
  String get courseStagesLabel => 'Этапы';

  @override
  String untilDateLabel(String date) {
    return 'до $date';
  }

  @override
  String get ongoingLabel => 'постоянно';

  @override
  String get detailsLabel => 'Детали';

  @override
  String get intakeLabel => 'Расписание';

  @override
  String get courseNounLabel => 'Период';

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
  String get stopCourseConfirmTitle => 'Остановить?';

  @override
  String stopCourseConfirmBody(String name) {
    return '«$name» будет удалено из списка активного инвентаря.';
  }

  @override
  String get enterMedicationNameError => 'Введите название';

  @override
  String get deleteMedicationConfirmTitle => 'Удалить запись?';

  @override
  String get deleteMedicationConfirmBody =>
      'Запись будет удалена из расписания.';

  @override
  String get editMedicationTitle => 'Редактировать запись';

  @override
  String get medicationNameHint => 'Название';

  @override
  String get medicationFormLabel => 'Форма выпуска';

  @override
  String get coursePhasesLabel => 'Фазы';

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
  String phaseCardTitle(int number) {
    return 'Фаза $number';
  }

  @override
  String get removePhaseAction => 'удалить';

  @override
  String get doseAmountLabel => 'КОЛИЧЕСТВО ЗА РАЗ';

  @override
  String get doseCommentSectionLabel => 'КОММЕНТАРИЙ';

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
  String get doseCommentHint => 'Комментарий (необязательно)';

  @override
  String get doseAmountDialogTitle => 'Количество за раз';

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
  String get inStockLabel => 'В наличии';

  @override
  String howManyNowLabel(String unit) {
    return 'Сколько $unit есть сейчас';
  }

  @override
  String get enoughForCourseLabel => 'Хватит на весь период';

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
  String get addPhotoHint => 'чтобы не перепутать позиции инвентаря';

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
    return 'Вы присоединяетесь как равноправный участник — ваш собственный профиль (имя и аватар) станет видимым \"$name\". Это не отменяет и не изменяет никакие ваши данные, уже внесённые в приложение. Ваш архив НИКОМУ автоматически не показывается — какие именно данные будут видеть другие участники, вы настроите отдельно, уже после присоединения.';
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
  String familySectionAccessClosedTitle(String name, String section) {
    return '«$name» закрыл(-а) доступ к разделу «$section»';
  }

  @override
  String get familySectionAccessClosedBody =>
      'Попросите поделиться, если хотите видеть эти записи';

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
  String sendFailedError(String error) {
    return 'Не удалось отправить: $error';
  }

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
  String get noMedsTodayLabel => 'Нет задач на сегодня';

  @override
  String get allDoneTodayLabel => 'Всё выполнено сегодня';

  @override
  String takenOfTotalIntakesLabel(int taken, int total) {
    return '$taken из $total приёмов';
  }

  @override
  String tasksProgressLabel(int taken, int total) {
    return '$taken из $total задач';
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
    return 'Будут удалены всё расписание и все записи из Полочек, привязанные к профилю $name';
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
    return 'Вы заботитесь о $_temp0. Элли пришлёт уведомление, если кто-то пропустит напоминание.';
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
  String get routineTasksLimitBadge => 'Рутинные дела';

  @override
  String get routineTasksLimitTitle => 'Лимит рутинных дел';

  @override
  String routineTasksLimitSubtitle(int used, int max) {
    return 'Использовано $used из $max. Перейдите на Elly Plus — неограниченное количество';
  }

  @override
  String get routineTasksLimitDeniedTitle => 'Лимит рутинных дел достигнут';

  @override
  String get routineTasksLimitDeniedSubtitle =>
      'На бесплатном тарифе доступно только 1 рутинное дело. Перейдите на Elly Plus для неограниченного количества';

  @override
  String get medcardSectionsLimitBadge => 'Полки';

  @override
  String get medcardSectionsLimitTitle => 'Лимит полок';

  @override
  String medcardSectionsLimitSubtitle(int used, int max) {
    return 'Использовано $used из $max. Перейдите на Elly Plus — неограниченное количество';
  }

  @override
  String get medcardSectionsLimitDeniedTitle => 'Лимит полок достигнут';

  @override
  String get medcardSectionsLimitDeniedSubtitle =>
      'На бесплатном тарифе доступно до 3 полок. Перейдите на Elly Plus для неограниченного количества';

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
  String get localUsersSectionLabel => 'Локальные пользователи';

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
  String get reminderWellbeingBody => 'Не забудьте отметить настроение';

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
  String get shareDbFileAction => 'Поделиться файлом БД';

  @override
  String get shareDbFileEmptySnackbar => 'Файл БД не найден';

  @override
  String get clearAction => 'Очистить';

  @override
  String get shareAction => 'Поделиться';

  @override
  String get antiStressLabel => 'Антистресс-упражнения';

  @override
  String get antiStressPickerSubtitle =>
      'Короткие упражнения на несколько минут';

  @override
  String get breathingExerciseTitle => 'Дышим вместе';

  @override
  String get breathingExerciseSubtitle =>
      'Медленное дыхание в своём темпе — 2 минуты';

  @override
  String get grounding54321Title => '5-4-3-2-1';

  @override
  String get grounding54321Subtitle =>
      'Короткое упражнение на 5 шагов с органами чувств';

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
      'Синхронизировать данные профиля на другие устройства';

  @override
  String get medcardSyncDescription =>
      'Если выключено, напоминания этого профиля (вместе с вложениями) не передаются на другие устройства семьи, подключённые через пейринг. Инвентарь и расписание использования синхронизируются независимо от этого переключателя.';

  @override
  String get pendingConnectionLabel => 'Ожидаем соединения';

  @override
  String get viewerNotifyPermissionLabel => 'Получает уведомления';

  @override
  String get viewerEditPermissionLabel => 'Может редактировать профиль';

  @override
  String get viewerViewPermissionLabel => 'Видит задачи, полки и расписание';

  @override
  String get familySectionsIntro =>
      'Что именно видит и может редактировать этот участник, пока доступ включён выше';

  @override
  String get familySectionScheduleLabel => 'Расписание';

  @override
  String get familySectionVisitsWellbeingLabel => 'Визиты и самочувствие';

  @override
  String get familySectionShelvesLabel => 'Полочки';

  @override
  String get familySectionViewColumnLabel => 'Просмотр';

  @override
  String get familySectionEditColumnLabel => 'Редактирование';

  @override
  String get yesAction => 'Да';

  @override
  String familyJoinPopupOwnerBody(String name) {
    return 'В семью добавился новый участник $name. Хотите поделиться своими записями?';
  }

  @override
  String familyJoinPopupInviteeBody(String name) {
    return 'Вас добавили в семью $name. Хотите поделиться своими записями?';
  }

  @override
  String get permissionDeniedNotYoursBody =>
      'Не удалось изменить — это не ваш профиль';

  @override
  String get privacyLabel => 'Конфиденциальность';

  @override
  String get securityLabel => 'Безопасность';

  @override
  String get privacyPolicyLabel => 'Политика конфиденциальности';

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
  String get groundingCompletedTitle => 'Упражнение завершено';

  @override
  String get groundingCompletedSubtitle =>
      'Отличная работа. Возвращайся к этому упражнению, когда понадобится.';

  @override
  String get healthSectionHeader => 'Мини-игры';

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
      'Управляет языком интерфейса и надиктовки комментариев. Пока доступны украинский, английский и русский — другие языки появятся после переводов.';

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
  String get appointmentsHistoryTitle => 'Архив напоминаний';

  @override
  String get sectionFuture => 'Будущие';

  @override
  String get visitPassedLabel => '✓ прошло';

  @override
  String get arrowRightLabel => '→';

  @override
  String get noRecordsYetTitle => 'Записей ещё нет';

  @override
  String get remindersArchiveEmptyHint =>
      'Здесь будут храниться все созданные напоминания. Нажмите «+», чтобы добавить первое';

  @override
  String get noAppointmentsForSpecialty => 'Нет напоминаний с этим тегом';

  @override
  String get tryDifferentSpecialtyHint =>
      'Попробуйте выбрать другой тег или сбросить фильтр';

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
  String get remindBeforeAtTime => 'В указанное время';

  @override
  String get remindBefore10Min => 'За 10 минут';

  @override
  String get remindBefore30Min => 'За 30 минут';

  @override
  String get remindBefore1Hour => 'За 1 час';

  @override
  String get remindBefore1Day => 'За день';

  @override
  String get remindBefore2Days => 'За 2 дня';

  @override
  String get deleteAppointmentBody => 'Напоминание будет удалено.';

  @override
  String get newAppointmentTitle => 'Новое напоминание';

  @override
  String get fieldWhere => 'Где';

  @override
  String get locationHint => 'Укажите адрес или название';

  @override
  String get fieldDateTime => 'Дата и время';

  @override
  String get dateCapsLabel => 'ДАТА';

  @override
  String get timeCapsLabel => 'ВРЕМЯ';

  @override
  String get remindBeforeLabel => 'Напомнить заранее';

  @override
  String get noteSingularLabel => 'Заметка';

  @override
  String get reminderNoteHint => 'Дополнительные детали…';

  @override
  String get saveReminderAction => 'Сохранить напоминание';

  @override
  String get reminderTitleFieldLabel => 'Название';

  @override
  String get reminderTitleHint => 'Укажите, о чём напомнить';

  @override
  String get enterReminderTitleError => 'Введите название';

  @override
  String get reminderRepeatSectionLabel => 'Повторение';

  @override
  String get reminderRepeatOnceLabel => 'Не повторять';

  @override
  String get reminderRepeatDailyLabel => 'Ежедневно';

  @override
  String get reminderRepeatWeeklyLabel => 'Определённые дни недели';

  @override
  String get reminderRepeatMonthlyLabel => 'Ежемесячно';

  @override
  String get reminderRepeatYearlyLabel => 'Ежегодно';

  @override
  String get reminderYearlyDateFieldLabel => 'Дата (год не важен)';

  @override
  String get reminderMonthlyDayFieldLabel => 'День месяца';

  @override
  String get dayOfMonthCapsLabel => 'ДЕНЬ';

  @override
  String get routineRepeatSectionLabel => 'Повторение';

  @override
  String get routineRepeatEveryNDaysOption => 'Каждые N дней';

  @override
  String get routineRepeatWeeklyGoalOption => 'N раз в неделю';

  @override
  String routineIntervalDaysValueLabel(int n) {
    return 'Каждые $n дн.';
  }

  @override
  String routineWeeklyGoalValueLabel(int n) {
    return '$n р./неделю';
  }

  @override
  String get routineTimeFieldLabel => 'Время';

  @override
  String get routineFixedTimeOption => 'В определённое время';

  @override
  String get routineNoFixedTimeOption => 'Без конкретного времени';

  @override
  String get routineWhoDoesLabel => 'Кто выполняет';

  @override
  String get routineRotationCadenceLabel => 'Как часто меняется очередь';

  @override
  String get routineRotationCadencePerOccurrence => 'Каждый раз';

  @override
  String get routineRotationCadenceWeekly => 'Еженедельно';

  @override
  String get routineRotationCadenceMonthly => 'Ежемесячно';

  @override
  String routineRotationSummary(int n) {
    return 'По очереди ($n)';
  }

  @override
  String get routineStepsLabel => 'Шаги';

  @override
  String get routineStepsSheetTitle => 'Шаги выполнения';

  @override
  String get routineAddStepHint => 'Добавить шаг…';

  @override
  String routineWhoseTurnLabel(String name) {
    return 'Очередь: $name';
  }

  @override
  String get routineSwapTurnAction => 'Поменяться';

  @override
  String get routineSkipTurnAction => 'Пропустить очередь';

  @override
  String get routineTakeTurnAction => 'Взять очередь на себя';

  @override
  String routineWeeklyGoalProgressLabel(int done, int total) {
    return '$done/$total на этой неделе';
  }

  @override
  String get routinePartialStatusLabel => 'Частично';

  @override
  String routineStepsProgressLabel(int done, int total) {
    return '$done/$total шагов';
  }

  @override
  String get routineAnyTimeTodayLabel => 'Когда-нибудь сегодня';

  @override
  String get routineFormExplainer =>
      'Рутина повторяется и считает выполнение — для привычек и семейных обязанностей, в отличие от разового напоминания';

  @override
  String routineStreakDaysLabel(int n) {
    return '$n дней подряд';
  }

  @override
  String get routineNoStreakYetLabel => 'Пока нет серии — начните сегодня';

  @override
  String get routineAllRoutinesScreenTitle => 'Обязанности семьи';

  @override
  String get routineNoAssigneesHint => 'Пока нет обязанностей';

  @override
  String get defaultNotesSectionName => 'Заметки';

  @override
  String get addAnotherTimeAction => 'Добавить ещё одно время';

  @override
  String get addAtLeastOneTimeError => 'Добавьте хотя бы одно время';

  @override
  String get chooseAtLeastOneDayError => 'Выберите хотя бы один день недели';

  @override
  String get reminderTagsFieldLabel => 'Теги';

  @override
  String get reminderTagsHint => 'Теги для структурирования, через запятую';

  @override
  String get reminderTagsPickerTitle => 'Выберите теги';

  @override
  String get addNewTagHint => 'Новый тег';

  @override
  String get noTagsYetLabel => 'Пока нет ни одного тега';

  @override
  String get reminderPhotoLabel => 'Фото';

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
  String get historyLabel => 'История';

  @override
  String get wellbeingScheduleInfoText =>
      'Настройте расписание чек-инов настроения. В назначенное время на главном экране появится карточка для заполнения.';

  @override
  String get frequencyPerDayLabel => 'ЧАСТОТА В ДЕНЬ';

  @override
  String get collectionTimeLabel => 'ВРЕМЯ СБОРА';

  @override
  String wellbeingSlotNumberLabel(int index) {
    return 'Чек-ин $index';
  }

  @override
  String get reminderTimesFieldLabel => 'ВРЕМЯ НАПОМИНАНИЯ';

  @override
  String timeSlotNumberLabel(int index) {
    return 'Время $index';
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
  String get wellbeingByDaySubtitle => 'настроение по дням';

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
      'Здесь будет храниться история настроения. Нажмите «+ Чек-ин», чтобы добавить первую запись';

  @override
  String get comingSoonEllipsis => 'Скоро...';

  @override
  String get sendDiaryToDoctorLabel => 'Поделиться итогом';

  @override
  String get diarySummaryHint => 'Чек-ины настроения и приёмы за месяц';

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
  String get chooseWellbeingErrorSnackbar => 'Выберите настроение';

  @override
  String get wellbeingSlotMorning => 'утренний чек-ин';

  @override
  String get wellbeingSlotAfternoon => 'дневной чек-ин';

  @override
  String get wellbeingSlotEvening => 'вечерний чек-ин';

  @override
  String get howAreYouFeelingLabel => 'Какое у вас настроение?';

  @override
  String get anySymptomsLabel => 'Теги';

  @override
  String get chooseFromListOrAddLabel => 'Добавьте свои теги (необязательно)';

  @override
  String get commentLabel => 'Комментарий';

  @override
  String get optionalSuffixLabel => '· необязательно';

  @override
  String get orTypeTextLabel => 'или введите текстом';

  @override
  String get describeFeelingHint => 'Опишите своё настроение…';

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
      'Добавьте что-нибудь в инвентарь, чтобы активировать напоминания';

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
    return '$name уже составил(-а) для вас расписание использования инвентаря. Вы сможете отредактировать его в любой момент после подключения.';
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
      'Elly поможет не забыть об инвентаре,\nактивности и настроении — для вас\nи всей семьи';

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
  String get createAccountSubtitle => 'Настрою инвентарь и расписание для себя';

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
  String get nextToMedsAction => 'Далее — инвентарь →';

  @override
  String get scanOrEnterManuallyHint => 'Добавьте то, что используете сейчас';

  @override
  String get addMedsShortAction => 'Добавить в инвентарь';

  @override
  String get addMoreMedsAction => 'Добавить ещё';

  @override
  String get onboardingAddItemAction => 'Добавить';

  @override
  String get onboardingAddItemHint =>
      'Напоминание или инвентарь — выберите вариант';

  @override
  String get addMedsLaterInfo =>
      'Инвентарь можно добавить позже через раздел «Инвентарь» в главном меню';

  @override
  String get nextAction => 'Далее →';

  @override
  String get skipAddLaterAction => 'Пропустить — добавлю позже';

  @override
  String get activityWellbeingTitle => 'Активность и настроение';

  @override
  String get activityWellbeingSubtitle =>
      'Включите одним переключателем — настройки можно изменить позже';

  @override
  String get activitySectionLabel => 'Активность';

  @override
  String get walkActivitySub => '30 мин · ежедневно · 08:30';

  @override
  String get wellbeingDiaryLabel => 'Дневник настроения';

  @override
  String get wellbeingDiaryDescription =>
      'Короткие отметки настроения помогут увидеть связь между инвентарём и тем, какое у вас настроение';

  @override
  String get wellbeingSlotsTitle => 'Чек-ины настроения';

  @override
  String get wellbeingSlotsSub => '2–3 раза в день · 08:00, 14:00, 20:00';

  @override
  String get almostDoneAction => 'Почти готово →';

  @override
  String get backupScreenTitle => 'Резервная копия';

  @override
  String get backupIntroBody =>
      'Инвентарь, расписание, архив (фото) и все остальные данные — выбирайте, где хранить резервную копию.';

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
  String get choosePlanSubtitle => 'Забота о семье';

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
  String planActivatedSnackbar(String plan) {
    return '$plan активирован!';
  }

  @override
  String actionFailedError(String error) {
    return 'Не удалось: $error';
  }

  @override
  String get planForeverPeriod => 'навсегда';

  @override
  String get planPerYearPeriod => 'в год';

  @override
  String get planPerMonthPeriod => 'ежемесячно';

  @override
  String get freeFeatureAllSections => '1 рутинное дело, 3 раздела Полочки';

  @override
  String get freeFeatureUnlimitedMeds => 'Неограниченно напоминаний';

  @override
  String get freeFeatureLocalBackup => 'Локально + копия в Google Drive/iCloud';

  @override
  String get selectFreeAction => 'Выбрать Бесплатный';

  @override
  String get plusFeatureAllFree => 'Всё из бесплатного';

  @override
  String get plusFeatureUnlimitedProfiles =>
      'Неограниченное количество профилей семьи — управляете только вы';

  @override
  String get planFeatureUnlimitedRoutines =>
      'Неограниченное количество рутинных дел';

  @override
  String get planFeatureUnlimitedShelves => 'Неограниченное количество полок';

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
  String billingTermsDisclaimer(String store) {
    return 'Оплата списывается с вашей учётной записи $store. Подписка автоматически продлевается на новый период по той же цене, если не отменить как минимум за 24 часа до окончания периода. Управлять подпиской и отменить автопродление можно в настройках учётной записи $store.';
  }

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
      'Файл в формате JSON со всеми профилями, инвентарём, расписанием, приёмами, настроением и записями к врачам — всё, что хранится на этом устройстве. Вы можете открыть его где угодно или передать кому угодно.\n\nФото инвентаря в файл не входят (они уже есть в «Резервной копии») — только текстовые данные.';

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
  String get addTypeMedsSub =>
      'Расходный запас по расписанию — учёт остатка, когда докупить';

  @override
  String get addTypeActivitySub => 'Прогулка, зарядка, упражнения, ЛФК';

  @override
  String get addTypeAppointmentSub => 'Дата, время и напоминание о чём угодно';

  @override
  String get addTypeWellbeingSub =>
      'Сделать чек-ин — настроение, теги, комментарий';

  @override
  String get taskTypeSport => 'Спорт';

  @override
  String get taskTypeSportSub => 'Прогулка, тренировка, упражнения';

  @override
  String get taskTypeMeeting => 'Встречи';

  @override
  String get taskTypeMeetingSub => 'Дата, время и напоминание о чём угодно';

  @override
  String get taskTypeSimple => 'Простые задачи';

  @override
  String get taskTypeSimpleSub => 'Разовое или простое напоминание';

  @override
  String get taskTypeRoutine => 'Рутинные дела';

  @override
  String get taskTypeRoutineSub =>
      'Привычка или обязанность с гибким повтором — чек-лист и очередь выполнения';

  @override
  String get reminderCategoryTitle => 'Напоминание';

  @override
  String get reminderCategorySub =>
      'Событие или дело с датой — разово или с повтором';

  @override
  String get noteCategoryTitle => 'Заметка';

  @override
  String get noteCategorySub => 'Просто запись — без напоминаний';

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
  String get faqFamilyQ4 =>
      'Могу ли я одновременно состоять в нескольких семейных группах?';

  @override
  String get faqFamilyA4 =>
      'Да. Например, вы можете быть участником семьи родителей и одновременно собственной семьи, которую создали сами, — это две независимые группы. Выход из одной не влияет на другую, а данные разных семей никогда не смешиваются.';

  @override
  String get faqFamilyQ5 =>
      'Как работает очередь выполнения рутинных дел между несколькими исполнителями?';

  @override
  String get faqFamilyA5 =>
      'Когда в рутине указано несколько исполнителей, приложение само определяет, чья сейчас очередь, по выбранному кадансу: \"каждый раз\" — очередь переходит после каждого выполнения; \"раз в неделю\" — тот же исполнитель делает все вхождения в течение календарной недели, затем очередь переходит дальше; \"раз в месяц\" — так же, но на весь календарный месяц, даже если рутина повторяется несколько раз в неделю. Карточку рутины на экране \"Сегодня\" видит только тот, чья сейчас очередь; передать очередь вручную можно кнопкой \"Пропустить очередь\".';

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
  String get faqPlansQ2 => 'Какие именно ограничения у бесплатного тарифа?';

  @override
  String get faqPlansA2 =>
      '1 локальный профиль, 1 активное рутинное дело, 3 раздела Полочки. Напоминания, инвентарь и самочувствие — без ограничений на всех тарифах. Превышение лимита ничего не удаляет: старые записи остаются доступными для просмотра, редактирование или создание новых — заблокировано, пока не обновите тариф.';

  @override
  String get faqPlansQ3 => 'Сколько человек можно добавить в семейную группу?';

  @override
  String get faqPlansA3 =>
      'На тарифе Elly Family — до 8 автономных участников. Приглашать новых людей может только тот, кто оплачивает подписку; принять приглашение можно бесплатно на любом тарифе. Приглашённый получает все возможности Family, кроме права приглашать других в ЭТУ же семью.';

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
  String get pushNotificationsSub => 'Напоминания об использовании инвентаря';

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
  String get disableWellbeingConfirmTitle => 'Выключить сбор настроения?';

  @override
  String get disableWellbeingConfirmBody =>
      'Напоминания исчезнут из Расписания и Сегодня. Настройки сохранятся — можно включить снова позже.';

  @override
  String get applyAction => 'Готово';

  @override
  String get noDaysSelectedHint => 'Дни не выбраны';

  @override
  String get chooseActivityTypeError => 'Выберите тип активности';

  @override
  String get enterActivityNameError => 'Введите название активности';

  @override
  String get editActivityTitle => 'Редактировать рутину';

  @override
  String get newRoutineTitle => 'Рутина';

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
  String get stockUnitKg => 'кг';

  @override
  String get stockUnitLiter => 'л';

  @override
  String get stockUnitTube => 'туба';

  @override
  String get stockUnitPack => 'пачка';

  @override
  String get stockUnitJar => 'банка';

  @override
  String get stockUnitBottle => 'бутылка';

  @override
  String get stockUnitPortion => 'порция';

  @override
  String get stockUnitSpoon => 'ложка';

  @override
  String get stockUnitGlass => 'стакан';

  @override
  String get stockUnitLabel => 'Единица измерения';

  @override
  String get inventoryFormHint => 'Флакон, пачка, банка...';

  @override
  String get chooseProfileLabel => 'Выберите профиль';

  @override
  String get chooseAction => 'Выбрать';

  @override
  String get noDocumentsLabel => 'Нет документов';

  @override
  String get addPhotoOrPdfLabel => 'Добавить фото или PDF';

  @override
  String get documentsPrivacyHint =>
      'Хранится только на устройстве (и в облаке, если включена резервная копия) — приложение не просматривает и не анализирует эти файлы.';

  @override
  String get notifChannelName => 'Напоминания Elly';

  @override
  String get notifChannelDesc =>
      'Напоминания об инвентаре, активностях, визитах и настроении';

  @override
  String notifTakeMedTitle(String name) {
    return '⏰ Время для $name';
  }

  @override
  String notifIntakeNoResponseTitle(String name) {
    return '🔔 Вы ещё не отметили: $name';
  }

  @override
  String get notifBackupReminderTitle => 'Защитите свои данные';

  @override
  String get notifBackupReminderBody =>
      'Резервная копия отключена — данные хранятся только на этом устройстве. Включите в Профиле, чтобы не потерять их.';

  @override
  String notifPeerRecordAddedTitle(String name) {
    return '$name добавил(-а) запись';
  }

  @override
  String notifPeerRecordEditedTitle(String name) {
    return '$name изменил(-а) запись';
  }

  @override
  String get notifLowStockTitle => '⚠️ Запас заканчивается';

  @override
  String notifLowStockBody(String medName, int remaining, String unit) {
    return '$medName — осталось $remaining $unit';
  }

  @override
  String get notifActivityTitle => '🚶 Время для активности';

  @override
  String get notifActivityNoResponseTitle => '🔔 Вы ещё не отметили активность';

  @override
  String get notifAppointmentTitle => '🔔 Напоминание';

  @override
  String get notifAppointmentNoResponseTitle =>
      '🔔 Не забудьте про напоминание';

  @override
  String get notifWellbeingTitle => '💜 Чек-ин настроения';

  @override
  String get notifWellbeingBody => 'Какое у вас настроение?';

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
    return 'Состоялось ли напоминание (\"$doctorType\") в $timeStr? Откройте приложение и дождитесь синхронизации, чтобы увидеть актуальное состояние.';
  }

  @override
  String notifPeerWellbeingCheckBody(String timeStr) {
    return 'Сделан ли чек-ин настроения в $timeStr? Откройте приложение и дождитесь синхронизации, чтобы увидеть актуальное состояние.';
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
  String manageSubscriptionExternallyHint(String store) {
    return 'Управление подпиской открыто в $store — завершите отмену там.';
  }

  @override
  String get restorePurchasesAction => 'Восстановить покупки';

  @override
  String get restorePurchasesSuccessSnackbar => 'Покупки восстановлены';

  @override
  String get restorePurchasesNothingFoundSnackbar =>
      'Активных покупок не найдено на этом аккаунте';

  @override
  String get todayScheduleForMedLabel => 'Расписание на сегодня';

  @override
  String get intakeSnoozed => 'Перенесено';

  @override
  String get resetLocalDbConfirmTitle => 'Сбросить локальную базу данных?';

  @override
  String get resetLocalDbConfirmBody =>
      'Это удалит все данные на этом устройстве (инвентарь, расписание, полки). Резервная копия не найдена — восстановить данные после этого будет невозможно.';

  @override
  String get resetAction => 'Сбросить';

  @override
  String get resetLocalDbAction => 'Сбросить локальную БД';

  @override
  String get petAvatarsSectionLabel => 'Домашние питомцы';
}
