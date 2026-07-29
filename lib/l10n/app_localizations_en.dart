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
  String get navMedCard => 'Shelves';

  @override
  String todayProgressTitle(int taken, int total) {
    return '$taken of $total';
  }

  @override
  String get todayProgressSubtitle => 'inventory items used today';

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

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get todaySectionFamily => 'Family';

  @override
  String get todayScheduleForToday => 'Today\'s schedule';

  @override
  String get todayScheduleForTomorrow => 'Tomorrow at a glance';

  @override
  String get todayNothingToday => 'Nothing scheduled for today';

  @override
  String get todayTapToAdd => 'Tap + to add';

  @override
  String get todayAllDoneChip => 'All done';

  @override
  String get todayNextNow => 'now';

  @override
  String todayNextInMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String get todayAllDoneTitle => 'All done for today!';

  @override
  String get todayAllDoneSubtitle => 'Great job — keep it up';

  @override
  String get todayHurtsNow => 'Add\nmood';

  @override
  String get todayMissedSection => 'You missed';

  @override
  String get todayActiveNowSection => 'Needed now';

  @override
  String get dayPartMorning => 'Morning';

  @override
  String get dayPartAfternoon => 'Afternoon';

  @override
  String get dayPartEvening => 'Evening';

  @override
  String get dayPartNight => 'Night';

  @override
  String get defaultMedName => 'Inventory';

  @override
  String get defaultActivityName => 'Activity';

  @override
  String get wellbeingTitle => 'Mood';

  @override
  String get detailLabelTime => 'Time';

  @override
  String get detailLabelDuration => 'Duration';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get detailLabelLocation => 'Location';

  @override
  String get detailLabelNotes => 'Notes';

  @override
  String todayDoneCount(int count) {
    return 'Done · $count';
  }

  @override
  String get skipIntakeAction => 'Skip dose';

  @override
  String get missedCaption => 'missed';

  @override
  String get videoPlaybackError => 'Couldn\'t play video here';

  @override
  String get openInYoutube => 'Open in YouTube';

  @override
  String get missedWellbeingSlot => 'Missed check-in';

  @override
  String get wellbeingTimeToCheck => 'Time for a mood check-in';

  @override
  String get wellbeingCommentHint =>
      'Rate your mood and, if you\'d like, add a note';

  @override
  String get skipGenericAction => 'Skip';

  @override
  String get snooze10 => 'Snooze 10 min';

  @override
  String get snooze30 => 'Snooze 30 min';

  @override
  String get snooze60 => 'Snooze 1 hr';

  @override
  String get doneAction => 'Done';

  @override
  String get welcomeTitle => 'Welcome to Elly';

  @override
  String get welcomeSubtitle => 'Add your profile to get started';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryMeds => 'Inventory';

  @override
  String get categoryActivities => 'Activities';

  @override
  String get categoryWellbeing => 'Mood';

  @override
  String get categoryDoctors => 'Reminders';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get searchAllSections => 'Search all sections';

  @override
  String get searchHint => 'Search';

  @override
  String get noResultsFoundHint => 'Nothing found';

  @override
  String get sectionMeds => 'Inventory';

  @override
  String get noActiveMeds => 'No active inventory';

  @override
  String get sectionAppointments => 'Reminders';

  @override
  String get noScheduledAppointments => 'No scheduled appointments';

  @override
  String get sectionActivities => 'Activities';

  @override
  String get noActiveActivities => 'No active activities';

  @override
  String get noSimpleTasksHint => 'No simple tasks';

  @override
  String get noRoutineTasksHint => 'No routine chores';

  @override
  String get sectionWellbeing => 'Mood';

  @override
  String get wellbeingScheduleNotSet => 'Schedule not set up';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get repeatDaily => 'daily';

  @override
  String get repeatAlternate => 'every other day';

  @override
  String get repeatWeekdays => 'specific days';

  @override
  String get repeatEveryN => 'every N days';

  @override
  String get repeatCycle => 'cycle';

  @override
  String get courseOngoing => 'ongoing';

  @override
  String get courseFinished => 'finished';

  @override
  String courseDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '$count day left',
    );
    return '$_temp0';
  }

  @override
  String get noLocation => 'No location set';

  @override
  String timesPerDayLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times a day',
      one: '$count time a day',
    );
    return '$_temp0';
  }

  @override
  String get addAction => 'Add';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get editAction => 'Edit';

  @override
  String get fieldName => 'Name';

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get allTagsFilter => 'All tags';

  @override
  String get allStatusesFilter => 'All statuses';

  @override
  String get medStatusFilterPickerTitle => 'Choose status';

  @override
  String get medCardTitle => 'Shelves';

  @override
  String get medCardArchiveTitle => 'Inventory archive';

  @override
  String get medCardArchiveSubtitle => 'All inventory items and their status';

  @override
  String get medCardAppointmentsTitle => 'Reminders archive';

  @override
  String get medCardAppointmentsSubtitle =>
      'Meetings, simple tasks, routine chores';

  @override
  String get medCardWellbeingHistoryTitle => 'Mood history';

  @override
  String get medCardWellbeingHistorySubtitle => 'Mood over time';

  @override
  String get customSectionsHeader => 'Your sections';

  @override
  String get addSectionAction => 'Add section';

  @override
  String get newSectionTitle => 'New section';

  @override
  String get editSectionTitle => 'Edit section';

  @override
  String get sectionNameFieldLabel => 'Name';

  @override
  String get sectionNameHint => 'Enter a name for this notes section';

  @override
  String get enterSectionNameError => 'Enter a name';

  @override
  String get sectionIconFieldLabel => 'Icon';

  @override
  String get chooseIconLabel => 'Choose an icon';

  @override
  String get sectionCommentFieldLabel => 'Short description';

  @override
  String get sectionCommentHint => 'Up to 30 characters (optional)';

  @override
  String get deleteSectionConfirmTitle => 'Delete this section?';

  @override
  String get deleteSectionConfirmBody =>
      'The section and all its entries will be deleted.';

  @override
  String get sectionEmptyHint =>
      'Nothing here yet. Add your first entry with the plus button';

  @override
  String get spaceFieldLabel => 'Shelf';

  @override
  String get spacePickerTitle => 'Choose a shelf';

  @override
  String get noSpaceOption => 'No shelf';

  @override
  String get createNewSpaceAction => 'Create a new section';

  @override
  String get newEntryTitle => 'New entry';

  @override
  String get editEntryTitle => 'Edit entry';

  @override
  String get entryTitleFieldLabel => 'Title';

  @override
  String get entryTitleHint => 'Entry title';

  @override
  String get enterEntryTitleError => 'Enter a title';

  @override
  String get entryDateFieldLabel => 'Entry date';

  @override
  String get entryNotesHint => 'Freeform notes…';

  @override
  String get deleteEntryConfirmBody => 'This entry will be deleted.';

  @override
  String get medicationArchiveEmptyHint =>
      'Everything you\'ve ever added to your inventory will appear here';

  @override
  String get medStatusOngoing => 'Ongoing';

  @override
  String get medStatusFinished => 'Finished';

  @override
  String get medStatusCancelled => 'Cancelled';

  @override
  String medArchiveDateRangeOngoing(String start) {
    return '$start — ongoing';
  }

  @override
  String get sectionPast => 'Past';

  @override
  String get emptyStateNoneYetTitle => 'Nothing added yet';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get deleteAction => 'Delete';

  @override
  String get documentsLabel => 'Documents';

  @override
  String get notSpecifiedValue => 'Not specified';

  @override
  String get deleteSurgeryConfirmTitle => 'Delete this record?';

  @override
  String get editSurgeryTitle => 'Edit record';

  @override
  String get removeAction => 'Remove';

  @override
  String get medsTitle => 'Inventory';

  @override
  String activeMedsCountSection(int count) {
    return 'Active ($count)';
  }

  @override
  String finishedMedsCountSection(int count) {
    return 'Finished ($count)';
  }

  @override
  String get noMedsYetTitle => 'Nothing in inventory yet';

  @override
  String get noMedsYetHint => 'Tap + to add your first item';

  @override
  String get addMedicationAction => 'Add to inventory';

  @override
  String get errorGenericShort => 'Error';

  @override
  String perDoseLabel(String dose, String unit) {
    return '$dose $unit per dose';
  }

  @override
  String timesPerDaySlash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times/day',
      one: '$count time/day',
    );
    return '$_temp0';
  }

  @override
  String get stockSectionLabel => 'Stock';

  @override
  String get untilCourseEndLabel => 'until end of period';

  @override
  String get next30DaysLabel => 'for the next 30 days';

  @override
  String get remainingColonLabel => 'Remaining: ';

  @override
  String daysLeftShortLabel(String days) {
    return 'for $days d.';
  }

  @override
  String get needToBuyLabel => 'Need to buy: ';

  @override
  String get refillPackageAction => '+ Refill package';

  @override
  String get refillPackageTitle => 'Refill package';

  @override
  String get quantityHint => 'Quantity';

  @override
  String get okAction => 'OK';

  @override
  String phaseNumberLabel(int number) {
    return 'Stage $number';
  }

  @override
  String get nowLabel => 'now';

  @override
  String phaseFromOngoing(String date) {
    return 'from $date, ongoing';
  }

  @override
  String get courseStagesLabel => 'Stages';

  @override
  String untilDateLabel(String date) {
    return 'until $date';
  }

  @override
  String get ongoingLabel => 'ongoing';

  @override
  String get detailsLabel => 'Details';

  @override
  String get intakeLabel => 'Schedule';

  @override
  String get courseNounLabel => 'Period';

  @override
  String get noteLabel => 'Note';

  @override
  String courseRangeLabel(String start, String endPart) {
    return 'from $start $endPart';
  }

  @override
  String get repeatDailyCap => 'Daily';

  @override
  String get repeatAlternateCap => 'Every other day';

  @override
  String repeatEveryNCap(String n) {
    return 'Every $n days';
  }

  @override
  String repeatCycleCap(String on, String off) {
    return '$on days on / $off off';
  }

  @override
  String get stopAction => 'Stop';

  @override
  String get stopCourseConfirmTitle => 'Stop?';

  @override
  String stopCourseConfirmBody(String name) {
    return '\"$name\" will be removed from your active inventory.';
  }

  @override
  String get enterMedicationNameError => 'Enter a name';

  @override
  String get deleteMedicationConfirmTitle => 'Delete this item?';

  @override
  String get deleteMedicationConfirmBody =>
      'The item will be removed from your schedule.';

  @override
  String get editMedicationTitle => 'Edit item';

  @override
  String get medicationNameHint => 'Name';

  @override
  String get medicationFormLabel => 'Form';

  @override
  String get coursePhasesLabel => 'Phases';

  @override
  String get addPhaseAction => 'Add phase';

  @override
  String get repeatSectionLabel => 'Repeat';

  @override
  String get savingLabel => 'Saving...';

  @override
  String get saveChangesAction => 'Save changes';

  @override
  String get saveAndContinueAction => 'Save and continue →';

  @override
  String get saveAndViewScheduleAction => 'Save and view schedule →';

  @override
  String phaseCardTitle(int number) {
    return 'Phase $number';
  }

  @override
  String get removePhaseAction => 'remove';

  @override
  String get doseAmountLabel => 'AMOUNT PER USE';

  @override
  String get doseCommentSectionLabel => 'COMMENT';

  @override
  String get durationSectionLabel => 'DURATION';

  @override
  String get daysCountDashLabel => '— d.';

  @override
  String daysCountLabel(int n) {
    return '$n d.';
  }

  @override
  String get orLabel => 'or';

  @override
  String get permanentLabel => 'Ongoing';

  @override
  String get intakeTimeSectionLabel => 'TIME OF INTAKE';

  @override
  String get specificTimeLabel => 'Specific time';

  @override
  String get everyNHoursLabel => 'Every N hours';

  @override
  String get addTimeAction => 'Add time';

  @override
  String get intervalLabel => 'INTERVAL';

  @override
  String hoursCountLabel(int n) {
    return '$n h';
  }

  @override
  String get startLabel => 'START';

  @override
  String get daysCountDialogTitle => 'Number of days';

  @override
  String get daysSuffix => 'd.';

  @override
  String get intervalDialogTitle => 'Interval';

  @override
  String get hoursSuffix => 'h';

  @override
  String get doseCommentHint => 'Comment (optional)';

  @override
  String get doseAmountDialogTitle => 'Amount per use';

  @override
  String get doseAmountExampleHint => 'e.g. 2.5';

  @override
  String get weekdayExampleLabel => 'Mon, Wed, Fri, Sun…';

  @override
  String get weekdaysOptionLabel => 'Specific days of the week';

  @override
  String get everyNDaysOptionLabel => 'Every N days';

  @override
  String get everyNDaysExampleLabel => 'E.g. every 3 days';

  @override
  String get everyLabel => 'Every';

  @override
  String get daysSuffixWord => 'days';

  @override
  String get cycleOptionLabel => 'Cycle';

  @override
  String get cycleExampleLabel => 'N days on — M days off';

  @override
  String get drinkLabel => 'Take';

  @override
  String get breakLabel => 'Break';

  @override
  String get optionalParamsLabel => 'Additional parameters';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get trackStockLabel => 'Track stock and remind when low';

  @override
  String get inStockLabel => 'In stock';

  @override
  String howManyNowLabel(String unit) {
    return 'How many $unit do you have now';
  }

  @override
  String get enoughForCourseLabel => 'Enough for the whole period';

  @override
  String get noCameraAccessError =>
      'No camera access. Allow it in your phone settings.';

  @override
  String get cameraOpenError => 'Couldn\'t open the camera';

  @override
  String get packagePhotoLabel => 'Package photo';

  @override
  String get addPhotoAction => 'Add photo';

  @override
  String get addPhotoHint => 'so you don\'t mix up items';

  @override
  String inviteMemberTitle(String name) {
    return 'Invite $name';
  }

  @override
  String get inviteToFamilyTitle => 'Invite to family';

  @override
  String get inviteCreateErrorTitle => 'Couldn\'t create the invitation';

  @override
  String get tryAgainAction => 'Try again';

  @override
  String inviteDependentBody(String name) {
    return 'Have $name enter this code in the app on their phone. The profile will become independent: all existing history will carry over as starting data, and you\'ll automatically keep full access to it, just as before.';
  }

  @override
  String get inviteMemberBody =>
      'Whoever enters this code will join as an equal member of your family group — with their own profile and their own data. You\'ll decide separately what they can see of your data.';

  @override
  String get inviteScanOrEnterHint =>
      'Scan this code on another device\nor enter it manually';

  @override
  String get codeCopiedSnackbar => 'Code copied';

  @override
  String get inviteCodeExpiryNotice =>
      'The code is valid for 30 minutes and works only once. Data on the server is encrypted — it contains nothing but the access code.';

  @override
  String alreadyJoinedFamilyError(String name) {
    return 'You\'ve already joined the family \"$name\"';
  }

  @override
  String get joinInvalidCodeError => 'Couldn\'t join: invalid or expired code';

  @override
  String get joinFamilyTitle => 'Join a family';

  @override
  String get confirmationTitle => 'Confirmation';

  @override
  String get doneTitle => 'Done';

  @override
  String get scanQrOrEnterHint =>
      'Point the camera at the QR code\nor enter the code manually';

  @override
  String get codeInputHint => '________';

  @override
  String get checkingLabel => 'Checking…';

  @override
  String get continueAction => 'Continue';

  @override
  String get invitesYouToFamilyGroup => 'invites you to their family group';

  @override
  String joinConsentBody(String name) {
    return 'You\'re joining as an equal member — your own profile (name and avatar) will become visible to \"$name\". This doesn\'t cancel or change any of your data already entered in the app. Your archive is NEVER automatically shown to anyone — you\'ll decide exactly what other members can see after joining.';
  }

  @override
  String joinConsentCheckbox(String name) {
    return 'I agree to join the family group \"$name\"';
  }

  @override
  String get joiningLabel => 'Joining…';

  @override
  String get joinAction => 'Join';

  @override
  String get joinedFamilyTitle => 'You\'re in the family!';

  @override
  String joinedFamilyBody(String name) {
    return 'Now you and \"$name\" can see each other in the \"Family\" section.';
  }

  @override
  String get scanQrCodeLabel => 'Scan QR code';

  @override
  String get tapToEnableCameraHint => 'Tap to enable the camera';

  @override
  String get doctorVisitLabel => 'Doctor visit';

  @override
  String get recordFallbackLabel => 'Record';

  @override
  String dataFromPeerTitle(String name) {
    return 'Data from $name';
  }

  @override
  String peerNothingSharedYet(String name) {
    return '$name hasn\'t shared anything with you yet — or access hasn\'t been granted yet.';
  }

  @override
  String get noViewableDataLabel => 'No data available to view';

  @override
  String get fileRequestSentSnackbar =>
      'Request sent — the file hasn\'t arrived yet';

  @override
  String fileRequestFailedError(String error) {
    return 'Couldn\'t send the request: $error';
  }

  @override
  String get pdfReceivedSavedSnackbar => 'PDF received and saved';

  @override
  String fileOpenFailedError(String error) {
    return 'Couldn\'t open the file: $error';
  }

  @override
  String get loadingEllipsis => '…';

  @override
  String get pdfLabel => 'PDF';

  @override
  String get photoLabel => 'Photo';

  @override
  String get awaitingFileLabel => 'Waiting for the file…';

  @override
  String get requestFileAction => 'Request file';

  @override
  String get editNotesTitle => 'Edit notes';

  @override
  String get editNotesDisclaimer =>
      'The data owner will see this edit — it applies only if they haven\'t changed this record in the meantime.';

  @override
  String get notesHintEllipsis => 'Notes…';

  @override
  String get editSentSnackbar => 'Edit sent';

  @override
  String sendFailedError(String error) {
    return 'Couldn\'t send: $error';
  }

  @override
  String get sendEditAction => 'Send edit';

  @override
  String get familyLabel => 'Family';

  @override
  String familyMembersCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get noMedsTodayLabel => 'No tasks today';

  @override
  String get allDoneTodayLabel => 'All done for today';

  @override
  String takenOfTotalIntakesLabel(int taken, int total) {
    return '$taken of $total doses taken';
  }

  @override
  String tasksProgressLabel(int taken, int total) {
    return '$taken of $total tasks';
  }

  @override
  String missedRemindersLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Missed $count reminders',
      one: 'Missed $count reminder',
    );
    return '$_temp0';
  }

  @override
  String nextIntakeLabel(String medName, String time) {
    return 'Next: $medName at $time';
  }

  @override
  String get meLabel => 'me';

  @override
  String get localLabel => 'Local';

  @override
  String notTakenSuffixLabel(String time) {
    return '$time · not taken';
  }

  @override
  String get autonomousProfilesPlusOnly =>
      'Independent profiles — Elly Family only';

  @override
  String get inviteAction => 'Invite';

  @override
  String get awaitingJoinLabel => 'Waiting to join';

  @override
  String get inviteToAppLabel => 'Invite to the app';

  @override
  String viewAsLabel(String name) {
    return 'View as $name';
  }

  @override
  String get deleteForeverAction => 'Delete forever';

  @override
  String get areYouSureTitle => 'Are you sure?';

  @override
  String deleteMemberConfirmBody(String name) {
    return 'This will delete all schedule and medical records linked to $name\'s profile';
  }

  @override
  String careSummaryLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'re caring for $count loved ones',
      one: 'You\'re caring for $count loved one',
    );
    return '$_temp0. Elly will notify you if someone misses a reminder.';
  }

  @override
  String get addFamilyMemberLabel => 'Add family member';

  @override
  String get addMemberHint => 'Parent, child, partner…';

  @override
  String get profileLimitReachedTitle => 'Profile limit reached';

  @override
  String get profileLimitReachedSubtitle =>
      'Upgrade to Elly Plus — unlimited local profiles';

  @override
  String get localProfilesTitle => 'Local profiles';

  @override
  String get familyUpgradeSubtitle =>
      'So your family can manage it too — upgrade to Elly Family';

  @override
  String get routineTasksLimitBadge => 'Routines';

  @override
  String get routineTasksLimitTitle => 'Routine tasks limit';

  @override
  String routineTasksLimitSubtitle(int used, int max) {
    return 'Used $used of $max. Upgrade to Elly Plus for unlimited';
  }

  @override
  String get routineTasksLimitDeniedTitle => 'Routine tasks limit reached';

  @override
  String get routineTasksLimitDeniedSubtitle =>
      'The free plan allows only 1 routine task. Upgrade to Elly Plus for an unlimited amount';

  @override
  String get medcardSectionsLimitBadge => 'Shelves';

  @override
  String get medcardSectionsLimitTitle => 'Shelves limit';

  @override
  String medcardSectionsLimitSubtitle(int used, int max) {
    return 'Used $used of $max. Upgrade to Elly Plus for unlimited';
  }

  @override
  String get medcardSectionsLimitDeniedTitle => 'Shelves limit reached';

  @override
  String get medcardSectionsLimitDeniedSubtitle =>
      'The free plan allows up to 3 shelves. Upgrade to Elly Plus for an unlimited amount';

  @override
  String leaveGroupConfirmTitle(String name) {
    return 'Leave \"$name\"?';
  }

  @override
  String get leaveGroupConfirmBody =>
      'Members of this group will lose access to your data, and you\'ll lose access to what they shared with you. Other family groups won\'t be affected.';

  @override
  String get leaveAction => 'Leave';

  @override
  String leftGroupSnackbar(String name) {
    return 'You left \"$name\"';
  }

  @override
  String get familyGroupSectionLabel => 'Family group';

  @override
  String slotsUsedLabel(int used, int total) {
    return '$used of $total';
  }

  @override
  String get autonomousLimitReachedTitle => 'Independent profile limit reached';

  @override
  String get autonomousLimitReachedSubtitle =>
      'Upgrade to Elly Family to invite more people';

  @override
  String get myFamilyLabel => 'My family';

  @override
  String peerFamilyLabel(String name) {
    return '$name\'s family';
  }

  @override
  String get doctorFallbackLabel => 'Doctor';

  @override
  String get reminderPushTitle => '🔔 Reminder';

  @override
  String reminderTakeMedBody(String title, String detailSuffix, String time) {
    return 'Don\'t forget to take \"$title\"$detailSuffix at $time';
  }

  @override
  String reminderDoActivityBody(String title, String time) {
    return 'Don\'t forget to do \"$title\" at $time';
  }

  @override
  String reminderDoctorVisitBody(String title, String detailSuffix) {
    return 'Don\'t forget your appointment: $title$detailSuffix';
  }

  @override
  String get reminderWellbeingBody => 'Don\'t forget to log your mood';

  @override
  String get reminderGenericBody => 'Check your schedule';

  @override
  String reminderSentSnackbar(String name) {
    return 'Reminder sent to $name';
  }

  @override
  String get independentAccountLabel => 'Independent account';

  @override
  String get missedLabel => 'Missed';

  @override
  String missedCountLabel(int count) {
    return 'Missed $count';
  }

  @override
  String get remindAction => '🔔 Remind';

  @override
  String removePeerConfirmTitle(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get removePeerConfirmBody =>
      'You\'ll both lose access to the data you shared with each other.';

  @override
  String get confirmGuardianConsentSnackbar =>
      'Please confirm you\'re authorized to manage this person\'s data';

  @override
  String get nameFieldLabel => 'NAME';

  @override
  String get avatarFieldLabel => 'AVATAR';

  @override
  String get memberNameHint => 'Mom, Dad, Grandma…';

  @override
  String get guardianConsentCheckbox =>
      'I am this person\'s legal guardian, or I have their consent to manage their data in the app';

  @override
  String get debugLogTitle => 'Event log';

  @override
  String get debugLogEmptyBody => 'The log is empty.';

  @override
  String get debugLogEmptySnackbar => 'Log is empty';

  @override
  String get debugLogShareSubject => 'Elly — event log';

  @override
  String get viewDebugLogAction => 'View event log';

  @override
  String get shareDbFileAction => 'Share DB file';

  @override
  String get shareDbFileEmptySnackbar => 'DB file not found';

  @override
  String get clearAction => 'Clear';

  @override
  String get shareAction => 'Share';

  @override
  String get antiStressLabel => 'Anti-stress exercises';

  @override
  String get antiStressPickerSubtitle => 'Short exercises, a few minutes each';

  @override
  String get breathingExerciseTitle => 'Let\'s breathe together';

  @override
  String get breathingExerciseSubtitle =>
      'Slow breathing at your own pace — 2 minutes';

  @override
  String get grounding54321Title => '5-4-3-2-1';

  @override
  String get grounding54321Subtitle =>
      'A short 5-step exercise using your senses';

  @override
  String get clearMindTitle => 'Clear mind';

  @override
  String get clearMindPickerSubtitle =>
      'Swipe your finger across the screen and the fog will clear';

  @override
  String get breathingScreenHeaderLabel => 'A moment of calm';

  @override
  String get breathingDoneBody => 'Well done! You made it through.';

  @override
  String breathingCyclesLeftBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cycles left.',
      one: '$count cycle left.',
    );
    return 'Slow inhale... and exhale. $_temp0';
  }

  @override
  String get restartAction => 'Again';

  @override
  String get inhaleLabel => 'Inhale';

  @override
  String get exhaleLabel => 'Exhale';

  @override
  String get safeYouTitle => 'You\'re safe';

  @override
  String get safeYouSubtitle =>
      'This anxiety will pass. Elly is here for as long as you need.';

  @override
  String get differentExerciseAction => 'Different exercise';

  @override
  String get feelBetterAction => 'I feel better';

  @override
  String get clearMindHeading => 'Clear the fog';

  @override
  String get clearMindInstructions =>
      'Swipe your finger across the screen to see what\'s hiding behind the fog';

  @override
  String get clearMindTouchHint => '👆 Touch and drag your finger';

  @override
  String get familyVisibilityLabel => 'Family visibility';

  @override
  String get familyVisibilityEmptyBody =>
      'If independent members (with their own account) join your family group, you\'ll be able to manage their access to your profile here';

  @override
  String get familyVisibilityIntro =>
      'What other family members can see and do with your profile';

  @override
  String get medcardSyncToggleLabel => 'Sync profile data to other devices';

  @override
  String get medcardSyncDescription =>
      'If disabled, this profile\'s reminders (along with attachments) won\'t be shared with other family devices connected via pairing. Inventory and usage schedule sync regardless of this toggle.';

  @override
  String get pendingConnectionLabel => 'Waiting for connection';

  @override
  String get viewerNotifyPermissionLabel => 'Receives notifications';

  @override
  String get viewerEditPermissionLabel => 'Can edit the profile';

  @override
  String get viewerViewPermissionLabel =>
      'Can see tasks, shelves, and schedule';

  @override
  String get permissionDeniedNotYoursBody =>
      'Couldn\'t change it — this isn\'t your profile';

  @override
  String get privacyLabel => 'Privacy';

  @override
  String get securityLabel => 'Security';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get dangerZoneLabel => 'Danger zone';

  @override
  String get deleteProfileForeverLabel => 'Delete profile forever';

  @override
  String deleteProfileForeverBody(String name) {
    return 'This will delete all data for \"$name\"\'s profile — locally and on the server, if sharing is set up';
  }

  @override
  String get appLockToggleLabel => 'App lock';

  @override
  String get appLockDescription =>
      'Face ID, Touch ID, or device passcode every time you open Elly';

  @override
  String policyAcceptedLabel(String date, String version) {
    return 'Accepted $date · version $version';
  }

  @override
  String policyAcceptedOldVersionLabel(String version) {
    return 'You accepted an older version ($version) — you\'ll be asked to agree again';
  }

  @override
  String get policyNotAcceptedLabel => 'Not accepted yet';

  @override
  String get viewFullTextAction => 'View full text';

  @override
  String get groundStep5Title => '5 things you can see';

  @override
  String get groundStep5Hint => 'One thing, e.g. a window';

  @override
  String get groundStep4Title => '4 things you can feel';

  @override
  String get groundStep4Hint => 'One thing, e.g. your sweater\'s fabric';

  @override
  String get groundStep3Title => '3 sounds you can hear';

  @override
  String get groundStep3Hint => 'One sound, e.g. the fridge humming';

  @override
  String get groundStep2Title => '2 smells you can notice';

  @override
  String get groundStep2Hint => 'One smell, e.g. coffee';

  @override
  String get groundStep1Title => '1 taste you can notice';

  @override
  String get groundStep1Hint => 'One taste, e.g. mint';

  @override
  String groundingNameStepLabel(String title) {
    return 'Name $title';
  }

  @override
  String groundingProgressCounter(int count, int total) {
    return '$count / $total named';
  }

  @override
  String get groundingListeningLabel => 'Listening…';

  @override
  String get groundingSkipStepAction => 'Skip this step';

  @override
  String get groundingCompletedTitle => 'Exercise complete';

  @override
  String get groundingCompletedSubtitle =>
      'Great work. Come back to this exercise whenever you need it.';

  @override
  String get healthSectionHeader => 'Mini-games';

  @override
  String get appSettingsSectionHeader => 'App settings';

  @override
  String get accountSectionHeader => 'Account';

  @override
  String get otherSectionHeader => 'Other';

  @override
  String get backupDisabledTitle => 'Backup is off';

  @override
  String get backupDisabledBody =>
      'Data is stored only on this device — turn on backup so you don\'t lose it';

  @override
  String get connectFamilyTitle => 'Connect your Family';

  @override
  String get connectFamilySubtitle => 'Take care of your whole family';

  @override
  String get planFreeLabel => 'Free plan';

  @override
  String get planPlusLabel => 'Elly Plus';

  @override
  String get planFamilyLabel => 'Elly Family';

  @override
  String get languageLabel => 'Language';

  @override
  String get voiceLanguageDescription =>
      'Controls the interface and comment-dictation language. Ukrainian, English, and Russian are available for now — more languages will follow as translations are added.';

  @override
  String get fontSizeLabel => 'Font size';

  @override
  String get fontSizeSampleLabel => 'Aa';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get plansLabel => 'Plans';

  @override
  String get backupLabel => 'Backup';

  @override
  String get rateAppLabel => 'Rate the app';

  @override
  String get helpFaqLabel => 'Help & FAQ';

  @override
  String get exportDataLabel => 'Export data';

  @override
  String get logoutLabel => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody =>
      'All data will be deleted from this device. This action cannot be undone.';

  @override
  String get logoutConfirmAction => 'Log out';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get yourNameHint => 'Your name';

  @override
  String get saveAction => 'Save';

  @override
  String get appointmentsHistoryTitle => 'Reminders archive';

  @override
  String get sectionFuture => 'Upcoming';

  @override
  String get visitPassedLabel => '✓ completed';

  @override
  String get arrowRightLabel => '→';

  @override
  String get noRecordsYetTitle => 'No records yet';

  @override
  String get remindersArchiveEmptyHint =>
      'All your reminders will show up here. Tap \"+\" to add the first one';

  @override
  String get noAppointmentsForSpecialty => 'No reminders with this tag';

  @override
  String get tryDifferentSpecialtyHint =>
      'Try choosing a different tag or reset the filter';

  @override
  String get tapToAddFirstHint => 'Tap \"+ Add\" to create your first one';

  @override
  String get meCapsLabel => 'ME';

  @override
  String get monthAbbrJan => 'JAN';

  @override
  String get monthAbbrFeb => 'FEB';

  @override
  String get monthAbbrMar => 'MAR';

  @override
  String get monthAbbrApr => 'APR';

  @override
  String get monthAbbrMay => 'MAY';

  @override
  String get monthAbbrJun => 'JUN';

  @override
  String get monthAbbrJul => 'JUL';

  @override
  String get monthAbbrAug => 'AUG';

  @override
  String get monthAbbrSep => 'SEP';

  @override
  String get monthAbbrOct => 'OCT';

  @override
  String get monthAbbrNov => 'NOV';

  @override
  String get monthAbbrDec => 'DEC';

  @override
  String get remindBeforeAtTime => 'At the exact time';

  @override
  String get remindBefore10Min => '10 minutes before';

  @override
  String get remindBefore30Min => '30 minutes before';

  @override
  String get remindBefore1Hour => '1 hour before';

  @override
  String get remindBefore1Day => '1 day before';

  @override
  String get remindBefore2Days => '2 days before';

  @override
  String get deleteAppointmentBody => 'This reminder will be deleted.';

  @override
  String get newAppointmentTitle => 'New reminder';

  @override
  String get fieldWhere => 'Where';

  @override
  String get locationHint => 'Enter an address or name';

  @override
  String get fieldDateTime => 'Date & time';

  @override
  String get dateCapsLabel => 'DATE';

  @override
  String get timeCapsLabel => 'TIME';

  @override
  String get remindBeforeLabel => 'Remind me ahead of time';

  @override
  String get noteSingularLabel => 'Note';

  @override
  String get reminderNoteHint => 'Additional details…';

  @override
  String get saveReminderAction => 'Save reminder';

  @override
  String get reminderTitleFieldLabel => 'Title';

  @override
  String get reminderTitleHint => 'What\'s this reminder about?';

  @override
  String get enterReminderTitleError => 'Enter a title';

  @override
  String get reminderRepeatSectionLabel => 'Repeat';

  @override
  String get reminderRepeatOnceLabel => 'Don\'t repeat';

  @override
  String get reminderRepeatDailyLabel => 'Daily';

  @override
  String get reminderRepeatWeeklyLabel => 'Specific weekdays';

  @override
  String get reminderRepeatMonthlyLabel => 'Monthly';

  @override
  String get reminderRepeatYearlyLabel => 'Yearly';

  @override
  String get reminderYearlyDateFieldLabel => 'Date (year ignored)';

  @override
  String get reminderMonthlyDayFieldLabel => 'Day of month';

  @override
  String get dayOfMonthCapsLabel => 'DAY';

  @override
  String get routineRepeatSectionLabel => 'Repeat';

  @override
  String get routineRepeatEveryNDaysOption => 'Every N days';

  @override
  String get routineRepeatWeeklyGoalOption => 'N times a week';

  @override
  String routineIntervalDaysValueLabel(int n) {
    return 'Every $n days';
  }

  @override
  String routineWeeklyGoalValueLabel(int n) {
    return '${n}x/week';
  }

  @override
  String get routineTimeFieldLabel => 'Time';

  @override
  String get routineFixedTimeOption => 'At a set time';

  @override
  String get routineNoFixedTimeOption => 'Anytime, no set time';

  @override
  String get routineWhoDoesLabel => 'Who does it';

  @override
  String get routineRotationCadenceLabel => 'How often the turn changes';

  @override
  String get routineRotationCadencePerOccurrence => 'Every time';

  @override
  String get routineRotationCadenceWeekly => 'Weekly';

  @override
  String get routineRotationCadenceMonthly => 'Monthly';

  @override
  String routineRotationSummary(int n) {
    return 'Rotating ($n)';
  }

  @override
  String get routineStepsLabel => 'Steps';

  @override
  String get routineStepsSheetTitle => 'Steps to complete';

  @override
  String get routineAddStepHint => 'Add a step…';

  @override
  String routineWhoseTurnLabel(String name) {
    return 'Turn: $name';
  }

  @override
  String get routineSwapTurnAction => 'Swap';

  @override
  String get routineSkipTurnAction => 'Skip turn';

  @override
  String routineWeeklyGoalProgressLabel(int done, int total) {
    return '$done/$total this week';
  }

  @override
  String get routinePartialStatusLabel => 'Partial';

  @override
  String routineStepsProgressLabel(int done, int total) {
    return '$done/$total steps';
  }

  @override
  String get routineAnyTimeTodayLabel => 'Anytime today';

  @override
  String get routineFormExplainer =>
      'A routine repeats and tracks completion — for habits and family duties, unlike a one-off reminder';

  @override
  String routineStreakDaysLabel(int n) {
    return '$n-day streak';
  }

  @override
  String get routineNoStreakYetLabel => 'No streak yet — start today';

  @override
  String get routineAllRoutinesScreenTitle => 'Family duties';

  @override
  String get routineNoAssigneesHint => 'No duties yet';

  @override
  String get defaultNotesSectionName => 'Notes';

  @override
  String get addAnotherTimeAction => 'Add another time';

  @override
  String get addAtLeastOneTimeError => 'Add at least one time';

  @override
  String get chooseAtLeastOneDayError => 'Choose at least one weekday';

  @override
  String get reminderTagsFieldLabel => 'Tags';

  @override
  String get reminderTagsHint =>
      'Tags to keep things organized, comma-separated';

  @override
  String get reminderTagsPickerTitle => 'Choose tags';

  @override
  String get addNewTagHint => 'New tag';

  @override
  String get noTagsYetLabel => 'No tags yet';

  @override
  String get reminderPhotoLabel => 'Photo';

  @override
  String get monthGenJan => 'January';

  @override
  String get monthGenFeb => 'February';

  @override
  String get monthGenMar => 'March';

  @override
  String get monthGenApr => 'April';

  @override
  String get monthGenMay => 'May';

  @override
  String get monthGenJun => 'June';

  @override
  String get monthGenJul => 'July';

  @override
  String get monthGenAug => 'August';

  @override
  String get monthGenSep => 'September';

  @override
  String get monthGenOct => 'October';

  @override
  String get monthGenNov => 'November';

  @override
  String get monthGenDec => 'December';

  @override
  String get historyLabel => 'History';

  @override
  String get wellbeingScheduleInfoText =>
      'Set up a schedule for mood check-ins. A card to fill in will appear on the home screen at the scheduled time.';

  @override
  String get frequencyPerDayLabel => 'FREQUENCY PER DAY';

  @override
  String get collectionTimeLabel => 'CHECK-IN TIME';

  @override
  String wellbeingSlotNumberLabel(int index) {
    return 'Check-in $index';
  }

  @override
  String get reminderTimesFieldLabel => 'REMINDER TIME';

  @override
  String timeSlotNumberLabel(int index) {
    return 'Time $index';
  }

  @override
  String timesCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$_temp0';
  }

  @override
  String get saveScheduleAction => 'Save schedule';

  @override
  String get wellbeingByDaySubtitle => 'mood by day';

  @override
  String get addWellbeingSlotAction => '+ Check-in';

  @override
  String moodChartTitle(String month) {
    return 'Mood — $month';
  }

  @override
  String get monthNomJan => 'January';

  @override
  String get monthNomFeb => 'February';

  @override
  String get monthNomMar => 'March';

  @override
  String get monthNomApr => 'April';

  @override
  String get monthNomMay => 'May';

  @override
  String get monthNomJun => 'June';

  @override
  String get monthNomJul => 'July';

  @override
  String get monthNomAug => 'August';

  @override
  String get monthNomSep => 'September';

  @override
  String get monthNomOct => 'October';

  @override
  String get monthNomNov => 'November';

  @override
  String get monthNomDec => 'December';

  @override
  String get weekdayFullMon => 'Monday';

  @override
  String get weekdayFullTue => 'Tuesday';

  @override
  String get weekdayFullWed => 'Wednesday';

  @override
  String get weekdayFullThu => 'Thursday';

  @override
  String get weekdayFullFri => 'Friday';

  @override
  String get weekdayFullSat => 'Saturday';

  @override
  String get weekdayFullSun => 'Sunday';

  @override
  String get todayLowerLabel => 'today';

  @override
  String get yesterdayLowerLabel => 'yesterday';

  @override
  String quotedCommentLabel(String comment) {
    return '\"$comment\"';
  }

  @override
  String get noWellbeingLogsTitle => 'No check-ins yet';

  @override
  String get noWellbeingLogsHint =>
      'Your mood history will show up here. Tap \"+ Check-in\" to add your first entry';

  @override
  String get comingSoonEllipsis => 'Coming soon...';

  @override
  String get sendDiaryToDoctorLabel => 'Share summary';

  @override
  String get diarySummaryHint => 'Mood check-ins and doses for the month';

  @override
  String get moodBadLabel => 'Bad';

  @override
  String get moodMehLabel => 'Meh';

  @override
  String get moodOkLabel => 'OK';

  @override
  String get moodGoodLabel => 'Good';

  @override
  String get moodGreatLabel => 'Great';

  @override
  String get chooseWellbeingErrorSnackbar => 'Please select your mood';

  @override
  String get wellbeingSlotMorning => 'morning check-in';

  @override
  String get wellbeingSlotAfternoon => 'afternoon check-in';

  @override
  String get wellbeingSlotEvening => 'evening check-in';

  @override
  String get howAreYouFeelingLabel => 'What\'s your mood?';

  @override
  String get anySymptomsLabel => 'Tags';

  @override
  String get chooseFromListOrAddLabel => 'Add your own tags (optional)';

  @override
  String get commentLabel => 'Comment';

  @override
  String get optionalSuffixLabel => '· optional';

  @override
  String get orTypeTextLabel => 'or type it out';

  @override
  String get describeFeelingHint => 'Describe your mood…';

  @override
  String get saveWellbeingCheckAction => 'Save check-in';

  @override
  String get voiceTranscriptLabel => 'Voice transcript';

  @override
  String get editableTextBelowHint =>
      'You can edit the text in the field below';

  @override
  String get recordAgainAction => 'Record again';

  @override
  String get dictateCommentLabel => 'Dictate your comment';

  @override
  String get micUnavailableLabel => 'Microphone unavailable';

  @override
  String get tapAndSpeakLabel => 'Tap and speak';

  @override
  String get speakNowLabel => 'Speak now… tap to stop';

  @override
  String get preparingMicLabel => 'Getting ready… one second';

  @override
  String get restoreErrorBody =>
      'Couldn\'t restore: check your password and connection, then try again';

  @override
  String get backupPasswordDialogTitle => 'Backup password';

  @override
  String get backupPasswordDialogBody =>
      'Enter the password you set when creating the backup.';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get restoreAccountTitle => 'Restore account';

  @override
  String get restoreAccountSubtitle =>
      'Connect to the storage where your backup is saved';

  @override
  String get googleDriveLabel => 'Google Drive';

  @override
  String get iCloudLabel => 'iCloud';

  @override
  String get doneExclamationTitle => 'Done!';

  @override
  String get setupCompleteBody =>
      'Everything\'s set up. Open the dashboard and start tracking your health.';

  @override
  String get firstReminderTodayLabel => 'First reminder — today';

  @override
  String get noRemindersYetLabel => 'No reminders yet';

  @override
  String get reminderWillArriveLabel =>
      'A reminder will arrive according to the schedule you just added';

  @override
  String get setupMedsToActivateLabel =>
      'Add something to your inventory to activate reminders';

  @override
  String get privacyConsentPrefix => 'I have read and agree to the ';

  @override
  String get privacyConsentSuffix => ' of the app';

  @override
  String get openDashboardAction => 'Open dashboard →';

  @override
  String get joinFailedCheckCodeError => 'Couldn\'t join: check the code';

  @override
  String get connectToFamilyTitle => 'Connect to family';

  @override
  String get enterAccessCodeHint =>
      'Enter the access code your family sent you';

  @override
  String get checkingEllipsisLabel => 'Checking...';

  @override
  String get scheduleAlreadyReadyTitle => 'Schedule is already set up';

  @override
  String scheduleSetByInviterBody(String name) {
    return '$name has already set up a usage schedule for you. You\'ll be able to edit it any time after connecting.';
  }

  @override
  String get agreeUseFamilyScheduleCheckbox =>
      'I agree to use the schedule set up by my family';

  @override
  String get startAction => 'Start';

  @override
  String get creatingEllipsisLabel => 'Creating...';

  @override
  String get declineScheduleCreateOwnAction =>
      'No, I\'ll create my own schedule';

  @override
  String get familyFallbackName => 'Family';

  @override
  String get profileFallbackName => 'Profile';

  @override
  String get enterYourNameError => 'Enter your name';

  @override
  String get walkActivityName => 'Walk';

  @override
  String onboardingFinishError(String error) {
    return 'Error finishing setup: $error';
  }

  @override
  String get welcomeGreeting => 'Hi there! 👋';

  @override
  String get welcomeDescription =>
      'Elly helps you keep track of your inventory,\nactivities, and mood — for you\nand your whole family';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get accountChoiceTitle => 'How would you like to start?';

  @override
  String get accountChoiceSubtitle => 'Choose the option that fits you';

  @override
  String get createAccountTitle => 'Create an account';

  @override
  String get createAccountSubtitle =>
      'I\'ll set up my inventory and a schedule for myself';

  @override
  String get joinFamilyChoiceTitle => 'Join a family';

  @override
  String get joinFamilyChoiceSubtitle => 'I have an access code from my family';

  @override
  String get restoreAccountChoiceSubtitle => 'I\'ve used Elly before';

  @override
  String get tellAboutYourselfTitle => 'Tell us about yourself';

  @override
  String get tellAboutYourselfSubtitle =>
      'Enter your name and choose a profile avatar';

  @override
  String get nextToMedsAction => 'Next — inventory →';

  @override
  String get scanOrEnterManuallyHint =>
      'Add the things you\'re currently using';

  @override
  String get addMedsShortAction => 'Add to inventory';

  @override
  String get addMoreMedsAction => 'Add more';

  @override
  String get onboardingAddItemAction => 'Add';

  @override
  String get onboardingAddItemHint =>
      'A reminder or an inventory item — pick one';

  @override
  String get addMedsLaterInfo =>
      'You can add inventory later from the \"Inventory\" section in the main menu';

  @override
  String get nextAction => 'Next →';

  @override
  String get skipAddLaterAction => 'Skip — I\'ll add later';

  @override
  String get activityWellbeingTitle => 'Activity & mood';

  @override
  String get activityWellbeingSubtitle =>
      'Turn it on with one switch — you can change the settings later';

  @override
  String get activitySectionLabel => 'Activity';

  @override
  String get walkActivitySub => '30 min · daily · 8:30 AM';

  @override
  String get wellbeingDiaryLabel => 'Mood diary';

  @override
  String get wellbeingDiaryDescription =>
      'Quick mood notes help you see the connection between your inventory and how you feel';

  @override
  String get wellbeingSlotsTitle => 'Mood check-ins';

  @override
  String get wellbeingSlotsSub => '2–3 times a day · 8:00 AM, 2:00 PM, 8:00 PM';

  @override
  String get almostDoneAction => 'Almost done →';

  @override
  String get backupScreenTitle => 'Backup';

  @override
  String get backupIntroBody =>
      'Inventory, schedule, archive (photos), and all other data — choose where to keep your backup.';

  @override
  String get backupModeLocalTitle => 'Device only';

  @override
  String get backupModeLocalSubtitle =>
      'All data will be lost if you reinstall the app';

  @override
  String get backupModeGoogleDriveSubtitle =>
      'Encrypted on your device — neither Elly nor Google can see your data';

  @override
  String get backupModeICloudSubtitle =>
      'Encrypted on your device — neither Elly nor Apple can see your data';

  @override
  String get backupFrequencyCapsLabel => 'AUTO-BACKUP FREQUENCY';

  @override
  String get backupFrequencyDailyLabel => 'Once a day';

  @override
  String get backupFrequencyWeeklyLabel => 'Once a week';

  @override
  String get backupFrequencyExplainerBody =>
      'This runs when you open the app or bring it back to the foreground — it\'s not a true background schedule. If you don\'t open Elly for longer than the chosen frequency, a backup will run right away the next time you open it.';

  @override
  String get backupNeverDoneLabel => 'No backup yet';

  @override
  String lastBackupAtLabel(String date) {
    return 'Last backup: $date';
  }

  @override
  String get createBackupNowAction => 'Create backup now';

  @override
  String get restoreFromBackupAction => 'Restore from backup';

  @override
  String get changeBackupPassphraseAction => 'Change backup password';

  @override
  String get backupPassphraseDialogTitle => 'Backup password';

  @override
  String get backupPassphraseDialogSubtitle =>
      'Choose a password. Without it, your data can\'t be restored — not even by us.';

  @override
  String backupSavedSnackbar(String target) {
    return 'Backup saved to $target';
  }

  @override
  String get restorePassphraseDialogTitle => 'Backup password';

  @override
  String get restorePassphraseDialogSubtitle =>
      'Enter the password you set when creating the backup.';

  @override
  String get restoreDoneBody => 'Data restored.';

  @override
  String get restoreFailedError =>
      'Couldn\'t restore: wrong password or no backup found';

  @override
  String get changePassphraseDialogTitle => 'New backup password';

  @override
  String get changePassphraseDialogSubtitle =>
      'A new backup will be created with this password right after the change — remember it, since the old backup under the old password can no longer be used.';

  @override
  String get passphraseChangedSnackbar => 'Password changed, new backup saved';

  @override
  String get confirmRestoreTitle => 'Restore from backup?';

  @override
  String get confirmRestoreBody =>
      'Current data on this device will be replaced with data from the backup. This action cannot be undone.';

  @override
  String get restoreAction => 'Restore';

  @override
  String get confirmPasswordFieldLabel => 'Confirm password';

  @override
  String get passwordTooShortError => 'Password must be at least 6 characters';

  @override
  String get passwordsMismatchError => 'Passwords don\'t match';

  @override
  String get gotItAction => 'Got it';

  @override
  String get choosePlanTitle => 'Choose your plan';

  @override
  String get choosePlanSubtitle => 'Care for your family';

  @override
  String get monthToggleLabel => 'Month';

  @override
  String get yearToggleDiscountLabel => 'Year −20%';

  @override
  String get familyTiesBrokenTitle => 'Family ties will be broken';

  @override
  String get familyTiesBrokenBody =>
      'Members of your family group will immediately lose access to Family perks and stop seeing each other. This happens instantly, with no grace period — you\'re being warned now.';

  @override
  String get breakAndChangePlanAction => 'Break ties and change plan';

  @override
  String planActivatedTestSnackbar(String plan) {
    return '$plan activated (test mode, no real payment)';
  }

  @override
  String actionFailedError(String error) {
    return 'Failed: $error';
  }

  @override
  String get planForeverPeriod => 'forever';

  @override
  String get planPerMonthYearlyPeriod => 'per month (billed yearly)';

  @override
  String get planPerMonthPeriod => 'per month';

  @override
  String get freeFeatureAllSections => '1 active routine, 3 Shelf sections';

  @override
  String get freeFeatureUnlimitedMeds => 'Unlimited reminders';

  @override
  String get freeFeatureLocalBackup => 'Local + backup to Google Drive/iCloud';

  @override
  String get selectFreeAction => 'Choose Free';

  @override
  String get plusFeatureAllFree => 'Everything in Free';

  @override
  String get plusFeatureUnlimitedProfiles =>
      'Unlimited family profiles — you\'re the only one in control';

  @override
  String get planFeatureUnlimitedRoutines => 'Unlimited routine tasks';

  @override
  String get planFeatureUnlimitedShelves => 'Unlimited shelves';

  @override
  String get selectPlusAction => 'Choose Plus';

  @override
  String get familyFeatureAllPlus => 'Everything in Elly Plus';

  @override
  String get familyFeatureAutonomousProfiles =>
      'Independent profiles — up to 8 people';

  @override
  String get familyFeatureSelfManaged => 'Everyone manages their own profile';

  @override
  String get selectFamilyAction => 'Choose Family';

  @override
  String billingTermsDisclaimer(String store) {
    return 'Payment is charged to your $store account. The subscription renews automatically for the same price unless cancelled at least 24 hours before the end of the period. You can manage your subscription and turn off auto-renewal in your $store account settings.';
  }

  @override
  String get privacyPolicyLinkLabel => 'Privacy Policy';

  @override
  String get termsOfUseLinkLabel => 'Terms of Use';

  @override
  String get currentPlanLabel => 'Current';

  @override
  String get tooManyProfilesForPlanTitle => 'Too many profiles for this plan';

  @override
  String get upgradeToEditSubtitle =>
      'Upgrade to Elly Plus or Elly Family to edit';

  @override
  String get viewPlansAction => 'View plans';

  @override
  String get paymentFailedTitle => 'Payment couldn\'t be charged';

  @override
  String gracePeriodRemainingBody(String timeLeft) {
    return 'You have $timeLeft left to update your payment method — everything still works without limits in the meantime, for you and everyone in your family group.';
  }

  @override
  String get gracePeriodExpiredBody =>
      'Update your payment method right away, or your family group will be broken up.';

  @override
  String get laterAction => 'Later';

  @override
  String get updatePaymentAction => 'Update payment';

  @override
  String get accessChangedTitle => 'Access has changed';

  @override
  String get changePlanAction => 'Change plan';

  @override
  String daysLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String hoursLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String minutesLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String get planFreeShortLabel => 'Free';

  @override
  String get exportShareSubject => 'Elly — data export';

  @override
  String get exportCopyTitle => 'A copy of all your data';

  @override
  String get exportDescriptionBody =>
      'A JSON file with all profiles, inventory, schedule, doses, mood logs, and doctor visits — everything stored on this device. You can open it anywhere or share it with anyone.\n\nInventory photos are not included in the file (they\'re already in your \"Backup\") — text data only.';

  @override
  String get exportAction => 'Export';

  @override
  String get appLockedTitle => 'Elly is locked';

  @override
  String get authFailedRetryBody =>
      'Couldn\'t verify your identity — try again';

  @override
  String get confirmIdentityBody => 'Confirm your identity to continue';

  @override
  String get checkingDotsLabel => 'Checking...';

  @override
  String get unlockAction => 'Unlock';

  @override
  String get addTypeSheetTitle => 'What would you like to add?';

  @override
  String get addTypeSheetSubtitle => 'Choose a type — the form will adjust';

  @override
  String get addTypeMedsSub =>
      'A consumable stock on a schedule — tracks what\'s left, when to restock';

  @override
  String get addTypeActivitySub => 'Walk, exercise, workout, physical therapy';

  @override
  String get addTypeAppointmentSub => 'Date, time, and a reminder for anything';

  @override
  String get addTypeWellbeingSub => 'Log a check-in — mood, tags, comment';

  @override
  String get taskTypeSport => 'Sport';

  @override
  String get taskTypeSportSub => 'Walk, workout, exercise';

  @override
  String get taskTypeMeeting => 'Meetings';

  @override
  String get taskTypeMeetingSub => 'Date, time, and a reminder for anything';

  @override
  String get taskTypeSimple => 'Simple tasks';

  @override
  String get taskTypeSimpleSub => 'A one-off or simple reminder';

  @override
  String get taskTypeRoutine => 'Routine chores';

  @override
  String get taskTypeRoutineSub =>
      'A habit or duty with a flexible repeat — checklist and turn-taking';

  @override
  String get reminderCategoryTitle => 'Reminder';

  @override
  String get reminderCategorySub =>
      'An event or task with a date — once or repeating';

  @override
  String get noteCategoryTitle => 'Note';

  @override
  String get noteCategorySub => 'Just a record — no reminders';

  @override
  String get faqGroupPrivacyTitle => 'Privacy & data';

  @override
  String get faqPrivacyQ1 => 'Who can see my data?';

  @override
  String get faqPrivacyA1 =>
      'No one but you. Everything is stored encrypted on your device (SQLCipher, AES-256). Elly\'s server is deliberately \"blind\": there\'s no email or password registration, and whatever does pass through the server (family invitations, sync, subscription confirmation) only sees encrypted blocks and technical identifiers — impossible to decrypt without the key.';

  @override
  String get faqPrivacyQ2 =>
      'What\'s the difference between Backup and Family Invitation?';

  @override
  String get faqPrivacyA2 =>
      'Backup is a snapshot of your own data in your Google Drive/iCloud in case you lose your phone or reinstall the app. A Family Invitation is a live exchange of schedules between DIFFERENT people (for example, a child seeing their mom\'s schedule) via QR code or invitation code. These are two different mechanisms: one is about you yourself, the other is about shared access between multiple people.';

  @override
  String get faqPrivacyQ3 =>
      'What happens if I delete the app without a backup?';

  @override
  String get faqPrivacyA3 =>
      'The data will be lost permanently — there\'s no copy on the server. Be sure to make a backup ahead of time (Profile → Backup).';

  @override
  String get faqPrivacyQ4 => 'How do I delete my data completely?';

  @override
  String get faqPrivacyA4 =>
      'Delete the app from your device (and the backup from Drive/iCloud manually, if you made one). You can also delete a profile separately — Profile → Privacy → Danger zone.';

  @override
  String get faqGroupFamilyTitle => 'Family';

  @override
  String get faqFamilyQ1 =>
      'How do I add a family member or a dependent profile?';

  @override
  String get faqFamilyA1 =>
      'On the \"Family\" tab — the add-profile button. Dependent profiles (children, elderly parents) don\'t have their own login — they\'re managed by the device owner.';

  @override
  String get faqFamilyQ2 =>
      'How do I hand off a profile to someone else (e.g. a grown child)?';

  @override
  String get faqFamilyA2 =>
      'On the local profile\'s card — the \"Invite to the app\" button: show the QR code or tell the invitation code to the person joining on their own device. The profile will turn from local into independent — that person will manage it themselves from then on, and all of its history will be kept. The data is encrypted with a key derived from the invitation code — the server only sees the encrypted block.';

  @override
  String get faqFamilyQ3 => 'Who can see what about other family members?';

  @override
  String get faqFamilyA3 =>
      'This is configured in Profile → Family visibility — separately for each profile.';

  @override
  String get faqFamilyQ4 => 'Can I belong to several family groups at once?';

  @override
  String get faqFamilyA4 =>
      'Yes. For example, you can be a member of your parents\' family while also having your own family that you created — these are two independent groups. Leaving one doesn\'t affect the other, and data from different families is never mixed.';

  @override
  String get faqFamilyQ5 =>
      'How does the turn order work for routines with several people?';

  @override
  String get faqFamilyA5 =>
      'When a routine has several assignees, the app works out whose turn it is based on the chosen cadence: \"every time\" — the turn moves on after each completion; \"weekly\" — the same person handles every occurrence for the whole calendar week, then the turn moves on; \"monthly\" — the same, but for a whole calendar month, even if the routine repeats several times a week. Only the person whose turn it currently is sees the routine\'s card on their own Today screen; you can hand the turn off manually with the \"Skip turn\" button.';

  @override
  String get faqNotificationsQ1 => 'Why aren\'t reminders arriving?';

  @override
  String get faqNotificationsA1 =>
      'The most common cause is Android\'s battery optimization limiting the app\'s background activity. Add Elly to the exceptions in your device\'s power-saving settings. Also check \"Quiet hours\" in Profile → Notifications.';

  @override
  String get faqNotificationsQ2 =>
      'How do I set up a repeat reminder if I didn\'t respond?';

  @override
  String get faqNotificationsA2 =>
      'Profile → Notifications → \"Repeat if no response\" — choose an interval with the slider.';

  @override
  String get faqPlansQ1 => 'What\'s the difference between plans?';

  @override
  String get faqPlansA1 =>
      'Elly (free) — basic features with limits. Elly Plus and Elly Family remove the limits and add extra features. Details — Profile → Plans.';

  @override
  String get faqPlansQ2 => 'What exactly does the free plan limit?';

  @override
  String get faqPlansA2 =>
      '1 local profile, 1 active routine, 3 Shelf sections. Reminders, inventory, and mood tracking are unlimited on every plan. Going over a limit never deletes anything: older entries stay viewable, only editing or creating new ones is blocked until you upgrade.';

  @override
  String get faqPlansQ3 => 'How many people can I add to a family group?';

  @override
  String get faqPlansA3 =>
      'On Elly Family — up to 8 independent members. Only the person paying for the subscription can invite new people; accepting an invitation is free on any plan. The invited person gets every Family perk except the right to invite others into that same family.';

  @override
  String get faqGroupTechTitle => 'Technical issues';

  @override
  String get faqTechQ1 =>
      'Biometrics aren\'t working / I forgot my backup password';

  @override
  String get faqTechA1 =>
      'The backup password is only remembered locally on this device (so scheduled automatic backups don\'t have to ask for it every time) — it never reaches our servers. If you reinstall the app or switch devices, you\'ll need to enter the same password manually again; if you\'ve forgotten it, the backup can\'t be restored and you\'ll need to create a new one. Biometrics can be reconfigured in your device\'s system settings.';

  @override
  String get faqTechQ2 => 'I can\'t restore data from a backup';

  @override
  String get faqTechA2 =>
      'The most common cause is a wrong password (the same one you set when creating the backup) or no internet connection. Make sure you\'re restoring the backup on a matching device type (iCloud backups only restore on iOS, Google Drive backups on Android or iOS). After a successful restore, the app will ask you to restart.';

  @override
  String get faqNotFoundQuestionTitle => 'Didn\'t find your answer?';

  @override
  String get faqWriteUsSubtitle => 'Write to us — we\'ll reply personally.';

  @override
  String get supportLabel => 'Support';

  @override
  String get supportChatLabel => 'Support chat';

  @override
  String get soonLabel => 'Coming soon';

  @override
  String get notificationsMainSectionTitle => 'Main';

  @override
  String get pushNotificationsLabel => 'Push notifications';

  @override
  String get pushNotificationsSub => 'Reminders to use your inventory';

  @override
  String get vibrationLabel => 'Vibration';

  @override
  String get vibrationSub => 'Together with sound';

  @override
  String get reminderTimeSectionTitle => 'Reminder time';

  @override
  String get quietHoursSectionTitle => 'Quiet hours';

  @override
  String get doNotDisturbLabel => 'Do not disturb';

  @override
  String get nightModeSub => 'Night mode';

  @override
  String get quietFromLabel => 'From';

  @override
  String get quietToLabel => 'To';

  @override
  String get memberMissedAlertsSectionTitle =>
      'Alerts when family members miss something';

  @override
  String get familyNotificationsSectionTitle => 'Notifications from family';

  @override
  String get peerNotifyExplainerBody =>
      'These members have allowed sending you notifications about themselves. Here you decide whether you want to receive them.';

  @override
  String get reminderOffsetLabel => 'Reminder offset';

  @override
  String get reminderOffsetSub =>
      'Get notified N minutes before the scheduled time';

  @override
  String get noOffsetLabel => 'no offset';

  @override
  String minusMinutesLabel(int minutes) {
    return '−$minutes min';
  }

  @override
  String get repeatIfNoResponseLabel => 'Repeat if no response';

  @override
  String repeatInLabel(String label) {
    return 'In $label';
  }

  @override
  String get deleteActivityConfirmTitle => 'Delete this activity?';

  @override
  String get deleteActivityConfirmBody =>
      'The activity will be removed from your schedule.';

  @override
  String get disableWellbeingConfirmTitle => 'Turn off mood check-ins?';

  @override
  String get disableWellbeingConfirmBody =>
      'Reminders will disappear from Schedule and Today. Your settings are kept — you can turn it back on later.';

  @override
  String get applyAction => 'Done';

  @override
  String get noDaysSelectedHint => 'No days selected';

  @override
  String get chooseActivityTypeError => 'Choose an activity type';

  @override
  String get enterActivityNameError => 'Enter the activity name';

  @override
  String get editActivityTitle => 'Edit routine';

  @override
  String get newRoutineTitle => 'Routine';

  @override
  String get activityTypeLabel => 'Activity type';

  @override
  String get activityTypeWorkout => 'Exercise';

  @override
  String get activityTypeGym => 'Workout';

  @override
  String get activityTypeYoga => 'Yoga / physical therapy';

  @override
  String get activityTypeCycling => 'Cycling';

  @override
  String get activityTypeCustom => 'Custom';

  @override
  String get activityNameHint => 'Activity name';

  @override
  String get youtubeLinkLabel => 'YouTube link';

  @override
  String get youtubeLinkDescription =>
      'A workout video or clip — a preview will show on today\'s card';

  @override
  String get addAnotherActivityAction => 'Add another activity';

  @override
  String get weekdaysLabel => 'Days of the week';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get reminderActivityDescription => '10 minutes before each session';

  @override
  String get saveActivityAction => 'Save activity';

  @override
  String activitySessionNumberLabel(int number) {
    return 'Session $number';
  }

  @override
  String get noDurationLabel => 'No duration';

  @override
  String saveWithDurationLabel(String duration) {
    return 'Save · $duration';
  }

  @override
  String durationHoursMinutesLabel(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String minutesWithValueLabel(String value) {
    return '$value min';
  }

  @override
  String get taskColorPickerLabel => 'CARD COLOR';

  @override
  String viewingProfileLabel(String name) {
    return 'You\'re viewing: $name';
  }

  @override
  String get returnAction => 'Return';

  @override
  String get recoveryKeyDialogTitle => 'Your recovery key';

  @override
  String get recoveryKeyDialogBody =>
      'Save this code somewhere safe. It\'s the only way to restore your data on a new device — without it, we can\'t help you either.';

  @override
  String get copiedSnackbar => 'Copied';

  @override
  String get recoveryKeySavedConfirmAction => 'I\'ve saved the code';

  @override
  String get buyAction => 'Buy';

  @override
  String get affiliateDisclaimerLabel =>
      'Ad · affiliate link, Elly doesn\'t sell this product';

  @override
  String get legalPageLoadError =>
      'Couldn\'t load the page. Check your internet connection.';

  @override
  String get medFormTablet => 'Tablet';

  @override
  String get medFormCapsule => 'Capsule';

  @override
  String get medFormSuppository => 'Suppository';

  @override
  String get medFormVial => 'Vial';

  @override
  String get medFormSyrup => 'Syrup';

  @override
  String get medFormDrops => 'Drops';

  @override
  String get medFormCream => 'Cream';

  @override
  String get medFormInhaler => 'Inhaler';

  @override
  String get medFormInjection => 'Injection';

  @override
  String get medUnitTablet => 'tab.';

  @override
  String get medUnitCapsule => 'cap.';

  @override
  String get medUnitMl => 'ml';

  @override
  String get medUnitDrops => 'gtt';

  @override
  String get medUnitGram => 'g';

  @override
  String get medUnitInhale => 'puff';

  @override
  String get medUnitSuppository => 'supp.';

  @override
  String get medUnitVial => 'vial';

  @override
  String get medUnitPiece => 'pc.';

  @override
  String get stockUnitKg => 'kg';

  @override
  String get stockUnitLiter => 'l';

  @override
  String get stockUnitTube => 'tube';

  @override
  String get stockUnitPack => 'pack';

  @override
  String get stockUnitJar => 'jar';

  @override
  String get stockUnitBottle => 'bottle';

  @override
  String get stockUnitPortion => 'portion';

  @override
  String get stockUnitSpoon => 'spoon';

  @override
  String get stockUnitGlass => 'glass';

  @override
  String get stockUnitLabel => 'Measurement unit';

  @override
  String get inventoryFormHint => 'Bottle, pack, jar...';

  @override
  String get chooseProfileLabel => 'Choose a profile';

  @override
  String get chooseAction => 'Choose';

  @override
  String get noDocumentsLabel => 'No documents';

  @override
  String get addPhotoOrPdfLabel => 'Add photo or PDF';

  @override
  String get documentsPrivacyHint =>
      'Stored only on your device (and in the cloud if backup is enabled) — the app never views or analyzes these files.';

  @override
  String get notifChannelName => 'Elly reminders';

  @override
  String get notifChannelDesc =>
      'Reminders for inventory, activities, visits, and mood check-ins';

  @override
  String notifTakeMedTitle(String name) {
    return '⏰ Time for $name';
  }

  @override
  String notifIntakeNoResponseTitle(String name) {
    return '🔔 You haven\'t marked yet: $name';
  }

  @override
  String get notifBackupReminderTitle => 'Protect your data';

  @override
  String get notifBackupReminderBody =>
      'Backup is off — data is stored only on this device. Turn it on in Profile so you don\'t lose it.';

  @override
  String get notifLowStockTitle => '⚠️ Running low';

  @override
  String notifLowStockBody(String medName, int remaining, String unit) {
    return '$medName — $remaining $unit left';
  }

  @override
  String get notifActivityTitle => '🚶 Time for your activity';

  @override
  String get notifActivityNoResponseTitle =>
      '🔔 You haven\'t marked this activity yet';

  @override
  String get notifAppointmentTitle => '🔔 Reminder';

  @override
  String get notifAppointmentNoResponseTitle =>
      '🔔 Don\'t forget your reminder';

  @override
  String get notifWellbeingTitle => '💜 Mood check-in';

  @override
  String get notifWellbeingBody => 'What\'s your mood?';

  @override
  String notifPeerCheckTitle(String subjectName) {
    return '🔔 Check on $subjectName';
  }

  @override
  String notifPeerIntakeCheckBody(String medName, String dose, String timeStr) {
    return 'Was \"$medName\" ($dose) taken at $timeStr? Open the app and wait for sync to see the current status.';
  }

  @override
  String notifPeerActivityCheckBody(String activityName, String timeStr) {
    return 'Was \"$activityName\" done at $timeStr? Open the app and wait for sync to see the current status.';
  }

  @override
  String notifPeerAppointmentCheckBody(String doctorType, String timeStr) {
    return 'Did the reminder (\"$doctorType\") at $timeStr happen? Open the app and wait for sync to see the current status.';
  }

  @override
  String notifPeerWellbeingCheckBody(String timeStr) {
    return 'Was the mood check-in at $timeStr done? Open the app and wait for sync to see the current status.';
  }

  @override
  String forMemberSuffix(String name) {
    return ' for $name';
  }

  @override
  String get dbLoadErrorTitle => 'Elly needs a restart';

  @override
  String get dbLoadErrorBody =>
      'Fully close the app — swipe up from the bottom of the screen and swipe the Elly card away — then open it again. Your data hasn\'t gone anywhere, everything will be back in a few seconds.';

  @override
  String get unlockPhoneTitle => 'Unlock your phone';

  @override
  String get unlockPhoneBody =>
      'Your data is safe — nothing is damaged and there\'s nothing to delete. iOS is simply keeping the encryption key locked until the phone has been unlocked at least once since restart.';

  @override
  String get unlockStep1 =>
      'Unlock your phone (Face ID, Touch ID, or passcode).';

  @override
  String get unlockStep2 =>
      'Return to Elly — your data will load automatically, nothing to tap.';

  @override
  String get checkAgainAction => 'Check again';

  @override
  String get loadingEllipsisLabel => 'Loading...';

  @override
  String get familyDisbandedReason =>
      'Family payment couldn\'t be renewed in time, so the family group has been disbanded. Your local data hasn\'t gone anywhere.';

  @override
  String manageSubscriptionExternallyHint(String store) {
    return 'Subscription management opened in the $store — finish cancelling there.';
  }

  @override
  String get restorePurchasesAction => 'Restore purchases';

  @override
  String get restorePurchasesSuccessSnackbar => 'Purchases restored';

  @override
  String get restorePurchasesNothingFoundSnackbar =>
      'No active purchases found for this account';

  @override
  String get todayScheduleForMedLabel => 'Today\'s schedule';

  @override
  String get intakeSnoozed => 'Postponed';

  @override
  String get resetLocalDbConfirmTitle => 'Reset local database?';

  @override
  String get resetLocalDbConfirmBody =>
      'This will delete all data on this device (inventory, schedule, shelves). No backup was found — this data cannot be recovered afterward.';

  @override
  String get resetAction => 'Reset';

  @override
  String get resetLocalDbAction => 'Reset local database';

  @override
  String get petAvatarsSectionLabel => 'Pets';
}
