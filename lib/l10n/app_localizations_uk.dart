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
  String get navMedCard => 'Полички';

  @override
  String todayProgressTitle(int taken, int total) {
    return '$taken з $total';
  }

  @override
  String get todayProgressSubtitle => 'інвентарю використано сьогодні';

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
  String get intakeTaken => 'Виконано';

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
  String get todayHurtsNow => 'Додати\nнастрій';

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
  String get defaultMedName => 'Інвентар';

  @override
  String get defaultActivityName => 'Активність';

  @override
  String get wellbeingTitle => 'Настрій';

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
  String get wellbeingTimeToCheck => 'Час перевірити настрій';

  @override
  String get wellbeingCommentHint =>
      'Оцініть настрій і, за бажанням, додайте нотатку';

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
  String get categoryMeds => 'Інвентар';

  @override
  String get categoryActivities => 'Активності';

  @override
  String get categoryWellbeing => 'Настрій';

  @override
  String get categoryDoctors => 'Нагадування';

  @override
  String get scheduleTitle => 'Розклад';

  @override
  String get searchAllSections => 'Пошук по всіх розділах';

  @override
  String get searchHint => 'Пошук';

  @override
  String get noResultsFoundHint => 'Нічого не знайдено';

  @override
  String get sectionMeds => 'Інвентар';

  @override
  String get noActiveMeds => 'Немає активного інвентарю';

  @override
  String get sectionAppointments => 'Нагадування';

  @override
  String get noScheduledAppointments => 'Немає запланованих прийомів';

  @override
  String get sectionActivities => 'Активності';

  @override
  String get noActiveActivities => 'Немає активних занять';

  @override
  String get noSimpleTasksHint => 'Немає простих завдань';

  @override
  String get noRoutineTasksHint => 'Немає рутинних справ';

  @override
  String get sectionWellbeing => 'Настрій';

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
  String get courseOngoing => 'використовується постійно';

  @override
  String get courseFinished => 'завершено';

  @override
  String courseDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів лишилось',
      few: '$count дні лишилось',
      one: '$count день лишилось',
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
  String get dayToday => 'Сьогодні';

  @override
  String get dayTomorrow => 'Завтра';

  @override
  String get dayYesterday => 'Вчора';

  @override
  String get allTagsFilter => 'Усі теги';

  @override
  String get allStatusesFilter => 'Усі статуси';

  @override
  String get medStatusFilterPickerTitle => 'Оберіть статус';

  @override
  String get medCardTitle => 'Полички';

  @override
  String get medCardArchiveTitle => 'Архів інвентарю';

  @override
  String get medCardArchiveSubtitle => 'Весь інвентар та його статус';

  @override
  String get medCardAppointmentsTitle => 'Архів нагадувань';

  @override
  String get medCardAppointmentsSubtitle =>
      'Зустрічі, прості завдання, рутинні справи';

  @override
  String get medCardWellbeingHistoryTitle => 'Історія настрою';

  @override
  String get medCardWellbeingHistorySubtitle => 'Настрій за весь час';

  @override
  String get customSectionsHeader => 'Ваші розділи';

  @override
  String get addSectionAction => 'Додати розділ';

  @override
  String get newSectionTitle => 'Новий розділ';

  @override
  String get editSectionTitle => 'Редагувати розділ';

  @override
  String get sectionNameFieldLabel => 'Назва';

  @override
  String get sectionNameHint => 'Вкажіть назву розділу для нотаток';

  @override
  String get enterSectionNameError => 'Введіть назву';

  @override
  String get sectionIconFieldLabel => 'Іконка';

  @override
  String get chooseIconLabel => 'Оберіть іконку';

  @override
  String get sectionCommentFieldLabel => 'Короткий опис';

  @override
  String get sectionCommentHint => 'До 30 символів (необов\'язково)';

  @override
  String get deleteSectionConfirmTitle => 'Видалити розділ?';

  @override
  String get deleteSectionConfirmBody =>
      'Розділ і всі записи в ньому буде видалено.';

  @override
  String get sectionEmptyHint =>
      'Тут порожньо. Додайте перший запис через плюсик';

  @override
  String get spaceFieldLabel => 'Поличка';

  @override
  String get spacePickerTitle => 'Оберіть поличку';

  @override
  String get noSpaceOption => 'Без полички';

  @override
  String get createNewSpaceAction => 'Створити новий розділ';

  @override
  String get newEntryTitle => 'Новий запис';

  @override
  String get editEntryTitle => 'Редагувати запис';

  @override
  String get entryTitleFieldLabel => 'Назва';

  @override
  String get entryTitleHint => 'Назва запису';

  @override
  String get enterEntryTitleError => 'Введіть назву';

  @override
  String get entryDateFieldLabel => 'Дата запису';

  @override
  String get entryNotesHint => 'Довільні нотатки…';

  @override
  String get deleteEntryConfirmBody => 'Запис буде видалено.';

  @override
  String get medicationArchiveEmptyHint =>
      'Тут з\'явиться весь інвентар, який ви колись додавали';

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
  String get sectionPast => 'Минулі';

  @override
  String get emptyStateNoneYetTitle => 'Ще нічого не додано';

  @override
  String get actionCancel => 'Скасувати';

  @override
  String get deleteAction => 'Видалити';

  @override
  String get documentsLabel => 'Документи';

  @override
  String get notSpecifiedValue => 'Не вказано';

  @override
  String get deleteSurgeryConfirmTitle => 'Видалити запис?';

  @override
  String get editSurgeryTitle => 'Редагувати запис';

  @override
  String get removeAction => 'Прибрати';

  @override
  String get medsTitle => 'Інвентар';

  @override
  String activeMedsCountSection(int count) {
    return 'Активні ($count)';
  }

  @override
  String finishedMedsCountSection(int count) {
    return 'Завершені ($count)';
  }

  @override
  String get noMedsYetTitle => 'Інвентарю ще немає';

  @override
  String get noMedsYetHint => 'Натисніть + щоб додати перший запис';

  @override
  String get addMedicationAction => 'Додати до інвентарю';

  @override
  String get errorGenericShort => 'Помилка';

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
  String get untilCourseEndLabel => 'до завершення';

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
  String get courseStagesLabel => 'Етапи';

  @override
  String untilDateLabel(String date) {
    return 'до $date';
  }

  @override
  String get ongoingLabel => 'постійно';

  @override
  String get detailsLabel => 'Деталі';

  @override
  String get intakeLabel => 'Розклад';

  @override
  String get courseNounLabel => 'Період';

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
  String get stopCourseConfirmTitle => 'Зупинити?';

  @override
  String stopCourseConfirmBody(String name) {
    return '«$name» буде видалено зі списку активного інвентарю.';
  }

  @override
  String get enterMedicationNameError => 'Введіть назву';

  @override
  String get deleteMedicationConfirmTitle => 'Видалити запис?';

  @override
  String get deleteMedicationConfirmBody => 'Запис буде вилучено з розкладу.';

  @override
  String get editMedicationTitle => 'Редагувати запис';

  @override
  String get medicationNameHint => 'Назва';

  @override
  String get medicationFormLabel => 'Форма випуску';

  @override
  String get coursePhasesLabel => 'Фази';

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
  String phaseCardTitle(int number) {
    return 'Фаза $number';
  }

  @override
  String get removePhaseAction => 'видалити';

  @override
  String get doseAmountLabel => 'КІЛЬКІСТЬ ЗА РАЗ';

  @override
  String get doseCommentSectionLabel => 'КОМЕНТАР';

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
  String get doseCommentHint => 'Коментар (необов\'язково)';

  @override
  String get doseAmountDialogTitle => 'Кількість за раз';

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
  String get inStockLabel => 'В наявності';

  @override
  String howManyNowLabel(String unit) {
    return 'Скільки $unit є зараз';
  }

  @override
  String get enoughForCourseLabel => 'Вистачить на весь період';

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
  String get addPhotoHint => 'щоб не переплутати позиції інвентарю';

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
    return 'Ви приєднуєтесь як рівноправний учасник — ваш власний профіль (ім\'я й аватар) стане видимим \"$name\". Це не скасовує і не змінює жодних ваших даних, уже внесених у застосунок. Ваш архів НІКОМУ автоматично не показується — які саме дані бачитимуть інші учасники, ви налаштуєте окремо, вже після приєднання.';
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
  String get noMedsTodayLabel => 'Немає завдань на сьогодні';

  @override
  String get allDoneTodayLabel => 'Усе виконано сьогодні';

  @override
  String takenOfTotalIntakesLabel(int taken, int total) {
    return '$taken з $total прийомів';
  }

  @override
  String tasksProgressLabel(int taken, int total) {
    return '$taken з $total завдань';
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
    return 'Ви піклуєтесь про $_temp0. Еллі надішле сповіщення, якщо хтось пропустить нагадування.';
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
  String get routineTasksLimitBadge => 'Рутинні справи';

  @override
  String get routineTasksLimitTitle => 'Ліміт рутинних справ';

  @override
  String routineTasksLimitSubtitle(int used, int max) {
    return 'Використано $used з $max. Перейдіть на Elly Plus — необмежена кількість';
  }

  @override
  String get routineTasksLimitDeniedTitle => 'Ліміт рутинних справ досягнуто';

  @override
  String get routineTasksLimitDeniedSubtitle =>
      'На безкоштовному тарифі доступна лише 1 рутинна справа. Перейдіть на Elly Plus для необмеженої кількості';

  @override
  String get medcardSectionsLimitBadge => 'Полички';

  @override
  String get medcardSectionsLimitTitle => 'Ліміт поличок';

  @override
  String medcardSectionsLimitSubtitle(int used, int max) {
    return 'Використано $used з $max. Перейдіть на Elly Plus — необмежена кількість';
  }

  @override
  String get medcardSectionsLimitDeniedTitle => 'Ліміт поличок досягнуто';

  @override
  String get medcardSectionsLimitDeniedSubtitle =>
      'На безкоштовному тарифі доступно до 3 поличок. Перейдіть на Elly Plus для необмеженої кількості';

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
  String get reminderWellbeingBody => 'Не забудьте відмітити настрій';

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
  String get viewDebugLogAction => 'Переглянути журнал подій';

  @override
  String get shareDbFileAction => 'Поділитись файлом БД';

  @override
  String get shareDbFileEmptySnackbar => 'Файл БД не знайдено';

  @override
  String get clearAction => 'Очистити';

  @override
  String get shareAction => 'Поділитись';

  @override
  String get antiStressLabel => 'Антистрес-вправи';

  @override
  String get antiStressPickerSubtitle => 'Короткі вправи на кілька хвилин';

  @override
  String get breathingExerciseTitle => 'Дихаймо разом';

  @override
  String get breathingExerciseSubtitle =>
      'Повільне дихання у своєму темпі — 2 хвилини';

  @override
  String get grounding54321Title => '5-4-3-2-1';

  @override
  String get grounding54321Subtitle =>
      'Коротка вправа на 5 кроків із органами чуття';

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
      'Синхронізувати дані профілю на інші пристрої';

  @override
  String get medcardSyncDescription =>
      'Якщо вимкнено, нагадування цього профілю (разом із вкладеннями) не передаються на інші пристрої сім\'ї, підключені через пейринг. Інвентар і розклад використання синхронізуються незалежно від цього перемикача.';

  @override
  String get pendingConnectionLabel => 'Очікуємо з\'єднання';

  @override
  String get viewerNotifyPermissionLabel => 'Отримує сповіщення';

  @override
  String get viewerEditPermissionLabel => 'Може редагувати профіль';

  @override
  String get viewerViewPermissionLabel => 'Бачить завдання, полички й розклад';

  @override
  String get permissionDeniedNotYoursBody =>
      'Не вдалося змінити — це не ваш профіль';

  @override
  String get privacyLabel => 'Конфіденційність';

  @override
  String get securityLabel => 'Безпека';

  @override
  String get privacyPolicyLabel => 'Політика конфіденційності';

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
  String get groundingCompletedTitle => 'Вправу завершено';

  @override
  String get groundingCompletedSubtitle =>
      'Чудова робота. Повертайся до цієї вправи, коли знадобиться.';

  @override
  String get healthSectionHeader => 'Міні-ігри';

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
      'Керує мовою інтерфейсу та диктування коментарів. Поки доступні українська, англійська та російська — інші мови з\'являться після перекладів.';

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
  String get appointmentsHistoryTitle => 'Архів нагадувань';

  @override
  String get sectionFuture => 'Майбутні';

  @override
  String get visitPassedLabel => '✓ пройшло';

  @override
  String get arrowRightLabel => '→';

  @override
  String get noRecordsYetTitle => 'Записів ще немає';

  @override
  String get remindersArchiveEmptyHint =>
      'Тут зберігатимуться всі створені нагадування. Натисніть «+», щоб додати перше';

  @override
  String get noAppointmentsForSpecialty => 'Немає нагадувань з цим тегом';

  @override
  String get tryDifferentSpecialtyHint =>
      'Спробуйте обрати інший тег або скиньте фільтр';

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
  String get remindBeforeAtTime => 'У вказаний час';

  @override
  String get remindBefore10Min => 'За 10 хвилин';

  @override
  String get remindBefore30Min => 'За 30 хвилин';

  @override
  String get remindBefore1Hour => 'За 1 годину';

  @override
  String get remindBefore1Day => 'За день';

  @override
  String get remindBefore2Days => 'За 2 дні';

  @override
  String get deleteAppointmentBody => 'Нагадування буде видалено.';

  @override
  String get newAppointmentTitle => 'Нове нагадування';

  @override
  String get fieldWhere => 'Де';

  @override
  String get locationHint => 'Вкажіть адресу або назву';

  @override
  String get fieldDateTime => 'Дата та час';

  @override
  String get dateCapsLabel => 'ДАТА';

  @override
  String get timeCapsLabel => 'ЧАС';

  @override
  String get remindBeforeLabel => 'Нагадати заздалегідь';

  @override
  String get noteSingularLabel => 'Нотатка';

  @override
  String get reminderNoteHint => 'Додаткові деталі…';

  @override
  String get saveReminderAction => 'Зберегти нагадування';

  @override
  String get reminderTitleFieldLabel => 'Назва';

  @override
  String get reminderTitleHint => 'Вкажіть, про що нагадати';

  @override
  String get enterReminderTitleError => 'Введіть назву';

  @override
  String get reminderRepeatSectionLabel => 'Повторювання';

  @override
  String get reminderRepeatOnceLabel => 'Не повторювати';

  @override
  String get reminderRepeatDailyLabel => 'Щодня';

  @override
  String get reminderRepeatWeeklyLabel => 'Певні дні тижня';

  @override
  String get reminderRepeatMonthlyLabel => 'Щомісяця';

  @override
  String get reminderRepeatYearlyLabel => 'Щороку';

  @override
  String get reminderYearlyDateFieldLabel => 'Дата (без року)';

  @override
  String get reminderMonthlyDayFieldLabel => 'День місяця';

  @override
  String get dayOfMonthCapsLabel => 'ДЕНЬ';

  @override
  String get routineRepeatSectionLabel => 'Повторення';

  @override
  String get routineRepeatEveryNDaysOption => 'Кожні N днів';

  @override
  String get routineRepeatWeeklyGoalOption => 'N разів на тиждень';

  @override
  String routineIntervalDaysValueLabel(int n) {
    return 'Кожні $n дн.';
  }

  @override
  String routineWeeklyGoalValueLabel(int n) {
    return '$n р./тиждень';
  }

  @override
  String get routineTimeFieldLabel => 'Час';

  @override
  String get routineFixedTimeOption => 'У певний час';

  @override
  String get routineNoFixedTimeOption => 'Без конкретного часу';

  @override
  String get routineWhoDoesLabel => 'Хто виконує';

  @override
  String get routineRotationCadenceLabel => 'Як часто змінюється черга';

  @override
  String get routineRotationCadencePerOccurrence => 'Кожного разу';

  @override
  String get routineRotationCadenceWeekly => 'Щотижня';

  @override
  String get routineRotationCadenceMonthly => 'Щомісяця';

  @override
  String routineRotationSummary(int n) {
    return 'По черзі ($n)';
  }

  @override
  String get routineStepsLabel => 'Кроки';

  @override
  String get routineStepsSheetTitle => 'Кроки виконання';

  @override
  String get routineAddStepHint => 'Додати крок…';

  @override
  String routineWhoseTurnLabel(String name) {
    return 'Черга: $name';
  }

  @override
  String get routineSwapTurnAction => 'Поміняти';

  @override
  String get routineSkipTurnAction => 'Пропустити чергу';

  @override
  String routineWeeklyGoalProgressLabel(int done, int total) {
    return '$done/$total цього тижня';
  }

  @override
  String get routinePartialStatusLabel => 'Частково';

  @override
  String routineStepsProgressLabel(int done, int total) {
    return '$done/$total кроків';
  }

  @override
  String get routineAnyTimeTodayLabel => 'Будь-коли сьогодні';

  @override
  String get routineFormExplainer =>
      'Рутина повторюється й рахує виконання — для звичок і сімейних обов\'язків, на відміну від разового нагадування';

  @override
  String routineStreakDaysLabel(int n) {
    return '$n днів поспіль';
  }

  @override
  String get routineNoStreakYetLabel => 'Ще немає серії — почніть сьогодні';

  @override
  String get routineAllRoutinesScreenTitle => 'Обов\'язки сім\'ї';

  @override
  String get routineNoAssigneesHint => 'Ще немає обов\'язків';

  @override
  String get defaultNotesSectionName => 'Нотатки';

  @override
  String get addAnotherTimeAction => 'Додати ще один час';

  @override
  String get addAtLeastOneTimeError => 'Додайте хоча б один час';

  @override
  String get chooseAtLeastOneDayError => 'Оберіть хоча б один день тижня';

  @override
  String get reminderTagsFieldLabel => 'Теги';

  @override
  String get reminderTagsHint => 'Теги для структурування, через кому';

  @override
  String get reminderTagsPickerTitle => 'Оберіть теги';

  @override
  String get addNewTagHint => 'Новий тег';

  @override
  String get noTagsYetLabel => 'Поки немає жодного тега';

  @override
  String get reminderPhotoLabel => 'Фото';

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
  String get historyLabel => 'Історія';

  @override
  String get wellbeingScheduleInfoText =>
      'Налаштуйте розклад збору зрізів настрою. У призначений час на головному екрані з\'явиться картка для заповнення.';

  @override
  String get frequencyPerDayLabel => 'ЧАСТОТА НА ДЕНЬ';

  @override
  String get collectionTimeLabel => 'ЧАС ЗБОРУ';

  @override
  String wellbeingSlotNumberLabel(int index) {
    return 'Зріз $index';
  }

  @override
  String get reminderTimesFieldLabel => 'ЧАС НАГАДУВАННЯ';

  @override
  String timeSlotNumberLabel(int index) {
    return 'Час $index';
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
  String get wellbeingByDaySubtitle => 'настрій по днях';

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
  String get noWellbeingLogsHint =>
      'Тут зберігатиметься історія настрою. Натисніть «+ Зріз», щоб додати перший запис';

  @override
  String get comingSoonEllipsis => 'Скоро...';

  @override
  String get sendDiaryToDoctorLabel => 'Поділитися підсумком';

  @override
  String get diarySummaryHint => 'Зрізи настрою та прийоми за місяць';

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
  String get chooseWellbeingErrorSnackbar => 'Оберіть настрій';

  @override
  String get wellbeingSlotMorning => 'ранковий зріз';

  @override
  String get wellbeingSlotAfternoon => 'денний зріз';

  @override
  String get wellbeingSlotEvening => 'вечірній зріз';

  @override
  String get howAreYouFeelingLabel => 'Який у вас настрій?';

  @override
  String get anySymptomsLabel => 'Теги';

  @override
  String get chooseFromListOrAddLabel => 'Додайте власні теги (необов\'язково)';

  @override
  String get commentLabel => 'Коментар';

  @override
  String get optionalSuffixLabel => '· необов\'язково';

  @override
  String get orTypeTextLabel => 'або введіть текстом';

  @override
  String get describeFeelingHint => 'Опишіть свій настрій…';

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
      'Додайте щось в інвентар щоб активувати нагадування';

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
    return '$name уже склав(-ла) для вас розклад використання інвентарю. Ви зможете відредагувати його будь-коли після підключення.';
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
      'Elly допоможе не забути про інвентар,\nактивність і настрій — для вас\nі всієї родини';

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
  String get createAccountSubtitle => 'Налаштую інвентар та розклад для себе';

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
  String get nextToMedsAction => 'Далі — інвентар →';

  @override
  String get scanOrEnterManuallyHint => 'Додайте те, що використовуєте зараз';

  @override
  String get addMedsShortAction => 'Додати до інвентарю';

  @override
  String get addMoreMedsAction => 'Додати ще';

  @override
  String get onboardingAddItemAction => 'Додати';

  @override
  String get onboardingAddItemHint =>
      'Нагадування чи інвентар — оберіть варіант';

  @override
  String get addMedsLaterInfo =>
      'Інвентар можна додати пізніше через розділ «Інвентар» в головному меню';

  @override
  String get nextAction => 'Далі →';

  @override
  String get skipAddLaterAction => 'Пропустити — додам пізніше';

  @override
  String get activityWellbeingTitle => 'Активність та настрій';

  @override
  String get activityWellbeingSubtitle =>
      'Увімкніть одним перемикачем — налаштування можна змінити пізніше';

  @override
  String get activitySectionLabel => 'Активність';

  @override
  String get walkActivitySub => '30 хв · щодня · 08:30';

  @override
  String get wellbeingDiaryLabel => 'Щоденник настрою';

  @override
  String get wellbeingDiaryDescription =>
      'Короткі відмітки настрою допоможуть побачити звʼязок між інвентарем і тим, який у вас настрій';

  @override
  String get wellbeingSlotsTitle => 'Зрізи настрою';

  @override
  String get wellbeingSlotsSub => '2–3 рази на день · 08:00, 14:00, 20:00';

  @override
  String get almostDoneAction => 'Майже готово →';

  @override
  String get backupScreenTitle => 'Резервна копія';

  @override
  String get backupIntroBody =>
      'Інвентар, розклад, архів (фото) і всі інші дані — обирайте, де зберігати резервну копію.';

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
  String get choosePlanSubtitle => 'Турбота про родину';

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
  String planActivatedSnackbar(String plan) {
    return '$plan активовано!';
  }

  @override
  String actionFailedError(String error) {
    return 'Не вдалося: $error';
  }

  @override
  String get planForeverPeriod => 'назавжди';

  @override
  String get planPerYearPeriod => 'на рік';

  @override
  String get planPerMonthPeriod => 'щомісяця';

  @override
  String get freeFeatureAllSections => '1 рутинна справа, 3 розділи Полички';

  @override
  String get freeFeatureUnlimitedMeds => 'Необмежено нагадувань';

  @override
  String get freeFeatureLocalBackup => 'Локально + копія в Google Drive/iCloud';

  @override
  String get selectFreeAction => 'Обрати Безкоштовний';

  @override
  String get plusFeatureAllFree => 'Все з безкоштовного';

  @override
  String get plusFeatureUnlimitedProfiles =>
      'Необмежена кількість профілів родини — керуєте тільки ви';

  @override
  String get planFeatureUnlimitedRoutines =>
      'Необмежена кількість рутинних справ';

  @override
  String get planFeatureUnlimitedShelves => 'Необмежена кількість поличок';

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
  String billingTermsDisclaimer(String store) {
    return 'Оплата списується з вашого облікового запису $store. Підписка автоматично продовжується на новий період за тією самою ціною, якщо не скасувати щонайменше за 24 години до завершення періоду. Керувати підпискою та скасувати автопродовження можна в налаштуваннях облікового запису $store.';
  }

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
      'Файл у форматі JSON з усіма профілями, інвентарем, розкладом, прийомами, настроєм і записами до лікарів — усе, що зберігається на цьому пристрої. Ви можете відкрити його будь-де або передати кому завгодно.\n\nФото інвентарю у файл не входять (вони вже є у «Резервній копії») — лише текстові дані.';

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
  String get addTypeMedsSub =>
      'Витратний запас за розкладом — облік залишку, коли докупити';

  @override
  String get addTypeActivitySub => 'Прогулянка, зарядка, вправи, ЛФК';

  @override
  String get addTypeAppointmentSub =>
      'Дата, час і нагадування про будь-яку подію';

  @override
  String get addTypeWellbeingSub => 'Зробити зріз — настрій, теги, коментар';

  @override
  String get taskTypeSport => 'Спорт';

  @override
  String get taskTypeSportSub => 'Прогулянка, тренування, вправи';

  @override
  String get taskTypeMeeting => 'Зустрічі';

  @override
  String get taskTypeMeetingSub => 'Дата, час і нагадування про будь-яку подію';

  @override
  String get taskTypeSimple => 'Прості завдання';

  @override
  String get taskTypeSimpleSub => 'Одноразове чи просте нагадування';

  @override
  String get taskTypeRoutine => 'Рутинні справи';

  @override
  String get taskTypeRoutineSub =>
      'Звичка чи обов\'язок з гнучким повтором — чек-лист і черга виконання';

  @override
  String get reminderCategoryTitle => 'Нагадування';

  @override
  String get reminderCategorySub =>
      'Подія чи справа з датою — разова або повторювана';

  @override
  String get noteCategoryTitle => 'Нотатка';

  @override
  String get noteCategorySub => 'Просто запис — без нагадувань';

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
  String get faqFamilyQ4 =>
      'Чи можу я бути одночасно в кількох сімейних групах?';

  @override
  String get faqFamilyA4 =>
      'Так. Наприклад, ви можете бути учасником сім\'ї батьків і водночас власної сім\'ї, яку створили самі, — це дві незалежні групи. Вихід з однієї не впливає на іншу, а дані різних сімей ніколи не змішуються.';

  @override
  String get faqFamilyQ5 =>
      'Як працює черга виконання рутинних справ між кількома виконавцями?';

  @override
  String get faqFamilyA5 =>
      'Коли в рутині вказано кількох виконавців, застосунок сам визначає, чия зараз черга, за обраним кадансом: \"кожного разу\" — черга переходить після кожного виконання; \"раз на тиждень\" — той самий виконавець виконує всі входження впродовж календарного тижня, потім черга переходить далі; \"раз на місяць\" — так само, але на цілий календарний місяць, навіть якщо рутина повторюється кілька разів на тиждень. Картку рутини на екрані \"Сьогодні\" бачить лише той, чия зараз черга; передати чергу вручну можна кнопкою \"Пропустити чергу\".';

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
  String get faqPlansQ2 => 'Які саме обмеження має безкоштовний тариф?';

  @override
  String get faqPlansA2 =>
      '1 локальний профіль, 1 активна рутинна справа, 3 розділи Полички. Нагадування, інвентар та самопочуття — без обмежень на всіх тарифах. Перевищення ліміту нічого не видаляє: старі записи лишаються доступними для перегляду, редагування чи створення нових — заблоковано, доки не оновите тариф.';

  @override
  String get faqPlansQ3 => 'Скільки людей можна додати до сімейної групи?';

  @override
  String get faqPlansA3 =>
      'На тарифі Elly Family — до 8 автономних учасників. Запрошувати нових людей може лише той, хто оплачує підписку; прийняти запрошення можна безкоштовно на будь-якому тарифі. Запрошений отримує усі можливості Family, окрім права запрошувати інших у ЦЮ саму сім\'ю.';

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
  String get pushNotificationsSub => 'Нагадування про використання інвентарю';

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
  String get disableWellbeingConfirmTitle => 'Вимкнути збір настрою?';

  @override
  String get disableWellbeingConfirmBody =>
      'Нагадування зникнуть з Розкладу і Сьогодні. Налаштування збережуться — можна ввімкнути знову пізніше.';

  @override
  String get applyAction => 'Готово';

  @override
  String get noDaysSelectedHint => 'Дні не обрані';

  @override
  String get chooseActivityTypeError => 'Оберіть тип активності';

  @override
  String get enterActivityNameError => 'Введіть назву активності';

  @override
  String get editActivityTitle => 'Редагувати рутину';

  @override
  String get newRoutineTitle => 'Рутина';

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
  String get stockUnitBottle => 'пляшка';

  @override
  String get stockUnitPortion => 'порція';

  @override
  String get stockUnitSpoon => 'ложка';

  @override
  String get stockUnitGlass => 'склянка';

  @override
  String get stockUnitLabel => 'Одиниця виміру';

  @override
  String get inventoryFormHint => 'Флакон, пачка, банка...';

  @override
  String get chooseProfileLabel => 'Оберіть профіль';

  @override
  String get chooseAction => 'Обрати';

  @override
  String get noDocumentsLabel => 'Немає документів';

  @override
  String get addPhotoOrPdfLabel => 'Додати фото чи PDF';

  @override
  String get documentsPrivacyHint =>
      'Зберігається лише на пристрої (і в хмарі, якщо ввімкнено резервну копію) — застосунок не переглядає й не аналізує ці файли.';

  @override
  String get notifChannelName => 'Нагадування Elly';

  @override
  String get notifChannelDesc =>
      'Нагадування про інвентар, активності, візити та настрій';

  @override
  String notifTakeMedTitle(String name) {
    return '⏰ Час для $name';
  }

  @override
  String notifIntakeNoResponseTitle(String name) {
    return '🔔 Ви ще не відмітили: $name';
  }

  @override
  String get notifBackupReminderTitle => 'Захистіть свої дані';

  @override
  String get notifBackupReminderBody =>
      'Резервна копія вимкнена — дані зберігаються лише на цьому пристрої. Увімкніть у Профілі, щоб не втратити їх.';

  @override
  String get notifLowStockTitle => '⚠️ Запас закінчується';

  @override
  String notifLowStockBody(String medName, int remaining, String unit) {
    return '$medName — залишилось $remaining $unit';
  }

  @override
  String get notifActivityTitle => '🚶 Час для активності';

  @override
  String get notifActivityNoResponseTitle => '🔔 Ви ще не відмітили активність';

  @override
  String get notifAppointmentTitle => '🔔 Нагадування';

  @override
  String get notifAppointmentNoResponseTitle =>
      '🔔 Не забудьте про нагадування';

  @override
  String get notifWellbeingTitle => '💜 Зріз настрою';

  @override
  String get notifWellbeingBody => 'Який у вас настрій?';

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
    return 'Чи відбулось нагадування (\"$doctorType\") о $timeStr? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.';
  }

  @override
  String notifPeerWellbeingCheckBody(String timeStr) {
    return 'Чи зроблено зріз настрою о $timeStr? Відкрийте застосунок і зачекайте на синхронізацію, щоб побачити актуальний стан.';
  }

  @override
  String forMemberSuffix(String name) {
    return ' для $name';
  }

  @override
  String get dbLoadErrorTitle => 'Потрібно перезапустити Elly';

  @override
  String get dbLoadErrorBody =>
      'Закрийте застосунок повністю — проведіть пальцем вгору з нижнього краю екрана й змахніть картку Elly — а тоді відкрийте знову. Ваші дані нікуди не зникли, за кілька секунд усе повернеться на місце.';

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

  @override
  String manageSubscriptionExternallyHint(String store) {
    return 'Керування підпискою відкрито в $store — завершіть скасування там.';
  }

  @override
  String get restorePurchasesAction => 'Відновити покупки';

  @override
  String get restorePurchasesSuccessSnackbar => 'Покупки відновлено';

  @override
  String get restorePurchasesNothingFoundSnackbar =>
      'Активних покупок не знайдено на цьому обліковому записі';

  @override
  String get todayScheduleForMedLabel => 'Розклад на сьогодні';

  @override
  String get intakeSnoozed => 'Перенесено';

  @override
  String get resetLocalDbConfirmTitle => 'Скинути локальну базу даних?';

  @override
  String get resetLocalDbConfirmBody =>
      'Це видалить усі дані на цьому пристрої (інвентар, розклад, полички). Резервної копії не знайдено — відновити дані після цього буде неможливо.';

  @override
  String get resetAction => 'Скинути';

  @override
  String get resetLocalDbAction => 'Скинути локальну БД';

  @override
  String get petAvatarsSectionLabel => 'Домашні улюбленці';
}
