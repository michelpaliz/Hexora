// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get groups => 'Groups';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Log out';

  @override
  String get groupData => 'Group Data';

  @override
  String get notifications => 'Notifications';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get language => 'en';

  @override
  String get changeView => 'Change the view';

  @override
  String welcomeGroupView(Object username) {
    return 'Welcome $username here you can see the list of groups that you are part of.';
  }

  @override
  String get zeroNotifications => 'You\'re all caught up';

  @override
  String get goToCalendar => 'Go to the calendar';

  @override
  String groupName(int maxChar) {
    return 'Group name (max $maxChar characters)  ';
  }

  @override
  String groupDescription(int maxChar) {
    return 'Group description (max $maxChar characters)  ';
  }

  @override
  String get addPplGroup => 'Add people to your group';

  @override
  String get addUser => 'Add user';

  @override
  String get addEvent => 'Add event';

  @override
  String get administrator => 'Administrator';

  @override
  String get coAdministrator => 'Co-Administrator';

  @override
  String get member => 'Member';

  @override
  String get saveGroup => 'Save the group';

  @override
  String get addImageGroup => 'Add image for the group';

  @override
  String get removeEvent => 'Are you sure you want to remove this event ?';

  @override
  String get removeGroup => 'Are you sure you want to remove this group ?';

  @override
  String get removeCalendar =>
      'Are you sure you want to remove this calendar ?';

  @override
  String get groupCreated => 'Group created successfully!';

  @override
  String get failedToCreateGroup => 'Failed to create the group';

  @override
  String get eventCreated => 'The event has been created';

  @override
  String get eventEdited => 'The event has been edited';

  @override
  String get eventAddedGroup => 'The event has been added to the group';

  @override
  String get event => 'Event';

  @override
  String get chooseEventColor => 'Choose the color of the event:';

  @override
  String get errorEventNote => 'Event note cannot be empty!';

  @override
  String get name => 'Name';

  @override
  String get userName => 'User name';

  @override
  String get currentPassword => 'Insert your current password';

  @override
  String get newPassword => 'Update your current password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get password => 'Password';

  @override
  String get register => 'Register';

  @override
  String get login => 'Login';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get downloadMobileApp => 'Download the mobile app';

  @override
  String get userNameHint => 'Enter your username (e.g., john_doe123)';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get emailHint => 'Introduce your email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get confirmPasswordHint => 'Enter your password again';

  @override
  String get logoutMessage => 'Are you sure you want to log out ?';

  @override
  String get passwordNotMatch =>
      'New password and confirmation password do not match.';

  @override
  String get userNameTaken => 'The user name is already taken';

  @override
  String get weakPassword => 'Weak Password';

  @override
  String get emailTaken => 'The email is already taken';

  @override
  String get invalidEmail => 'This is an invalid email address';

  @override
  String get invalidUrl => 'This URL is not valid';

  @override
  String get registrationError => 'Registration error';

  @override
  String get registerCheckEmail =>
      'Account created. Check your email to verify.';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongCredentials => 'Wrong credentials';

  @override
  String get loginInvalidCredentials =>
      'Invalid credentials. Please try again.';

  @override
  String get authError => 'Authentication error';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailInfo =>
      'We\'ve sent you a verification link. Open the link from your email to finish verifying.';

  @override
  String get verifyingEmail => 'Verifying your email...';

  @override
  String get verifyEmailTryAgain => 'Try again';

  @override
  String get resendVerificationButton => 'Resend verification email';

  @override
  String get resendVerificationSending => 'Sending...';

  @override
  String get resendVerificationInvalidEmail =>
      'Please enter a valid email to resend.';

  @override
  String resendVerificationSent(String email) {
    return 'Verification email sent to $email';
  }

  @override
  String resendVerificationFailed(String error) {
    return 'Could not resend verification: $error';
  }

  @override
  String get verifySuccessTitle => 'Email verified';

  @override
  String get verifySuccessMessage =>
      'Your email has been confirmed. You can now sign in and start using the app.';

  @override
  String get downloadAppTitle => 'Get Hexora on your phone';

  @override
  String get downloadAppSubtitle =>
      'Install the Android or iOS app to stay in sync on the go.';

  @override
  String get downloadAppAndroid => 'Get it on Google Play';

  @override
  String get downloadAppIos => 'Download on the App Store';

  @override
  String get downloadAppOpenError =>
      'Couldn\'t open the store link. Please try again.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notRegistered =>
      'Not registered yet?, Don\'t worry register here.';

  @override
  String get alreadyRegistered => 'Already registered?, Login here.';

  @override
  String title(Object maxChar) {
    return 'Title (max $maxChar characters)  ';
  }

  @override
  String description(int maxChar) {
    return 'Description (max $maxChar characters)  ';
  }

  @override
  String note(int maxChar) {
    return 'Note (max $maxChar characters)  ';
  }

  @override
  String get location => 'Location';

  @override
  String get repetitionEvent => 'Duplicate Start Date\'';

  @override
  String get repetitionEventInfo =>
      'An event with the same start hour and day already exists.';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get repetitionDetails => 'Repetition details';

  @override
  String dailyRepetitionInf(int concurrenceDay) {
    return 'This event will repeat every $concurrenceDay day';
  }

  @override
  String get every => 'Every:';

  @override
  String get dailys => 'daily(s)';

  @override
  String get weeklys => 'weekly(s)';

  @override
  String get monthlies => 'monthly(s)';

  @override
  String get yearlys => 'year(s)';

  @override
  String get untilDate => 'Until Date: ';

  @override
  String untilDateSelected(String untilDate) {
    return 'Until Date: $untilDate ';
  }

  @override
  String get notSelected => 'Not Selected';

  @override
  String get utilDateNotSelected => 'Until Date: Not Selected';

  @override
  String get specifyRepeatInterval => 'Please specify repeat interval';

  @override
  String get selectOneDayAtLeast =>
      'Please select at least one day of the week.';

  @override
  String get datesMustBeSame =>
      'Start and end dates must be the same day for the event to repeat';

  @override
  String get startDate => 'Start Date: ';

  @override
  String get endDate => 'End Date: ';

  @override
  String get noDaysSelected => 'No Days Selected';

  @override
  String get selectRepetition => 'Select repetition';

  @override
  String get selectDay => 'Select Day: ';

  @override
  String dayRepetitionInf(int concurrenceWeeks) {
    return 'This event will repeat every $concurrenceWeeks day.';
  }

  @override
  String weeklyRepetitionInf(
      int concurrenceWeeks,
      String customDaysOfWeeksString,
      String lastDay,
      Object customDaysOfWeekString) {
    return 'This event will repeat every $concurrenceWeeks week(s) on $customDaysOfWeekString, and $lastDay ';
  }

  @override
  String weeklyRepetitionInf1(int repeatInterval, String selectedDayNames) {
    return 'This event will repeat every $repeatInterval week(s) on \$$selectedDayNames';
  }

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String errorSelectedDays(String selectedDays) {
    return 'The day of the event is $selectedDays should coincide with one of the selected day/s.';
  }

  @override
  String textFieldGroupName(int TITLE_MAX_LENGHT) {
    return 'Enter group name (Limit: $TITLE_MAX_LENGHT characters) ';
  }

  @override
  String textFieldDescription(int DESCRIPTION_MAX_LENGHT) {
    return 'Enter group description (Limit: $DESCRIPTION_MAX_LENGHT characters)';
  }

  @override
  String monthlyRepetitionInf(
      String selectedDay, int repeatInterval, Object selectDay) {
    return 'This event will repeat on the $selectDay day every $repeatInterval month(s) ';
  }

  @override
  String yearlyRepetitionInf(
      String selectedDay, int repeatInterval, Object selectDay) {
    return 'This event will repeat on the $selectDay day every $repeatInterval year(s) ';
  }

  @override
  String get editGroup => 'Edit Group';

  @override
  String get remove => 'Remove';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get removeConfirmation => 'Confirm to remove';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionDeniedInf =>
      'You are not an administrator to remove this item.';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String permissionDeniedRole(Object role) {
    return 'You are currently a $role of this group.';
  }

  @override
  String get putGroupImage => 'Put an image for the group';

  @override
  String get close => 'close';

  @override
  String get addNewUser => 'Add a new user to your group';

  @override
  String get cannotRemoveYourself =>
      'You cannot remove yourself from the group';

  @override
  String get requiredTextFields => 'Group name and description are required.';

  @override
  String get groupNameRequired => 'Group name cannot be empty';

  @override
  String get groupEdited => 'Group edited successfully!';

  @override
  String get failedToEditGroup => 'Failed to edit the group. Please try again';

  @override
  String get searchPerson => 'Search by user name';

  @override
  String get delete => 'Delete';

  @override
  String get confirmRemovalMessage =>
      'Are you sure you want to delete this group?';

  @override
  String get confirmRemoval => 'Confirm Removal';

  @override
  String get groupDeletedSuccessfully => 'Group deleted successfully!';

  @override
  String get showInactiveClients => 'Show inactive clients';

  @override
  String get hideInactiveClients => 'Hide inactive clients';

  @override
  String removeClientConfirm(Object name) {
    return 'Remove client \"$name\"?';
  }

  @override
  String removeServiceConfirm(Object name) {
    return 'Remove service \"$name\"?';
  }

  @override
  String clientRemovedSnack(Object name) {
    return 'Client removed: $name';
  }

  @override
  String serviceRemovedSnack(Object name) {
    return 'Service removed: $name';
  }

  @override
  String clientDeactivatedSnack(Object name) {
    return 'Client moved to inactive: $name';
  }

  @override
  String serviceDeactivatedSnack(Object name) {
    return 'Service moved to inactive: $name';
  }

  @override
  String removeFailedWithReason(Object reason) {
    return 'Could not remove item: $reason';
  }

  @override
  String get noGroupsAvailable => 'NO GROUP/S FOUND/S';

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get noGroupsDescription => 'Create or join a group to get started';

  @override
  String get searchGroups => 'Search groups';

  @override
  String get weatherSummarySunny => 'Sunny';

  @override
  String get weatherSummaryPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherSummaryCloudyWithRain => 'Cloudy with rain';

  @override
  String get weatherSummaryLightRain => 'Light rain';

  @override
  String get weatherSummaryHeavyRain => 'Heavy rain';

  @override
  String get weatherSummaryStormy => 'Stormy';

  @override
  String get weatherSummaryCloudy => 'Cloudy';

  @override
  String get weatherSummaryDefault => 'Pleasant weather';

  @override
  String weatherGreeting(Object emoji, Object name, Object summary) {
    return 'Hi $name, today looks $summary $emoji';
  }

  @override
  String weatherTempLine(Object max, Object min) {
    return 'High $max° / Low $min°';
  }

  @override
  String get weatherFunTooHot => 'Stay hydrated—it’s going to be scorching.';

  @override
  String get weatherFunTooCold => 'Bundle up—it’s freezing outside.';

  @override
  String get weatherFunGradeA => 'Grade A day. Plan something fun outdoors!';

  @override
  String get weatherFunGradeB => 'Pretty good weather overall.';

  @override
  String get weatherFunGradeC => 'Keep an umbrella handy just in case.';

  @override
  String get weatherFunGradeD => 'Maybe plan for indoor activities today.';

  @override
  String get weatherFunDefault =>
      'Make the most of the day, whatever the weather.';

  @override
  String get weatherForecastLoading => 'Loading weather forecast...';

  @override
  String get weatherForecastEmpty => 'No forecast data available.';

  @override
  String get weatherForecastRainShort => 'rain';

  @override
  String get monday => 'monday';

  @override
  String get tuesday => 'tuesday';

  @override
  String get wednesday => 'wednesday';

  @override
  String get thursday => 'thursday';

  @override
  String get friday => 'friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'sunday';

  @override
  String get save => 'Save changes';

  @override
  String get groupNameText => 'Group name';

  @override
  String get groupOwner => 'Group owner';

  @override
  String get enableRepetitiveEvents => 'Enable repetitive events';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get currentPasswordIncorrect =>
      'Current password is incorrect. Please try again.';

  @override
  String get newPasswordConfirmationError =>
      'New password and confirmation password do not match.';

  @override
  String get changedPasswordError =>
      'Failed to change password. Please try again';

  @override
  String get passwordContainsUnwantedChar =>
      'Password contains unwanted characters.';

  @override
  String get changeUsername => 'Change your username';

  @override
  String get successChangingUsername => 'Username updated successfully!';

  @override
  String get usernameAlreadyTaken =>
      'Username is already taken. Choose a different one.';

  @override
  String get errorUnwantedCharactersUsername =>
      'Invalid characters in the username. Please use only alphanumeric characters and underscores.';

  @override
  String get errorChangingUsername =>
      'Error changing username. Please try again later.';

  @override
  String get errorChangingPassword =>
      'Failed to change password. Please try again.';

  @override
  String get errorUsernameLength =>
      'Error Username should be between 6 char and 10 char ';

  @override
  String formatDate(Object date) {
    return '$date';
  }

  @override
  String get forgotPassword => 'Recover here your password.';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get userNameRequired => 'User name is required';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordLength => 'Password maximum length is 6 characters';

  @override
  String get groupNotCreated =>
      'There was an error creating the group, try again';

  @override
  String get questionDeleteGroup =>
      'Are you sure you want to delete this group?';

  @override
  String get errorEventCreation =>
      'Error occurred while creating the event, try again later';

  @override
  String get eventEditFailed =>
      'Error occurred while editing the event, try again later';

  @override
  String get noEventsFoundForDate =>
      'Events not found for this date, try again later.';

  @override
  String get confirmDelete => 'Are you sure you want to remove this event ?';

  @override
  String get confirmDeleteDescription => 'Remove event.';

  @override
  String get groupNameLabel => 'Group Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get refresh => 'Refreshing screen ...';

  @override
  String get accepted => 'Accepted';

  @override
  String get pending => 'Pending';

  @override
  String get notAccepted => 'NotAccepted';

  @override
  String get newUsers => 'New';

  @override
  String get expired => 'Expired';

  @override
  String get userNotSignedIn => 'User is not signed in.';

  @override
  String get createdOn => 'Created On';

  @override
  String get userCount => 'User Count';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String timeHoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String timeDaysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get timeLast30Days => 'Last 30 days';

  @override
  String get groupRecent => 'Recent';

  @override
  String get groupLast7Days => 'Last 7 days';

  @override
  String get groupLast30Days => 'Last 30 days';

  @override
  String get groupOlder => 'Older';

  @override
  String get notificationGroupCreationTitle => 'Congratulations!';

  @override
  String notificationGroupCreationMessage(Object groupName) {
    return 'You created the group: $groupName';
  }

  @override
  String get notificationJoinedGroupTitle => 'Welcome to the Group';

  @override
  String notificationJoinedGroupMessage(Object groupName) {
    return 'You have joined the group: $groupName';
  }

  @override
  String get notificationInvitationTitle => 'Group Invitation';

  @override
  String notificationInvitationMessage(Object groupName) {
    return 'You have been invited to join the group: $groupName';
  }

  @override
  String get notificationInvitationDeniedTitle => 'Invitation Declined';

  @override
  String notificationInvitationDeniedMessage(
      Object groupName, Object userName) {
    return '$userName declined the invitation to join $groupName';
  }

  @override
  String get notificationUserAcceptedTitle => 'User Joined';

  @override
  String notificationUserAcceptedMessage(Object groupName, Object userName) {
    return '$userName has accepted the invitation to join $groupName';
  }

  @override
  String get notificationGroupEditedTitle => 'Group Updated';

  @override
  String notificationGroupEditedMessage(Object groupName) {
    return 'You updated the group: $groupName';
  }

  @override
  String get notificationGroupDeletedTitle => 'Group Deleted';

  @override
  String notificationGroupDeletedMessage(Object groupName) {
    return 'You have deleted the group: $groupName';
  }

  @override
  String get notificationUserRemovedTitle => 'User Removed';

  @override
  String notificationUserRemovedMessage(Object adminName, Object groupName) {
    return 'You have been removed from $groupName by $adminName';
  }

  @override
  String get notificationAdminUserRemovedTitle => 'User Removed';

  @override
  String notificationAdminUserRemovedMessage(
      Object groupName, Object userName) {
    return '$userName was removed from $groupName';
  }

  @override
  String get notificationUserLeftTitle => 'User Left';

  @override
  String notificationUserLeftMessage(Object groupName, Object userName) {
    return '$userName has left the group: $groupName';
  }

  @override
  String get notificationGroupUpdateTitle => 'Group Updated';

  @override
  String notificationGroupUpdateMessage(Object editorName, Object groupName) {
    return '$editorName updated the group: $groupName';
  }

  @override
  String get notificationGroupDeletedAllTitle => 'Group Deleted';

  @override
  String notificationGroupDeletedAllMessage(Object groupName) {
    return 'The group \"$groupName\" has been deleted by the owner.';
  }

  @override
  String get viewDetails => 'View Details';

  @override
  String get editEvent => 'Edit Event';

  @override
  String eventDayNotIncludedWarning(String day) {
    return 'Warning: The event starts on $day, but this day is not selected in the recurrence pattern.';
  }

  @override
  String get removeRecurrence => 'Remove Recurrence';

  @override
  String get removeRecurrenceConfirm =>
      'Are you sure you want to remove the recurrence rule?';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get reminderHelper => 'Choose when to be reminded';

  @override
  String get reminderOptionAtTime => 'At time of event';

  @override
  String get reminderOption5min => '5 minutes before';

  @override
  String get reminderOption10min => '10 minutes before';

  @override
  String get reminderOption30min => '30 minutes before';

  @override
  String get reminderOption1hour => '1 hour before';

  @override
  String get reminderOption2hours => '2 hours before';

  @override
  String get reminderOption1day => '1 day before';

  @override
  String get reminderOption2days => '2 days before';

  @override
  String get reminderOption3days => '3 days before';

  @override
  String get saveChangesMessage => 'Saving changes...';

  @override
  String get createEventMessage => 'Creating event...';

  @override
  String get dialogSelectUsersTitle => 'Select users for this event';

  @override
  String get dialogClose => 'Close';

  @override
  String get dialogShowUsers => 'Show User Selection';

  @override
  String get repeatEventLabel => 'Repeat Event:';

  @override
  String get repeatYes => 'Yes';

  @override
  String get repeatNo => 'No';

  @override
  String get notificationEventReminderTitle => 'Event Reminder';

  @override
  String notificationEventReminderMessage(Object eventTitle) {
    return 'Reminder: \"$eventTitle\" is coming up soon.';
  }

  @override
  String get userDropdownSelect => 'Select Users';

  @override
  String get noUsersSelected => 'No users selected.';

  @override
  String get noUserRolesAvailable => 'No user roles available';

  @override
  String get userExpandableCardTitle => 'Select Users';

  @override
  String get eventDetailsTitle => 'Event Details';

  @override
  String get eventTitleHint => 'Title';

  @override
  String get eventStartDateHint => 'Start Date';

  @override
  String get eventEndDateHint => 'End Date';

  @override
  String get eventLocationHint => 'Localization';

  @override
  String get eventDescriptionHint => 'Description';

  @override
  String get eventNoteHint => 'Note';

  @override
  String get eventRecurrenceHint => 'Recurrence Rule';

  @override
  String get notificationEventCreatedTitle => 'Event Created';

  @override
  String notificationEventCreatedMessage(String eventTitle) {
    return 'An event \"$eventTitle\" has been created.';
  }

  @override
  String get notificationEventUpdatedTitle => 'Event Updated';

  @override
  String notificationEventUpdatedMessage(String eventTitle) {
    return 'The event \"$eventTitle\" has been updated.';
  }

  @override
  String get notificationEventDeletedTitle => 'Event Deleted';

  @override
  String notificationEventDeletedMessage(String eventTitle) {
    return 'The event \"$eventTitle\" has been removed.';
  }

  @override
  String get notificationRecurrenceAddedTitle => 'Recurring Event';

  @override
  String notificationRecurrenceAddedMessage(String title) {
    return 'The event \"$title\" is now recurring.';
  }

  @override
  String get notificationEventMarkedDoneTitle => 'Event Completed';

  @override
  String notificationEventMarkedDoneMessage(
      String eventTitle, String userName) {
    return 'The event \"$eventTitle\" was marked as completed by $userName.';
  }

  @override
  String get notificationEventReopenedTitle => 'Event Reopened';

  @override
  String notificationEventReopenedMessage(String eventTitle, String userName) {
    return 'The event \"$eventTitle\" was reopened by $userName.';
  }

  @override
  String get notificationEventStartedTitle => 'Event Started';

  @override
  String notificationEventStartedMessage(String eventTitle) {
    return 'The event \"$eventTitle\" has just started.';
  }

  @override
  String notificationEventReminderBodyWithTime(
      String eventTitle, String eventTime) {
    return '“$eventTitle” starts at $eventTime';
  }

  @override
  String get notificationEventReminderManual => 'Manual Test Notification';

  @override
  String get categoryGroup => 'Group';

  @override
  String get categoryUser => 'User';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryOther => 'Other';

  @override
  String get passwordRecoveryTitle => 'Password Recovery';

  @override
  String get passwordRecoveryInstruction =>
      'Enter your account email or username to start password recovery:';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordRecoveryEmptyField =>
      'Please enter your email or username.';

  @override
  String get passwordRecoverySuccess =>
      'A password reset request has been noted. Please contact support or check your account settings.';

  @override
  String get endDateMustBeAfterStartDate =>
      'End date must be after the start date';

  @override
  String get pleaseSelectAtLeastOneUser => 'Please select at least one user';

  @override
  String get groupMembers => 'Group Members';

  @override
  String get noInvitedUsersToDisplay => 'No invited users to display.';

  @override
  String userRemovedSuccessfully(String userName) {
    return 'User $userName removed successfully.';
  }

  @override
  String failedToRemoveUser(String userName) {
    return 'Failed to remove user $userName.';
  }

  @override
  String get groupDescriptionLabel => 'Group Description';

  @override
  String get agenda => 'Agenda';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get noItems => 'Nothing upcoming';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get displayName => 'Display name';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get saving => 'Saving...';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get failedToSavePhoto => 'Failed to save photo';

  @override
  String get failedToUploadImage => 'Failed to upload image';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get failedToSaveProfile => 'Failed to save profile';

  @override
  String get notAuthenticatedOrUserMissing =>
      'Not authenticated or user missing';

  @override
  String get noUserLoaded => 'No user loaded';

  @override
  String get motivationSectionTitle => 'Motivation';

  @override
  String get groupSectionTitle => 'Groups';

  @override
  String get clearAllTooltip => 'Clear all notifications';

  @override
  String get clearAll => 'Clear all';

  @override
  String get clearAllConfirmTitle => 'Clear all?';

  @override
  String get clearAllConfirmMessage =>
      'Remove all notifications? This action can\'t be undone.';

  @override
  String get clearedAllSuccess => 'All notifications cleared';

  @override
  String get all => 'All';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get termsAndPrivacy =>
      'By signing up, you agree to our Terms & Privacy Policy';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeSubtitle =>
      'Create an account to get started with our app.';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordMedium => 'Medium';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get terms => 'Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndPrivacyPrefix => 'By signing up, you agree to our ';

  @override
  String get andSeparator => ' and ';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don’t have an account?';

  @override
  String get loginWelcomeTitle => 'Welcome back!';

  @override
  String get loginWelcomeSubtitle =>
      'Please enter your credentials to continue.';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we’ll send you a reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Password reset link sent!';

  @override
  String get forgotPasswordNeutralSuccess =>
      'If an account exists, we sent a password reset link.';

  @override
  String get forgotPasswordNetworkError =>
      'Could not send reset link. Check your connection and try again.';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters.';

  @override
  String get confirmPasswordRequired => 'Please confirm your new password.';

  @override
  String get resetPasswordSubmit => 'Reset password';

  @override
  String get resetPasswordInvalidLinkTitle => 'Invalid reset link';

  @override
  String get resetPasswordInvalidLinkBody =>
      'This reset link is invalid or missing a token. Request a new password reset link.';

  @override
  String get resetPasswordRequestNewLink => 'Request new reset link';

  @override
  String get resetPasswordInvalidToken =>
      'This reset token is invalid or has expired.';

  @override
  String get resetPasswordGenericError =>
      'Failed to reset password. Please try again.';

  @override
  String get resetPasswordSuccessTitle => 'Password reset successfully';

  @override
  String get resetPasswordSuccessBody =>
      'Your password has been updated. You can now sign in with your new password.';

  @override
  String get noUpcomingHint => 'Try another category or extend the range.';

  @override
  String get agendaSelectGroupPrompt => 'Select a group to load events';

  @override
  String get agendaChooseGroupButton => 'Choose';

  @override
  String get hi => 'Hi';

  @override
  String get completed => 'Completed';

  @override
  String get showFourteenDays => '14 days';

  @override
  String get showThirtyDays => '30 days';

  @override
  String get meetings => 'Meetings';

  @override
  String get tasks => 'Tasks';

  @override
  String get deadlines => 'Deadlines';

  @override
  String get personal => 'Personal';

  @override
  String get statusDone => 'Done';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusFinished => 'Finished';

  @override
  String completedSummary(Object done, Object total, Object percent) {
    return '$done of $total completed ($percent%)';
  }

  @override
  String get notifyMe => 'Notify me';

  @override
  String get notifyMeOnSubtitle => 'You\'ll receive a reminder for this event';

  @override
  String get notifyMeOffSubtitle => 'No reminder will be sent';

  @override
  String get noInvitableUsers => 'No users available to invite';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get noClientsYet => 'No clients yet';

  @override
  String get addYourFirstClient => 'Add your first client to this group.';

  @override
  String get addClient => 'Add Client';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get noServicesYet => 'No services yet';

  @override
  String get createServicesSubtitle =>
      'Create services you can assign to bookings.';

  @override
  String get addService => 'Add Service';

  @override
  String get noDefaultDuration => 'No default duration';

  @override
  String get minutesAbbrev => 'min';

  @override
  String get editClient => 'Edit Client';

  @override
  String get createClient => 'Create Client';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saveClient => 'Save Client';

  @override
  String failedWithReason(String reason) {
    return 'Failed: $reason';
  }

  @override
  String get editService => 'Edit Service';

  @override
  String get createService => 'Create Service';

  @override
  String get serviceNameExample => 'e.g. Garden maintenance';

  @override
  String get defaultMinutesLabel => 'Default minutes';

  @override
  String get defaultMinutesHint => 'e.g., 45';

  @override
  String get colorLabel => 'Color';

  @override
  String get saveService => 'Save Service';

  @override
  String get screenServicesClientsTitle => 'Services & Clients';

  @override
  String get tabClients => 'Clients';

  @override
  String get tabServices => 'Services';

  @override
  String get clientsSectionTitle => 'Clients in this group';

  @override
  String get servicesSectionTitle => 'Services in this group';

  @override
  String get activeClientsSection => 'Active clients';

  @override
  String get inactiveClientsSection => 'Inactive clients';

  @override
  String get activeServicesSection => 'Active services';

  @override
  String get inactiveServicesSection => 'Inactive services';

  @override
  String clientCreatedWithName(String name) {
    return 'Client created: $name';
  }

  @override
  String serviceCreatedWithName(String name) {
    return 'Service created: $name';
  }

  @override
  String clientUpdatedWithName(String name) {
    return 'Client updated: $name';
  }

  @override
  String serviceUpdatedWithName(String name) {
    return 'Service updated: $name';
  }

  @override
  String nClients(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# clients',
      one: '# client',
    );
    return '$_temp0';
  }

  @override
  String nServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# services',
      one: '# service',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get sectionOverview => 'Overview';

  @override
  String get sectionUpcoming => 'Upcoming';

  @override
  String get sectionEvents => 'Events';

  @override
  String get pendingEventsSectionTitle => 'Pending events';

  @override
  String get pendingEventsSectionSubtitle =>
      'Mark visits as completed when you\'re done.';

  @override
  String get pendingEventsEmpty => 'You\'re all caught up.';

  @override
  String get pendingEventsError => 'We couldn\'t load pending events.';

  @override
  String get pendingEventsMarkDone => 'Mark done';

  @override
  String get completedEventsSectionTitle => 'Completed events';

  @override
  String get completedEventsSectionSubtitle =>
      'Recently completed visits and tasks.';

  @override
  String get completedEventsEmpty => 'No events have been completed yet.';

  @override
  String get roleCardTapHint => 'Tap to view all role capabilities.';

  @override
  String get createdByLabel => 'Created by';

  @override
  String get sectionManage => 'Manage';

  @override
  String get sectionStatus => 'Status';

  @override
  String createdOnDay(String date) {
    return 'Created on $date';
  }

  @override
  String get membersTitle => 'Members';

  @override
  String membersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# total',
      one: '# total',
    );
    return '$_temp0';
  }

  @override
  String get servicesClientsTitle => 'Services & Clients';

  @override
  String get servicesClientsSubtitle => 'Create and manage services/clients';

  @override
  String get noCalendarWarning => 'This group has no calendar linked yet.';

  @override
  String get sectionFilters => 'Filters';

  @override
  String get noMembersTitle => 'No members';

  @override
  String get noMembersMatchFilters => 'No members match these filters.';

  @override
  String get tryAdjustingFilters => 'Try adjusting the filters above.';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusNotAccepted => 'Not accepted';

  @override
  String errorLoadingUser(String error) {
    return 'Error loading user: $error';
  }

  @override
  String get viewProfile => 'View profile';

  @override
  String get message => 'Message';

  @override
  String get changeRole => 'Change role';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get details => 'Details';

  @override
  String get edit => 'Edit';

  @override
  String get addToContacts => 'Add to contact';

  @override
  String get share => 'Share';

  @override
  String get copiedToClipboard => 'Copied!';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get team => 'Team';

  @override
  String get teams => 'Teams';

  @override
  String get calendars => 'Calendars';

  @override
  String teamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# teams',
      one: '# team',
    );
    return '$_temp0';
  }

  @override
  String calendarsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# calendars',
      one: '# calendar',
    );
    return '$_temp0';
  }

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# notifications',
      one: '# notification',
    );
    return '$_temp0';
  }

  @override
  String get clearAllConfirm =>
      'Are you sure you want to remove all notifications?';

  @override
  String get clearedAllNotifications => 'All notifications have been cleared.';

  @override
  String get groupNotificationsSectionTitle => 'Group notifications';

  @override
  String get updateRoleTitle => 'Update role';

  @override
  String get groupNotificationsSubtitle =>
      'See invites, reminders, and alerts scoped to this group.';

  @override
  String get groupNotificationsEmpty =>
      'This group doesn\'t have any notifications yet.';

  @override
  String get groupNotificationsError =>
      'We couldn\'t load the notifications for this group.';

  @override
  String groupNotificationsTitle(String groupName) {
    return '$groupName notifications';
  }

  @override
  String get error => 'Error';

  @override
  String get typeNameOrEmail => 'Type name or email address';

  @override
  String noMatchesForX(String query) {
    return 'No matches found for \"$query\"';
  }

  @override
  String get inviteByEmail => 'Invite by Email';

  @override
  String get noMatchesInvite =>
      'No matches found. Would you like to invite them by email?';

  @override
  String get addPeople => 'Add People';

  @override
  String get add => 'Add';

  @override
  String get jobTitle => 'Job title';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get client => 'Client';

  @override
  String get primaryService => 'Primary service';

  @override
  String get workVisit => 'Work visit';

  @override
  String get simpleEvent => 'Simple event';

  @override
  String get loadingUpcoming => 'Loading upcoming…';

  @override
  String get noUpcomingEvents => 'No upcoming events';

  @override
  String get nothingScheduledSoon => 'Nothing scheduled soon for this group.';

  @override
  String get nextUp => 'Next up';

  @override
  String get upcomingEventsSubtitle => 'Upcoming events for this group';

  @override
  String get seeAll => 'See all';

  @override
  String get untitledEvent => '(untitled)';

  @override
  String get userId => 'User ID';

  @override
  String teamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams',
      one: '1 team',
      zero: 'No teams',
    );
    return '$_temp0';
  }

  @override
  String calendarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calendars',
      one: '1 calendar',
      zero: 'No calendars',
    );
    return '$_temp0';
  }

  @override
  String get nothingScheduledSoonForThisGroup =>
      'Nothing scheduled soon for this group.';

  @override
  String get upcomingEventsForThisGroup => 'Upcoming events for this group';

  @override
  String get untitled => '(untitled)';

  @override
  String get allTypes => 'All';

  @override
  String get simpleEvents => 'Simple';

  @override
  String get workVisits => 'Work';

  @override
  String get byCategory => 'by category';

  @override
  String get sectionInsights => 'Insights';

  @override
  String get insightsTitle => 'Insights & Graphs';

  @override
  String get insightsSubtitle => 'Time spent by client or service';

  @override
  String get timeByClient => 'Time by Client';

  @override
  String get timeByService => 'Time by Service';

  @override
  String get noDataRange => 'No data in this range';

  @override
  String get dateRange7d => '7d';

  @override
  String get dateRange30d => '30d';

  @override
  String get dateRange3m => '3m';

  @override
  String get dateRange4m => '4m';

  @override
  String get dateRange6m => '6m';

  @override
  String get dateRange1y => '1y';

  @override
  String get dateRangeYTD => 'YTD';

  @override
  String get dateRangeCustom => 'Custom';

  @override
  String get filterDimensionClients => 'Clients';

  @override
  String get filterDimensionServices => 'Services';

  @override
  String get filterTypeAll => 'All';

  @override
  String get filterTypeSimple => 'Simple';

  @override
  String get filterTypeWork => 'Work';

  @override
  String get insightsHintUpcomingOnly =>
      'Showing upcoming data only. For past ranges, please enable server-side range fetch.';

  @override
  String get logoutConfirmTitle => 'Log out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get preferencesSectionTitle => 'Preferences';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get roleCoAdmin => 'Co-Administrator';

  @override
  String get leaveGroupQuestion => 'Are you sure you want to leave this group?';

  @override
  String get removeMembersFirst =>
      'Please remove all members before deleting the group.';

  @override
  String get refreshSuccess => 'Calendar refreshed';

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get shareButtonTooltip => 'Share';

  @override
  String get soonLabel => 'Coming soon';

  @override
  String get detailsSectionTitle => 'Details';

  @override
  String get workVisitSectionTitle => 'Work Visit';

  @override
  String get rawFieldsSectionTitle => 'Raw Fields';

  @override
  String get eventWhenLabel => 'When';

  @override
  String get clientLabel => 'Client';

  @override
  String get servicePrimaryLabel => 'Primary Service';

  @override
  String get workVisitBadge => 'Work Visit';

  @override
  String get editButtonLabel => 'Edit Event';

  @override
  String get editAction => 'Edit';

  @override
  String get duplicateAction => 'Duplicate';

  @override
  String get analyticsSectionTitle => 'Insights';

  @override
  String get graphsComingSoon => 'Charts coming soon';

  @override
  String get timeTrackingEnabled => 'Time tracking enabled';

  @override
  String get timeTrackingDisabled => 'Time tracking disabled';

  @override
  String get exportSuccess => 'Exported Excel successfully';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get exportToExcelTooltip => 'Export to Excel';

  @override
  String get exportToExcelCta => 'Export Excel';

  @override
  String trackHoursFor(Object groupName) {
    return 'Track hours for $groupName';
  }

  @override
  String get timeTrackingHeaderHint =>
      'Enable tracking and manage workers. Export a timesheet anytime.';

  @override
  String get enableTrackingCta => 'Enable';

  @override
  String get disableTrackingCta => 'Disable';

  @override
  String get employeesHeader => 'Employees';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get currencyAllOption => 'All';

  @override
  String get workerRequiredError => 'Worker required';

  @override
  String get workersLabel => 'Workers';

  @override
  String get selectWorkersPlaceholder => 'Select workers';

  @override
  String get pickWorkersCta => 'Pick workers';

  @override
  String get noWorkersAvailable => 'No workers available';

  @override
  String get currencyFilterLabel => 'Filter by currency';

  @override
  String get currencyFilterAll => 'Show all currencies';

  @override
  String get workerChipRemoveTooltip => 'Remove worker';

  @override
  String get workerPickerTitle => 'Choose workers';

  @override
  String get workerPickerSave => 'Save selection';

  @override
  String get selectAll => 'Select all';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get currencyWorkersSectionTitle => 'Workers & currency';

  @override
  String get currencyWorkersSectionDescription =>
      'Filter by currency and pick which workers to include.';

  @override
  String get currencyHelperText =>
      'Use a currency to quickly narrow the worker list.';

  @override
  String get workersHelperText => 'Tap to add or remove workers.';

  @override
  String get workersValidationHint => 'Pick at least one worker before saving.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesOptionalHint => 'Add context or leave empty';

  @override
  String get savingLabel => 'Saving…';

  @override
  String get invalidTimeRange => 'End time must be after start time.';

  @override
  String get toggleEmptyDays => 'Show/hide empty days';

  @override
  String didNotWorkDay(Object name) {
    return '$name did not work this day';
  }

  @override
  String daysMissedAll(int count) {
    return '$count days without hours';
  }

  @override
  String daysMissedNoSunday(int count) {
    return '$count days without hours (Mon-Sat)';
  }

  @override
  String avgHoursPerDayWorked(String hours) {
    return 'Avg $hours h/day worked';
  }

  @override
  String didNotWorkSunday(String name) {
    return '$name logged no hours (Sunday)';
  }

  @override
  String daysWorked(int count) {
    return '$count days worked';
  }

  @override
  String sundaysWorked(int count) {
    return '$count Sundays worked';
  }

  @override
  String avgHoursPerDayWorkedWithCount(String hours, int count) {
    return 'Avg $hours h/day across $count days';
  }

  @override
  String get unknownWorker => 'Unnamed worker';

  @override
  String get noTrackedYet => 'No tracked time yet';

  @override
  String trackedTotal(Object tracked) {
    return 'Tracked: $tracked';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noWorkersYetTitle => 'No workers yet';

  @override
  String get noWorkersYetSubtitle =>
      'Enable tracking to start counting hours and add workers.';

  @override
  String get timeTrackingTitle => 'Time tracking';

  @override
  String get sectionWorkersHours => 'Workers\' hours';

  @override
  String get sectionBusinessHours => 'Business hours';

  @override
  String get businessHoursAdminSubtitle =>
      'Define the window when members can schedule events.';

  @override
  String get businessHoursMemberSubtitle =>
      'Events must be created during this time window.';

  @override
  String get businessHoursUnset => 'Not configured yet';

  @override
  String businessHoursRange(String start, String end, String timezone) {
    return '$start – $end · $timezone';
  }

  @override
  String get businessHoursEdit => 'Edit';

  @override
  String get businessHoursSave => 'Save hours';

  @override
  String get businessHoursReset => 'Clear hours';

  @override
  String get businessHoursTimezoneLabel => 'Timezone';

  @override
  String get businessHoursTimezoneHint => 'Example: Europe/Madrid';

  @override
  String get businessHoursPartialError =>
      'Set both start and end to save this window.';

  @override
  String get businessHoursStartLabel => 'Start time';

  @override
  String get businessHoursEndLabel => 'End time';

  @override
  String get businessHoursUpdateSuccess => 'Business hours updated';

  @override
  String get businessHoursUpdateError => 'Couldn\'t update business hours';

  @override
  String get selectMonthPrompt => 'Please select a month to view entries.';

  @override
  String businessHoursValidationMessage(
      String start, String end, String timezone) {
    return 'Events must take place between $start and $end ($timezone).';
  }

  @override
  String get timeTrackingDisabledTitle => 'Time tracking is off';

  @override
  String get timeTrackingDisabledSubtitle =>
      'Enable it to start tracking hours for your team.';

  @override
  String get createWorkerTitle => 'Create Worker';

  @override
  String get linkExistingUserLabel => 'Link to existing user';

  @override
  String get linkExistingUserHint =>
      'If the worker already has an account, link it here.';

  @override
  String get userIdLabel => 'User ID';

  @override
  String get userIdHint => 'Paste the existing user’s ID';

  @override
  String get userIdRequired => 'User ID is required when linking an account.';

  @override
  String get displayNameLabel => 'Name';

  @override
  String get displayNameHint => 'Enter worker’s name';

  @override
  String get displayNameRequired => 'Name is required for external workers.';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleHint => 'e.g., Barista';

  @override
  String get hourlyRateLabel => 'Hourly Rate';

  @override
  String get hourlyRateHint => 'e.g., 15.00';

  @override
  String get saveWorkerCta => 'Save Worker';

  @override
  String get workerCreated => 'Worker created successfully!';

  @override
  String get createWorkerCta => 'Add Worker';

  @override
  String get createTimeEntryTitle => 'Add Time Entry';

  @override
  String get workerLabel => 'Worker';

  @override
  String get workerRequired => 'Please select a worker.';

  @override
  String get startLabel => 'Start time';

  @override
  String get endLabel => 'End time';

  @override
  String get notesHint => 'Optional notes about this shift';

  @override
  String get saveTimeEntryCta => 'Save Entry';

  @override
  String get timeEntryCreated => 'Time entry added successfully!';

  @override
  String get addTimeEntryCta => 'Add Time Entry';

  @override
  String get timeTrackingActionsCta => 'Actions';

  @override
  String get noTimeEntriesYetTitle => 'No time entries yet';

  @override
  String get noTimeEntriesYetSubtitle =>
      'Add your first recorded hours for this worker.';

  @override
  String get inProgress => 'In Progress';

  @override
  String get totalEntries => 'Entries';

  @override
  String get totalHours => 'Hours';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get editWorker => 'Edit worker';

  @override
  String get linkedUser => 'Linked user';

  @override
  String get externalWorker => 'External worker';

  @override
  String get viewWorker => 'View worker';

  @override
  String get workerUpdated => 'Worker updated';

  @override
  String get workerNameLabel => 'Name';

  @override
  String get statusLabel => 'Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get invalidRate => 'Enter a valid hourly rate';

  @override
  String get editTimeEntry => 'Edit time entry';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get breakMinutesLabel => 'Break (minutes)';

  @override
  String get timeEntryUpdated => 'Time entry updated successfully';

  @override
  String get pickStartTime => 'Pick start time';

  @override
  String get pickEndTime => 'Pick end time';

  @override
  String get noTimeEntries => 'No time entries yet.';

  @override
  String totalHoursFormat(Object hours, Object minutes) {
    return 'Total: ${hours}h ${minutes}m';
  }

  @override
  String totalHoursAndPayFormat(Object hours, Object pay) {
    return 'Total: ${hours}h – $pay';
  }

  @override
  String get pickMonth => 'Select month';

  @override
  String get selectMonthFirst => 'Select month';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get areYouSureDelete =>
      'Are you sure you want to delete this time entry?';

  @override
  String get entries => 'entries';

  @override
  String get exportExcel => 'Export';

  @override
  String get exportReady => 'Export ready — choose where to share/save';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get info => 'Info';

  @override
  String get overviewInfoTitle => 'Monthly overview';

  @override
  String get overviewInfoBody =>
      'Each tile shows the month, total hours and pay for this worker. Tap a month to open detailed time entries. Use the arrows to switch years. Pull down to refresh.';

  @override
  String get hours => 'Hours';

  @override
  String get pay => 'Pay';

  @override
  String get tipTapMonthToOpen => 'Tap a month to open details';

  @override
  String get tipPullToRefresh => 'Pull down to refresh';

  @override
  String get addWorker => 'Add worker';

  @override
  String get addWorkerSubtitle =>
      'Create a worker profile to start tracking hours and pay.';

  @override
  String get membersInfoAccepted => 'Users who are part of this group.';

  @override
  String get membersInfoPending => 'Invitations sent and awaiting acceptance.';

  @override
  String get membersInfoNotAccepted =>
      'Invites that were declined, revoked, or expired.';

  @override
  String get contact => 'Contact';

  @override
  String get e_gJohnDoe => 'e.g., John Doe';

  @override
  String get e_gPhone => 'e.g., +1 555-1234';

  @override
  String get e_gEmail => 'e.g., john.doe@example.com';

  @override
  String get clientWillBeActive => 'Client will be active';

  @override
  String get clientWillBeInactive => 'Client will be inactive';

  @override
  String get noContactInfo => 'No contact info';

  @override
  String get activeStatus => 'Active';

  @override
  String get inactiveStatus => 'Inactive';

  @override
  String get serviceWillBeActive => 'Service will be active';

  @override
  String get serviceWillBeInactive => 'Service will be inactive';

  @override
  String get chooseType => 'Choose type';

  @override
  String get simpleEventHint =>
      'Create a quick event without client/service selection.';

  @override
  String get workVisitHint =>
      'Track a work visit by choosing a client and one or more services.';

  @override
  String get color => 'Color';

  @override
  String get date => 'Date';

  @override
  String get assignedUsers => 'Assigned users';

  @override
  String get repetition => 'Repetition';

  @override
  String get category => 'Category';

  @override
  String get workVisitHintShort =>
      'Choose a client and services for this work visit.';

  @override
  String get simpleEventHintShort => 'Simple event with no client or service.';

  @override
  String get newCategory => 'New category';

  @override
  String get newSubcategory => 'New subcategory';

  @override
  String failedToCreate(String error) {
    return 'Failed to create: $error';
  }

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get addCategory => 'Add category';

  @override
  String get addSubcategory => 'Add subcategory';

  @override
  String get subcategory => 'Subcategory';

  @override
  String get newEvent => 'New Event';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get noGroupAvailable => 'No group available';

  @override
  String get tabDay => 'Day';

  @override
  String get tabWeek => 'Week';

  @override
  String get tabMonth => 'Month';

  @override
  String get tabAgenda => 'Agenda';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get titleHint => 'Input title';

  @override
  String get descriptionHint => 'Input description';

  @override
  String get noteHint => 'Input note';

  @override
  String get services => 'Additional Services';

  @override
  String get noWorkVisitData => 'No work-visit data available.';

  @override
  String get roleAdministrator => 'Administrator';

  @override
  String get roleCoAdministrator => 'Co-Administrator';

  @override
  String get roleGuest => 'Guest';

  @override
  String get viewMembers => 'View members';

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String monthYearFormat(Object month, Object year) {
    return '$month $year';
  }

  @override
  String get groupDescriptionHint => 'Introduce the purpose of this group';

  @override
  String get groupNameTooShort => 'Group name too short';

  @override
  String get groupNameHint => 'Input group name';

  @override
  String get reviewUsersTitle => 'Members — Review & Roles';

  @override
  String get tabUpdateRoles => 'Update roles';

  @override
  String get tabAddUsers => 'Add users';

  @override
  String get done => 'Done';

  @override
  String get selectedLabel => 'Selected';

  @override
  String loadMore(Object count) {
    return 'Load more ($count)';
  }

  @override
  String addUsersCount(Object count) {
    return 'Add users ($count)';
  }

  @override
  String get ok => 'OK';

  @override
  String get searchMinChars => 'Type at least 3 characters';

  @override
  String get errorSearchingUser => 'Error searching user';

  @override
  String get errorAddingUser => 'Error adding user';

  @override
  String get userAlreadyAdded => 'User is already a member';

  @override
  String get userAlreadyPending => 'User already in selection';

  @override
  String selectedCommitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users added',
      one: '1 user added',
      zero: 'No users added',
    );
    return '$_temp0';
  }

  @override
  String get online => 'online';

  @override
  String get addUsersHelperText =>
      'Search and stage members to be added. You can set roles per user before uploading changes.';

  @override
  String get updateRolesHelperText =>
      'Review members and adjust roles. Tap a card to change the role.';

  @override
  String get membersHelperText =>
      'Browse members by status, review invites, and manage roles.';

  @override
  String get createGroup => 'Create group';

  @override
  String get editImage => 'Edit';

  @override
  String get tapToChangePhoto => 'Tap to change group photo';

  @override
  String get tapToAddPhoto => 'Tap to add group photo';

  @override
  String get groupSaved => 'Group saved';

  @override
  String get manageGroup => 'Manage group';

  @override
  String get hey => 'Hey';

  @override
  String get youAreThe => 'you are the';

  @override
  String get ofThisGroup => 'of this group';

  @override
  String get youHaveSuperPowersHere => 'You have super powers for this group!';

  @override
  String get roleOwnerBullet1 => 'Change group settings and features';

  @override
  String get roleOwnerBullet2 => 'Manage billing and subscription';

  @override
  String get roleOwnerBullet3 => 'Add or remove co-admins and members';

  @override
  String get roleOwnerBullet4 => 'View and edit all calendars and events';

  @override
  String get roleOwnerBullet5 => 'Delete or transfer the group';

  @override
  String get roleCoAdminBullet1 =>
      'Create, edit, and delete events for the group';

  @override
  String get roleCoAdminBullet2 => 'Manage services and clients';

  @override
  String get roleCoAdminBullet3 =>
      'Invite or remove members (except the owner)';

  @override
  String get roleCoAdminBullet4 => 'Configure notifications and work hours';

  @override
  String get roleMemberBullet1 => 'See your assigned events';

  @override
  String get roleMemberBullet2 => 'Mark visits or tasks as done';

  @override
  String get roleMemberBullet3 => 'Add notes and comments';

  @override
  String get groupSettingsTitle => 'Group settings';

  @override
  String get groupSettingsOwnerBannerOwner =>
      'You are the owner of this group. You can manage every setting from here.';

  @override
  String get groupSettingsOwnerBannerNotOwner =>
      'Only the group owner can update these settings.';

  @override
  String get groupSettingsOverviewTitle => 'Overview';

  @override
  String get groupSettingsOverviewSubtitle =>
      'General information about this group.';

  @override
  String get groupSettingsDescriptionLabel => 'Description';

  @override
  String get groupSettingsNoDescription => 'No description provided';

  @override
  String get groupSettingsOwnerIdLabel => 'Owner ID';

  @override
  String get groupSettingsCreatedOnLabel => 'Created on';

  @override
  String get groupSettingsMemberCountLabel => 'Member count';

  @override
  String get groupSettingsUserRolesTitle => 'User roles';

  @override
  String get groupSettingsUserRolesSubtitle =>
      'Permissions for users in this group.';

  @override
  String get groupSettingsNoRoles => 'No specific roles assigned yet.';

  @override
  String get groupSettingsUserIdLabel => 'User ID:';

  @override
  String get groupSettingsRoleLabel => 'Role:';

  @override
  String get groupSettingsInvitationsTitle => 'Invitations';

  @override
  String get groupSettingsInvitationsSubtitle =>
      'Invite new members or manage pending invitations.';

  @override
  String get groupSettingsInvitationsInfo =>
      'Invitations are managed separately.';

  @override
  String get groupSettingsViewInvitations => 'View invitations';

  @override
  String get groupSettingsDangerZoneTitle => 'Danger zone';

  @override
  String get groupSettingsDangerZoneOwner =>
      'Deleting this group is permanent and cannot be undone.';

  @override
  String get groupSettingsDangerZoneNonOwner =>
      'Only the group owner can delete this group.';

  @override
  String get groupInfo => 'Group info';

  @override
  String get groupInfoSubtitle => 'Name, description and basic details';

  @override
  String get notificationsSubtitle => 'Alerts, reminders and preferences';

  @override
  String get billingDetails => 'Billing details';

  @override
  String get billingDetailsSubtitle =>
      'Captured for invoices (legal name, tax ID, address, contact).';

  @override
  String get billingLegalName => 'Legal name';

  @override
  String get billingTaxId => 'Tax ID';

  @override
  String get billingTaxIdHelper => 'Used on invoices and PDFs.';

  @override
  String get addressStreet => 'Street';

  @override
  String get addressExtra => 'Address extra';

  @override
  String get addressCity => 'City';

  @override
  String get addressProvince => 'Province/State';

  @override
  String get addressPostalCode => 'Postal code';

  @override
  String get addressCountry => 'Country';

  @override
  String get billingEmailLabel => 'Billing email';

  @override
  String get billingPhoneLabel => 'Billing phone';

  @override
  String get billingComplete => 'Billing ready';

  @override
  String get billingMissing => 'Billing incomplete';

  @override
  String billingProgressLabel(Object completed, Object total) {
    return '$completed/$total completed';
  }

  @override
  String get billingProfileTitle => 'Billing profile';

  @override
  String get billingProfileEmpty =>
      'Add your issuer details (legal name, tax ID, address, VAT, IBAN) to issue invoices.';

  @override
  String get billingWebsite => 'Website';

  @override
  String get billingIban => 'IBAN';

  @override
  String get billingIbanHelper => 'Shown on invoices for bank transfer.';

  @override
  String get billingTaxRate => 'VAT rate';

  @override
  String get billingTaxRateHelper => 'Default VAT (0–100).';

  @override
  String get billingCurrency => 'Currency';

  @override
  String get billingCurrencyHelper => 'Default currency (e.g. EUR).';

  @override
  String get billingLanguage => 'Language';

  @override
  String get billingLanguageHelper => 'Invoice language code (e.g. es, en).';

  @override
  String get billingAddress => 'Address';

  @override
  String get billingProfileSaved => 'Billing profile saved';

  @override
  String get billingLogoUploadTitle => 'Upload Company Logo';

  @override
  String get billingLogoUploadBody =>
      'Select a PNG or JPG logo (max 15MB). This logo will appear in invoices and email footers.';

  @override
  String get billingLogoUploadSelectFile => 'Select file';

  @override
  String get billingLogoUploadCta => 'Upload';

  @override
  String get billingLogoUploadSuccess => 'Logo uploaded successfully.';

  @override
  String get billingLogoUploadError =>
      'The logo must be PNG or JPG and must not exceed 15 MB.';

  @override
  String get createInvoiceCta => 'Create invoice';

  @override
  String get invoiceCreated => 'Invoice created';

  @override
  String get noInvoicesYet => 'No invoices yet';

  @override
  String get noInvoicesYetSubtitle =>
      'Create your first invoice to keep billing organized.';

  @override
  String get invoicesListTitle => 'Invoices';

  @override
  String get invoicesNavLabel => 'Invoices';

  @override
  String get invoicesNavSubtitle => 'Create and track invoices';

  @override
  String invoicesTitle(String groupName) {
    return 'Invoices · $groupName';
  }

  @override
  String get openInvoicesWorkspace => 'Open invoices workspace';

  @override
  String get invoiceNumberLabel => 'Invoice number (NNN-YY)';

  @override
  String invoiceNumberHelper(String year) {
    return 'Year suffix locked to $year. Enter the 3 digits.';
  }

  @override
  String get invoiceNumberInvalid =>
      'Use three digits (e.g., 001). Year is fixed to the current YY.';

  @override
  String get bulkDownloadInvoiceNumberRequired =>
      'Enter at least one invoice number.';

  @override
  String get bulkDownloadInvoiceNumberInvalidFormat =>
      'Use letters, numbers, hyphen, slash, underscore, or dot only.';

  @override
  String get bulkDownloadInvoiceNumberRangeInvalid =>
      'The starting invoice number must be lower than or equal to the ending number.';

  @override
  String get invoiceClientLabel => 'Client';

  @override
  String get invoiceClientRequired => 'Client is required';

  @override
  String get invoicePdfUrl => 'Invoice PDF URL';

  @override
  String get invoiceRegisteredAt => 'Registered at';

  @override
  String get invoiceRegisteredUnknown => 'Not set';

  @override
  String get invoiceParties => 'Parties';

  @override
  String get invoiceClientSection => 'Client billing';

  @override
  String get invoiceLinesTitle => 'Invoice lines';

  @override
  String get invoiceBlocksTitle => 'Invoice blocks';

  @override
  String get invoiceBlocksModeBlocks => 'Blocks';

  @override
  String get invoiceBlocksModeLines => 'Lines';

  @override
  String get invoiceLinesModeManual => 'Manual';

  @override
  String get invoiceLinesModePhoto => 'Photo';

  @override
  String get invoiceLinesModeJson => 'JSON';

  @override
  String get invoiceLinesPhotoTitle => 'Extract lines from invoice photo';

  @override
  String get invoiceLinesPhotoSubtitle =>
      'Upload an invoice screenshot/image, then apply detected lines to the editor.';

  @override
  String get invoiceLinesPhotoApply => 'Apply to lines';

  @override
  String get invoiceLinesPhotoClear => 'Clear';

  @override
  String get invoiceLinesPhotoExtracting => 'Extracting...';

  @override
  String invoiceLinesPhotoExtractedCount(Object count) {
    return '$count extracted line(s)';
  }

  @override
  String get invoiceLineEvidenceAttach => 'Attach evidence';

  @override
  String get invoiceLineEvidenceOpen => 'Open evidence';

  @override
  String get invoiceLineEvidenceDelete => 'Delete evidence';

  @override
  String get invoiceLineEvidenceNoId =>
      'Save the draft first to attach evidence.';

  @override
  String get invoiceLineEvidenceAttached => 'Evidence attached successfully.';

  @override
  String get invoiceLineEvidenceRemoved => 'Evidence removed.';

  @override
  String get invoiceLineEvidenceAttachFailed => 'Could not attach evidence.';

  @override
  String get invoiceLineEvidenceOpenFailed => 'Could not open evidence.';

  @override
  String get invoiceLineEvidenceDeleteFailed => 'Could not remove evidence.';

  @override
  String get invoiceLinesJsonImportTitle => 'Import lines from JSON';

  @override
  String get invoiceLinesJsonImportSubtitle =>
      'Paste structured draftLines JSON or upload a .json file to create lines immediately.';

  @override
  String get invoiceLinesJsonImportModePaste => 'Paste JSON';

  @override
  String get invoiceLinesJsonImportModeFile => 'Upload file';

  @override
  String get invoiceLinesJsonImportInputHint =>
      'Paste JSON payload with draftLines...';

  @override
  String get invoiceLinesJsonImportPickFile => 'Choose JSON file';

  @override
  String get invoiceLinesJsonImportNoFile => 'No JSON file selected.';

  @override
  String get invoiceLinesJsonImportOverwrite => 'Overwrite existing lines';

  @override
  String get invoiceLinesJsonImportDefaultTaxRate => 'Default tax rate';

  @override
  String get invoiceLinesJsonImportApply => 'Import lines';

  @override
  String get invoiceLinesJsonImportGetPrompt => 'Get LLM prompt';

  @override
  String get invoiceLinesJsonImportPromptCopied =>
      'Prompt copied to clipboard.';

  @override
  String get invoiceLinesJsonImportInvalidPayload =>
      'Invalid JSON. Provide a non-empty draftLines array.';

  @override
  String get invoiceLinesJsonImportGenericError =>
      'Could not import JSON lines.';

  @override
  String invoiceLinesJsonImportSuccess(Object count) {
    return 'Imported $count line(s).';
  }

  @override
  String get jsonAutoRepairAppliedSnack => 'JSON auto-corrected before import.';

  @override
  String get invoiceAddBlock => 'Add block';

  @override
  String get invoiceBlocksInfoTooltip =>
      'Blocks let you mix items with headers, notes, and checklists. Only billable items affect totals.';

  @override
  String get invoiceBlocksEmptyMessage =>
      'Start your invoice with blocks (Date, Section, Items...).';

  @override
  String get invoiceBlocksQuickItem => 'Item';

  @override
  String get invoiceBlocksQuickDate => 'Date';

  @override
  String get invoiceHeaderCompactCta => 'Compact header';

  @override
  String get invoiceHeaderExpandCta => 'Expand header';

  @override
  String get invoiceBlockAdvancedShowCta => 'Advanced';

  @override
  String get invoiceBlockAdvancedHideCta => 'Hide advanced';

  @override
  String get invoiceAddBlockMore => 'More...';

  @override
  String get invoiceAddBlockRecommended => 'Recommended';

  @override
  String get invoiceAddBlockFooterInsert =>
      'Will be added below the current block';

  @override
  String get invoiceAddBlockFooterOutsideWrapper =>
      'Will be added outside the grouped block';

  @override
  String get invoiceWrapperAddInsideLabel => 'Add inside';

  @override
  String get invoiceBlockDateAutoFormatCta => 'Use auto format';

  @override
  String get invoiceBlockTypeLabel => 'Block type';

  @override
  String get invoiceBlockTypeItem => 'Item';

  @override
  String get invoiceBlockTypeDate => 'Date';

  @override
  String get invoiceBlockTypeSection => 'Section';

  @override
  String get invoiceBlockTypeSubsection => 'Subsection';

  @override
  String get invoiceBlockTypeDivider => 'Divider';

  @override
  String get invoiceBlockTypeNote => 'Note';

  @override
  String get invoiceBlockTypeChecklist => 'Checklist';

  @override
  String get invoiceBlockSkuLabel => 'SKU';

  @override
  String get invoiceBlockUnitLabel => 'Unit';

  @override
  String get invoiceBlockLevelLabel => 'Level';

  @override
  String get invoiceBlockBillableLabel => 'Billable item';

  @override
  String get invoiceBlockTitleLabelDate => 'Date title';

  @override
  String get invoiceBlockTitleLabelSection => 'Section title';

  @override
  String get invoiceBlockTitleLabelSubsection => 'Subsection title';

  @override
  String get invoiceBlockNoteLabel => 'Note';

  @override
  String get invoiceBlockChecklistItemLabel => 'Checklist item';

  @override
  String get invoiceBlockAddChecklistItem => 'Add checklist item';

  @override
  String get invoiceBlockMoveUp => 'Move up';

  @override
  String get invoiceBlockMoveDown => 'Move down';

  @override
  String get invoiceValidationNonNegative => 'Must be 0 or higher';

  @override
  String get invoiceValidationTaxRate => 'Tax rate must be 0-100';

  @override
  String get invoiceLinesPlaceholderTitle => 'Invoice lines coming soon';

  @override
  String get invoiceLinesPlaceholderSubtitle =>
      'Lines will list items with qty, unit price, tax and totals.';

  @override
  String get unknownClient => 'Unknown client';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get select => 'Select';

  @override
  String get change => 'Change';

  @override
  String get stepLabel => 'Step';

  @override
  String get ofLabel => 'of';

  @override
  String get fieldIsRequired => 'This field is required';

  @override
  String get taxRateShort => 'VAT';

  @override
  String get invoiceStatusLabel => 'Status';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusIssued => 'Issued';

  @override
  String get statusPaid => 'Paid';

  @override
  String get invoiceNotesLabel => 'Notes';

  @override
  String get invoiceAddLine => 'Add line';

  @override
  String get invoiceLinesRequired => 'Add at least one line';

  @override
  String get lineDescription => 'Description';

  @override
  String get lineQuantity => 'Quantity';

  @override
  String get lineUnitPrice => 'Unit price';

  @override
  String get lineTaxRate => 'Tax rate';

  @override
  String get invoiceTotalLabel => 'Total';

  @override
  String get invoiceTotalsTitle => 'Totals';

  @override
  String get invoiceEditorTitle => 'Invoice editor';

  @override
  String get invoiceCustomerTitle => 'Customer';

  @override
  String get invoiceDatesTitle => 'Dates';

  @override
  String get invoiceDateLabel => 'Invoice date';

  @override
  String get invoiceDueDateLabel => 'Due date';

  @override
  String get invoiceFromLabel => 'From';

  @override
  String get invoiceBillToLabel => 'Bill to';

  @override
  String get invoiceSelectClientLabel => 'Select client';

  @override
  String get invoiceSubtotalLabel => 'Subtotal';

  @override
  String get invoiceTaxLabel => 'Tax';

  @override
  String get invoiceNoLinesYet => 'No lines yet';

  @override
  String get invoicePdfGeneratedLabel => 'PDF generated';

  @override
  String get invoicePdfNotGeneratedLabel => 'PDF not generated';

  @override
  String get invoiceIssueCta => 'Issue invoice';

  @override
  String get invoiceSaveDraftCta => 'Save draft';

  @override
  String get invoicePdfCta => 'PDF';

  @override
  String get invoicePdfDownloadCta => 'Download PDF';

  @override
  String get invoiceOpenCta => 'Open invoice';

  @override
  String get invoiceBillingNameTitle => 'Client billing details';

  @override
  String get invoiceBillingNameEditCta => 'Edit client billing details';

  @override
  String get invoiceBillingNameCurrentLabel => 'Current billing name';

  @override
  String get invoiceBillingNameNewLabel => 'Billing name';

  @override
  String get invoiceBillingNameReasonLabel => 'Reason (optional)';

  @override
  String get invoiceBillingNameNewRequired => 'Billing name is required';

  @override
  String get invoiceBillingNameUpdateSuccess =>
      'Client billing details updated';

  @override
  String get invoiceChangeHistoryTitle => 'Changes';

  @override
  String get invoiceChangeHistoryEmpty => 'No changes yet.';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get updatedByLabel => 'Updated by';

  @override
  String get invoicePreviewCta => 'Preview (PDF)';

  @override
  String get invoiceSendCta => 'Send invoice';

  @override
  String get invoiceStepsTitle => 'Steps';

  @override
  String get invoiceStepCreateTitle => 'Step 1 - Create invoice';

  @override
  String get invoiceStepCreateShort => 'Create';

  @override
  String get invoiceStepPreviewTitle => 'Step 2 - Preview';

  @override
  String get invoiceStepPreviewShort => 'Preview';

  @override
  String get invoiceStepIssueTitle => 'Step 3 - Save draft';

  @override
  String get invoiceStepIssueShort => 'Draft';

  @override
  String get invoiceChecklistClient => 'Client selected';

  @override
  String get invoiceChecklistDates => 'Invoice date selected';

  @override
  String get invoiceChecklistLines => 'Lines added';

  @override
  String get invoiceWarningsTitle => 'Warnings';

  @override
  String get invoiceWarningDueDateBefore => 'Due date is before invoice date';

  @override
  String get invoiceWarningPendingDrafts =>
      'You have pending drafts. Resolve them before continuing.';

  @override
  String get invoicePreviewNeedsClient => 'Select a client to continue.';

  @override
  String get invoicePreviewNeedsDate => 'Select the invoice date to continue.';

  @override
  String get invoicePreviewInvalidDates =>
      'Due date cannot be before invoice date.';

  @override
  String get invoicePreviewNeedsLines =>
      'Add at least one line with a price to continue.';

  @override
  String get invoicePreviewNeedsDraft =>
      'Save a draft to generate the PDF preview.';

  @override
  String get invoiceIssueNeedsPreview => 'Preview the invoice before issuing.';

  @override
  String get invoiceSummaryTitle => 'Summary';

  @override
  String get invoiceNumberSummaryLabel => 'Invoice number';

  @override
  String get invoicePreviewPendingLabel => 'Preview pending';

  @override
  String get invoicePreviewReviewedStatus => 'Preview reviewed';

  @override
  String get invoicePreviewReviewedLabel => 'You have reviewed the invoice';

  @override
  String get invoiceIssueConfirmTitle => 'Issue invoice';

  @override
  String get invoiceIssueConfirmMessage => 'This action cannot be undone.';

  @override
  String get invoiceIssuingLabel => 'Issuing…';

  @override
  String get invoiceDetailsShowCta => 'Show details';

  @override
  String get invoiceDetailsHideCta => 'Hide details';

  @override
  String get invoiceClientSearchHint => 'Search client';

  @override
  String get invoiceNotesShowCta => 'Show';

  @override
  String get invoiceNotesHideCta => 'Hide';

  @override
  String get invoiceNotesOptionalLabel => 'Optional';

  @override
  String get invoiceClientInvoicesThisMonthLabel => 'Invoices this month';

  @override
  String get clientMissingInvoiceThisMonth => 'Missing invoice this month';

  @override
  String get clientInvoiceAllGood => 'Invoice issued this month';

  @override
  String get clientAllHaveInvoiceTitle => 'All clients invoiced';

  @override
  String get clientInvoiceStatusUnavailableTitle =>
      'Invoice status unavailable';

  @override
  String get clientNoMatchFiltersTitle => 'No clients match these filters';

  @override
  String get clientAllHaveInvoiceDesc =>
      'No clients are missing an invoice this month.';

  @override
  String get clientInvoiceStatusUnavailableDesc =>
      'Invoice data has not been returned for these clients yet.';

  @override
  String get clientNoMatchFiltersDesc => 'Try adjusting the search or filters.';

  @override
  String get clientNoInvoiceIssuedThisMonth => 'No invoice this month';

  @override
  String clientLastInvoiceShort(String date) {
    return 'Last: $date';
  }

  @override
  String clientMissingCountThisMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missing this month',
      one: '1 missing this month',
      zero: 'None missing',
    );
    return '$_temp0';
  }

  @override
  String clientInvoiceCountThisMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices this month',
      one: '1 invoice this month',
      zero: 'No invoices this month',
    );
    return '$_temp0';
  }

  @override
  String get invoiceDraftInfoTooltip => 'Drafts info';

  @override
  String get invoiceDraftInfoTitle => 'Before creating a draft';

  @override
  String get invoiceDraftInfoMessage =>
      'Before creating a draft, make sure you do not have any pending drafts.';

  @override
  String get invoicePendingDraftsLabel => 'Pending drafts';

  @override
  String get invoiceFillRequiredFieldsError =>
      'Please fill the required fields';

  @override
  String invoiceDraftSavedSnack(Object invoiceNumber) {
    return 'Draft saved: $invoiceNumber';
  }

  @override
  String get invoiceDraftSavedSnackNoNumber => 'Draft saved';

  @override
  String get invoiceDraftSavedSnackTitle => 'Draft saved';

  @override
  String get invoiceDraftSavedSnackMessage =>
      'Your invoice draft is safe and ready to continue later.';

  @override
  String get invoiceDraftUpdatedSnackTitle => 'Draft updated';

  @override
  String get invoiceDraftUpdatedSnackMessage =>
      'Your latest changes were saved to this draft.';

  @override
  String get invoiceDraftSnackDismiss => 'Close';

  @override
  String get invoiceDraftSaveFailedSnack =>
      'Could not save draft. Please try again.';

  @override
  String get invoiceDraftRemoveTitle => 'Remove draft?';

  @override
  String get invoiceDraftRemoveMessage => 'This will delete the current draft.';

  @override
  String get invoiceDraftRemovedSnack => 'Draft removed';

  @override
  String get invoiceDraftRemoveFailedSnack =>
      'Could not remove draft. Please try again.';

  @override
  String invoiceBatchIssueSuccessSnack(Object count) {
    return '$count invoices issued successfully';
  }

  @override
  String invoiceBatchIssuePartialSnack(Object issued, Object failed) {
    return '$issued issued, $failed failed';
  }

  @override
  String get invoiceIssueDuplicateNumberSnack =>
      'That invoice number already exists in this group. Refresh the list or edit the draft number before issuing.';

  @override
  String invoiceIssueDuplicateNumberValueSnack(Object number) {
    return 'Invoice number $number already exists in this group. Refresh the list or edit the draft number before issuing.';
  }

  @override
  String get invoiceBatchIssueErrorsTitle => 'Errors';

  @override
  String invoiceDraftOpenFailed(Object reason) {
    return 'Could not open draft: $reason';
  }

  @override
  String invoiceIssueSuccessSnack(Object invoiceNumber) {
    return 'Invoice issued: $invoiceNumber';
  }

  @override
  String get invoiceIssueFailedSnack =>
      'Could not issue invoice. Please try again.';

  @override
  String get invoicePdfPreviewFailedSnack =>
      'Could not generate PDF preview. Please try again.';

  @override
  String get invoiceSortByNumberLabel => 'Sort by number';

  @override
  String get invoiceSortByNumberRecent => 'Most recent';

  @override
  String get invoiceSortByNumberAsc => 'Number (ascending)';

  @override
  String get invoiceSortByNumberDesc => 'Number (descending)';

  @override
  String get invoiceStatusDraft => 'Draft';

  @override
  String get invoiceStatusSent => 'Sent';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusOverdue => 'Overdue';

  @override
  String get invoiceStatusCancelled => 'Cancelled';

  @override
  String get invoiceStatusUnknown => 'Unknown';

  @override
  String get invoiceRecurringLabel => 'Recurring';

  @override
  String get invoiceEmailSettingsChecking => 'Checking email settings...';

  @override
  String get invoiceEmailSettingsUnavailable => 'Email settings unavailable';

  @override
  String get invoiceEmailSettingsConfigured => 'Email sending is configured ✅';

  @override
  String get invoiceEmailSettingsNeedsSetup => 'Email sending needs setup ⚠️';

  @override
  String get invoiceEmailConfigureCta => 'Configure email';

  @override
  String get invoiceEmailCopyLinkCta => 'Copy invoice link';

  @override
  String get invoiceEmailNoSentYet => 'No email sent yet';

  @override
  String get invoiceEmailHistoryShowCta => 'View history';

  @override
  String get invoiceEmailHistoryHideCta => 'Hide history';

  @override
  String get invoiceEmailNoHistory => 'No email history yet.';

  @override
  String get invoiceEmailResentSnack => 'Invoice email resent';

  @override
  String get invoiceEmailDetailsTitle => 'Email details';

  @override
  String get invoiceEmailStatusNotSent => 'Not sent';

  @override
  String get invoiceEmailLogToLabel => 'To';

  @override
  String get invoiceEmailLogCcLabel => 'CC';

  @override
  String get invoiceEmailViewDetailsCta => 'View details';

  @override
  String get invoiceEmailResendCta => 'Resend';

  @override
  String get invoiceEmailResendingLabel => 'Resending...';

  @override
  String invoiceEmailSubjectTemplate(Object invoiceNumber) {
    return 'Invoice $invoiceNumber';
  }

  @override
  String invoiceEmailMessageTemplate(Object clientName, Object invoiceNumber) {
    return 'Hi $clientName,\n\nPlease find your invoice $invoiceNumber attached.\n\nThanks,';
  }

  @override
  String get invoiceEmailSheetTitle => 'Send invoice';

  @override
  String get invoiceEmailSheetSubtitle =>
      'Compose and preview your invoice email.';

  @override
  String get invoiceEmailAttachPdfLabel => 'Attach PDF';

  @override
  String get invoiceEmailSendLinkLabel => 'Send link';

  @override
  String get invoiceEmailTabEdit => 'Edit';

  @override
  String get invoiceEmailTabPreview => 'Preview';

  @override
  String get invoiceEmailToLabel => 'To';

  @override
  String get invoiceEmailCcLabel => 'CC (optional)';

  @override
  String get invoiceEmailSubjectLabel => 'Subject';

  @override
  String get invoiceEmailMessageLabel => 'Message';

  @override
  String get invoiceEmailNoPreview =>
      'No preview yet. Tap refresh to generate.';

  @override
  String get invoiceEmailPreviewRefreshCta => 'Refresh preview';

  @override
  String get invoiceEmailSendCta => 'Send';

  @override
  String get invoiceEmailSendingLabel => 'Sending...';

  @override
  String invoiceEmailSentAtLabel(Object timestamp) {
    return 'Sent $timestamp';
  }

  @override
  String get invoiceLogoTitle => 'Invoice logo';

  @override
  String get invoiceLogoSubtitle => 'Shown on invoices and PDFs.';

  @override
  String get invoiceLogoUploadCta => 'Upload';

  @override
  String get invoiceLogoUrlLabel => 'Logo URL';

  @override
  String get invoiceLogoEmpty => 'No logo set';

  @override
  String get invoiceLogoUpdated => 'Logo updated';

  @override
  String get groupInvoicesBusinessTitle => 'Business';

  @override
  String get groupInvoicesTotalsTitle => 'Invoice totals';

  @override
  String get groupInvoicesExpandTooltip => 'Expand';

  @override
  String get groupInvoicesCollapseTooltip => 'Collapse';

  @override
  String get groupInvoicesClientsFlowCta => 'Clients invoice flow';

  @override
  String get groupInvoicesDraftInvoicesTitle => 'Draft invoices';

  @override
  String get groupInvoicesSelectInvoiceHint =>
      'Select an invoice to see details';

  @override
  String groupInvoicesTabDrafts(Object count) {
    return 'Drafts ($count)';
  }

  @override
  String groupInvoicesTabInvoices(Object count) {
    return 'Invoices ($count)';
  }

  @override
  String groupInvoicesTotalsInline(Object draftsCount, Object issuedCount) {
    return 'Issued: $issuedCount • Drafts: $draftsCount';
  }

  @override
  String groupInvoicesTotalsIssuedButton(Object count) {
    return 'Issued: $count';
  }

  @override
  String groupInvoicesTotalsDraftsButton(Object count) {
    return 'Drafts: $count';
  }

  @override
  String get groupInvoicesRemoveDraftTitle => 'Remove draft?';

  @override
  String get groupInvoicesRemoveInvoiceTitle => 'Remove invoice?';

  @override
  String groupInvoicesRemoveInvoiceMessage(Object invoiceNumber) {
    return 'This will delete the invoice $invoiceNumber.';
  }

  @override
  String get groupInvoicesRemovedSnack => 'Invoice removed';

  @override
  String get groupInvoicesInvoiceAlreadyRemovedSnack =>
      'Invoice not found (already removed). Refreshing…';

  @override
  String groupInvoicesRemoveFailedSnack(Object reason) {
    return 'Could not remove invoice: $reason';
  }

  @override
  String get clientsTitle => 'Clients';

  @override
  String get selectClientFirst =>
      'Select a client to view billing and invoices';

  @override
  String get clientEntityTypeLabel => 'Entity type';

  @override
  String get clientEntityTypeHint => 'e.g. community, company, individual';

  @override
  String get clientPropertyKindLabel => 'Property kind';

  @override
  String get clientPropertyKindHint => 'e.g. building, apartment, chalet';

  @override
  String get clientClassificationTitle => 'Client classification';

  @override
  String get clientClassificationManageCta => 'Manage';

  @override
  String get clientClassificationManageTitle => 'Manage saved options';

  @override
  String get clientAddOptionHint => 'Add option (max 50)';

  @override
  String get clientClassificationManageHint =>
      'These options are saved for the group and can be reused when assigning types to clients.';

  @override
  String get clientClassificationSaveCta => 'Save';

  @override
  String get clientClassificationSavedSnack => 'Options saved';

  @override
  String get clientClassificationRebuildCta => 'Rebuild';

  @override
  String get clientClassificationRebuiltSnack => 'Options rebuilt';

  @override
  String get clientClassificationSectionTitle => 'Classification';

  @override
  String get clientClassificationAddTitle => 'Add classification';

  @override
  String get clientClassificationTypeLabel => 'Type';

  @override
  String get clientClassificationNameLabel => 'Name';

  @override
  String get clientClassificationSelectHint =>
      'Select a classification to see assignments';

  @override
  String clientClassificationAssignedCount(int count) {
    return 'Assigned clients ($count)';
  }

  @override
  String get clientClassificationNoClients => 'No clients assigned yet.';

  @override
  String get clientClassificationExpandTooltip => 'Expand';

  @override
  String get clientClassificationCollapseTooltip => 'Collapse';

  @override
  String get clientHideInactiveChip => 'Hide inactive';

  @override
  String get clientInactiveHiddenChip => 'Inactive hidden';

  @override
  String get clientDetailsExpandTooltip => 'Show details';

  @override
  String get clientDetailsCollapseTooltip => 'Hide details';

  @override
  String get clientSearchHint => 'Search clients…';

  @override
  String get clientFiltersTitle => 'Filters';

  @override
  String get clientFiltersClear => 'Clear';

  @override
  String get clientSelectedHiddenByFilters =>
      'Selected client is hidden by filters';

  @override
  String get clientQuickAssignTitle => 'Quick assign';

  @override
  String get clientQuickAssignSubtitle => 'Tap to assign. Tap again to clear.';

  @override
  String get clientClassificationUpdatedSnack => 'Client updated';

  @override
  String get clientBillingMissingTitle => 'Missing billing information';

  @override
  String clientBillingMissingMessage(String fields) {
    return 'Complete: $fields';
  }

  @override
  String get billingDocumentType => 'Document type';

  @override
  String get documentTypeInvoice => 'Invoice';

  @override
  String get documentTypeReceipt => 'Receipt';

  @override
  String get receiptsTitle => 'Receipts';

  @override
  String get createReceiptCta => 'Create receipt';

  @override
  String groupReceiptsTabDrafts(Object count) {
    return 'Drafts ($count)';
  }

  @override
  String groupReceiptsTabReceipts(Object count) {
    return 'Receipts ($count)';
  }

  @override
  String get groupReceiptsSelectReceiptHint =>
      'Select a receipt to see details';

  @override
  String get groupReceiptsRemoveDraftTitle => 'Remove receipt draft?';

  @override
  String groupReceiptsRemoveDraftMessage(Object receiptNumber) {
    return 'This will delete the receipt $receiptNumber.';
  }

  @override
  String get groupReceiptsRemovedSnack => 'Receipt removed';

  @override
  String get groupReceiptsAlreadyRemovedSnack =>
      'Receipt not found (already removed). Refreshing…';

  @override
  String get groupReceiptsCannotRemoveIssuedSnack =>
      'Cannot remove an issued receipt';

  @override
  String groupReceiptsRemoveFailedSnack(Object reason) {
    return 'Could not remove receipt: $reason';
  }

  @override
  String get receiptDraftNumberPlaceholder => 'Draft receipt';

  @override
  String get receiptDateUnknown => 'Date unknown';

  @override
  String get receiptIssueDateLabel => 'Issue date';

  @override
  String get receiptLinesTitle => 'Receipt lines';

  @override
  String get receiptSummaryTitle => 'Summary';

  @override
  String get receiptNoLinesYet => 'No lines yet';

  @override
  String get receiptLineTotalLabel => 'Total';

  @override
  String get receiptSubtotalLabel => 'Subtotal';

  @override
  String get receiptTotalLabel => 'Total';

  @override
  String get receiptIssueCta => 'Issue receipt';

  @override
  String get receiptLockedHint => 'Issued receipts are locked';

  @override
  String receiptEditorTitle(Object number) {
    return 'Receipt $number';
  }

  @override
  String get receiptEditorFormTitle => 'Receipt';

  @override
  String get receiptSelectClientLabel => 'Select client';

  @override
  String get receiptClientRequired => 'Select a client first';

  @override
  String get receiptLinesRequired => 'Add at least one line';

  @override
  String get receiptNotesHint => 'Optional notes';

  @override
  String get receiptDraftSavedSnack => 'Draft saved';

  @override
  String get receiptDraftSavedSnackTitle => 'Receipt draft saved';

  @override
  String get receiptDraftSavedSnackMessage =>
      'Your receipt draft is safe and ready to continue later.';

  @override
  String get receiptSaveFailed => 'Could not save receipt';

  @override
  String get receiptPreviewFailed => 'Could not preview receipt PDF';

  @override
  String get receiptDownloadFailed => 'Could not download receipt PDF';

  @override
  String get receiptIssueConfirmTitle => 'Issue receipt?';

  @override
  String get receiptIssueConfirmMessage =>
      'Assign final number and lock the receipt.';

  @override
  String receiptIssueSuccessSnack(Object receiptNumber) {
    return 'Receipt issued: $receiptNumber';
  }

  @override
  String get receiptIssueFailed => 'Could not issue receipt';

  @override
  String get preview => 'Preview';

  @override
  String get download => 'Download';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get addLine => 'Add line';

  @override
  String get statementsTabTitle => 'Import Statements (Excel)';

  @override
  String get bankProvidersTabTitle => 'Bank Providers';

  @override
  String get statementsImportTabTitle => 'Import';

  @override
  String get statementsHistoryTabTitle => 'History';

  @override
  String get statementsStepUpload => 'Upload file';

  @override
  String get statementsStepReview => 'Review data';

  @override
  String get statementsStepConfirm => 'Confirm import';

  @override
  String get statementsReviewDisabled =>
      'Upload a file to review parsed entries and deduplication.';

  @override
  String get statementsConfirmHelp =>
      'Review the summary and confirm to finalize the import.';

  @override
  String get statementsConfirmDisabled =>
      'Complete the upload to enable confirmation.';

  @override
  String get statementsConfirmAction => 'Confirm import';

  @override
  String get statementsConfirmSuccess => 'Import confirmed.';

  @override
  String get statementsStepDisabledHint =>
      'Complete the previous step to continue.';

  @override
  String get autoStatementImportTitle => 'Enable automatic data';

  @override
  String get autoStatementImportHelper =>
      'When on, we\'ll automatically import your daily Caixa statement into your account.';

  @override
  String get autoStatementImportUpdateFailed =>
      'Unable to update automatic data setting.';

  @override
  String get statementsDragDropTitle => 'Upload your statement';

  @override
  String get statementsDragDropHint => 'Drag your file here or click to select';

  @override
  String get statementsFormatsHint =>
      'Supported formats: .xls, .xlsx · Max 10 MB';

  @override
  String get statementsRemoveFile => 'Remove';

  @override
  String get statementsSecurityNote => 'ðŸ”’ Your data is processed securely';

  @override
  String get statementsFileTooLarge => 'File exceeds 10 MB limit';

  @override
  String get statementsResultsTitle => 'Import results';

  @override
  String get statementsResultsHelp =>
      'Review deduplication and client matching before confirming the import.';

  @override
  String get statementsResultsEmpty =>
      'Upload a file to see the import result and preview.';

  @override
  String get statementsDuplicateFileError =>
      'This file was already imported (duplicate checksum).';

  @override
  String get statementsFilterYear => 'Year';

  @override
  String get statementsFilterFrom => 'From';

  @override
  String get statementsFilterTo => 'To';

  @override
  String get statementsApplyFilters => 'Apply filters';

  @override
  String get statementsClearFilters => 'Clear';

  @override
  String get statementsPageSize => 'Page size';

  @override
  String statementsPageInfo(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get statementsPrevPage => 'Prev';

  @override
  String get statementsNextPage => 'Next';

  @override
  String get statementsSummaryTitle => 'Summary';

  @override
  String get statementsSummaryMonthly => 'Monthly';

  @override
  String get statementsSummaryYearly => 'Yearly';

  @override
  String get statementsSummaryNet => 'Net';

  @override
  String get statementsSummaryIncome => 'Income';

  @override
  String get statementsSummaryExpense => 'Expense';

  @override
  String get statementsSummaryEmpty => 'No summary data for this range.';

  @override
  String statementsSummaryLine(String total, String count) {
    return 'total $total • $count entries';
  }

  @override
  String get statementsActionViewEntries => 'View entries';

  @override
  String get statementsReprocessTitle => 'Reprocess batch?';

  @override
  String get statementsReprocessMessage =>
      'This will re-run the parser using the saved column map for this batch.';

  @override
  String get statementsReprocessAction => 'Reprocess';

  @override
  String get statementsDeleteTitle => 'Delete batch?';

  @override
  String get statementsDeleteMessage =>
      'This will permanently remove the batch and all its entries.';

  @override
  String get statementsDeleteAction => 'Delete';

  @override
  String get statementsCancel => 'Cancel';

  @override
  String statementsDuplicateSummary(String count) {
    return '$count duplicate movements skipped — View details';
  }

  @override
  String get statementsViewDetails => 'View details';

  @override
  String get statementsStatusSuccess => 'Success';

  @override
  String get statementsStatusWarning => 'Warning';

  @override
  String get statementsShowTechDetails => 'View technical details';

  @override
  String get statementsHideTechDetails => 'Hide technical details';

  @override
  String get statementsTechBatchId => 'Batch ID';

  @override
  String get statementsTechChecksum => 'Checksum';

  @override
  String get statementsTechUploader => 'Uploaded by';

  @override
  String get statementsCopy => 'Copy';

  @override
  String get moreActions => 'More actions';

  @override
  String get statementsNoImportsHelp =>
      'When you import a file, past batches will appear here for quick review.';

  @override
  String get statementsDownloadTemplate => 'Download Excel template';

  @override
  String get statementsViewExample => 'View example';

  @override
  String get statementsUploadDescription =>
      'Upload XLS/XLSX statements to parse, dedupe, and link entries to clients. Duplicates are auto-skipped and reported separately.';

  @override
  String get statementsChooseFile => 'Choose XLS/XLSX';

  @override
  String get statementsNoFileSelected => 'No file selected';

  @override
  String statementsSelectedFile(String fileName) {
    return 'Selected: $fileName';
  }

  @override
  String get statementsUploadParse => 'Upload & parse';

  @override
  String get statementsUploadFailed => 'Upload failed';

  @override
  String get statementsUploadComplete => 'Upload complete';

  @override
  String get statementsFileReadError => 'Unable to read file bytes';

  @override
  String statementsBatchLabel(String batchId) {
    return 'Batch: $batchId';
  }

  @override
  String statementsSheetLabel(String sheet) {
    return 'Sheet: $sheet';
  }

  @override
  String statementsInsertedLabel(String count) {
    return 'Inserted: $count';
  }

  @override
  String statementsSkippedLabel(String count) {
    return 'Skipped: $count';
  }

  @override
  String statementsPreviewTitle(int count) {
    return 'Preview (first $count entries)';
  }

  @override
  String get statementsNoDescription => '(no description)';

  @override
  String statementsAmountLabel(String amount) {
    return 'amount: $amount';
  }

  @override
  String get statementsPastImports => 'Past imports';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get statementsNoImports => 'No imports yet.';

  @override
  String get statementsBatchFallback => 'Batch';

  @override
  String statementsBatchTitle(String batchId) {
    return 'Batch $batchId';
  }

  @override
  String statementsUploadedAt(String uploadedAt) {
    return 'uploaded: $uploadedAt';
  }

  @override
  String statementsFileLabel(String fileName) {
    return 'file: $fileName';
  }

  @override
  String statementsChecksumLabel(String checksum) {
    return 'checksum: $checksum';
  }

  @override
  String statementsUploaderLabel(String uploader) {
    return 'uploader: $uploader';
  }

  @override
  String statementsEntryCount(String count) {
    return 'entries: $count';
  }

  @override
  String get statementsBatchEntries => 'Batch entries';

  @override
  String statementsBatchChip(String batchId) {
    return 'batch: $batchId';
  }

  @override
  String get statementsSelectBatch => 'Select a batch to view entries.';

  @override
  String get statementsHeaderDate => 'Date';

  @override
  String get statementsHeaderDescription => 'Description';

  @override
  String get statementsHeaderDetails => 'Details';

  @override
  String get statementsHeaderAmount => 'Amount';

  @override
  String get statementsHeaderBalance => 'Balance';

  @override
  String get statementsHeaderClient => 'Client';

  @override
  String get statementsHeaderActions => 'Actions';

  @override
  String get statementsHeaderBatch => 'Batch';

  @override
  String get statementsActionSuggest => 'Suggest';

  @override
  String get statementsActionLink => 'Link';

  @override
  String get statementsUnlinked => 'Unlinked';

  @override
  String get statementsAllDataTitle => 'All statements';

  @override
  String get statementsAllDataSubtitle =>
      'Review all movements, link clients, and keep data clean.';

  @override
  String get statementsAllDataEmpty =>
      'No entries yet. Import an Excel file to review movements here.';

  @override
  String get statementsFiltersTitle => 'Filters';

  @override
  String get statementsPaginationTitle => 'Pagination';

  @override
  String get statementsPresetsTitle => 'Quick ranges';

  @override
  String get statementsPickRange => 'Pick range';

  @override
  String get statementsPanelCollapse => 'Hide guidance panel';

  @override
  String get statementsPanelExpand => 'Show guidance panel';

  @override
  String get statementsStepContextUploadTitle => 'Step 1 · Upload file';

  @override
  String get statementsStepContextReviewTitle => 'Step 2 · Review data';

  @override
  String get statementsStepContextConfirmTitle => 'Step 3 · Confirm import';

  @override
  String get statementsImportSummaryTitle => 'Import summary';

  @override
  String get statementsConfirmChecklistTitle => 'Final checklist';

  @override
  String get statementsConfirmChecklistItem1 =>
      'Verify duplicates and totals before confirming.';

  @override
  String get statementsConfirmChecklistItem2 =>
      'You can still link clients after import.';

  @override
  String get statementsPresetThisMonth => 'This month';

  @override
  String get statementsPresetLast30Days => 'Last 30 days';

  @override
  String get statementsPresetThisYear => 'This year';

  @override
  String get statementsFiltersActive => 'Active filters';

  @override
  String get statementsFiltersNone => 'No active filters';

  @override
  String get statementsColumnBatchTooltip => 'Batch id';

  @override
  String get statementsColumnBatchCopy => 'Copy batch id';

  @override
  String get statementsActionsTooltipSuggest =>
      'Suggest a client based on description';

  @override
  String get statementsActionsTooltipLink => 'Manually link a client';

  @override
  String statementsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get statementsBulkSuggest => 'Suggest for selected';

  @override
  String get statementsBulkLink => 'Link in bulk';

  @override
  String get statementsClearSelection => 'Clear selection';

  @override
  String statementsBulkSuggestResult(int withSuggestions, int linked) {
    return '$withSuggestions suggestions found · $linked linked';
  }

  @override
  String get statementsBulkLinkTitle => 'Link selected entries';

  @override
  String get statementsTotalAmount => 'Total amount';

  @override
  String get statementsTotalCount => 'Total movements';

  @override
  String get statementsLastBalance => 'Latest balance';

  @override
  String statementsLastBalanceDate(String date) {
    return 'as of $date';
  }

  @override
  String get statementsNavTitle => 'Bank';

  @override
  String get statementsNavCollapse => 'Collapse menu';

  @override
  String get statementsNavExpand => 'Expand menu';

  @override
  String get statementsAnalyticsTitle => 'Statements Analytics';

  @override
  String get statementsAnalyticsBatch => 'Batch';

  @override
  String get statementsAnalyticsMonth => 'Month';

  @override
  String get statementsAnalyticsMode => 'Mode';

  @override
  String get statementsAnalyticsCompareMode => 'Comparison';

  @override
  String get statementsAnalyticsCompareTitle => 'Dual-period comparison';

  @override
  String get statementsAnalyticsCompareHelp =>
      'Compare calendar month vs settlement window totals for each month in the selected year.';

  @override
  String get statementsAnalyticsComparePickYear =>
      'Select a year to see the comparison.';

  @override
  String get statementsAnalyticsCompareBoth => 'Both';

  @override
  String get statementsAnalyticsCompareCalendar => 'Calendar';

  @override
  String get statementsAnalyticsCompareSettlement => 'Settlement';

  @override
  String get statementsAnalyticsCompareDelta => 'Delta';

  @override
  String get statementsAnalyticsModeCalendar => 'Calendar month';

  @override
  String get statementsAnalyticsModeSettlement => 'Settlement window';

  @override
  String statementsAnalyticsModeLabel(Object mode) {
    return 'Mode: $mode';
  }

  @override
  String get statementsAnalyticsSettlementStart => 'Start day';

  @override
  String get statementsAnalyticsSettlementEnd => 'End day';

  @override
  String statementsAnalyticsPeriodLabel(Object from, Object to) {
    return 'Period: $from – $to';
  }

  @override
  String get statementsAnalyticsPeriodPending =>
      'Period: select a year and month';

  @override
  String get statementsAnalyticsTop => 'Top';

  @override
  String statementsAnalyticsTopHelp(int count) {
    return 'Top $count';
  }

  @override
  String get statementsAnalyticsTrends => 'Trends';

  @override
  String get statementsAnalyticsTrendsHelp =>
      'Compare income, expense, and net across the selected range.';

  @override
  String get statementsAnalyticsYearAverageTitle => 'Year average';

  @override
  String get statementsAnalyticsYearAveragesTitle =>
      'Average monthly income & expense by year';

  @override
  String get statementsAnalyticsAverageIncome => 'Avg income';

  @override
  String get statementsAnalyticsAverageExpense => 'Avg expense';

  @override
  String get statementsAnalyticsTotalsTab => 'Totals';

  @override
  String get statementsAnalyticsAverageTab => 'Average per entry';

  @override
  String get statementsAnalyticsTopMerchants => 'Top merchants';

  @override
  String get statementsAnalyticsTopHelpSubtitle =>
      'Largest merchants by total amount for the selected filters.';

  @override
  String get statementsAnalyticsNoData => 'No analytics data yet.';

  @override
  String get statementsAnalyticsNoMerchants =>
      'No merchant data for this range.';

  @override
  String get statementsAnalyticsNoBatches =>
      'No statement batches available yet.';

  @override
  String get statementsAnalyticsAllBatches => 'All batches';

  @override
  String get statementsAnalyticsAllYears => 'All years';

  @override
  String get statementsAnalyticsAllMonths => 'All months';

  @override
  String get statementsAnalyticsNoSelection =>
      'Select a batch to load analytics.';

  @override
  String statementsAnalyticsMonthHint(int month) {
    return 'Month $month selected';
  }

  @override
  String get statementsAnalyticsExpand => 'Show more';

  @override
  String get statementsAnalyticsCollapse => 'Show less';

  @override
  String get statementsFreshnessThreshold => 'Threshold (days)';

  @override
  String get statementsFreshnessLoading => 'Loading freshness...';

  @override
  String get statementsFreshnessNoData => 'No transactions yet';

  @override
  String statementsFreshnessStale(Object date, Object days) {
    return 'Last entry: $date ($days days ago)';
  }

  @override
  String statementsFreshnessUpToDate(Object date) {
    return 'Up to date (Last entry: $date)';
  }

  @override
  String get statementsFreshnessSendReminder => 'Send reminder';

  @override
  String get statementsFreshnessReminderSent => 'Reminder sent';

  @override
  String get statementsFreshnessReminderFailed => 'Failed to send reminder';

  @override
  String get statementsFreshnessNotStale =>
      'Data is not stale. No notification sent.';

  @override
  String get statementsReminderSettingsTitle => 'Reminder settings';

  @override
  String get statementsReminderSettingsLoading =>
      'Loading reminder settings...';

  @override
  String get statementsReminderSettingsAuto => 'Auto reminders';

  @override
  String get statementsReminderSettingsThreshold => 'Threshold (days)';

  @override
  String get statementsReminderSettingsSaved => 'Reminder settings saved';

  @override
  String get statementsReminderSettingsFailed =>
      'Failed to save reminder settings';

  @override
  String statementsReminderStatusOn(Object days) {
    return 'Auto reminders ON ($days days)';
  }

  @override
  String get statementsReminderStatusOff => 'Auto reminders OFF';

  @override
  String get statementsReminderStatusUnknown => 'Auto reminders: N/A';

  @override
  String get statementsAllDataSummaryTitle => 'Summary for current range';

  @override
  String get dashboardNavTitle => 'Navigation';

  @override
  String get dashboardNavCollapse => 'Collapse menu';

  @override
  String get dashboardNavExpand => 'Expand menu';

  @override
  String get groupInvoicesNavCollapse => 'Collapse menu';

  @override
  String get groupInvoicesNavExpand => 'Expand menu';

  @override
  String get statementsRowDetailsTitle => 'Movement details';

  @override
  String statementsRowDetailsSubtitle(String batchId) {
    return 'Batch $batchId';
  }

  @override
  String get statementsRowDetailsRaw => 'Raw data';

  @override
  String get statementsNoSuggestions => 'No client suggestions found';

  @override
  String get statementsNoInvoiceSuggestions => 'No matching invoices found';

  @override
  String get statementsSuggestedClientsTitle => 'Suggested clients';

  @override
  String get statementsSuggestedInvoicesTitle => 'Suggested invoices';

  @override
  String get statementsBestMatchBadge => 'Best match';

  @override
  String get statementsInvoiceAlreadySelected =>
      'Already selected in another movement';

  @override
  String get statementsInvoiceAlreadyLinkedBadge => 'Already linked';

  @override
  String statementsInvoiceAlreadyLinkedMeta(Object date, Object count) {
    return 'Linked on $date · $count link(s)';
  }

  @override
  String get statementsInvoiceAlreadyLinkedTitle => 'Invoice already linked';

  @override
  String get statementsInvoiceAlreadyLinkedBody =>
      'This invoice is already linked to another transaction. Do you want to link it here as well?';

  @override
  String get statementsInvoiceLinkAnyway => 'Link anyway';

  @override
  String get statementsInvoiceAlreadyLinkedToast =>
      'This invoice was already linked to another bank transaction.';

  @override
  String get statementsInvalidInvoiceToast => 'Invalid invoice.';

  @override
  String get statementsInvoiceNotFoundToast => 'Invoice not found.';

  @override
  String get statementsRepetitiveInvoiceBadge => 'Repeated invoice';

  @override
  String statementsRepetitiveInvoiceTooltip(Object count) {
    return 'This invoice is linked to $count bank movements.';
  }

  @override
  String statementsRepetitiveInvoiceLinkedToast(Object count) {
    return 'Invoice linked, but it was already used in other movements ($count).';
  }

  @override
  String get statementsSuggestionAlreadyLinkedSubtext =>
      'Linked in other transactions';

  @override
  String get statementsInvoiceSuggestTolerance => 'Tolerance';

  @override
  String get statementsLinkClientTitle => 'Link client';

  @override
  String get statementsSearchClients => 'Search clients';

  @override
  String get statementsNoClientsMatch => 'No clients match your search';

  @override
  String get statementsClearLink => 'Clear link';

  @override
  String get statementsUnnamedClient => '(unnamed)';

  @override
  String get statementsImportExcelTab => 'Excel';

  @override
  String get expenseUploadTitle => 'Upload expense';

  @override
  String get expenseUploadFileSectionTitle => 'File';

  @override
  String get expenseUploadFileDropHint => 'Drag the file here';

  @override
  String get expenseUploadFileOrLabel => 'or';

  @override
  String get expenseUploadFileSelectPlaceholder => 'Select a file';

  @override
  String get expenseUploadFileSelectCta => 'Choose file';

  @override
  String get expenseUploadProviderSavedLabel => 'Saved provider';

  @override
  String get expenseUploadProviderManualOption => 'Manual provider';

  @override
  String get expenseUploadProviderSearchPlaceholder => 'Search provider';

  @override
  String get expenseUploadDataSectionTitle => 'Details';

  @override
  String get expenseUploadVendorLabel => 'Provider';

  @override
  String get expenseUploadIssueDateLabel => 'Issue date';

  @override
  String get expenseUploadDateButtonLabel => 'Date';

  @override
  String get expenseUploadTotalLabel => 'Total';

  @override
  String get expenseUploadVendorTaxIdLabel => 'Provider tax ID';

  @override
  String get expenseUploadInvoiceNumberLabel => 'Invoice number';

  @override
  String get expenseUploadDueDateLabel => 'Due date';

  @override
  String get expenseUploadTaxTotalLabel => 'VAT total';

  @override
  String get expenseUploadCurrencyLabel => 'Currency';

  @override
  String get expenseUploadNotesLabel => 'Notes';

  @override
  String get expenseUploadSubmitCta => 'Upload expense';

  @override
  String get expenseUploadFileHelp =>
      'After selecting the file, complete the details in Organize.';

  @override
  String get expenseUploadEmptyList => 'No expenses uploaded in this session.';

  @override
  String get expenseUploadNewProviderTitle => 'New provider';

  @override
  String get expenseUploadEditProviderTitle => 'Edit provider';

  @override
  String get expenseUploadProviderNameLabel => 'Name';

  @override
  String get expenseUploadProviderTaxIdLabel => 'Tax ID';

  @override
  String get expenseUploadProviderEmailLabel => 'Email';

  @override
  String get expenseUploadProviderPhoneLabel => 'Phone';

  @override
  String get expenseUploadProviderStreetLabel => 'Street';

  @override
  String get expenseUploadProviderExtraLabel => 'Extra';

  @override
  String get expenseUploadProviderCityLabel => 'City';

  @override
  String get expenseUploadProviderProvinceLabel => 'Province';

  @override
  String get expenseUploadProviderPostalCodeLabel => 'Postal code';

  @override
  String get expenseUploadProviderCountryLabel => 'Country';

  @override
  String get expenseUploadProviderSaveCta => 'Save';

  @override
  String get expenseUploadProviderUpdateCta => 'Update';

  @override
  String get expenseUploadProviderClearCta => 'Clear';

  @override
  String get expenseUploadProvidersEmpty => 'No providers';

  @override
  String get expenseUploadProvidersSelectHint => 'Select a provider';

  @override
  String get expenseUploadProvidersNoExpenses =>
      'No expenses for this provider.';

  @override
  String get expenseUploadSelectFileError => 'Select a file';

  @override
  String get expenseUploadRequiredFieldsError =>
      'Provider and issue date are required';

  @override
  String get expenseUploadTotalOrLinesError =>
      'Total or line items are required';

  @override
  String get expenseUploadLinesRequiredError => 'Line items are required';

  @override
  String get expenseUploadLinesInvalidError =>
      'Fill in description, quantity, unit price, and tax rate for all lines';

  @override
  String get expenseUploadInvalidIssueDateError => 'Invalid issue date';

  @override
  String get expenseUploadSuccessSnack => 'Expense uploaded';

  @override
  String get expenseUploadTabOrganize => 'Organize';

  @override
  String get expenseUploadTabFile => 'File';

  @override
  String get expenseUploadTabList => 'List';

  @override
  String get expenseUploadTabUpload => 'Upload';

  @override
  String get expenseUploadBatchFlow =>
      'Batch flow: upload documents and then import.';

  @override
  String get expenseUploadBatchUploadDocsCta => 'Upload documents';

  @override
  String get expenseUploadBatchLimits => 'Up to 200 files, max 10MB each.';

  @override
  String expenseUploadBatchSelectedCount(int count) {
    return '$count document(s) selected.';
  }

  @override
  String get expenseUploadBatchVerificationTitle => 'Verification';

  @override
  String get expenseUploadBatchWaiting => 'Waiting for import...';

  @override
  String get expenseUploadBatchImportTitle => 'Import';

  @override
  String get expenseUploadBatchGroupRequired =>
      'You must select a group before importing.';

  @override
  String get expenseUploadBatchImportCta => 'Import Expenses';

  @override
  String get expenseUploadTabByProvider => 'By provider';

  @override
  String get expenseUploadTabProviders => 'Providers';

  @override
  String get expenseUploadProvidersListTitle => 'Providers';

  @override
  String get expenseUploadProvidersInvoicesTitle => 'Provider expenses';

  @override
  String get expenseUploadLinesTitle => 'Line items';

  @override
  String get expenseUploadLinesEmpty => 'No line items added yet.';

  @override
  String get expenseUploadLinesAddCta => 'Add line item';

  @override
  String get expenseUploadLinesItemLabel => 'Line';

  @override
  String get expenseUploadLinesDescriptionLabel => 'Description';

  @override
  String get expenseUploadLinesQuantityLabel => 'Qty';

  @override
  String get expenseUploadLinesUnitPriceLabel => 'Unit price';

  @override
  String get expenseUploadLinesTaxRateLabel => 'Tax rate %';

  @override
  String get expenseUploadLinesSubtotalLabel => 'Subtotal';

  @override
  String get expenseUploadLinesTaxLabel => 'Tax';

  @override
  String get expenseUploadLinesTotalLabel => 'Total';

  @override
  String get expenseUploadTotalAutoHelper => 'Auto-calculated from line items';

  @override
  String get expenseUploadVatBreakdownTitle => 'VAT breakdown';

  @override
  String get expenseUploadVatRateLabel => 'Rate';

  @override
  String get expenseUploadVatBaseLabel => 'Base';

  @override
  String get expenseUploadVatTaxLabel => 'Tax';

  @override
  String get vatSummaryMenuLabel => 'VAT summary';

  @override
  String get vatSummaryTitle => 'VAT summary';

  @override
  String get vatSummaryPrevYear => 'Previous year';

  @override
  String get vatSummaryNextYear => 'Next year';

  @override
  String get vatSummaryQuarterQ1 => 'Q1';

  @override
  String get vatSummaryQuarterQ2 => 'Q2';

  @override
  String get vatSummaryQuarterQ3 => 'Q3';

  @override
  String get vatSummaryQuarterQ4 => 'Q4';

  @override
  String vatSummaryQuarterRangeLabel(String quarter, String range) {
    return 'Quarter $quarter: $range';
  }

  @override
  String vatSummaryQuarterRangeQ1(Object year) {
    return 'Jan 1 – Mar 31, $year';
  }

  @override
  String vatSummaryQuarterRangeQ2(Object year) {
    return 'Apr 1 – Jun 30, $year';
  }

  @override
  String vatSummaryQuarterRangeQ3(Object year) {
    return 'Jul 1 – Sep 30, $year';
  }

  @override
  String vatSummaryQuarterRangeQ4(Object year) {
    return 'Oct 1 – Dec 31, $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ1(Object year) {
    return 'Deadline: Apr 20, $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ2(Object year) {
    return 'Deadline: Jul 20, $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ3(Object year) {
    return 'Deadline: Oct 20, $year';
  }

  @override
  String vatSummaryQuarterDeadlineQ4(Object year) {
    return 'Deadline: Jan 30, $year';
  }

  @override
  String get vatSummaryNoData => 'No VAT summary available.';

  @override
  String get vatSummarySalesTitle => 'Sales';

  @override
  String get vatSummaryPurchasesTitle => 'Purchases';

  @override
  String get vatSummaryNetTitle => 'Net VAT';

  @override
  String get vatSummaryNoRates => 'No rates for this quarter.';

  @override
  String get vatSummaryRateLabel => 'Rate';

  @override
  String get vatSummaryBaseLabel => 'Base';

  @override
  String get vatSummaryTaxLabel => 'Tax';

  @override
  String get vatSummaryTotalsLabel => 'Totals';

  @override
  String get vatSummaryProvidersTitle => 'Providers';

  @override
  String get vatSummaryProvidersEmpty => 'No providers for this quarter.';

  @override
  String get recurringInvoicesTitle => 'Recurring invoices';

  @override
  String get recurringInvoicesSubtitle =>
      'Create and automate billing schedules.';

  @override
  String get recurringInvoicesRefreshCta => 'Refresh';

  @override
  String get recurringInvoicesCreateCta => 'Create series';

  @override
  String get recurringInvoicesStatusFilterLabel => 'Status';

  @override
  String get recurringInvoicesStatusAll => 'All';

  @override
  String get recurringInvoicesStatusActive => 'Active';

  @override
  String get recurringInvoicesStatusPaused => 'Paused';

  @override
  String get recurringInvoicesStatusCancelled => 'Cancelled';

  @override
  String get recurringInvoicesStatusCompleted => 'Completed';

  @override
  String get recurringInvoicesClientFilterLabel => 'Client';

  @override
  String get recurringInvoicesDueSoon => 'Due soon';

  @override
  String get recurringInvoicesEmpty => 'No recurring invoices yet.';

  @override
  String get recurringInvoicesNextRunLabel => 'Next';

  @override
  String get recurringInvoicesPreviewCta => 'View upcoming invoices';

  @override
  String get recurringInvoicesPauseCta => 'Pause';

  @override
  String get recurringInvoicesResumeCta => 'Resume';

  @override
  String get recurringInvoicesCancelCta => 'Cancel series';

  @override
  String get recurringInvoicesRunNowCta => 'Run now';

  @override
  String get recurringInvoicesNoRunsSnack => 'No pending invoices to generate.';

  @override
  String recurringInvoicesRunCreatedSnack(Object count) {
    return 'Invoices created: $count';
  }

  @override
  String get recurringInvoicesCreateSuccess => 'Recurring series created';

  @override
  String get recurringInvoicesCreateFailed =>
      'Could not create recurring series. Please try again.';

  @override
  String get recurringInvoicesChangesNote =>
      'Changes only affect future invoices; generated invoices are snapshots.';

  @override
  String get recurringInvoicesRuleTab => 'Rule';

  @override
  String get recurringInvoicesTemplateTab => 'Template';

  @override
  String get recurringInvoicesGeneratedTab => 'Generated';

  @override
  String get recurringInvoicesSeriesInvoicesTitle =>
      'Invoices from this series';

  @override
  String get recurringInvoicesSeriesInvoicesCta => 'View generated invoices';

  @override
  String get recurringInvoicesSeriesInvoicesHint =>
      'Load all invoices generated by this recurrence.';

  @override
  String get recurringInvoicesSeriesInvoicesEmpty =>
      'No invoices generated yet.';

  @override
  String get recurringInvoicesActivityTab => 'Activity';

  @override
  String get recurringInvoicesSaveRuleCta => 'Save rule';

  @override
  String get recurringInvoicesSavingRule => 'Saving...';

  @override
  String get recurringInvoicesSaveTemplateCta => 'Save template';

  @override
  String get recurringInvoicesSavingTemplate => 'Saving...';

  @override
  String get recurringInvoicesGeneratedHint =>
      'Generated invoices appear in Drafts.';

  @override
  String get recurringInvoicesActivityHint => 'Activity coming soon.';

  @override
  String get recurringInvoicesCreateTitle => 'Create series';

  @override
  String get recurringInvoicesStepClient => 'Client';

  @override
  String get recurringInvoicesStepTemplate => 'Template';

  @override
  String get recurringInvoicesStepSchedule => 'Schedule';

  @override
  String get recurringInvoicesStepPreview => 'Preview';

  @override
  String get recurringInvoicesNameLabel => 'Name';

  @override
  String get recurringInvoicesNameRequired => 'Name required';

  @override
  String get recurringInvoicesFrequencyLabel => 'Frequency';

  @override
  String get recurringInvoicesIntervalLabel => 'Interval';

  @override
  String get recurringInvoicesStartLabel => 'Start';

  @override
  String get recurringInvoicesTimeLabel => 'Time';

  @override
  String recurringInvoicesLocalTimeHelper(Object timezone) {
    return 'Scheduled in your local time ($timezone). Saved as UTC.';
  }

  @override
  String recurringInvoicesLocalTimeSummary(
      Object local, Object timezone, Object utc) {
    return 'Selected: $local ($timezone) · Saved: $utc UTC';
  }

  @override
  String get recurringInvoicesEndLabel => 'End';

  @override
  String get recurringInvoicesEndNever => 'Never';

  @override
  String get recurringInvoicesEndDate => 'Until date';

  @override
  String get recurringInvoicesEndCount => 'Occurrences';

  @override
  String get recurringInvoicesEndDateSelect => 'Select date';

  @override
  String recurringInvoicesEndDateLabel(Object date) {
    return 'Until: $date';
  }

  @override
  String get recurringInvoicesCountLabel => 'Number of invoices';

  @override
  String get recurringInvoicesBillDayLabel => 'Billing day (1-31)';

  @override
  String get recurringInvoicesBillDayHelper =>
      'If the month lacks that day, the last day is used.';

  @override
  String get recurringInvoicesWeekDayLabel => 'Weekday (0-6)';

  @override
  String get recurringInvoicesWeekDayHelper => '0=Sunday, 6=Saturday.';

  @override
  String get recurringInvoicesTimezoneLabel => 'Timezone';

  @override
  String get recurringInvoicesExceptionsLabel => 'Exceptions';

  @override
  String get recurringInvoicesAddExceptionCta => 'Add date';

  @override
  String get recurringInvoicesNoExceptions => 'No exceptions.';

  @override
  String get recurringInvoicesPreviewEmpty => 'No dates calculated yet.';

  @override
  String get recurringInvoicesPreviewTitle => 'Upcoming invoices';

  @override
  String get recurringInvoicesPreviewDialogEmpty => 'No dates calculated.';

  @override
  String get recurringInvoicesContinueCta => 'Continue';

  @override
  String get recurringInvoicesBackCta => 'Back';

  @override
  String get recurringFrequencyDaily => 'Daily';

  @override
  String get recurringFrequencyWeekly => 'Weekly';

  @override
  String get recurringFrequencyMonthly => 'Monthly';

  @override
  String get recurringFrequencyYearly => 'Yearly';

  @override
  String recurringEveryDays(Object count) {
    return 'Every $count days';
  }

  @override
  String recurringEveryWeeks(Object count) {
    return 'Every $count weeks';
  }

  @override
  String recurringEveryMonths(Object count) {
    return 'Every $count months';
  }

  @override
  String recurringEveryYears(Object count) {
    return 'Every $count years';
  }

  @override
  String recurringBillDaySummary(Object day) {
    return 'day $day';
  }

  @override
  String recurringStartFromLabel(Object date) {
    return 'from $date';
  }

  @override
  String get recurringRuleEmpty => 'No schedule';

  @override
  String get recurringInvoicesTimezoneSearchHint => 'Search timezone';

  @override
  String get recurringInvoicesTimezoneUseCta => 'Use';

  @override
  String get mailDetailTitle => 'Message';

  @override
  String get mailDetailFromLabel => 'From';

  @override
  String get mailDetailToLabel => 'To';

  @override
  String get mailDetailDateLabel => 'Date';

  @override
  String get mailDetailBodyLabel => 'Message';

  @override
  String get mailDetailAttachmentsLabel => 'Attachments';

  @override
  String get mailDetailUnknownSender => 'Unknown sender';

  @override
  String get mailDetailNoSubject => '(no subject)';

  @override
  String get mailDetailNotFound => 'Message not found.';

  @override
  String get mailDetailMarkRead => 'Mark read';

  @override
  String get mailDetailMarkUnread => 'Mark unread';

  @override
  String get mailDetailArchive => 'Archive';

  @override
  String get mailDetailTrash => 'Trash';

  @override
  String get mailDetailSpam => 'Spam';

  @override
  String get mailDetailMarkedRead => 'Marked as read.';

  @override
  String get mailDetailMarkedUnread => 'Marked as unread.';

  @override
  String get mailDetailArchived => 'Archived.';

  @override
  String get mailDetailTrashed => 'Moved to trash.';

  @override
  String get mailDetailSpammed => 'Reported as spam.';

  @override
  String mailDetailActionFailed(Object error) {
    return 'Action failed: $error';
  }

  @override
  String mailDetailDownloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get mailDetailDownloadUnsupported =>
      'Downloads are only supported on web for now.';

  @override
  String get mailDetailDownloadTooltip => 'Download';

  @override
  String get mailDetailAttachmentFallback => 'Attachment';

  @override
  String get mailInboxTitle => 'Inbox';

  @override
  String get mailSearchHint => 'Search mail';

  @override
  String get mailSearchClear => 'Clear search';

  @override
  String get mailSearchMinChars =>
      'Search query must be at least 2 characters.';

  @override
  String get mailSearchUnreadOnly => 'Unread only';

  @override
  String get mailSearchDateRange => 'Date range';

  @override
  String get mailSearchClearDates => 'Clear dates';

  @override
  String get mailSearchNoResults => 'No messages found.';

  @override
  String get mailThreadsTitle => 'Threads';

  @override
  String get mailThreadsEmpty => 'No threads found.';

  @override
  String get mailThreadSearchNoResults => 'No conversations found.';

  @override
  String get mailThreadSearchNoResultsHint =>
      'Try another term, like \"invoice\", \"factura\", \"quote\", \"presupuesto\", or the client name.';

  @override
  String get mailThreadSearchTooltip =>
      'Search conversations. Try invoice, factura, quote, or presupuesto.';

  @override
  String get mailThreadDetailTitle => 'Thread';

  @override
  String get mailThreadParticipantsLabel => 'Participants';

  @override
  String get mailThreadMessageCountLabel => 'Messages';

  @override
  String get mailThreadUnreadCountLabel => 'Unread';

  @override
  String get mailThreadNoMessages => 'No messages in this thread.';

  @override
  String get mailThreadNotFound => 'Thread not found.';

  @override
  String get mailThreadOpenMessage => 'Open message';

  @override
  String get mailThreadOpenThread => 'Open thread';

  @override
  String get mailConsoleTitle => 'Mail';

  @override
  String get mailConsoleFoldersTitle => 'Folders';

  @override
  String get mailFolderInbox => 'Inbox';

  @override
  String get mailFolderSent => 'Sent';

  @override
  String get mailFolderArchive => 'Archive';

  @override
  String get mailFolderTrash => 'Trash';

  @override
  String get mailFolderSpam => 'Spam';

  @override
  String get mailConsoleSearchPlaceholder => 'Search conversations...';

  @override
  String get mailConsoleSelectThread => 'Select a thread to view messages.';

  @override
  String get mailConsoleLoadError => 'Couldn\'t load mailbox. Retry.';

  @override
  String get mailConsoleReplyPlaceholder => 'Write a reply…';

  @override
  String get mailConsoleReplySend => 'Reply';

  @override
  String get mailConsoleReplySending => 'Sending…';

  @override
  String get mailConsoleReplySent => 'Reply sent.';

  @override
  String mailConversationReplyTo(Object name) {
    return 'Reply to $name…';
  }

  @override
  String mailConversationPreviousMessage(Object count) {
    return 'Previous message ($count)';
  }

  @override
  String get mailConversationSignature => 'Signature';

  @override
  String get mailConversationReply => 'Reply';

  @override
  String get mailConversationReplyAll => 'Reply all';

  @override
  String get mailConversationForward => 'Forward';

  @override
  String get mailLegalNoticeShow => 'Show legal notice';

  @override
  String get mailLegalNoticeHide => 'Hide legal notice';

  @override
  String get mailConsoleClientPanelTitle => 'Client & invoices';

  @override
  String get mailConsoleClientNotFound => 'No client found for this thread.';

  @override
  String get mailConsoleClientEmailMissing => 'Client email is missing.';

  @override
  String get mailConsoleOpenInvoicesTitle => 'Open invoices';

  @override
  String get mailConsoleInvoicesEmpty => 'No open invoices.';

  @override
  String get mailConsoleInvoiceActionsTitle => 'Invoice actions';

  @override
  String get mailConsoleResendInvoice => 'Resend invoice';

  @override
  String get mailConsoleSendPaymentLink => 'Send payment link';

  @override
  String get mailConsoleMarkPaid => 'Mark paid';

  @override
  String get mailConsoleInvoiceUnknown => 'Invoice';

  @override
  String get mailConsoleInvoiceResent => 'Invoice resent.';

  @override
  String get mailConsolePaymentLinkSent => 'Payment link sent.';

  @override
  String get mailConsoleMarkedPaid => 'Invoice marked paid.';

  @override
  String mailConsoleActionFailed(Object error) {
    return 'Action failed: $error';
  }

  @override
  String mailConsoleInvoiceSubject(Object number) {
    return 'Invoice $number';
  }

  @override
  String mailConsoleInvoiceBody(Object number) {
    return 'Please see invoice $number.';
  }

  @override
  String get mailComposeTitle => 'Compose';

  @override
  String get mailComposeToLabel => 'To';

  @override
  String get mailComposeToHint => 'Enter recipient emails';

  @override
  String get mailComposeToHelper => 'Add at least one recipient';

  @override
  String get mailComposeCcLabel => 'Cc';

  @override
  String get mailComposeCcHint => 'Add cc emails';

  @override
  String get mailComposeAddCc => 'Add Cc';

  @override
  String get mailComposeBccLabel => 'Bcc';

  @override
  String get mailComposeBccHint => 'Add bcc emails';

  @override
  String get mailComposeAddBcc => 'Add Bcc';

  @override
  String get mailComposeSubjectLabel => 'Subject';

  @override
  String get mailComposeSubjectHint => 'Subject';

  @override
  String get mailComposeSubjectHelper =>
      'A subject helps identify the conversation';

  @override
  String get mailComposeBodyLabel => 'Body';

  @override
  String get mailComposeFormat => 'Format';

  @override
  String get mailComposeHtmlToggle => 'HTML';

  @override
  String get mailComposeHtmlHint => 'Paste HTML content';

  @override
  String get mailComposeTextHint => 'Write your message';

  @override
  String get mailComposeBodyHelper => 'Write a message to send';

  @override
  String get mailComposeAttachmentsLabel => 'Attachments';

  @override
  String get mailComposeAttachmentsEmpty => 'No attachments yet.';

  @override
  String get mailComposeAddAttachment => 'Add attachment';

  @override
  String get mailComposeStorageKeyLabel => 'Storage key';

  @override
  String get mailComposeStorageKeyHint => 'e.g. uploads/abc.pdf';

  @override
  String get mailComposeFilenameLabel => 'Filename (optional)';

  @override
  String get mailComposeFilenameHint => 'invoice.pdf';

  @override
  String get mailComposeContentTypeLabel => 'Content type (optional)';

  @override
  String get mailComposeContentTypeHint => 'application/pdf';

  @override
  String get mailComposeSizeLabel => 'Size (optional)';

  @override
  String get mailComposeSizeHint => 'Bytes';

  @override
  String get mailComposeCancel => 'Cancel';

  @override
  String get mailComposeStorageKeyRequired => 'Storage key is required.';

  @override
  String get mailComposeInvoiceOptions => 'Invoice options';

  @override
  String get mailComposeInvoiceOptionsHelper =>
      'These options are used only when sending invoices';

  @override
  String get mailComposeApplyFooterLabel => 'Apply default footer';

  @override
  String get mailComposeApplyFooterHelper =>
      'Adds your default footer to this email.';

  @override
  String get mailComposeInvoiceIdsLabel => 'Invoice IDs';

  @override
  String get mailComposeInvoiceIdsHint => 'Comma-separated IDs';

  @override
  String get mailComposeAttachInvoicePdf => 'Attach invoice PDF';

  @override
  String get mailComposeIncludeInvoiceLinks => 'Include invoice links';

  @override
  String get mailComposeUploadAttachment => 'Upload file';

  @override
  String get mailComposeUploading => 'Uploading…';

  @override
  String get mailComposeFileReadError => 'Could not read the selected file.';

  @override
  String mailComposeUploadFailed(Object error) {
    return 'Upload failed: $error';
  }

  @override
  String get mailComposeSend => 'Send';

  @override
  String get mailComposeSending => 'Sending…';

  @override
  String get mailComposeSentToast => 'Sent';

  @override
  String get mailComposeToRequired => 'Please add at least one recipient.';

  @override
  String get mailComposeSubjectRequired => 'Subject is required.';

  @override
  String get mailComposeBodyRequired => 'Message body is required.';

  @override
  String mailComposeSendFailed(Object error) {
    return 'Failed to send: $error';
  }

  @override
  String get mailFooterTitle => 'Create Email Footer';

  @override
  String get mailFooterBody =>
      'Build a footer that appears on outgoing emails. The company logo will be added automatically.';

  @override
  String get mailFooterNameLabel => 'Footer name';

  @override
  String get mailFooterNameHint => 'Default Footer';

  @override
  String get mailFooterTextLabel => 'Footer text (plain text)';

  @override
  String get mailFooterTextHint => 'Enter footer text';

  @override
  String get mailFooterHtmlLabel => 'Footer HTML (advanced)';

  @override
  String get mailFooterHtmlHint => '<div>...</div>';

  @override
  String get mailFooterDefaultLabel => 'Set as default';

  @override
  String get mailFooterHelperTextOnly =>
      'If you only fill plain text, we’ll render it in both text + HTML emails.';

  @override
  String get mailFooterHelperHtmlOverrides =>
      'If you provide HTML, that will be used in HTML emails.';

  @override
  String get mailFooterSaveCta => 'Save Footer';

  @override
  String get mailFooterCancel => 'Cancel';

  @override
  String get mailFooterCreateCta => 'Create footer';

  @override
  String get mailFooterNameRequired => 'Footer name is required.';

  @override
  String get mailFooterSaved => 'Footer saved.';

  @override
  String get mailFooterCurrentTitle => 'Current footer';

  @override
  String get mailFooterSystemDefault => 'Using the system default footer.';

  @override
  String get mailFooterUnnamed => 'Untitled footer';

  @override
  String get mailFooterHtmlPreview => 'HTML provided';

  @override
  String get mailFooterDefaultBadge => 'Default';

  @override
  String get mailFooterCreateTitle => 'Footer options';

  @override
  String get mailFooterFormTitle => 'Create footer';

  @override
  String get mailFooterUseSystemDefault => 'Use system default';

  @override
  String get mailFooterPreviewBody =>
      'Preview how your footer will look in outgoing emails.';

  @override
  String get mailFooterPreviewCta => 'Preview footer';

  @override
  String get mailFooterPreviewSystemCta => 'Preview system footer';

  @override
  String get mailFooterUseThis => 'Use This Footer';

  @override
  String get mailFooterEdit => 'Edit';

  @override
  String mailFooterSaveFailed(Object error) {
    return 'Failed to save footer: $error';
  }

  @override
  String get budgetsMenuSection => 'Budgets';

  @override
  String get budgetsMenuList => 'List budgets';

  @override
  String get budgetsMenuNew => 'New budget';

  @override
  String get budgetStepClient => 'Client';

  @override
  String get budgetStepBudget => 'Budget';

  @override
  String get budgetStepLines => 'Lines';

  @override
  String get budgetStepConfirm => 'Confirm';

  @override
  String get budgetStepPreview => 'Preview';

  @override
  String get budgetClientInfoPrompt =>
      'Presupuesto client information is flexible. Choose an existing client or enter a client name. At least one is required. This applies only to Presupuestos - invoices and receipts still require a saved client.';

  @override
  String get budgetClientSelectSavedLabel =>
      'Select a saved client (optional for Presupuestos).';

  @override
  String get budgetClientNoneSaved => 'No saved client';

  @override
  String get budgetClientNameLabel =>
      'Use this if the client isn\'t in your database yet.';

  @override
  String get budgetValidationClientRequired =>
      'Provide either a saved client or a client name.';

  @override
  String get budgetValidationNumberFormat => 'Use NNN-YY (e.g., 001-26).';

  @override
  String get budgetValidationGroupRequired =>
      'Missing groupId for presupuesto creation.';

  @override
  String get budgetValidationLineItemsRequired =>
      'Add at least one line with a work concept before continuing.';

  @override
  String get budgetDraftSavedSnack => 'Draft changes saved.';

  @override
  String get budgetDraftCreatedSnack => 'Draft saved successfully.';

  @override
  String get budgetDraftSavedSnackTitle => 'Budget draft saved';

  @override
  String get budgetDraftSavedSnackMessage =>
      'Your presupuesto draft is safe and ready to continue later.';

  @override
  String get budgetDraftUpdatedSnackTitle => 'Budget draft updated';

  @override
  String get budgetDraftUpdatedSnackMessage =>
      'Your latest presupuesto changes were saved.';

  @override
  String get budgetDraftNotEditableSnack =>
      'This budget is no longer a draft and cannot be edited.';

  @override
  String get budgetPreviewAcceptRequired => 'Accept before opening preview.';

  @override
  String get budgetNumberLabel => 'Budget number';

  @override
  String get budgetNumberHint => '001-26';

  @override
  String get budgetNumberAutoOnIssue =>
      'Budget number is assigned by the server when issuing.';

  @override
  String get budgetNumberPendingIssue => 'Pending issue';

  @override
  String get budgetLineItemsSimulateLabel =>
      'Simulate line items added (UI-only validation)';

  @override
  String get budgetInfoBanner =>
      'Presupuestos can be created with a hardcoded client name. If no client is selected, the PDF will show the name and leave other client fields blank.';

  @override
  String budgetConfirmClientValue(Object value) {
    return 'Client: $value';
  }

  @override
  String budgetConfirmNumberValue(Object value) {
    return 'Budget number: $value';
  }

  @override
  String budgetConfirmDraftIdValue(Object value) {
    return 'Draft ID: $value';
  }

  @override
  String budgetConfirmLinesValue(Object value) {
    return 'Lines: $value';
  }

  @override
  String get budgetListIntro =>
      'Budget listing (UI). Server listing will be connected later.';

  @override
  String get budgetListPlaceholder => 'No budgets to show yet.';

  @override
  String get budgetBackCta => 'Back';

  @override
  String get budgetNextCta => 'Next';

  @override
  String get budgetValidateCta => 'Validate';

  @override
  String get budgetValidatedSnack =>
      'Budget draft validated (UI only). Server integration pending.';

  @override
  String budgetIssuedSnack(Object number) {
    return 'Presupuesto issued with number $number.';
  }

  @override
  String get budgetIssueConflict =>
      'Numbering conflict while issuing. Please retry.';

  @override
  String get budgetPreviewInlineTitle => 'Preview';

  @override
  String get budgetPreviewDialogTitle => 'Budget preview';

  @override
  String get budgetPreviewOpenCta => 'Open preview';

  @override
  String get budgetPreviewAcceptLabel =>
      'I confirm this data and want to generate the preview PDF';

  @override
  String budgetPreviewAutoTitle(Object id) {
    return 'PDF preview for presupuesto $id';
  }

  @override
  String get budgetPreviewEmpty => 'Add line items to preview this budget.';

  @override
  String get budgetShortLogicFlowTitle => 'Short Logic Flow';

  @override
  String get budgetShortLogicFlow1 =>
      'Create draft without presupuestoNumber; backend stores it as draft.';

  @override
  String get budgetShortLogicFlow2 =>
      'Either clientId or clientName is required, with groupId.';

  @override
  String get budgetShortLogicFlow3 =>
      'Issue via POST /api/presupuestos/:id/issue to assign NNN-YY.';

  @override
  String get budgetShortLogicFlow4 =>
      'Use returned presupuestoNumber for display; preview uses /api/presupuestos/:id/pdf/preview.';

  @override
  String get insightsChatFabTooltip => 'Insights chat';

  @override
  String get insightsChatTitle => 'Insights';

  @override
  String get insightsChatWelcome =>
      'Ask me about your last 30 days of expenses and issued invoices.';

  @override
  String get insightsChatModeAuto => 'Auto';

  @override
  String get insightsChatModeStream => 'Stream';

  @override
  String get insightsChatClearTooltip => 'Clear chat';

  @override
  String get insightsChatClearTitle => 'Clear chat?';

  @override
  String get insightsChatClearMessage =>
      'This will remove all messages in this chat.';

  @override
  String get insightsChatClearAction => 'Clear';

  @override
  String get insightsChatDaysPrefix => 'Context';

  @override
  String get insightsChatDaysTooltip => 'Context window days';

  @override
  String get insightsChatNoResponse =>
      'No response returned by insights service.';

  @override
  String get insightsChatAnswerReady => 'Insights answer is ready.';

  @override
  String get insightsChatInputHint =>
      'Ask about revenue, expenses, margin, trends...';

  @override
  String get insightsChatSend => 'Send';

  @override
  String get insightsChatExportExcel => 'Export to Excel';

  @override
  String get insightsChatExportExcelTooltip =>
      'Export this finance answer to Excel';

  @override
  String insightsChatExportSuccess(String fileName) {
    return 'Excel generated: $fileName';
  }

  @override
  String get insightsChatExportError => 'Could not export to Excel';

  @override
  String get insightsChatExportUnsupported =>
      'File download is not available on this platform';

  @override
  String get systemConfigMenuLabel => 'System configuration';

  @override
  String get groupPhotoUpdated => 'Group photo updated';

  @override
  String get groupPhotoUpdateFailed => 'Failed to update group photo';

  @override
  String get premiumRequiredSingleGroupMessage =>
      'Your current plan allows only 1 group. Upgrade to Premium to create or join additional groups.';

  @override
  String get premiumRequiredJoinGroupOnlyMessage =>
      'You are already in a group. Upgrade to Premium to join more groups.';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get contractsTitle => 'Contracts';

  @override
  String contractsForClient(Object client) {
    return 'Contracts for $client';
  }

  @override
  String get contractsEmptyTitle => 'No contracts yet';

  @override
  String get contractsEmptySubtitle =>
      'Upload the first contract for this client.';

  @override
  String get contractsLoadFailedTitle => 'Could not load contracts';

  @override
  String get contractUploadTitle => 'Upload contract';

  @override
  String get contractUploadSubtitle =>
      'Attach a PDF and add the metadata you want to keep on this client.';

  @override
  String get contractEditTitle => 'Edit contract';

  @override
  String get contractEditSubtitle =>
      'Update the contract metadata without re-uploading the PDF.';

  @override
  String get contractUploadAction => 'Upload contract';

  @override
  String get contractUploadSuccess => 'Contract uploaded successfully.';

  @override
  String contractUploadFailed(Object reason) {
    return 'Could not upload the contract: $reason';
  }

  @override
  String get contractUpdateSuccess => 'Contract updated successfully.';

  @override
  String contractUpdateFailed(Object reason) {
    return 'Could not update the contract: $reason';
  }

  @override
  String get contractDeleteTitle => 'Delete contract?';

  @override
  String contractDeleteBody(Object name) {
    return 'Delete contract \"$name\"? This action cannot be undone.';
  }

  @override
  String get contractDeleteSuccess => 'Contract deleted successfully.';

  @override
  String contractDeleteFailed(Object reason) {
    return 'Could not delete the contract: $reason';
  }

  @override
  String get contractMarkedCurrentSuccess => 'Current contract updated.';

  @override
  String get contractOpenFailedGeneric => 'The PDF could not be opened.';

  @override
  String contractOpenFailed(Object reason) {
    return 'Could not open the PDF: $reason';
  }

  @override
  String contractDownloadFailed(Object reason) {
    return 'Could not download the PDF: $reason';
  }

  @override
  String get contractTitleLabel => 'Title';

  @override
  String get contractFileNameLabel => 'File name';

  @override
  String get contractVersionLabel => 'Version';

  @override
  String get contractStatusLabel => 'Status';

  @override
  String get contractRenewalDateLabel => 'Renewal date';

  @override
  String get contractSignedDateLabel => 'Signed date';

  @override
  String get contractNotesLabel => 'Notes';

  @override
  String get contractTagsLabel => 'Tags';

  @override
  String get contractTagsHint => 'Separate tags with commas';

  @override
  String get contractCurrentBadge => 'Current contract';

  @override
  String get contractCurrentHint =>
      'Mark this document as the currently valid contract for the client.';

  @override
  String get contractPickPdf => 'Choose PDF';

  @override
  String get contractNoFileSelected => 'No PDF selected';

  @override
  String get contractPdfOnlyHint => 'PDF files only.';

  @override
  String get contractDropHint => 'Drag a PDF here or click to upload it.';

  @override
  String get contractDropActiveHint => 'Drop the PDF to upload it.';

  @override
  String get contractFileReadError => 'The selected PDF could not be read.';

  @override
  String get contractFileRequired => 'Select a PDF file before continuing.';

  @override
  String get contractViewPdfAction => 'View PDF';

  @override
  String get contractDownloadAction => 'Download';

  @override
  String get contractMarkCurrentAction => 'Mark as current';

  @override
  String get contractUploadedAtLabel => 'Uploaded';

  @override
  String get contractExpiredBadge => 'Expired';

  @override
  String get contractExpiringSoonBadge => 'Expiring soon';

  @override
  String get contractClearDateAction => 'Clear date';

  @override
  String get clientContractTypeLabel => 'Contract type';

  @override
  String get clientContractTypeService => 'Service';

  @override
  String get clientContractTypeMaintenance => 'Maintenance';

  @override
  String get clientContractTypeRental => 'Rental';

  @override
  String get clientContractTypeNda => 'NDA';

  @override
  String get clientContractTypeCustom => 'Other';

  @override
  String get clientContractStatusExpired => 'Expired';

  @override
  String get clientContractStatusTerminated => 'Terminated';

  @override
  String get clientContractStatusArchived => 'Archived';

  @override
  String get statementsNoExpenseSuggestions => 'No matching expenses found';

  @override
  String get statementsSuggestedExpensesTitle => 'Suggested expenses';

  @override
  String get statementsExpenseAlreadyLinkedBadge => 'Already linked';

  @override
  String get statementsExpenseLinkAction => 'Use this expense';

  @override
  String get statementsExpenseOpenManualLink => 'Open manual selector';

  @override
  String get statementsExpenseSuggestionsLoadFailedTitle =>
      'We couldn\'t load suggested expenses';

  @override
  String get statementsExpenseSuggestionsFallbackHint =>
      'You can still link an expense manually.';

  @override
  String get statementsExpenseLinkFailed => 'Could not link the expense.';

  @override
  String get statementsExpenseStatusRegistered => 'Registered';

  @override
  String statementsExpenseAlreadyLinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Already linked to # bank entries',
      one: 'Already linked to # bank entry',
    );
    return '$_temp0';
  }

  @override
  String get rolesTabLabel => 'Roles';

  @override
  String get rolesCurrentRoleLabel => 'Your current role';

  @override
  String get rolesPermissionsUnit => 'permissions';

  @override
  String get rolesGuideTitle => 'Role guide';

  @override
  String get rolesYourRoleBadge => 'Your role';

  @override
  String get rolesLoadError => 'Could not load permissions';

  @override
  String get rolesRetryButton => 'Retry';

  @override
  String get roleFallbackDescOwner =>
      'Full control over the group. Can transfer ownership.';

  @override
  String get roleFallbackDescAdmin =>
      'Can manage members, roles, billing and settings.';

  @override
  String get roleFallbackDescCoAdmin =>
      'Can invite members and manage the calendar and events.';

  @override
  String get roleFallbackDescMember => 'Can view and participate in the group.';

  @override
  String get permLabelInvite => 'Invite';

  @override
  String get permLabelKick => 'Remove members';

  @override
  String get permLabelEditGroup => 'Edit group';

  @override
  String get permLabelDeleteGroup => 'Delete group';

  @override
  String get permLabelManageRoles => 'Manage roles';

  @override
  String get permLabelViewBilling => 'View billing';

  @override
  String get permLabelManageInvoices => 'Invoices';

  @override
  String get permLabelManageBudgets => 'Budgets';

  @override
  String get permLabelViewMembers => 'View members';

  @override
  String get permLabelManageMembers => 'Manage members';

  @override
  String get permLabelSendMessages => 'Messages';

  @override
  String get permLabelViewCalendar => 'View calendar';

  @override
  String get permLabelEditCalendar => 'Edit calendar';

  @override
  String get permLabelManageEvents => 'Events';

  @override
  String get permLabelViewReports => 'Reports';

  @override
  String get permLabelManageSettings => 'Settings';

  @override
  String get permLabelTransferOwnership => 'Transfer ownership';

  @override
  String get permLabelGroup => 'Group';

  @override
  String get permLabelStatements => 'Statements';

  @override
  String get permLabelCalendar => 'Calendar';

  @override
  String get permLabelEvents => 'Events';

  @override
  String get permLabelTimeTracking => 'Time tracking';

  @override
  String get permLabelExpenses => 'Expenses';

  @override
  String get permLabelInvoices => 'Invoices';

  @override
  String get permLabelReports => 'Reports';

  @override
  String get permLabelSettings => 'Settings';

  @override
  String get permLabelMembers => 'Members';

  @override
  String get roleDescOwner =>
      'Full control of the group, members, settings, and shared tools.';

  @override
  String get roleDescAdmin =>
      'Legacy elevated manager role. Treated like a co-admin for frontend guidance.';

  @override
  String get roleDescCoAdmin =>
      'Can manage most shared group operations, but cannot delete the group or outrank the owner.';

  @override
  String get roleDescMember =>
      'Can view shared group data and manage only their own allowed actions.';

  @override
  String get expenseJsonTabFlowHint =>
      'Paste the JSON and attach the invoice to import.';

  @override
  String get expenseJsonTabPickJsonFile => 'JSON file';

  @override
  String get expenseJsonTabPickInvoiceFile => 'Invoice file';

  @override
  String get expenseJsonTabGetAiPrompt => 'Get AI Prompt';

  @override
  String get expenseJsonTabGeneratingPrompt => 'Generating AI prompt...';

  @override
  String get expenseJsonTabPromptLabel => 'AI PROMPT';

  @override
  String get expenseJsonTabCopyPrompt => 'Copy';

  @override
  String get expenseJsonTabPayloadLabel => 'JSON Payload';

  @override
  String get expenseJsonTabPayloadHint => 'Paste the invoice JSON here...';

  @override
  String get expenseJsonTabAdvancedOptions => 'ADVANCED OPTIONS';

  @override
  String get expenseJsonTabSectionExpenseType => 'Expense type';

  @override
  String get expenseJsonTabSectionDiscount => 'Global discount';

  @override
  String get expenseJsonTabSectionTotal => 'Document total';

  @override
  String get expenseJsonTabImportCta => 'Import JSON';

  @override
  String get expenseJsonTabImportHint =>
      'Requires JSON and attached invoice file.';

  @override
  String get expenseJsonLeftTitle => 'JSON Import';

  @override
  String get expenseJsonLeftSubtitle =>
      'Load the JSON, attach the invoice and review the payload on the right panel.';

  @override
  String get expenseJsonLeftDropActive => 'Drop the JSON or invoice';

  @override
  String get expenseJsonLeftDropHint => 'Drag the JSON or invoice here';

  @override
  String get expenseJsonLeftFileTypes => 'JSON / PDF / JPG / JPEG / PNG / WEBP';

  @override
  String get expenseJsonLeftPickJson => 'Select JSON';

  @override
  String get expenseJsonLeftPickInvoice => 'Attach invoice';

  @override
  String get expenseJsonLeftPromptTitle => 'AI Prompt';

  @override
  String get expenseJsonLeftPromptAvailable => 'Available';

  @override
  String get expenseJsonLeftPromptGenerate => 'Generate template';

  @override
  String get expenseJsonLeftPromptTooltip => 'Get AI prompt';

  @override
  String get expenseJsonLeftCopyPromptTooltip => 'Copy prompt';

  @override
  String get expenseJsonLeftSummaryTitle => 'Summary';

  @override
  String get expenseJsonLeftJsonPending => 'JSON pending';

  @override
  String get expenseJsonLeftInvoicePending => 'Invoice pending';

  @override
  String get expenseBatchLeftTitle => 'Import documents';

  @override
  String get expenseBatchLeftSubtitle =>
      'Select the PDFs or images to process. The full list and issues are shown in the right panel.';

  @override
  String get expenseBatchLeftDropActive => 'Drop documents to load them';

  @override
  String get expenseBatchLeftDropHint => 'Drag your documents here';

  @override
  String get expenseBatchLeftFileTypes => 'PDF / JPG / JPEG / PNG / WEBP';

  @override
  String get expenseBatchLeftPickCta => 'Select documents';

  @override
  String get expenseBatchLeftProcessing => 'Processing batch...';

  @override
  String expenseBatchLeftSelected(int count) {
    return '$count documents selected';
  }

  @override
  String expenseBatchLeftCapacity(int selected, int max) {
    return 'Capacity: $selected / $max';
  }

  @override
  String expenseBatchLeftTotalSize(String size) {
    return 'Total size: $size';
  }

  @override
  String expenseBatchLeftSlots(int slots) {
    return 'Available slots: $slots';
  }

  @override
  String get expenseBatchLeftClearCta => 'Clear selection';

  @override
  String get expenseBatchLeftCompleted => 'Batch completed';

  @override
  String get expenseBatchLeftImportCta => 'Import expenses';

  @override
  String get expenseBatchLeftGroupRequired =>
      'Select a group before importing.';

  @override
  String get expenseBatchProgressCompleted => 'Import completed';

  @override
  String get expenseBatchProgressFailed => 'Import failed';

  @override
  String get expenseBatchProgressQueued => 'Import queued';

  @override
  String get expenseBatchProgressProcessing => 'Processing batch';

  @override
  String get expenseBatchStatProcessed => 'Processed';

  @override
  String get expenseBatchStatImported => 'Imported';

  @override
  String get expenseBatchStatIssues => 'With issues';

  @override
  String get expenseBatchStatResult => 'Result';

  @override
  String get expenseBatchStatLoading => 'Loading...';

  @override
  String expenseBatchHeaderSlotsFree(int count) {
    return '$count free';
  }

  @override
  String get expenseBatchProgressBackgroundHint =>
      'You can leave this screen while the import completes.';

  @override
  String get expenseBatchListTitle => 'Loaded files';

  @override
  String expenseBatchListCount(int count) {
    return '$count file(s)';
  }

  @override
  String get expenseBatchListFilterAll => 'All';

  @override
  String get expenseBatchListFilterReady => 'Ready';

  @override
  String get expenseBatchListFilterIssues => 'Issues';

  @override
  String expenseBatchListRemoveWarnings(int count) {
    return 'Remove $count';
  }

  @override
  String get expenseBatchListEmpty => 'No files match this filter yet.';

  @override
  String get expenseBatchListRemoveTooltip => 'Remove from selection';

  @override
  String expenseBatchDocListFiles(int count) {
    return '$count files';
  }

  @override
  String get expenseBatchDocListAlreadyUploaded => 'Already uploaded';

  @override
  String expenseBatchDocListDuplicates(int count) {
    return '$count already uploaded';
  }

  @override
  String get expenseBatchDocListClearAll => 'Clear all';

  @override
  String get expenseBatchDocListRemove => 'Remove';

  @override
  String get expenseBatchErrorCopyList => 'Copy list';

  @override
  String get expenseTotalsUseSummaryLabel => 'Use document summary';

  @override
  String get expenseTotalsSummaryMode => 'Totals extracted from summary';

  @override
  String get expenseTotalsCalculateMode => 'Calculate from lines';

  @override
  String get expenseTotalsSummaryHelp =>
      'The VAT for this document appears in the summary at the bottom of the ticket/invoice. It is not necessary for each line to show VAT separately.';

  @override
  String get expenseTotalsLockToLinesHelp =>
      'Base, VAT and total are calculated from the lines and discounts. Enable summary if the document only shows VAT in the footer.';

  @override
  String get expenseTotalsDirectReviewHelp =>
      'You can review the document totals directly from this block.';

  @override
  String get expenseTotalsTaxableBase => 'Taxable base';

  @override
  String get expenseTotalsTax => 'Total VAT';

  @override
  String get expenseTotalsTotal => 'Total document';

  @override
  String get suspectExpensesMenuLabel => 'Suspect expenses';

  @override
  String get suspectExpensesTitle => 'Suspect expenses';

  @override
  String get suspectExpensesScanned => 'Scanned';

  @override
  String get suspectExpensesCount => 'Suspects';

  @override
  String get suspectExpensesFilterResults => 'Filter results';

  @override
  String get suspectExpensesShown => 'Shown suspects';

  @override
  String get suspectExpensesEmpty =>
      'No suspect expenses found for this filter.';

  @override
  String get suspectExpensesEmptyUnreviewed =>
      'No unreviewed suspect expenses found.';

  @override
  String get suspectExpensesEmptyConfirmedOk =>
      'No expenses are marked as confirmed correct.';

  @override
  String get suspectExpensesEmptyNeedsFix =>
      'No expenses are marked as needs correction.';

  @override
  String get suspectExpensesFilterAll => 'All';

  @override
  String get suspectExpensesFilterUnreviewed => 'Unreviewed';

  @override
  String get suspectExpensesFilterConfirmedOk => 'Confirmed OK';

  @override
  String get suspectExpensesFilterNeedsFix => 'Needs Fix';

  @override
  String get suspectExpensesStatusUnreviewed => 'Unreviewed';

  @override
  String get suspectExpensesStatusConfirmedOk => 'Confirmed OK';

  @override
  String get suspectExpensesStatusNeedsFix => 'Needs Fix';

  @override
  String get suspectExpensesStoredLabel => 'Stored';

  @override
  String get suspectExpensesDerivedLabel => 'Derived';

  @override
  String get suspectExpensesStoredSubtotal => 'Subtotal';

  @override
  String get suspectExpensesStoredTax => 'VAT';

  @override
  String get suspectExpensesStoredTotal => 'Total';

  @override
  String get suspectExpensesReasons => 'Detected reasons';

  @override
  String get suspectExpensesActionConfirmOk => 'Mark as correct';

  @override
  String get suspectExpensesActionNeedsFix => 'Mark for fix';

  @override
  String get suspectExpensesActionReset => 'Reset review';

  @override
  String get suspectExpensesNotes => 'Notes';

  @override
  String get suspectExpensesNotesHint => 'Add a note before saving…';

  @override
  String get suspectExpensesUploadedAt => 'Uploaded';

  @override
  String get notificationBankExpensesDetectedTitle => 'Bank expenses detected';

  @override
  String notificationBankExpensesDetectedMessage(int count, String amount) {
    return '$count bank expenses totaling $amount were detected.';
  }

  @override
  String get invoiceCreateMobileComingSoonSnack =>
      'Create invoice on mobile will be available soon.';

  @override
  String get invoiceExportConceptsExcelFailed =>
      'Could not export invoice concepts to Excel.';

  @override
  String get receiptJsonImportDraftOnlySnack =>
      'Only draft receipts can be updated via JSON import.';

  @override
  String receiptJsonImportSuccessSnack(Object count) {
    return 'Imported $count lines.';
  }

  @override
  String get budgetDeletedSnack => 'Budget deleted.';

  @override
  String get budgetAdvanceInvoiceCreatedSnack =>
      'Advance invoice created successfully (70%).';

  @override
  String get budgetAdvanceInvoiceCreatedSimpleSnack =>
      'Advance invoice created successfully.';

  @override
  String get budgetFinalInvoiceCreatedSnack =>
      'Final invoice created successfully.';

  @override
  String get budgetConvertedToInvoiceSnack => 'Invoice created from budget.';

  @override
  String get chatComposerHintMessage => 'Write a message…';

  @override
  String get chatComposerHintReply => 'Write a reply…';

  @override
  String get chatComposerHintCaption => 'Add a caption…';

  @override
  String get chatComposerHintBody => 'Enter sends · Shift+Enter new line';

  @override
  String get chatComposerHintAttachment =>
      'Attachment ready · use the text box as a caption';

  @override
  String get chatComposerAttachFile => 'Local file';

  @override
  String get chatComposerAttachClientPdf => 'Client PDF';

  @override
  String get chatComposerAttachWorkerPdf => 'Worker-hours PDF';

  @override
  String get chatComposerSend => 'Send';

  @override
  String get chatComposerSendFile => 'Send file';

  @override
  String get chatComposerSending => 'Sending…';

  @override
  String get chatComposerUploading => 'Uploading…';

  @override
  String get chatComposerRetry => 'Retry';

  @override
  String get telegramSearchChats => 'Search chats…';

  @override
  String get telegramMenuChats => 'Chats';

  @override
  String get telegramMenuExports => 'Exports';

  @override
  String get telegramMenuAccount => 'Account';

  @override
  String get telegramMenuDisconnect => 'Disconnect';

  @override
  String get telegramFilterAll => 'All';

  @override
  String get telegramFilterGroups => 'Groups';

  @override
  String get telegramFilterChannels => 'Channels';

  @override
  String get telegramFilterPrivate => 'Private';

  @override
  String telegramNoChatsMatch(String query) {
    return 'No chats match \"$query\"';
  }

  @override
  String get telegramNoChatsAvailable => 'No Telegram chats available';

  @override
  String get telegramClearSearch => 'Clear search';

  @override
  String get telegramMainChatsSection => 'Main Chats';

  @override
  String get telegramNoMainChatsInfo =>
      'No chats in the main list. Archived chats are available below.';

  @override
  String get telegramArchivedChats => 'Archived Chats';

  @override
  String get telegramChatsLoadError => 'Failed to load chats';

  @override
  String get telegramRetry => 'Retry';

  @override
  String get telegramTopics => 'Topics';

  @override
  String telegramBrowseTopicsIn(String chat) {
    return 'Browse forum topics inside $chat.';
  }

  @override
  String get telegramSearchTopics => 'Search topics…';

  @override
  String get telegramGeneralTopic => 'General topic';

  @override
  String get telegramHiddenTopic => 'Hidden topic';

  @override
  String get telegramForumTopicLabel => 'Forum topic';

  @override
  String get telegramNoTopicsMatch => 'No topics match your search';

  @override
  String get telegramNoTopicsFound => 'No forum topics found';

  @override
  String get telegramNoTopicsMatchBody =>
      'Try a different name or clear the search.';

  @override
  String get telegramNoTopicsFoundBody =>
      'This forum has no visible topics yet.';

  @override
  String get telegramToday => 'Today';

  @override
  String get telegramYesterday => 'Yesterday';

  @override
  String get telegramLoadOlder => 'Load older';

  @override
  String get telegramBeginningOfHistory => 'Beginning of history';

  @override
  String get telegramNoMessagesYet => 'No messages loaded yet';

  @override
  String get telegramNoMessagesTip =>
      'Try refreshing this chat or loading older history.';

  @override
  String get telegramSelectChatTitle => 'Select a chat to start reading';

  @override
  String get telegramSelectChatBody =>
      'Choose a Telegram chat from the list to load recent messages, browse history, and export it.';

  @override
  String get telegramFailedToLoadMessages => 'Failed to load messages';

  @override
  String get telegramRefresh => 'Refresh';

  @override
  String get telegramExport => 'Export';

  @override
  String get telegramEdited => 'edited';

  @override
  String telegramForwardedFrom(String source) {
    return 'Forwarded from $source';
  }

  @override
  String get telegramForwardedMessage => 'Forwarded message';

  @override
  String telegramReplyingTo(String sender) {
    return 'Replying to $sender';
  }

  @override
  String telegramReplyTo(String id) {
    return 'Reply to #$id';
  }

  @override
  String get telegramClearReply => 'Clear reply';

  @override
  String get telegramRemoveAttachment => 'Remove attachment';

  @override
  String get telegramReply => 'Reply';

  @override
  String get telegramReplying => 'Replying';

  @override
  String get telegramPreviewPdf => 'Preview PDF';

  @override
  String get telegramDownloadDocument => 'Download document';

  @override
  String get telegramClose => 'Close';

  @override
  String telegramTopicSubtitle(String name) {
    return 'Topic · $name';
  }

  @override
  String get telegramCouldNotReadFile => 'Could not read the selected file.';

  @override
  String get telegramNeedGroupClientPdf =>
      'A group must be selected before attaching client PDFs.';

  @override
  String get telegramNeedGroupWorkerPdf =>
      'A group must be selected before attaching worker PDFs.';

  @override
  String get telegramCouldNotOpenPdf => 'Could not open the PDF preview.';

  @override
  String get telegramCouldNotDownload => 'Could not download this document.';

  @override
  String get back => 'Back';

  @override
  String get issueInvoice => 'Issue invoice';

  @override
  String get invoiceActionsTitle => 'Actions';

  @override
  String get invoicePdfPreviewTitle => 'PDF preview';

  @override
  String get invoicePdfGenerated => 'Generated';

  @override
  String get invoicePdfReadyToPreview => 'PDF is ready to preview';

  @override
  String get invoiceSaveDraftToPreview =>
      'Save draft to generate a PDF preview';

  @override
  String get invoicePdfOpenPreview => 'Open preview';

  @override
  String get invoicePreviewTitle => 'Preview';

  @override
  String get invoicePreviewNoNotes => 'No notes';

  @override
  String invoicePreviewLinesCount(int count) {
    return 'Lines: $count';
  }

  @override
  String invoicePreviewTotalLabel(String amount) {
    return 'Total: $amount';
  }

  @override
  String get invoiceDraftPdfDialogTitle => 'Download Draft PDF';

  @override
  String get invoiceDraftPdfDialogContent =>
      'Generate a PDF preview of this draft invoice.';

  @override
  String get invoiceDraftPreviewInBrowser => 'Preview in Browser';

  @override
  String get invoiceDraftDownloadPdf => 'Download PDF';

  @override
  String get invoiceDeliveryStatusUpdated => 'Delivery status updated';

  @override
  String get invoiceMarkedUnsent => 'Invoice marked as unsent';

  @override
  String get invoiceDeliveryOnlyIssued =>
      'Delivery can only be marked on issued invoices.';

  @override
  String get invoiceDeliveryUpdateError => 'Could not update delivery status.';

  @override
  String get invoiceReviewPdfBeforeDraft =>
      'Review the PDF preview before saving the draft.';

  @override
  String get invoiceStepClientShort => 'Client';

  @override
  String get invoiceStepLinesShort => 'Lines';

  @override
  String get invoiceStepDraftShort => 'Draft';

  @override
  String get notificationRecurringDraftInvoiceCreatedTitle =>
      'Recurring draft invoice created';

  @override
  String notificationRecurringDraftInvoiceCreatedMessage(
      String clientName, String recurrenceName, String amount) {
    return 'A draft invoice for $clientName was created from recurrence \"$recurrenceName\" for $amount.';
  }

  @override
  String notificationRecurringDraftInvoiceCreatedMessageNoAmount(
      String clientName, String recurrenceName) {
    return 'A draft invoice for $clientName was created from recurrence \"$recurrenceName\".';
  }

  @override
  String get notificationRecurringDraftInvoiceCreatedMessageFallback =>
      'A recurring draft invoice was created.';
}
