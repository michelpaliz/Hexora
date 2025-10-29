import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @groupData.
  ///
  /// In en, this message translates to:
  /// **'Group Data'**
  String get groupData;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// The current language
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get language;

  /// Change View
  ///
  /// In en, this message translates to:
  /// **'Change the view'**
  String get changeView;

  /// No description provided for @welcomeGroupView.
  ///
  /// In en, this message translates to:
  /// **'Welcome {username} here you can see the list of groups that you are part of.'**
  String welcomeGroupView(Object username);

  /// No description provided for @zeroNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get zeroNotifications;

  /// No description provided for @goToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Go to the calendar'**
  String get goToCalendar;

  /// Note form
  ///
  /// In en, this message translates to:
  /// **'Group name (max {maxChar} characters)  '**
  String groupName(int maxChar);

  /// Note form
  ///
  /// In en, this message translates to:
  /// **'Group description (max {maxChar} characters)  '**
  String groupDescription(int maxChar);

  /// No description provided for @addPplGroup.
  ///
  /// In en, this message translates to:
  /// **'Add people to your group'**
  String get addPplGroup;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUser;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @coAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Co-Administrator'**
  String get coAdministrator;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @saveGroup.
  ///
  /// In en, this message translates to:
  /// **'Save the group'**
  String get saveGroup;

  /// No description provided for @addImageGroup.
  ///
  /// In en, this message translates to:
  /// **'Add image for the group'**
  String get addImageGroup;

  /// No description provided for @removeEvent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this event ?'**
  String get removeEvent;

  /// No description provided for @removeGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this group ?'**
  String get removeGroup;

  /// No description provided for @removeCalendar.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this calendar ?'**
  String get removeCalendar;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully!'**
  String get groupCreated;

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create the group'**
  String get failedToCreateGroup;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'The event has been created'**
  String get eventCreated;

  /// No description provided for @eventEdited.
  ///
  /// In en, this message translates to:
  /// **'The event has been edited'**
  String get eventEdited;

  /// No description provided for @eventAddedGroup.
  ///
  /// In en, this message translates to:
  /// **'The event has been added to the group'**
  String get eventAddedGroup;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @chooseEventColor.
  ///
  /// In en, this message translates to:
  /// **'Choose the color of the event:'**
  String get chooseEventColor;

  /// No description provided for @errorEventNote.
  ///
  /// In en, this message translates to:
  /// **'Event note cannot be empty!'**
  String get errorEventNote;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get userName;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Insert your current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your current password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @userNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username (e.g., john_doe123)'**
  String get userNameHint;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce your email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get confirmPasswordHint;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out ?'**
  String get logoutMessage;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New password and confirmation password do not match.'**
  String get passwordNotMatch;

  /// No description provided for @userNameTaken.
  ///
  /// In en, this message translates to:
  /// **'The user name is already taken'**
  String get userNameTaken;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak Password'**
  String get weakPassword;

  /// No description provided for @emailTaken.
  ///
  /// In en, this message translates to:
  /// **'The email is already taken'**
  String get emailTaken;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'This is an invalid email address'**
  String get invalidEmail;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registrationError;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong credentials'**
  String get wrongCredentials;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authError;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered yet?, Don\'t worry register here.'**
  String get notRegistered;

  /// No description provided for @alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already registered?, Login here.'**
  String get alreadyRegistered;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title (max {maxChar} characters)  '**
  String title(Object maxChar);

  /// Description form
  ///
  /// In en, this message translates to:
  /// **'Description (max {maxChar} characters)  '**
  String description(int maxChar);

  /// Note form
  ///
  /// In en, this message translates to:
  /// **'Note (max {maxChar} characters)  '**
  String note(int maxChar);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @repetitionEvent.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Start Date\''**
  String get repetitionEvent;

  /// No description provided for @repetitionEventInfo.
  ///
  /// In en, this message translates to:
  /// **'An event with the same start hour and day already exists.'**
  String get repetitionEventInfo;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @repetitionDetails.
  ///
  /// In en, this message translates to:
  /// **'Repetition details'**
  String get repetitionDetails;

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'This event will repeat every {concurrenceDay} day'**
  String dailyRepetitionInf(int concurrenceDay);

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'Every:'**
  String get every;

  /// No description provided for @dailys.
  ///
  /// In en, this message translates to:
  /// **'daily(s)'**
  String get dailys;

  /// No description provided for @weeklys.
  ///
  /// In en, this message translates to:
  /// **'weekly(s)'**
  String get weeklys;

  /// No description provided for @monthlies.
  ///
  /// In en, this message translates to:
  /// **'monthly(s)'**
  String get monthlies;

  /// No description provided for @yearlys.
  ///
  /// In en, this message translates to:
  /// **'year(s)'**
  String get yearlys;

  /// No description provided for @untilDate.
  ///
  /// In en, this message translates to:
  /// **'Until Date: '**
  String get untilDate;

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'Until Date: {untilDate} '**
  String untilDateSelected(String untilDate);

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected'**
  String get notSelected;

  /// No description provided for @utilDateNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Until Date: Not Selected'**
  String get utilDateNotSelected;

  /// No description provided for @specifyRepeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Please specify repeat interval'**
  String get specifyRepeatInterval;

  /// No description provided for @selectOneDayAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day of the week.'**
  String get selectOneDayAtLeast;

  /// No description provided for @datesMustBeSame.
  ///
  /// In en, this message translates to:
  /// **'Start and end dates must be the same day for the event to repeat'**
  String get datesMustBeSame;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date: '**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date: '**
  String get endDate;

  /// No description provided for @noDaysSelected.
  ///
  /// In en, this message translates to:
  /// **'No Days Selected'**
  String get noDaysSelected;

  /// No description provided for @selectRepetition.
  ///
  /// In en, this message translates to:
  /// **'Select repetition'**
  String get selectRepetition;

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select Day: '**
  String get selectDay;

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'This event will repeat every {concurrenceWeeks} day.'**
  String dayRepetitionInf(int concurrenceWeeks);

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'This event will repeat every {concurrenceWeeks} week(s) on {customDaysOfWeekString}, and {lastDay} '**
  String weeklyRepetitionInf(
      int concurrenceWeeks,
      String customDaysOfWeeksString,
      String lastDay,
      Object customDaysOfWeekString);

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'This event will repeat every {repeatInterval} week(s) on \${selectedDayNames}'**
  String weeklyRepetitionInf1(int repeatInterval, String selectedDayNames);

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'The day of the event is {selectedDays} should coincide with one of the selected day/s.'**
  String errorSelectedDays(String selectedDays);

  /// Textfield for the group name
  ///
  /// In en, this message translates to:
  /// **'Enter group name (Limit: {TITLE_MAX_LENGHT} characters) '**
  String textFieldGroupName(int TITLE_MAX_LENGHT);

  /// Textfield for the group description
  ///
  /// In en, this message translates to:
  /// **'Enter group description (Limit: {DESCRIPTION_MAX_LENGHT} characters)'**
  String textFieldDescription(int DESCRIPTION_MAX_LENGHT);

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'This event will repeat on the {selectDay} day every {repeatInterval} month(s) '**
  String monthlyRepetitionInf(
      String selectedDay, int repeatInterval, Object selectDay);

  /// Concurrence for the event
  ///
  /// In en, this message translates to:
  /// **'This event will repeat on the {selectDay} day every {repeatInterval} year(s) '**
  String yearlyRepetitionInf(
      String selectedDay, int repeatInterval, Object selectDay);

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @removeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm to remove'**
  String get removeConfirmation;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedInf.
  ///
  /// In en, this message translates to:
  /// **'You are not an administrator to remove this item.'**
  String get permissionDeniedInf;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @permissionDeniedRole.
  ///
  /// In en, this message translates to:
  /// **'You are currently a {role} of this group.'**
  String permissionDeniedRole(Object role);

  /// No description provided for @putGroupImage.
  ///
  /// In en, this message translates to:
  /// **'Put an image for the group'**
  String get putGroupImage;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get close;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add a new user to your group'**
  String get addNewUser;

  /// No description provided for @cannotRemoveYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot remove yourself from the group'**
  String get cannotRemoveYourself;

  /// No description provided for @requiredTextFields.
  ///
  /// In en, this message translates to:
  /// **'Group name and description are required.'**
  String get requiredTextFields;

  /// No description provided for @groupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name cannot be empty'**
  String get groupNameRequired;

  /// No description provided for @groupEdited.
  ///
  /// In en, this message translates to:
  /// **'Group edited successfully!'**
  String get groupEdited;

  /// No description provided for @failedToEditGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit the group. Please try again'**
  String get failedToEditGroup;

  /// No description provided for @searchPerson.
  ///
  /// In en, this message translates to:
  /// **'Search by user name'**
  String get searchPerson;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmRemovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group?'**
  String get confirmRemovalMessage;

  /// No description provided for @confirmRemoval.
  ///
  /// In en, this message translates to:
  /// **'Confirm Removal'**
  String get confirmRemoval;

  /// No description provided for @groupDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group deleted successfully!'**
  String get groupDeletedSuccessfully;

  /// No description provided for @noGroupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'NO GROUP/S FOUND/S'**
  String get noGroupsAvailable;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'sunday'**
  String get sunday;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get save;

  /// No description provided for @groupNameText.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameText;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Group owner'**
  String get groupOwner;

  /// No description provided for @enableRepetitiveEvents.
  ///
  /// In en, this message translates to:
  /// **'Enable repetitive events'**
  String get enableRepetitiveEvents;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect. Please try again.'**
  String get currentPasswordIncorrect;

  /// No description provided for @newPasswordConfirmationError.
  ///
  /// In en, this message translates to:
  /// **'New password and confirmation password do not match.'**
  String get newPasswordConfirmationError;

  /// No description provided for @changedPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password. Please try again'**
  String get changedPasswordError;

  /// No description provided for @passwordContainsUnwantedChar.
  ///
  /// In en, this message translates to:
  /// **'Password contains unwanted characters.'**
  String get passwordContainsUnwantedChar;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change your username'**
  String get changeUsername;

  /// No description provided for @successChangingUsername.
  ///
  /// In en, this message translates to:
  /// **'Username updated successfully!'**
  String get successChangingUsername;

  /// No description provided for @usernameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken. Choose a different one.'**
  String get usernameAlreadyTaken;

  /// No description provided for @errorUnwantedCharactersUsername.
  ///
  /// In en, this message translates to:
  /// **'Invalid characters in the username. Please use only alphanumeric characters and underscores.'**
  String get errorUnwantedCharactersUsername;

  /// No description provided for @errorChangingUsername.
  ///
  /// In en, this message translates to:
  /// **'Error changing username. Please try again later.'**
  String get errorChangingUsername;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password. Please try again.'**
  String get errorChangingPassword;

  /// No description provided for @errorUsernameLength.
  ///
  /// In en, this message translates to:
  /// **'Error Username should be between 6 char and 10 char '**
  String get errorUsernameLength;

  /// No description provided for @formatDate.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String formatDate(Object date);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Recover here your password.'**
  String get forgotPassword;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @userNameRequired.
  ///
  /// In en, this message translates to:
  /// **'User name is required'**
  String get userNameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Password maximum length is 6 characters'**
  String get passwordLength;

  /// No description provided for @groupNotCreated.
  ///
  /// In en, this message translates to:
  /// **'There was an error creating the group, try again'**
  String get groupNotCreated;

  /// No description provided for @questionDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group?'**
  String get questionDeleteGroup;

  /// No description provided for @errorEventCreation.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while creating the event, try again later'**
  String get errorEventCreation;

  /// No description provided for @eventEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while editing the event, try again later'**
  String get eventEditFailed;

  /// No description provided for @noEventsFoundForDate.
  ///
  /// In en, this message translates to:
  /// **'Events not found for this date, try again later.'**
  String get noEventsFoundForDate;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this event ?'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove event.'**
  String get confirmDeleteDescription;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupNameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refreshing screen ...'**
  String get refresh;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @notAccepted.
  ///
  /// In en, this message translates to:
  /// **'NotAccepted'**
  String get notAccepted;

  /// No description provided for @newUsers.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newUsers;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// Error shown when a user action requires being signed in
  ///
  /// In en, this message translates to:
  /// **'User is not signed in.'**
  String get userNotSignedIn;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created On'**
  String get createdOn;

  /// No description provided for @userCount.
  ///
  /// In en, this message translates to:
  /// **'User Count'**
  String get userCount;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String timeMinutesAgo(Object minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String timeHoursAgo(Object hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(Object days);

  /// No description provided for @timeLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get timeLast30Days;

  /// No description provided for @groupRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get groupRecent;

  /// No description provided for @groupLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get groupLast7Days;

  /// No description provided for @groupLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get groupLast30Days;

  /// No description provided for @groupOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get groupOlder;

  /// No description provided for @notificationGroupCreationTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get notificationGroupCreationTitle;

  /// No description provided for @notificationGroupCreationMessage.
  ///
  /// In en, this message translates to:
  /// **'You created the group: {groupName}'**
  String notificationGroupCreationMessage(Object groupName);

  /// No description provided for @notificationJoinedGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Group'**
  String get notificationJoinedGroupTitle;

  /// No description provided for @notificationJoinedGroupMessage.
  ///
  /// In en, this message translates to:
  /// **'You have joined the group: {groupName}'**
  String notificationJoinedGroupMessage(Object groupName);

  /// No description provided for @notificationInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Invitation'**
  String get notificationInvitationTitle;

  /// No description provided for @notificationInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to join the group: {groupName}'**
  String notificationInvitationMessage(Object groupName);

  /// No description provided for @notificationInvitationDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation Declined'**
  String get notificationInvitationDeniedTitle;

  /// No description provided for @notificationInvitationDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'{userName} declined the invitation to join {groupName}'**
  String notificationInvitationDeniedMessage(Object groupName, Object userName);

  /// No description provided for @notificationUserAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'User Joined'**
  String get notificationUserAcceptedTitle;

  /// No description provided for @notificationUserAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'{userName} has accepted the invitation to join {groupName}'**
  String notificationUserAcceptedMessage(Object groupName, Object userName);

  /// No description provided for @notificationGroupEditedTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Updated'**
  String get notificationGroupEditedTitle;

  /// No description provided for @notificationGroupEditedMessage.
  ///
  /// In en, this message translates to:
  /// **'You updated the group: {groupName}'**
  String notificationGroupEditedMessage(Object groupName);

  /// No description provided for @notificationGroupDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Deleted'**
  String get notificationGroupDeletedTitle;

  /// No description provided for @notificationGroupDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have deleted the group: {groupName}'**
  String notificationGroupDeletedMessage(Object groupName);

  /// No description provided for @notificationUserRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'User Removed'**
  String get notificationUserRemovedTitle;

  /// No description provided for @notificationUserRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from {groupName} by {adminName}'**
  String notificationUserRemovedMessage(Object adminName, Object groupName);

  /// No description provided for @notificationAdminUserRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'User Removed'**
  String get notificationAdminUserRemovedTitle;

  /// No description provided for @notificationAdminUserRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'{userName} was removed from {groupName}'**
  String notificationAdminUserRemovedMessage(Object groupName, Object userName);

  /// No description provided for @notificationUserLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'User Left'**
  String get notificationUserLeftTitle;

  /// No description provided for @notificationUserLeftMessage.
  ///
  /// In en, this message translates to:
  /// **'{userName} has left the group: {groupName}'**
  String notificationUserLeftMessage(Object groupName, Object userName);

  /// No description provided for @notificationGroupUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Updated'**
  String get notificationGroupUpdateTitle;

  /// No description provided for @notificationGroupUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'{editorName} updated the group: {groupName}'**
  String notificationGroupUpdateMessage(Object editorName, Object groupName);

  /// No description provided for @notificationGroupDeletedAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Deleted'**
  String get notificationGroupDeletedAllTitle;

  /// No description provided for @notificationGroupDeletedAllMessage.
  ///
  /// In en, this message translates to:
  /// **'The group \"{groupName}\" has been deleted by the owner.'**
  String notificationGroupDeletedAllMessage(Object groupName);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// Shown as a warning when a user selects weekly recurrence days that do not include the event's start day
  ///
  /// In en, this message translates to:
  /// **'Warning: The event starts on {day}, but this day is not selected in the recurrence pattern.'**
  String eventDayNotIncludedWarning(String day);

  /// No description provided for @removeRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Remove Recurrence'**
  String get removeRecurrence;

  /// No description provided for @removeRecurrenceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the recurrence rule?'**
  String get removeRecurrenceConfirm;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @reminderHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose when to be reminded'**
  String get reminderHelper;

  /// No description provided for @reminderOptionAtTime.
  ///
  /// In en, this message translates to:
  /// **'At time of event'**
  String get reminderOptionAtTime;

  /// No description provided for @reminderOption5min.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get reminderOption5min;

  /// No description provided for @reminderOption10min.
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get reminderOption10min;

  /// No description provided for @reminderOption30min.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get reminderOption30min;

  /// No description provided for @reminderOption1hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminderOption1hour;

  /// No description provided for @reminderOption2hours.
  ///
  /// In en, this message translates to:
  /// **'2 hours before'**
  String get reminderOption2hours;

  /// No description provided for @reminderOption1day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get reminderOption1day;

  /// No description provided for @reminderOption2days.
  ///
  /// In en, this message translates to:
  /// **'2 days before'**
  String get reminderOption2days;

  /// No description provided for @reminderOption3days.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get reminderOption3days;

  /// No description provided for @saveChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get saveChangesMessage;

  /// No description provided for @createEventMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating event...'**
  String get createEventMessage;

  /// No description provided for @dialogSelectUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Select users for this event'**
  String get dialogSelectUsersTitle;

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// No description provided for @dialogShowUsers.
  ///
  /// In en, this message translates to:
  /// **'Show User Selection'**
  String get dialogShowUsers;

  /// No description provided for @repeatEventLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat Event:'**
  String get repeatEventLabel;

  /// No description provided for @repeatYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get repeatYes;

  /// No description provided for @repeatNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get repeatNo;

  /// No description provided for @notificationEventReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Reminder'**
  String get notificationEventReminderTitle;

  /// No description provided for @notificationEventReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder: \"{eventTitle}\" is coming up soon.'**
  String notificationEventReminderMessage(Object eventTitle);

  /// No description provided for @userDropdownSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Users'**
  String get userDropdownSelect;

  /// No description provided for @noUsersSelected.
  ///
  /// In en, this message translates to:
  /// **'No users selected.'**
  String get noUsersSelected;

  /// No description provided for @noUserRolesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No user roles available'**
  String get noUserRolesAvailable;

  /// No description provided for @userExpandableCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Users'**
  String get userExpandableCardTitle;

  /// No description provided for @eventDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetailsTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventTitleHint;

  /// No description provided for @eventStartDateHint.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get eventStartDateHint;

  /// No description provided for @eventEndDateHint.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get eventEndDateHint;

  /// No description provided for @eventLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get eventLocationHint;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventDescriptionHint;

  /// No description provided for @eventNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get eventNoteHint;

  /// No description provided for @eventRecurrenceHint.
  ///
  /// In en, this message translates to:
  /// **'Recurrence Rule'**
  String get eventRecurrenceHint;

  /// No description provided for @notificationEventCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Created'**
  String get notificationEventCreatedTitle;

  /// Message shown when an event is created
  ///
  /// In en, this message translates to:
  /// **'An event \"{eventTitle}\" has been created.'**
  String notificationEventCreatedMessage(String eventTitle);

  /// No description provided for @notificationEventUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Updated'**
  String get notificationEventUpdatedTitle;

  /// Message shown when an event is updated
  ///
  /// In en, this message translates to:
  /// **'The event \"{eventTitle}\" has been updated.'**
  String notificationEventUpdatedMessage(String eventTitle);

  /// No description provided for @notificationEventDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Deleted'**
  String get notificationEventDeletedTitle;

  /// Message shown when an event is deleted
  ///
  /// In en, this message translates to:
  /// **'The event \"{eventTitle}\" has been removed.'**
  String notificationEventDeletedMessage(String eventTitle);

  /// No description provided for @notificationRecurrenceAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Event'**
  String get notificationRecurrenceAddedTitle;

  /// Shown when a recurrence rule is added to an event
  ///
  /// In en, this message translates to:
  /// **'The event \"{title}\" is now recurring.'**
  String notificationRecurrenceAddedMessage(String title);

  /// No description provided for @notificationEventMarkedDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Completed'**
  String get notificationEventMarkedDoneTitle;

  /// Shown when a user marks an event as completed
  ///
  /// In en, this message translates to:
  /// **'The event \"{eventTitle}\" was marked as completed by {userName}.'**
  String notificationEventMarkedDoneMessage(String eventTitle, String userName);

  /// No description provided for @notificationEventReopenedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Reopened'**
  String get notificationEventReopenedTitle;

  /// Shown when a user reopens an event
  ///
  /// In en, this message translates to:
  /// **'The event \"{eventTitle}\" was reopened by {userName}.'**
  String notificationEventReopenedMessage(String eventTitle, String userName);

  /// No description provided for @notificationEventStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Started'**
  String get notificationEventStartedTitle;

  /// Message shown when an event starts
  ///
  /// In en, this message translates to:
  /// **'The event \"{eventTitle}\" has just started.'**
  String notificationEventStartedMessage(String eventTitle);

  /// Body of a notification reminding about an event's start time
  ///
  /// In en, this message translates to:
  /// **'“{eventTitle}” starts at {eventTime}'**
  String notificationEventReminderBodyWithTime(
      String eventTitle, String eventTime);

  /// No description provided for @notificationEventReminderManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Test Notification'**
  String get notificationEventReminderManual;

  /// No description provided for @categoryGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get categoryGroup;

  /// No description provided for @categoryUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get categoryUser;

  /// No description provided for @categorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get categorySystem;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @passwordRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecoveryTitle;

  /// No description provided for @passwordRecoveryInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email or username to start password recovery:'**
  String get passwordRecoveryInstruction;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordRecoveryEmptyField.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or username.'**
  String get passwordRecoveryEmptyField;

  /// No description provided for @passwordRecoverySuccess.
  ///
  /// In en, this message translates to:
  /// **'A password reset request has been noted. Please contact support or check your account settings.'**
  String get passwordRecoverySuccess;

  /// No description provided for @endDateMustBeAfterStartDate.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date'**
  String get endDateMustBeAfterStartDate;

  /// No description provided for @pleaseSelectAtLeastOneUser.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one user'**
  String get pleaseSelectAtLeastOneUser;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembers;

  /// No description provided for @noInvitedUsersToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No invited users to display.'**
  String get noInvitedUsersToDisplay;

  /// Snackbar after removing an invited/new user
  ///
  /// In en, this message translates to:
  /// **'User {userName} removed successfully.'**
  String userRemovedSuccessfully(String userName);

  /// Snackbar when removal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove user {userName}.'**
  String failedToRemoveUser(String userName);

  /// No description provided for @groupDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupDescriptionLabel;

  /// No description provided for @agenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing upcoming'**
  String get noItems;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @failedToSavePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to save photo'**
  String get failedToSavePhoto;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get failedToSaveProfile;

  /// No description provided for @notAuthenticatedOrUserMissing.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated or user missing'**
  String get notAuthenticatedOrUserMissing;

  /// No description provided for @noUserLoaded.
  ///
  /// In en, this message translates to:
  /// **'No user loaded'**
  String get noUserLoaded;

  /// No description provided for @motivationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get motivationSectionTitle;

  /// No description provided for @groupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupSectionTitle;

  /// No description provided for @clearAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllTooltip;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @clearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all?'**
  String get clearAllConfirmTitle;

  /// No description provided for @clearAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove all notifications? This action can\'t be undone.'**
  String get clearAllConfirmMessage;

  /// No description provided for @clearedAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get clearedAllSuccess;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms & Privacy Policy'**
  String get termsAndPrivacy;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to get started with our app.'**
  String get welcomeSubtitle;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordMedium;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndPrivacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our '**
  String get termsAndPrivacyPrefix;

  /// No description provided for @andSeparator.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andSeparator;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials to continue.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we’ll send you a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent!'**
  String get resetLinkSent;

  /// No description provided for @noUpcomingHint.
  ///
  /// In en, this message translates to:
  /// **'Try another category or extend the range.'**
  String get noUpcomingHint;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @showFourteenDays.
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get showFourteenDays;

  /// No description provided for @showThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get showThirtyDays;

  /// No description provided for @meetings.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get meetings;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @deadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get deadlines;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statusFinished;

  /// No description provided for @completedSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} completed ({percent}%)'**
  String completedSummary(Object done, Object total, Object percent);

  /// No description provided for @notifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get notifyMe;

  /// No description provided for @notifyMeOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a reminder for this event'**
  String get notifyMeOnSubtitle;

  /// No description provided for @notifyMeOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No reminder will be sent'**
  String get notifyMeOffSubtitle;

  /// No description provided for @noInvitableUsers.
  ///
  /// In en, this message translates to:
  /// **'No users available to invite'**
  String get noInvitableUsers;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Empty-state title for clients list
  ///
  /// In en, this message translates to:
  /// **'No clients yet'**
  String get noClientsYet;

  /// Empty-state subtitle for clients list
  ///
  /// In en, this message translates to:
  /// **'Add your first client to this group.'**
  String get addYourFirstClient;

  /// CTA to add a client
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// Status label for active client
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Status label for inactive client
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Empty state title for services list
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get noServicesYet;

  /// Empty state subtitle for services list
  ///
  /// In en, this message translates to:
  /// **'Create services you can assign to bookings.'**
  String get createServicesSubtitle;

  /// CTA button to add a new service
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// Shown when a service has no default minutes set
  ///
  /// In en, this message translates to:
  /// **'No default duration'**
  String get noDefaultDuration;

  /// Abbreviation for minutes, used like '45 min'
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesAbbrev;

  /// Title for editing an existing client
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// Title for creating a new client
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClient;

  /// Label for name text field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Validation message when name is empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// Label for phone text field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Label for email text field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Button label for saving edits
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Button label for creating a client
  ///
  /// In en, this message translates to:
  /// **'Save Client'**
  String get saveClient;

  /// Snackbar error message with reason
  ///
  /// In en, this message translates to:
  /// **'Failed: {reason}'**
  String failedWithReason(String reason);

  /// Title for editing an existing service
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// Title for creating a new service
  ///
  /// In en, this message translates to:
  /// **'Create Service'**
  String get createService;

  /// Label for default minutes field
  ///
  /// In en, this message translates to:
  /// **'Default minutes'**
  String get defaultMinutesLabel;

  /// Hint text for default minutes field
  ///
  /// In en, this message translates to:
  /// **'e.g., 45'**
  String get defaultMinutesHint;

  /// Label above the color picker
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// Button label for creating a service
  ///
  /// In en, this message translates to:
  /// **'Save Service'**
  String get saveService;

  /// App bar title for the Services & Clients screen
  ///
  /// In en, this message translates to:
  /// **'Services & Clients'**
  String get screenServicesClientsTitle;

  /// Tab label for Clients
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get tabClients;

  /// Tab label for Services
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get tabServices;

  /// Header shown above the clients list
  ///
  /// In en, this message translates to:
  /// **'Clients in this group'**
  String get clientsSectionTitle;

  /// Header shown above the services list
  ///
  /// In en, this message translates to:
  /// **'Services in this group'**
  String get servicesSectionTitle;

  /// Header for active clients subsection
  ///
  /// In en, this message translates to:
  /// **'Active clients'**
  String get activeClientsSection;

  /// Header for inactive clients subsection
  ///
  /// In en, this message translates to:
  /// **'Inactive clients'**
  String get inactiveClientsSection;

  /// Header for active services subsection
  ///
  /// In en, this message translates to:
  /// **'Active services'**
  String get activeServicesSection;

  /// Header for inactive services subsection
  ///
  /// In en, this message translates to:
  /// **'Inactive services'**
  String get inactiveServicesSection;

  /// Snackbar after creating a client
  ///
  /// In en, this message translates to:
  /// **'Client created: {name}'**
  String clientCreatedWithName(String name);

  /// Snackbar after creating a service
  ///
  /// In en, this message translates to:
  /// **'Service created: {name}'**
  String serviceCreatedWithName(String name);

  /// Snackbar after updating a client
  ///
  /// In en, this message translates to:
  /// **'Client updated: {name}'**
  String clientUpdatedWithName(String name);

  /// Snackbar after updating a service
  ///
  /// In en, this message translates to:
  /// **'Service updated: {name}'**
  String serviceUpdatedWithName(String name);

  /// Count label for number of clients
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# client} other {# clients}}'**
  String nClients(int count);

  /// Count label for number of services
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# service} other {# services}}'**
  String nServices(int count);

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @sectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get sectionOverview;

  /// No description provided for @sectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sectionUpcoming;

  /// No description provided for @sectionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get sectionManage;

  /// No description provided for @sectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sectionStatus;

  /// Shows the date the group was created.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String createdOnDay(String date);

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// Total members in group
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# total} other {# total}}'**
  String membersSubtitle(int count);

  /// No description provided for @servicesClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Services & Clients'**
  String get servicesClientsTitle;

  /// No description provided for @servicesClientsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage services/clients'**
  String get servicesClientsSubtitle;

  /// No description provided for @noCalendarWarning.
  ///
  /// In en, this message translates to:
  /// **'This group has no calendar linked yet.'**
  String get noCalendarWarning;

  /// No description provided for @sectionFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get sectionFilters;

  /// No description provided for @noMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembersTitle;

  /// No description provided for @noMembersMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No members match these filters.'**
  String get noMembersMatchFilters;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting the filters above.'**
  String get tryAdjustingFilters;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get statusNotAccepted;

  /// No description provided for @errorLoadingUser.
  ///
  /// In en, this message translates to:
  /// **'Error loading user: {error}'**
  String errorLoadingUser(String error);

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addToContacts.
  ///
  /// In en, this message translates to:
  /// **'Add to contact'**
  String get addToContacts;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedToClipboard;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @calendars.
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get calendars;

  /// No description provided for @teamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# team} other {# teams}}'**
  String teamsCount(int count);

  /// No description provided for @calendarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# calendar} other {# calendars}}'**
  String calendarsCount(int count);

  /// No description provided for @notificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# notification} other {# notifications}}'**
  String notificationsCount(int count);

  /// Confirmation message shown before removing all notifications.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all notifications?'**
  String get clearAllConfirm;

  /// Message shown after successfully clearing all notifications.
  ///
  /// In en, this message translates to:
  /// **'All notifications have been cleared.'**
  String get clearedAllNotifications;

  /// Generic label for displaying error messages.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Placeholder text for the search bar when adding people to a group.
  ///
  /// In en, this message translates to:
  /// **'Type name or email address'**
  String get typeNameOrEmail;

  /// Message shown when there are no search results for a given query.
  ///
  /// In en, this message translates to:
  /// **'No matches found for \"{query}\"'**
  String noMatchesForX(String query);

  /// Button text to invite someone by email when no search results are found.
  ///
  /// In en, this message translates to:
  /// **'Invite by Email'**
  String get inviteByEmail;

  /// Message shown when no results are found and user may invite by email.
  ///
  /// In en, this message translates to:
  /// **'No matches found. Would you like to invite them by email?'**
  String get noMatchesInvite;

  /// Default label for the button when no users are selected.
  ///
  /// In en, this message translates to:
  /// **'Add People'**
  String get addPeople;

  /// Short action label for adding selected people to the group.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @primaryService.
  ///
  /// In en, this message translates to:
  /// **'Primary service'**
  String get primaryService;

  /// No description provided for @workVisit.
  ///
  /// In en, this message translates to:
  /// **'Work visit'**
  String get workVisit;

  /// No description provided for @simpleEvent.
  ///
  /// In en, this message translates to:
  /// **'Simple event'**
  String get simpleEvent;

  /// No description provided for @loadingUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Loading upcoming…'**
  String get loadingUpcoming;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get noUpcomingEvents;

  /// No description provided for @nothingScheduledSoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled soon for this group.'**
  String get nothingScheduledSoon;

  /// No description provided for @nextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get nextUp;

  /// No description provided for @upcomingEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events for this group'**
  String get upcomingEventsSubtitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @untitledEvent.
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get untitledEvent;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// Pluralized label for team count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No teams} =1 {1 team} other {{count} teams}}'**
  String teamCount(int count);

  /// Pluralized label for calendar count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No calendars} =1 {1 calendar} other {{count} calendars}}'**
  String calendarCount(int count);

  /// No description provided for @nothingScheduledSoonForThisGroup.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled soon for this group.'**
  String get nothingScheduledSoonForThisGroup;

  /// No description provided for @upcomingEventsForThisGroup.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events for this group'**
  String get upcomingEventsForThisGroup;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get untitled;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTypes;

  /// No description provided for @simpleEvents.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simpleEvents;

  /// No description provided for @workVisits.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workVisits;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'by category'**
  String get byCategory;

  /// No description provided for @sectionInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get sectionInsights;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights & Graphs'**
  String get insightsTitle;

  /// No description provided for @insightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time spent by client or service'**
  String get insightsSubtitle;

  /// No description provided for @timeByClient.
  ///
  /// In en, this message translates to:
  /// **'Time by Client'**
  String get timeByClient;

  /// No description provided for @timeByService.
  ///
  /// In en, this message translates to:
  /// **'Time by Service'**
  String get timeByService;

  /// No description provided for @noDataRange.
  ///
  /// In en, this message translates to:
  /// **'No data in this range'**
  String get noDataRange;

  /// No description provided for @dateRange7d.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get dateRange7d;

  /// No description provided for @dateRange30d.
  ///
  /// In en, this message translates to:
  /// **'30d'**
  String get dateRange30d;

  /// No description provided for @dateRange3m.
  ///
  /// In en, this message translates to:
  /// **'3m'**
  String get dateRange3m;

  /// No description provided for @dateRange4m.
  ///
  /// In en, this message translates to:
  /// **'4m'**
  String get dateRange4m;

  /// No description provided for @dateRange6m.
  ///
  /// In en, this message translates to:
  /// **'6m'**
  String get dateRange6m;

  /// No description provided for @dateRange1y.
  ///
  /// In en, this message translates to:
  /// **'1y'**
  String get dateRange1y;

  /// No description provided for @dateRangeYTD.
  ///
  /// In en, this message translates to:
  /// **'YTD'**
  String get dateRangeYTD;

  /// No description provided for @dateRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dateRangeCustom;

  /// No description provided for @filterDimensionClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get filterDimensionClients;

  /// No description provided for @filterDimensionServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get filterDimensionServices;

  /// No description provided for @filterTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterTypeAll;

  /// No description provided for @filterTypeSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get filterTypeSimple;

  /// No description provided for @filterTypeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get filterTypeWork;

  /// No description provided for @insightsHintUpcomingOnly.
  ///
  /// In en, this message translates to:
  /// **'Showing upcoming data only. For past ranges, please enable server-side range fetch.'**
  String get insightsHintUpcomingOnly;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @accountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionTitle;

  /// No description provided for @preferencesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSectionTitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @roleCoAdmin.
  ///
  /// In en, this message translates to:
  /// **'Co-Administrator'**
  String get roleCoAdmin;

  /// No description provided for @leaveGroupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get leaveGroupQuestion;

  /// No description provided for @removeMembersFirst.
  ///
  /// In en, this message translates to:
  /// **'Please remove all members before deleting the group.'**
  String get removeMembersFirst;

  /// Snackbar text shown when the calendar finishes refreshing successfully
  ///
  /// In en, this message translates to:
  /// **'Calendar refreshed'**
  String get refreshSuccess;

  /// Snackbar text shown when the calendar refresh fails
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshFailed;

  /// No description provided for @shareButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButtonTooltip;

  /// No description provided for @soonLabel.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get soonLabel;

  /// No description provided for @detailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSectionTitle;

  /// No description provided for @workVisitSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Visit'**
  String get workVisitSectionTitle;

  /// No description provided for @rawFieldsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw Fields'**
  String get rawFieldsSectionTitle;

  /// No description provided for @eventWhenLabel.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventWhenLabel;

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientLabel;

  /// No description provided for @servicePrimaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Service'**
  String get servicePrimaryLabel;

  /// No description provided for @workVisitBadge.
  ///
  /// In en, this message translates to:
  /// **'Work Visit'**
  String get workVisitBadge;

  /// No description provided for @editButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editButtonLabel;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @duplicateAction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateAction;

  /// No description provided for @analyticsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get analyticsSectionTitle;

  /// No description provided for @graphsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Charts coming soon'**
  String get graphsComingSoon;

  /// No description provided for @timeTrackingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Time tracking enabled'**
  String get timeTrackingEnabled;

  /// No description provided for @timeTrackingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Time tracking disabled'**
  String get timeTrackingDisabled;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported Excel successfully'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @exportToExcelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcelTooltip;

  /// No description provided for @exportToExcelCta.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportToExcelCta;

  /// No description provided for @trackHoursFor.
  ///
  /// In en, this message translates to:
  /// **'Track hours for {groupName}'**
  String trackHoursFor(Object groupName);

  /// No description provided for @timeTrackingHeaderHint.
  ///
  /// In en, this message translates to:
  /// **'Enable tracking and manage workers. Export a timesheet anytime.'**
  String get timeTrackingHeaderHint;

  /// No description provided for @enableTrackingCta.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableTrackingCta;

  /// No description provided for @disableTrackingCta.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableTrackingCta;

  /// No description provided for @employeesHeader.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesHeader;

  /// No description provided for @unknownWorker.
  ///
  /// In en, this message translates to:
  /// **'Unnamed worker'**
  String get unknownWorker;

  /// No description provided for @noTrackedYet.
  ///
  /// In en, this message translates to:
  /// **'No tracked time yet'**
  String get noTrackedYet;

  /// No description provided for @trackedTotal.
  ///
  /// In en, this message translates to:
  /// **'Tracked: {tracked}'**
  String trackedTotal(Object tracked);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noWorkersYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No workers yet'**
  String get noWorkersYetTitle;

  /// No description provided for @noWorkersYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable tracking to start counting hours and add workers.'**
  String get noWorkersYetSubtitle;

  /// No description provided for @timeTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Time tracking'**
  String get timeTrackingTitle;

  /// No description provided for @sectionWorkersHours.
  ///
  /// In en, this message translates to:
  /// **'Workers\' hours'**
  String get sectionWorkersHours;

  /// No description provided for @timeTrackingDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Time tracking is off'**
  String get timeTrackingDisabledTitle;

  /// No description provided for @timeTrackingDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable it to start tracking hours for your team.'**
  String get timeTrackingDisabledSubtitle;

  /// No description provided for @createWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Worker'**
  String get createWorkerTitle;

  /// No description provided for @linkExistingUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Link to existing user'**
  String get linkExistingUserLabel;

  /// No description provided for @linkExistingUserHint.
  ///
  /// In en, this message translates to:
  /// **'If the worker already has an account, link it here.'**
  String get linkExistingUserHint;

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdLabel;

  /// No description provided for @userIdHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the existing user’s ID'**
  String get userIdHint;

  /// No description provided for @userIdRequired.
  ///
  /// In en, this message translates to:
  /// **'User ID is required when linking an account.'**
  String get userIdRequired;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter worker’s name'**
  String get displayNameHint;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required for external workers.'**
  String get displayNameRequired;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @roleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Barista'**
  String get roleHint;

  /// No description provided for @hourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRateLabel;

  /// No description provided for @hourlyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 15.00'**
  String get hourlyRateHint;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @saveWorkerCta.
  ///
  /// In en, this message translates to:
  /// **'Save Worker'**
  String get saveWorkerCta;

  /// No description provided for @workerCreated.
  ///
  /// In en, this message translates to:
  /// **'Worker created successfully!'**
  String get workerCreated;

  /// No description provided for @createWorkerCta.
  ///
  /// In en, this message translates to:
  /// **'Add Worker'**
  String get createWorkerCta;

  /// No description provided for @createTimeEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Time Entry'**
  String get createTimeEntryTitle;

  /// No description provided for @workerLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get workerLabel;

  /// No description provided for @workerRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a worker.'**
  String get workerRequired;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes about this shift'**
  String get notesHint;

  /// No description provided for @saveTimeEntryCta.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get saveTimeEntryCta;

  /// No description provided for @timeEntryCreated.
  ///
  /// In en, this message translates to:
  /// **'Time entry added successfully!'**
  String get timeEntryCreated;

  /// No description provided for @addTimeEntryCta.
  ///
  /// In en, this message translates to:
  /// **'Add Time Entry'**
  String get addTimeEntryCta;

  /// No description provided for @timeTrackingActionsCta.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get timeTrackingActionsCta;

  /// No description provided for @noTimeEntriesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No time entries yet'**
  String get noTimeEntriesYetTitle;

  /// No description provided for @noTimeEntriesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first recorded hours for this worker.'**
  String get noTimeEntriesYetSubtitle;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get totalEntries;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get totalHours;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @editWorker.
  ///
  /// In en, this message translates to:
  /// **'Edit worker'**
  String get editWorker;

  /// No description provided for @linkedUser.
  ///
  /// In en, this message translates to:
  /// **'Linked user'**
  String get linkedUser;

  /// No description provided for @externalWorker.
  ///
  /// In en, this message translates to:
  /// **'External worker'**
  String get externalWorker;

  /// No description provided for @viewWorker.
  ///
  /// In en, this message translates to:
  /// **'View worker'**
  String get viewWorker;

  /// No description provided for @workerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Worker updated'**
  String get workerUpdated;

  /// No description provided for @workerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workerNameLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @invalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid hourly rate'**
  String get invalidRate;

  /// No description provided for @editTimeEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit time entry'**
  String get editTimeEntry;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @breakMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Break (minutes)'**
  String get breakMinutesLabel;

  /// No description provided for @timeEntryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Time entry updated successfully'**
  String get timeEntryUpdated;

  /// No description provided for @pickStartTime.
  ///
  /// In en, this message translates to:
  /// **'Pick start time'**
  String get pickStartTime;

  /// No description provided for @pickEndTime.
  ///
  /// In en, this message translates to:
  /// **'Pick end time'**
  String get pickEndTime;

  /// No description provided for @noTimeEntries.
  ///
  /// In en, this message translates to:
  /// **'No time entries yet.'**
  String get noTimeEntries;

  /// No description provided for @totalHoursFormat.
  ///
  /// In en, this message translates to:
  /// **'Total: {hours}h {minutes}m'**
  String totalHoursFormat(Object hours, Object minutes);

  /// No description provided for @totalHoursAndPayFormat.
  ///
  /// In en, this message translates to:
  /// **'Total: {hours}h – {pay}'**
  String totalHoursAndPayFormat(Object hours, Object pay);

  /// No description provided for @pickMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get pickMonth;

  /// No description provided for @selectMonthPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a month to view entries.'**
  String get selectMonthPrompt;

  /// No description provided for @selectMonthFirst.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get selectMonthFirst;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this time entry?'**
  String get areYouSureDelete;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportExcel;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready — choose where to share/save'**
  String get exportReady;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @overviewInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly overview'**
  String get overviewInfoTitle;

  /// No description provided for @overviewInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Each tile shows the month, total hours and pay for this worker. Tap a month to open detailed time entries. Use the arrows to switch years. Pull down to refresh.'**
  String get overviewInfoBody;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @tipTapMonthToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap a month to open details'**
  String get tipTapMonthToOpen;

  /// No description provided for @tipPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get tipPullToRefresh;

  /// No description provided for @addWorker.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get addWorker;

  /// No description provided for @addWorkerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a worker profile to start tracking hours and pay.'**
  String get addWorkerSubtitle;

  /// No description provided for @membersInfoAccepted.
  ///
  /// In en, this message translates to:
  /// **'Users who are part of this group.'**
  String get membersInfoAccepted;

  /// No description provided for @membersInfoPending.
  ///
  /// In en, this message translates to:
  /// **'Invitations sent and awaiting acceptance.'**
  String get membersInfoPending;

  /// No description provided for @membersInfoNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invites that were declined, revoked, or expired.'**
  String get membersInfoNotAccepted;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @e_gJohnDoe.
  ///
  /// In en, this message translates to:
  /// **'e.g., John Doe'**
  String get e_gJohnDoe;

  /// No description provided for @e_gPhone.
  ///
  /// In en, this message translates to:
  /// **'e.g., +1 555-1234'**
  String get e_gPhone;

  /// No description provided for @e_gEmail.
  ///
  /// In en, this message translates to:
  /// **'e.g., john.doe@example.com'**
  String get e_gEmail;

  /// No description provided for @clientWillBeActive.
  ///
  /// In en, this message translates to:
  /// **'Client will be active'**
  String get clientWillBeActive;

  /// No description provided for @clientWillBeInactive.
  ///
  /// In en, this message translates to:
  /// **'Client will be inactive'**
  String get clientWillBeInactive;

  /// No description provided for @noContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get noContactInfo;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @serviceWillBeActive.
  ///
  /// In en, this message translates to:
  /// **'Service will be active'**
  String get serviceWillBeActive;

  /// No description provided for @serviceWillBeInactive.
  ///
  /// In en, this message translates to:
  /// **'Service will be inactive'**
  String get serviceWillBeInactive;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose type'**
  String get chooseType;

  /// No description provided for @simpleEventHint.
  ///
  /// In en, this message translates to:
  /// **'Create a quick event without client/service selection.'**
  String get simpleEventHint;

  /// No description provided for @workVisitHint.
  ///
  /// In en, this message translates to:
  /// **'Track a work visit by choosing a client and one or more services.'**
  String get workVisitHint;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @assignedUsers.
  ///
  /// In en, this message translates to:
  /// **'Assigned users'**
  String get assignedUsers;

  /// No description provided for @repetition.
  ///
  /// In en, this message translates to:
  /// **'Repetition'**
  String get repetition;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @workVisitHintShort.
  ///
  /// In en, this message translates to:
  /// **'Choose a client and services for this work visit.'**
  String get workVisitHintShort;

  /// No description provided for @simpleEventHintShort.
  ///
  /// In en, this message translates to:
  /// **'Simple event with no client or service.'**
  String get simpleEventHintShort;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newSubcategory.
  ///
  /// In en, this message translates to:
  /// **'New subcategory'**
  String get newSubcategory;

  /// No description provided for @failedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create: {error}'**
  String failedToCreate(String error);

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @addSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Add subcategory'**
  String get addSubcategory;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
