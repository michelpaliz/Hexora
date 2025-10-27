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
  String get registrationError => 'Registration error';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongCredentials => 'Wrong credentials';

  @override
  String get authError => 'Authentication error';

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
  String get noGroupsAvailable => 'NO GROUP/S FOUND/S';

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
  String get noUpcomingHint => 'Try another category or extend the range.';

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
  String get saveChanges => 'Save Changes';

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
  String get currencyLabel => 'Currency';

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
  String get notesLabel => 'Notes';

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
  String get selectMonthPrompt => 'Please select a month to view entries.';

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
}
