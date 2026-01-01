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

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @downloadMobileApp.
  ///
  /// In en, this message translates to:
  /// **'Download the mobile app'**
  String get downloadMobileApp;

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

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'This URL is not valid'**
  String get invalidUrl;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registrationError;

  /// No description provided for @registerCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to verify.'**
  String get registerCheckEmail;

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

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please try again.'**
  String get loginInvalidCredentials;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authError;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailInfo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent you a verification link. Open the link from your email to finish verifying.'**
  String get verifyEmailInfo;

  /// No description provided for @verifyingEmail.
  ///
  /// In en, this message translates to:
  /// **'Verifying your email...'**
  String get verifyingEmail;

  /// No description provided for @verifyEmailTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get verifyEmailTryAgain;

  /// No description provided for @resendVerificationButton.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationButton;

  /// No description provided for @resendVerificationSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get resendVerificationSending;

  /// No description provided for @resendVerificationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email to resend.'**
  String get resendVerificationInvalidEmail;

  /// No description provided for @resendVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent to {email}'**
  String resendVerificationSent(String email);

  /// No description provided for @resendVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resend verification: {error}'**
  String resendVerificationFailed(String error);

  /// No description provided for @verifySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get verifySuccessTitle;

  /// No description provided for @verifySuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your email has been confirmed. You can now sign in and start using the app.'**
  String get verifySuccessMessage;

  /// No description provided for @downloadAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Hexora on your phone'**
  String get downloadAppTitle;

  /// No description provided for @downloadAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Install the Android or iOS app to stay in sync on the go.'**
  String get downloadAppSubtitle;

  /// No description provided for @downloadAppAndroid.
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get downloadAppAndroid;

  /// No description provided for @downloadAppIos.
  ///
  /// In en, this message translates to:
  /// **'Download on the App Store'**
  String get downloadAppIos;

  /// No description provided for @downloadAppOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the store link. Please try again.'**
  String get downloadAppOpenError;

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

  /// No description provided for @noGroupsFound.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get noGroupsFound;

  /// No description provided for @noGroupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or join a group to get started'**
  String get noGroupsDescription;

  /// No description provided for @searchGroups.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get searchGroups;

  /// No description provided for @weatherSummarySunny.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get weatherSummarySunny;

  /// No description provided for @weatherSummaryPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherSummaryPartlyCloudy;

  /// No description provided for @weatherSummaryCloudyWithRain.
  ///
  /// In en, this message translates to:
  /// **'Cloudy with rain'**
  String get weatherSummaryCloudyWithRain;

  /// No description provided for @weatherSummaryLightRain.
  ///
  /// In en, this message translates to:
  /// **'Light rain'**
  String get weatherSummaryLightRain;

  /// No description provided for @weatherSummaryHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get weatherSummaryHeavyRain;

  /// No description provided for @weatherSummaryStormy.
  ///
  /// In en, this message translates to:
  /// **'Stormy'**
  String get weatherSummaryStormy;

  /// No description provided for @weatherSummaryCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherSummaryCloudy;

  /// No description provided for @weatherSummaryDefault.
  ///
  /// In en, this message translates to:
  /// **'Pleasant weather'**
  String get weatherSummaryDefault;

  /// No description provided for @weatherGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, today looks {summary} {emoji}'**
  String weatherGreeting(Object emoji, Object name, Object summary);

  /// No description provided for @weatherTempLine.
  ///
  /// In en, this message translates to:
  /// **'High {max}° / Low {min}°'**
  String weatherTempLine(Object max, Object min);

  /// No description provided for @weatherFunTooHot.
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated—it’s going to be scorching.'**
  String get weatherFunTooHot;

  /// No description provided for @weatherFunTooCold.
  ///
  /// In en, this message translates to:
  /// **'Bundle up—it’s freezing outside.'**
  String get weatherFunTooCold;

  /// No description provided for @weatherFunGradeA.
  ///
  /// In en, this message translates to:
  /// **'Grade A day. Plan something fun outdoors!'**
  String get weatherFunGradeA;

  /// No description provided for @weatherFunGradeB.
  ///
  /// In en, this message translates to:
  /// **'Pretty good weather overall.'**
  String get weatherFunGradeB;

  /// No description provided for @weatherFunGradeC.
  ///
  /// In en, this message translates to:
  /// **'Keep an umbrella handy just in case.'**
  String get weatherFunGradeC;

  /// No description provided for @weatherFunGradeD.
  ///
  /// In en, this message translates to:
  /// **'Maybe plan for indoor activities today.'**
  String get weatherFunGradeD;

  /// No description provided for @weatherFunDefault.
  ///
  /// In en, this message translates to:
  /// **'Make the most of the day, whatever the weather.'**
  String get weatherFunDefault;

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

  /// No description provided for @agendaSelectGroupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a group to load events'**
  String get agendaSelectGroupPrompt;

  /// No description provided for @agendaChooseGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get agendaChooseGroupButton;

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
  /// **'Save changes'**
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

  /// Generic title for the events section on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get sectionEvents;

  /// Title for the pending/undone events section on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Pending events'**
  String get pendingEventsSectionTitle;

  /// Subtitle shown below the pending events section title.
  ///
  /// In en, this message translates to:
  /// **'Mark visits as completed when you\'re done.'**
  String get pendingEventsSectionSubtitle;

  /// Shown when there are no pending events.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get pendingEventsEmpty;

  /// Generic error message for pending events list.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load pending events.'**
  String get pendingEventsError;

  /// Button text to mark an event as done.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get pendingEventsMarkDone;

  /// Title for the completed events tab/section.
  ///
  /// In en, this message translates to:
  /// **'Completed events'**
  String get completedEventsSectionTitle;

  /// Subtitle that explains the completed events tab.
  ///
  /// In en, this message translates to:
  /// **'Recently completed visits and tasks.'**
  String get completedEventsSectionSubtitle;

  /// Shown when there are no completed events for the user.
  ///
  /// In en, this message translates to:
  /// **'No events have been completed yet.'**
  String get completedEventsEmpty;

  /// Hint displayed on the profile role card encouraging users to tap for more details.
  ///
  /// In en, this message translates to:
  /// **'Tap to view all role capabilities.'**
  String get roleCardTapHint;

  /// Label shown before the event owner's information.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdByLabel;

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

  /// No description provided for @groupNotificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Group notifications'**
  String get groupNotificationsSectionTitle;

  /// No description provided for @updateRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Update role'**
  String get updateRoleTitle;

  /// No description provided for @groupNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See invites, reminders, and alerts scoped to this group.'**
  String get groupNotificationsSubtitle;

  /// No description provided for @groupNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This group doesn\'t have any notifications yet.'**
  String get groupNotificationsEmpty;

  /// No description provided for @groupNotificationsError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the notifications for this group.'**
  String get groupNotificationsError;

  /// Page title for the per-group notifications screen
  ///
  /// In en, this message translates to:
  /// **'{groupName} notifications'**
  String groupNotificationsTitle(String groupName);

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

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @currencyAllOption.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get currencyAllOption;

  /// No description provided for @workerRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Worker required'**
  String get workerRequiredError;

  /// No description provided for @workersLabel.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workersLabel;

  /// No description provided for @selectWorkersPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select workers'**
  String get selectWorkersPlaceholder;

  /// No description provided for @pickWorkersCta.
  ///
  /// In en, this message translates to:
  /// **'Pick workers'**
  String get pickWorkersCta;

  /// No description provided for @noWorkersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No workers available'**
  String get noWorkersAvailable;

  /// No description provided for @currencyFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by currency'**
  String get currencyFilterLabel;

  /// No description provided for @currencyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Show all currencies'**
  String get currencyFilterAll;

  /// No description provided for @workerChipRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove worker'**
  String get workerChipRemoveTooltip;

  /// No description provided for @workerPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose workers'**
  String get workerPickerTitle;

  /// No description provided for @workerPickerSave.
  ///
  /// In en, this message translates to:
  /// **'Save selection'**
  String get workerPickerSave;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @currencyWorkersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Workers & currency'**
  String get currencyWorkersSectionTitle;

  /// No description provided for @currencyWorkersSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Filter by currency and pick which workers to include.'**
  String get currencyWorkersSectionDescription;

  /// No description provided for @currencyHelperText.
  ///
  /// In en, this message translates to:
  /// **'Use a currency to quickly narrow the worker list.'**
  String get currencyHelperText;

  /// No description provided for @workersHelperText.
  ///
  /// In en, this message translates to:
  /// **'Tap to add or remove workers.'**
  String get workersHelperText;

  /// No description provided for @workersValidationHint.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one worker before saving.'**
  String get workersValidationHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @notesOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Add context or leave empty'**
  String get notesOptionalHint;

  /// No description provided for @savingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingLabel;

  /// No description provided for @invalidTimeRange.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get invalidTimeRange;

  /// No description provided for @toggleEmptyDays.
  ///
  /// In en, this message translates to:
  /// **'Show/hide empty days'**
  String get toggleEmptyDays;

  /// No description provided for @didNotWorkDay.
  ///
  /// In en, this message translates to:
  /// **'{name} did not work this day'**
  String didNotWorkDay(Object name);

  /// No description provided for @daysMissedAll.
  ///
  /// In en, this message translates to:
  /// **'{count} days without hours'**
  String daysMissedAll(int count);

  /// No description provided for @daysMissedNoSunday.
  ///
  /// In en, this message translates to:
  /// **'{count} days without hours (Mon-Sat)'**
  String daysMissedNoSunday(int count);

  /// No description provided for @avgHoursPerDayWorked.
  ///
  /// In en, this message translates to:
  /// **'Avg {hours} h/day worked'**
  String avgHoursPerDayWorked(String hours);

  /// No description provided for @didNotWorkSunday.
  ///
  /// In en, this message translates to:
  /// **'{name} logged no hours (Sunday)'**
  String didNotWorkSunday(String name);

  /// No description provided for @daysWorked.
  ///
  /// In en, this message translates to:
  /// **'{count} days worked'**
  String daysWorked(int count);

  /// No description provided for @sundaysWorked.
  ///
  /// In en, this message translates to:
  /// **'{count} Sundays worked'**
  String sundaysWorked(int count);

  /// No description provided for @avgHoursPerDayWorkedWithCount.
  ///
  /// In en, this message translates to:
  /// **'Avg {hours} h/day across {count} days'**
  String avgHoursPerDayWorkedWithCount(String hours, int count);

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

  /// No description provided for @sectionBusinessHours.
  ///
  /// In en, this message translates to:
  /// **'Business hours'**
  String get sectionBusinessHours;

  /// No description provided for @businessHoursAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define the window when members can schedule events.'**
  String get businessHoursAdminSubtitle;

  /// No description provided for @businessHoursMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Events must be created during this time window.'**
  String get businessHoursMemberSubtitle;

  /// No description provided for @businessHoursUnset.
  ///
  /// In en, this message translates to:
  /// **'Not configured yet'**
  String get businessHoursUnset;

  /// Formatted representation of the business hours window
  ///
  /// In en, this message translates to:
  /// **'{start} – {end} · {timezone}'**
  String businessHoursRange(String start, String end, String timezone);

  /// No description provided for @businessHoursEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get businessHoursEdit;

  /// No description provided for @businessHoursSave.
  ///
  /// In en, this message translates to:
  /// **'Save hours'**
  String get businessHoursSave;

  /// No description provided for @businessHoursReset.
  ///
  /// In en, this message translates to:
  /// **'Clear hours'**
  String get businessHoursReset;

  /// No description provided for @businessHoursTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get businessHoursTimezoneLabel;

  /// No description provided for @businessHoursTimezoneHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Europe/Madrid'**
  String get businessHoursTimezoneHint;

  /// No description provided for @businessHoursPartialError.
  ///
  /// In en, this message translates to:
  /// **'Set both start and end to save this window.'**
  String get businessHoursPartialError;

  /// No description provided for @businessHoursStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get businessHoursStartLabel;

  /// No description provided for @businessHoursEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get businessHoursEndLabel;

  /// No description provided for @businessHoursUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Business hours updated'**
  String get businessHoursUpdateSuccess;

  /// No description provided for @businessHoursUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update business hours'**
  String get businessHoursUpdateError;

  /// No description provided for @selectMonthPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a month to view entries.'**
  String get selectMonthPrompt;

  /// Shown when a user attempts to create an event outside of the configured business hours
  ///
  /// In en, this message translates to:
  /// **'Events must take place between {start} and {end} ({timezone}).'**
  String businessHoursValidationMessage(
      String start, String end, String timezone);

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

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @noGroupAvailable.
  ///
  /// In en, this message translates to:
  /// **'No group available'**
  String get noGroupAvailable;

  /// No description provided for @tabDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get tabDay;

  /// No description provided for @tabWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get tabWeek;

  /// No description provided for @tabMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get tabMonth;

  /// No description provided for @tabAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get tabAgenda;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Input title'**
  String get titleHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Input description'**
  String get descriptionHint;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Input note'**
  String get noteHint;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Additional Services'**
  String get services;

  /// No description provided for @noWorkVisitData.
  ///
  /// In en, this message translates to:
  /// **'No work-visit data available.'**
  String get noWorkVisitData;

  /// No description provided for @roleAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdministrator;

  /// No description provided for @roleCoAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Co-Administrator'**
  String get roleCoAdministrator;

  /// No description provided for @roleGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get roleGuest;

  /// No description provided for @viewMembers.
  ///
  /// In en, this message translates to:
  /// **'View members'**
  String get viewMembers;

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @monthYearFormat.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String monthYearFormat(Object month, Object year);

  /// No description provided for @groupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce the purpose of this group'**
  String get groupDescriptionHint;

  /// No description provided for @groupNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Group name too short'**
  String get groupNameTooShort;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Input group name'**
  String get groupNameHint;

  /// No description provided for @reviewUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members — Review & Roles'**
  String get reviewUsersTitle;

  /// No description provided for @tabUpdateRoles.
  ///
  /// In en, this message translates to:
  /// **'Update roles'**
  String get tabUpdateRoles;

  /// No description provided for @tabAddUsers.
  ///
  /// In en, this message translates to:
  /// **'Add users'**
  String get tabAddUsers;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more ({count})'**
  String loadMore(Object count);

  /// No description provided for @addUsersCount.
  ///
  /// In en, this message translates to:
  /// **'Add users ({count})'**
  String addUsersCount(Object count);

  /// Generic confirmation/action label.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Hint shown when the user types fewer than 3 characters in search.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 characters'**
  String get searchMinChars;

  /// Shown when a search request fails.
  ///
  /// In en, this message translates to:
  /// **'Error searching user'**
  String get errorSearchingUser;

  /// Shown when adding a user fails.
  ///
  /// In en, this message translates to:
  /// **'Error adding user'**
  String get errorAddingUser;

  /// Shown when the selected username already belongs to a group member.
  ///
  /// In en, this message translates to:
  /// **'User is already a member'**
  String get userAlreadyAdded;

  /// Shown when the username is already staged (pending selection).
  ///
  /// In en, this message translates to:
  /// **'User already in selection'**
  String get userAlreadyPending;

  /// Toast after committing pending selections into the group.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No users added} =1{1 user added} other{{count} users added}}'**
  String selectedCommitted(int count);

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get online;

  /// No description provided for @addUsersHelperText.
  ///
  /// In en, this message translates to:
  /// **'Search and stage members to be added. You can set roles per user before uploading changes.'**
  String get addUsersHelperText;

  /// No description provided for @updateRolesHelperText.
  ///
  /// In en, this message translates to:
  /// **'Review members and adjust roles. Tap a card to change the role.'**
  String get updateRolesHelperText;

  /// No description provided for @membersHelperText.
  ///
  /// In en, this message translates to:
  /// **'Browse members by status, review invites, and manage roles.'**
  String get membersHelperText;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @editImage.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editImage;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change group photo'**
  String get tapToChangePhoto;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add group photo'**
  String get tapToAddPhoto;

  /// No description provided for @groupSaved.
  ///
  /// In en, this message translates to:
  /// **'Group saved'**
  String get groupSaved;

  /// No description provided for @manageGroup.
  ///
  /// In en, this message translates to:
  /// **'Manage group'**
  String get manageGroup;

  /// No description provided for @hey.
  ///
  /// In en, this message translates to:
  /// **'Hey'**
  String get hey;

  /// No description provided for @youAreThe.
  ///
  /// In en, this message translates to:
  /// **'you are the'**
  String get youAreThe;

  /// No description provided for @ofThisGroup.
  ///
  /// In en, this message translates to:
  /// **'of this group'**
  String get ofThisGroup;

  /// No description provided for @youHaveSuperPowersHere.
  ///
  /// In en, this message translates to:
  /// **'You have super powers for this group!'**
  String get youHaveSuperPowersHere;

  /// No description provided for @roleOwnerBullet1.
  ///
  /// In en, this message translates to:
  /// **'Change group settings and features'**
  String get roleOwnerBullet1;

  /// No description provided for @roleOwnerBullet2.
  ///
  /// In en, this message translates to:
  /// **'Manage billing and subscription'**
  String get roleOwnerBullet2;

  /// No description provided for @roleOwnerBullet3.
  ///
  /// In en, this message translates to:
  /// **'Add or remove co-admins and members'**
  String get roleOwnerBullet3;

  /// No description provided for @roleOwnerBullet4.
  ///
  /// In en, this message translates to:
  /// **'View and edit all calendars and events'**
  String get roleOwnerBullet4;

  /// No description provided for @roleOwnerBullet5.
  ///
  /// In en, this message translates to:
  /// **'Delete or transfer the group'**
  String get roleOwnerBullet5;

  /// No description provided for @roleCoAdminBullet1.
  ///
  /// In en, this message translates to:
  /// **'Create, edit, and delete events for the group'**
  String get roleCoAdminBullet1;

  /// No description provided for @roleCoAdminBullet2.
  ///
  /// In en, this message translates to:
  /// **'Manage services and clients'**
  String get roleCoAdminBullet2;

  /// No description provided for @roleCoAdminBullet3.
  ///
  /// In en, this message translates to:
  /// **'Invite or remove members (except the owner)'**
  String get roleCoAdminBullet3;

  /// No description provided for @roleCoAdminBullet4.
  ///
  /// In en, this message translates to:
  /// **'Configure notifications and work hours'**
  String get roleCoAdminBullet4;

  /// No description provided for @roleMemberBullet1.
  ///
  /// In en, this message translates to:
  /// **'See your assigned events'**
  String get roleMemberBullet1;

  /// No description provided for @roleMemberBullet2.
  ///
  /// In en, this message translates to:
  /// **'Mark visits or tasks as done'**
  String get roleMemberBullet2;

  /// No description provided for @roleMemberBullet3.
  ///
  /// In en, this message translates to:
  /// **'Add notes and comments'**
  String get roleMemberBullet3;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingsOwnerBannerOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the owner of this group. You can manage every setting from here.'**
  String get groupSettingsOwnerBannerOwner;

  /// No description provided for @groupSettingsOwnerBannerNotOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the group owner can update these settings.'**
  String get groupSettingsOwnerBannerNotOwner;

  /// No description provided for @groupSettingsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get groupSettingsOverviewTitle;

  /// No description provided for @groupSettingsOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'General information about this group.'**
  String get groupSettingsOverviewSubtitle;

  /// No description provided for @groupSettingsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupSettingsDescriptionLabel;

  /// No description provided for @groupSettingsNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get groupSettingsNoDescription;

  /// No description provided for @groupSettingsOwnerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner ID'**
  String get groupSettingsOwnerIdLabel;

  /// No description provided for @groupSettingsCreatedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get groupSettingsCreatedOnLabel;

  /// No description provided for @groupSettingsMemberCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Member count'**
  String get groupSettingsMemberCountLabel;

  /// No description provided for @groupSettingsUserRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'User roles'**
  String get groupSettingsUserRolesTitle;

  /// No description provided for @groupSettingsUserRolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions for users in this group.'**
  String get groupSettingsUserRolesSubtitle;

  /// No description provided for @groupSettingsNoRoles.
  ///
  /// In en, this message translates to:
  /// **'No specific roles assigned yet.'**
  String get groupSettingsNoRoles;

  /// No description provided for @groupSettingsUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID:'**
  String get groupSettingsUserIdLabel;

  /// No description provided for @groupSettingsRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get groupSettingsRoleLabel;

  /// No description provided for @groupSettingsInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get groupSettingsInvitationsTitle;

  /// No description provided for @groupSettingsInvitationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite new members or manage pending invitations.'**
  String get groupSettingsInvitationsSubtitle;

  /// No description provided for @groupSettingsInvitationsInfo.
  ///
  /// In en, this message translates to:
  /// **'Invitations are managed separately.'**
  String get groupSettingsInvitationsInfo;

  /// No description provided for @groupSettingsViewInvitations.
  ///
  /// In en, this message translates to:
  /// **'View invitations'**
  String get groupSettingsViewInvitations;

  /// No description provided for @groupSettingsDangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get groupSettingsDangerZoneTitle;

  /// No description provided for @groupSettingsDangerZoneOwner.
  ///
  /// In en, this message translates to:
  /// **'Deleting this group is permanent and cannot be undone.'**
  String get groupSettingsDangerZoneOwner;

  /// No description provided for @groupSettingsDangerZoneNonOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the group owner can delete this group.'**
  String get groupSettingsDangerZoneNonOwner;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group info'**
  String get groupInfo;

  /// No description provided for @groupInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, description and basic details'**
  String get groupInfoSubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts, reminders and preferences'**
  String get notificationsSubtitle;

  /// No description provided for @billingDetails.
  ///
  /// In en, this message translates to:
  /// **'Billing details'**
  String get billingDetails;

  /// No description provided for @billingDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Captured for invoices (legal name, tax ID, address, contact).'**
  String get billingDetailsSubtitle;

  /// No description provided for @billingLegalName.
  ///
  /// In en, this message translates to:
  /// **'Legal name'**
  String get billingLegalName;

  /// No description provided for @billingTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get billingTaxId;

  /// No description provided for @billingTaxIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Used on invoices and PDFs.'**
  String get billingTaxIdHelper;

  /// No description provided for @addressStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get addressStreet;

  /// No description provided for @addressExtra.
  ///
  /// In en, this message translates to:
  /// **'Address extra'**
  String get addressExtra;

  /// No description provided for @addressCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addressCity;

  /// No description provided for @addressProvince.
  ///
  /// In en, this message translates to:
  /// **'Province/State'**
  String get addressProvince;

  /// No description provided for @addressPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get addressPostalCode;

  /// No description provided for @addressCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get addressCountry;

  /// No description provided for @billingEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing email'**
  String get billingEmailLabel;

  /// No description provided for @billingPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing phone'**
  String get billingPhoneLabel;

  /// No description provided for @billingComplete.
  ///
  /// In en, this message translates to:
  /// **'Billing ready'**
  String get billingComplete;

  /// No description provided for @billingMissing.
  ///
  /// In en, this message translates to:
  /// **'Billing incomplete'**
  String get billingMissing;

  /// No description provided for @billingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing profile'**
  String get billingProfileTitle;

  /// No description provided for @billingProfileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add your issuer details (legal name, tax ID, address, VAT, IBAN) to issue invoices.'**
  String get billingProfileEmpty;

  /// No description provided for @billingWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get billingWebsite;

  /// No description provided for @billingIban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get billingIban;

  /// No description provided for @billingIbanHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown on invoices for bank transfer.'**
  String get billingIbanHelper;

  /// No description provided for @billingTaxRate.
  ///
  /// In en, this message translates to:
  /// **'VAT rate'**
  String get billingTaxRate;

  /// No description provided for @billingTaxRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Default VAT (0–100).'**
  String get billingTaxRateHelper;

  /// No description provided for @billingCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get billingCurrency;

  /// No description provided for @billingCurrencyHelper.
  ///
  /// In en, this message translates to:
  /// **'Default currency (e.g. EUR).'**
  String get billingCurrencyHelper;

  /// No description provided for @billingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get billingLanguage;

  /// No description provided for @billingLanguageHelper.
  ///
  /// In en, this message translates to:
  /// **'Invoice language code (e.g. es, en).'**
  String get billingLanguageHelper;

  /// No description provided for @billingAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get billingAddress;

  /// No description provided for @billingProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Billing profile saved'**
  String get billingProfileSaved;

  /// No description provided for @createInvoiceCta.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get createInvoiceCta;

  /// No description provided for @invoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Invoice created'**
  String get invoiceCreated;

  /// No description provided for @noInvoicesYet.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get noInvoicesYet;

  /// No description provided for @noInvoicesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first invoice to keep billing organized.'**
  String get noInvoicesYetSubtitle;

  /// No description provided for @invoicesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoicesListTitle;

  /// No description provided for @invoicesNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoicesNavLabel;

  /// No description provided for @invoicesNavSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and track invoices'**
  String get invoicesNavSubtitle;

  /// No description provided for @invoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices · {groupName}'**
  String invoicesTitle(String groupName);

  /// No description provided for @openInvoicesWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open invoices workspace'**
  String get openInvoicesWorkspace;

  /// No description provided for @invoiceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice number (NNN-YY)'**
  String get invoiceNumberLabel;

  /// No description provided for @invoiceNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Year suffix locked to {year}. Enter the 3 digits.'**
  String invoiceNumberHelper(String year);

  /// No description provided for @invoiceNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use three digits (e.g., 001). Year is fixed to the current YY.'**
  String get invoiceNumberInvalid;

  /// No description provided for @invoiceClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get invoiceClientLabel;

  /// No description provided for @invoiceClientRequired.
  ///
  /// In en, this message translates to:
  /// **'Client is required'**
  String get invoiceClientRequired;

  /// No description provided for @invoicePdfUrl.
  ///
  /// In en, this message translates to:
  /// **'Invoice PDF URL'**
  String get invoicePdfUrl;

  /// No description provided for @invoiceRegisteredAt.
  ///
  /// In en, this message translates to:
  /// **'Registered at'**
  String get invoiceRegisteredAt;

  /// No description provided for @invoiceRegisteredUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get invoiceRegisteredUnknown;

  /// No description provided for @invoiceParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get invoiceParties;

  /// No description provided for @invoiceClientSection.
  ///
  /// In en, this message translates to:
  /// **'Client billing'**
  String get invoiceClientSection;

  /// No description provided for @invoiceLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice lines'**
  String get invoiceLinesTitle;

  /// No description provided for @invoiceLinesPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice lines coming soon'**
  String get invoiceLinesPlaceholderTitle;

  /// No description provided for @invoiceLinesPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lines will list items with qty, unit price, tax and totals.'**
  String get invoiceLinesPlaceholderSubtitle;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown client'**
  String get unknownClient;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldIsRequired;

  /// No description provided for @taxRateShort.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get taxRateShort;

  /// No description provided for @invoiceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get invoiceStatusLabel;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get statusIssued;

  /// No description provided for @invoiceNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get invoiceNotesLabel;

  /// No description provided for @invoiceAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get invoiceAddLine;

  /// No description provided for @invoiceLinesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line'**
  String get invoiceLinesRequired;

  /// No description provided for @lineDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get lineDescription;

  /// No description provided for @lineQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get lineQuantity;

  /// No description provided for @lineUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get lineUnitPrice;

  /// No description provided for @lineTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax rate'**
  String get lineTaxRate;

  /// No description provided for @invoiceTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get invoiceTotalLabel;

  /// No description provided for @invoiceEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice editor'**
  String get invoiceEditorTitle;

  /// No description provided for @invoiceCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get invoiceCustomerTitle;

  /// No description provided for @invoiceDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get invoiceDatesTitle;

  /// No description provided for @invoiceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice date'**
  String get invoiceDateLabel;

  /// No description provided for @invoiceDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get invoiceDueDateLabel;

  /// No description provided for @invoiceFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get invoiceFromLabel;

  /// No description provided for @invoiceBillToLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill to'**
  String get invoiceBillToLabel;

  /// No description provided for @invoiceSelectClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get invoiceSelectClientLabel;

  /// No description provided for @invoiceSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoiceSubtotalLabel;

  /// No description provided for @invoiceTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get invoiceTaxLabel;

  /// No description provided for @invoiceNoLinesYet.
  ///
  /// In en, this message translates to:
  /// **'No lines yet'**
  String get invoiceNoLinesYet;

  /// No description provided for @invoicePdfGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF generated'**
  String get invoicePdfGeneratedLabel;

  /// No description provided for @invoicePdfNotGeneratedLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF not generated'**
  String get invoicePdfNotGeneratedLabel;

  /// No description provided for @invoiceIssueCta.
  ///
  /// In en, this message translates to:
  /// **'Issue invoice'**
  String get invoiceIssueCta;

  /// No description provided for @invoiceSaveDraftCta.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get invoiceSaveDraftCta;

  /// No description provided for @invoicePdfCta.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get invoicePdfCta;

  /// No description provided for @invoiceIssuingLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuing…'**
  String get invoiceIssuingLabel;

  /// No description provided for @invoiceDetailsShowCta.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get invoiceDetailsShowCta;

  /// No description provided for @invoiceDetailsHideCta.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get invoiceDetailsHideCta;

  /// No description provided for @invoiceClientSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search client'**
  String get invoiceClientSearchHint;

  /// No description provided for @invoiceNotesShowCta.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get invoiceNotesShowCta;

  /// No description provided for @invoiceNotesHideCta.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get invoiceNotesHideCta;

  /// No description provided for @invoiceNotesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get invoiceNotesOptionalLabel;

  /// No description provided for @invoiceClientInvoicesThisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoices this month'**
  String get invoiceClientInvoicesThisMonthLabel;

  /// No description provided for @invoiceDraftInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Drafts info'**
  String get invoiceDraftInfoTooltip;

  /// No description provided for @invoiceDraftInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Before creating a draft'**
  String get invoiceDraftInfoTitle;

  /// No description provided for @invoiceDraftInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Before creating a draft, make sure you do not have any pending drafts.'**
  String get invoiceDraftInfoMessage;

  /// No description provided for @invoicePendingDraftsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending drafts'**
  String get invoicePendingDraftsLabel;

  /// No description provided for @invoiceFillRequiredFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill the required fields'**
  String get invoiceFillRequiredFieldsError;

  /// No description provided for @invoiceDraftSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Draft saved: {invoiceNumber}'**
  String invoiceDraftSavedSnack(Object invoiceNumber);

  /// No description provided for @invoiceDraftSavedSnackNoNumber.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get invoiceDraftSavedSnackNoNumber;

  /// No description provided for @invoiceDraftSaveFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not save draft. Please try again.'**
  String get invoiceDraftSaveFailedSnack;

  /// No description provided for @invoiceIssueSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Invoice issued: {invoiceNumber}'**
  String invoiceIssueSuccessSnack(Object invoiceNumber);

  /// No description provided for @invoiceIssueFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not issue invoice. Please try again.'**
  String get invoiceIssueFailedSnack;

  /// No description provided for @invoicePdfPreviewFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not generate PDF preview. Please try again.'**
  String get invoicePdfPreviewFailedSnack;

  /// No description provided for @invoiceLogoTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice logo'**
  String get invoiceLogoTitle;

  /// No description provided for @invoiceLogoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shown on invoices and PDFs.'**
  String get invoiceLogoSubtitle;

  /// No description provided for @invoiceLogoUploadCta.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get invoiceLogoUploadCta;

  /// No description provided for @invoiceLogoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo URL'**
  String get invoiceLogoUrlLabel;

  /// No description provided for @invoiceLogoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logo set'**
  String get invoiceLogoEmpty;

  /// No description provided for @invoiceLogoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Logo updated'**
  String get invoiceLogoUpdated;

  /// No description provided for @groupInvoicesBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get groupInvoicesBusinessTitle;

  /// No description provided for @groupInvoicesTotalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice totals'**
  String get groupInvoicesTotalsTitle;

  /// No description provided for @groupInvoicesExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get groupInvoicesExpandTooltip;

  /// No description provided for @groupInvoicesCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get groupInvoicesCollapseTooltip;

  /// No description provided for @groupInvoicesClientsFlowCta.
  ///
  /// In en, this message translates to:
  /// **'Clients invoice flow'**
  String get groupInvoicesClientsFlowCta;

  /// No description provided for @groupInvoicesDraftInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft invoices'**
  String get groupInvoicesDraftInvoicesTitle;

  /// No description provided for @groupInvoicesSelectInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Select an invoice to see details'**
  String get groupInvoicesSelectInvoiceHint;

  /// No description provided for @groupInvoicesTabDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts ({count})'**
  String groupInvoicesTabDrafts(Object count);

  /// No description provided for @groupInvoicesTabInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices ({count})'**
  String groupInvoicesTabInvoices(Object count);

  /// No description provided for @groupInvoicesTotalsInline.
  ///
  /// In en, this message translates to:
  /// **'Issued: {issuedCount} • Drafts: {draftsCount}'**
  String groupInvoicesTotalsInline(Object draftsCount, Object issuedCount);

  /// No description provided for @groupInvoicesTotalsIssuedButton.
  ///
  /// In en, this message translates to:
  /// **'Issued: {count}'**
  String groupInvoicesTotalsIssuedButton(Object count);

  /// No description provided for @groupInvoicesTotalsDraftsButton.
  ///
  /// In en, this message translates to:
  /// **'Drafts: {count}'**
  String groupInvoicesTotalsDraftsButton(Object count);

  /// No description provided for @groupInvoicesRemoveDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove draft?'**
  String get groupInvoicesRemoveDraftTitle;

  /// No description provided for @groupInvoicesRemoveInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove invoice?'**
  String get groupInvoicesRemoveInvoiceTitle;

  /// No description provided for @groupInvoicesRemoveInvoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete the invoice {invoiceNumber}.'**
  String groupInvoicesRemoveInvoiceMessage(Object invoiceNumber);

  /// No description provided for @groupInvoicesRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Invoice removed'**
  String get groupInvoicesRemovedSnack;

  /// No description provided for @groupInvoicesInvoiceAlreadyRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Invoice not found (already removed). Refreshing…'**
  String get groupInvoicesInvoiceAlreadyRemovedSnack;

  /// No description provided for @groupInvoicesRemoveFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not remove invoice: {reason}'**
  String groupInvoicesRemoveFailedSnack(Object reason);

  /// No description provided for @clientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsTitle;

  /// No description provided for @selectClientFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a client to view billing and invoices'**
  String get selectClientFirst;

  /// No description provided for @clientEntityTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entity type'**
  String get clientEntityTypeLabel;

  /// No description provided for @clientEntityTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. community, company, individual'**
  String get clientEntityTypeHint;

  /// No description provided for @clientPropertyKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Property kind'**
  String get clientPropertyKindLabel;

  /// No description provided for @clientPropertyKindHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. building, apartment, chalet'**
  String get clientPropertyKindHint;

  /// No description provided for @clientClassificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved options'**
  String get clientClassificationTitle;

  /// No description provided for @clientClassificationManageCta.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get clientClassificationManageCta;

  /// No description provided for @clientClassificationManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage saved options'**
  String get clientClassificationManageTitle;

  /// No description provided for @clientAddOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add option (max 50)'**
  String get clientAddOptionHint;

  /// No description provided for @clientClassificationManageHint.
  ///
  /// In en, this message translates to:
  /// **'These options are saved for the group and can be reused when assigning types to clients.'**
  String get clientClassificationManageHint;

  /// No description provided for @clientClassificationSaveCta.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get clientClassificationSaveCta;

  /// No description provided for @clientClassificationSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Options saved'**
  String get clientClassificationSavedSnack;

  /// No description provided for @clientClassificationRebuildCta.
  ///
  /// In en, this message translates to:
  /// **'Rebuild'**
  String get clientClassificationRebuildCta;

  /// No description provided for @clientClassificationRebuiltSnack.
  ///
  /// In en, this message translates to:
  /// **'Options rebuilt'**
  String get clientClassificationRebuiltSnack;

  /// No description provided for @clientClassificationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get clientClassificationSectionTitle;

  /// No description provided for @clientClassificationExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get clientClassificationExpandTooltip;

  /// No description provided for @clientClassificationCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get clientClassificationCollapseTooltip;

  /// No description provided for @clientHideInactiveChip.
  ///
  /// In en, this message translates to:
  /// **'Hide inactive'**
  String get clientHideInactiveChip;

  /// No description provided for @clientInactiveHiddenChip.
  ///
  /// In en, this message translates to:
  /// **'Inactive hidden'**
  String get clientInactiveHiddenChip;

  /// No description provided for @clientDetailsExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get clientDetailsExpandTooltip;

  /// No description provided for @clientDetailsCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get clientDetailsCollapseTooltip;

  /// No description provided for @clientSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search clients…'**
  String get clientSearchHint;

  /// No description provided for @clientFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get clientFiltersTitle;

  /// No description provided for @clientFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientFiltersClear;

  /// No description provided for @clientSelectedHiddenByFilters.
  ///
  /// In en, this message translates to:
  /// **'Selected client is hidden by filters'**
  String get clientSelectedHiddenByFilters;

  /// No description provided for @clientQuickAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick assign'**
  String get clientQuickAssignTitle;

  /// No description provided for @clientQuickAssignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to assign. Tap again to clear.'**
  String get clientQuickAssignSubtitle;

  /// No description provided for @clientClassificationUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Client updated'**
  String get clientClassificationUpdatedSnack;

  /// No description provided for @clientBillingMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing billing information'**
  String get clientBillingMissingTitle;

  /// No description provided for @clientBillingMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete: {fields}'**
  String clientBillingMissingMessage(String fields);

  /// No description provided for @billingDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get billingDocumentType;

  /// No description provided for @documentTypeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get documentTypeInvoice;

  /// No description provided for @documentTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get documentTypeReceipt;

  /// No description provided for @receiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsTitle;

  /// No description provided for @createReceiptCta.
  ///
  /// In en, this message translates to:
  /// **'Create receipt'**
  String get createReceiptCta;

  /// No description provided for @groupReceiptsTabDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts ({count})'**
  String groupReceiptsTabDrafts(Object count);

  /// No description provided for @groupReceiptsTabReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts ({count})'**
  String groupReceiptsTabReceipts(Object count);

  /// No description provided for @groupReceiptsSelectReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Select a receipt to see details'**
  String get groupReceiptsSelectReceiptHint;

  /// No description provided for @groupReceiptsRemoveDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove receipt draft?'**
  String get groupReceiptsRemoveDraftTitle;

  /// No description provided for @groupReceiptsRemoveDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete the receipt {receiptNumber}.'**
  String groupReceiptsRemoveDraftMessage(Object receiptNumber);

  /// No description provided for @groupReceiptsRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Receipt removed'**
  String get groupReceiptsRemovedSnack;

  /// No description provided for @groupReceiptsAlreadyRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Receipt not found (already removed). Refreshing…'**
  String get groupReceiptsAlreadyRemovedSnack;

  /// No description provided for @groupReceiptsCannotRemoveIssuedSnack.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove an issued receipt'**
  String get groupReceiptsCannotRemoveIssuedSnack;

  /// No description provided for @groupReceiptsRemoveFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not remove receipt: {reason}'**
  String groupReceiptsRemoveFailedSnack(Object reason);

  /// No description provided for @receiptDraftNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Draft receipt'**
  String get receiptDraftNumberPlaceholder;

  /// No description provided for @receiptDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Date unknown'**
  String get receiptDateUnknown;

  /// No description provided for @receiptIssueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get receiptIssueDateLabel;

  /// No description provided for @receiptLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt lines'**
  String get receiptLinesTitle;

  /// No description provided for @receiptSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get receiptSummaryTitle;

  /// No description provided for @receiptNoLinesYet.
  ///
  /// In en, this message translates to:
  /// **'No lines yet'**
  String get receiptNoLinesYet;

  /// No description provided for @receiptLineTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receiptLineTotalLabel;

  /// No description provided for @receiptSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get receiptSubtotalLabel;

  /// No description provided for @receiptTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receiptTotalLabel;

  /// No description provided for @receiptIssueCta.
  ///
  /// In en, this message translates to:
  /// **'Issue receipt'**
  String get receiptIssueCta;

  /// No description provided for @receiptLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Issued receipts are locked'**
  String get receiptLockedHint;

  /// No description provided for @receiptEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt {number}'**
  String receiptEditorTitle(Object number);

  /// No description provided for @receiptEditorFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptEditorFormTitle;

  /// No description provided for @receiptSelectClientLabel.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get receiptSelectClientLabel;

  /// No description provided for @receiptClientRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a client first'**
  String get receiptClientRequired;

  /// No description provided for @receiptLinesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line'**
  String get receiptLinesRequired;

  /// No description provided for @receiptNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes'**
  String get receiptNotesHint;

  /// No description provided for @receiptDraftSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get receiptDraftSavedSnack;

  /// No description provided for @receiptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save receipt'**
  String get receiptSaveFailed;

  /// No description provided for @receiptPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not preview receipt PDF'**
  String get receiptPreviewFailed;

  /// No description provided for @receiptDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download receipt PDF'**
  String get receiptDownloadFailed;

  /// No description provided for @receiptIssueConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue receipt?'**
  String get receiptIssueConfirmTitle;

  /// No description provided for @receiptIssueConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Assign final number and lock the receipt.'**
  String get receiptIssueConfirmMessage;

  /// No description provided for @receiptIssueSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Receipt issued: {receiptNumber}'**
  String receiptIssueSuccessSnack(Object receiptNumber);

  /// No description provided for @receiptIssueFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not issue receipt'**
  String get receiptIssueFailed;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @addLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get addLine;

  /// No description provided for @statementsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Statements (Excel)'**
  String get statementsTabTitle;

  /// No description provided for @bankProvidersTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Providers'**
  String get bankProvidersTabTitle;

  /// No description provided for @statementsImportTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get statementsImportTabTitle;

  /// No description provided for @statementsHistoryTabTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get statementsHistoryTabTitle;

  /// No description provided for @statementsStepUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get statementsStepUpload;

  /// No description provided for @statementsStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review data'**
  String get statementsStepReview;

  /// No description provided for @statementsStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm import'**
  String get statementsStepConfirm;

  /// No description provided for @statementsReviewDisabled.
  ///
  /// In en, this message translates to:
  /// **'Upload a file to review parsed entries and deduplication.'**
  String get statementsReviewDisabled;

  /// No description provided for @statementsConfirmHelp.
  ///
  /// In en, this message translates to:
  /// **'Review the summary and confirm to finalize the import.'**
  String get statementsConfirmHelp;

  /// No description provided for @statementsConfirmDisabled.
  ///
  /// In en, this message translates to:
  /// **'Complete the upload to enable confirmation.'**
  String get statementsConfirmDisabled;

  /// No description provided for @statementsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm import'**
  String get statementsConfirmAction;

  /// No description provided for @statementsConfirmSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import confirmed.'**
  String get statementsConfirmSuccess;

  /// No description provided for @statementsStepDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous step to continue.'**
  String get statementsStepDisabledHint;

  /// No description provided for @statementsDragDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your statement'**
  String get statementsDragDropTitle;

  /// No description provided for @statementsDragDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag your file here or click to select'**
  String get statementsDragDropHint;

  /// No description provided for @statementsFormatsHint.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: .xls, .xlsx · Max 10 MB'**
  String get statementsFormatsHint;

  /// No description provided for @statementsRemoveFile.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get statementsRemoveFile;

  /// No description provided for @statementsSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'🔒 Your data is processed securely'**
  String get statementsSecurityNote;

  /// No description provided for @statementsFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File exceeds 10 MB limit'**
  String get statementsFileTooLarge;

  /// No description provided for @statementsResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import results'**
  String get statementsResultsTitle;

  /// No description provided for @statementsResultsHelp.
  ///
  /// In en, this message translates to:
  /// **'Review deduplication and client matching before confirming the import.'**
  String get statementsResultsHelp;

  /// No description provided for @statementsResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Upload a file to see the import result and preview.'**
  String get statementsResultsEmpty;

  /// No description provided for @statementsDuplicateFileError.
  ///
  /// In en, this message translates to:
  /// **'This file was already imported (duplicate checksum).'**
  String get statementsDuplicateFileError;

  /// No description provided for @statementsFilterYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statementsFilterYear;

  /// No description provided for @statementsFilterFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get statementsFilterFrom;

  /// No description provided for @statementsFilterTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get statementsFilterTo;

  /// No description provided for @statementsApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get statementsApplyFilters;

  /// No description provided for @statementsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get statementsClearFilters;

  /// No description provided for @statementsPageSize.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get statementsPageSize;

  /// No description provided for @statementsPageInfo.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String statementsPageInfo(int page, int total);

  /// No description provided for @statementsPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get statementsPrevPage;

  /// No description provided for @statementsNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get statementsNextPage;

  /// No description provided for @statementsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get statementsSummaryTitle;

  /// No description provided for @statementsSummaryMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get statementsSummaryMonthly;

  /// No description provided for @statementsSummaryYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get statementsSummaryYearly;

  /// No description provided for @statementsSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get statementsSummaryNet;

  /// No description provided for @statementsSummaryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get statementsSummaryIncome;

  /// No description provided for @statementsSummaryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get statementsSummaryExpense;

  /// No description provided for @statementsSummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No summary data for this range.'**
  String get statementsSummaryEmpty;

  /// No description provided for @statementsSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'total {total} • {count} entries'**
  String statementsSummaryLine(String total, String count);

  /// No description provided for @statementsActionViewEntries.
  ///
  /// In en, this message translates to:
  /// **'View entries'**
  String get statementsActionViewEntries;

  /// No description provided for @statementsReprocessTitle.
  ///
  /// In en, this message translates to:
  /// **'Reprocess batch?'**
  String get statementsReprocessTitle;

  /// No description provided for @statementsReprocessMessage.
  ///
  /// In en, this message translates to:
  /// **'This will re-run the parser using the saved column map for this batch.'**
  String get statementsReprocessMessage;

  /// No description provided for @statementsReprocessAction.
  ///
  /// In en, this message translates to:
  /// **'Reprocess'**
  String get statementsReprocessAction;

  /// No description provided for @statementsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete batch?'**
  String get statementsDeleteTitle;

  /// No description provided for @statementsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the batch and all its entries.'**
  String get statementsDeleteMessage;

  /// No description provided for @statementsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get statementsDeleteAction;

  /// No description provided for @statementsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get statementsCancel;

  /// No description provided for @statementsDuplicateSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} duplicate movements skipped — View details'**
  String statementsDuplicateSummary(String count);

  /// No description provided for @statementsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get statementsViewDetails;

  /// No description provided for @statementsStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get statementsStatusSuccess;

  /// No description provided for @statementsStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get statementsStatusWarning;

  /// No description provided for @statementsShowTechDetails.
  ///
  /// In en, this message translates to:
  /// **'View technical details'**
  String get statementsShowTechDetails;

  /// No description provided for @statementsHideTechDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide technical details'**
  String get statementsHideTechDetails;

  /// No description provided for @statementsTechBatchId.
  ///
  /// In en, this message translates to:
  /// **'Batch ID'**
  String get statementsTechBatchId;

  /// No description provided for @statementsTechChecksum.
  ///
  /// In en, this message translates to:
  /// **'Checksum'**
  String get statementsTechChecksum;

  /// No description provided for @statementsTechUploader.
  ///
  /// In en, this message translates to:
  /// **'Uploaded by'**
  String get statementsTechUploader;

  /// No description provided for @statementsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get statementsCopy;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @statementsNoImportsHelp.
  ///
  /// In en, this message translates to:
  /// **'When you import a file, past batches will appear here for quick review.'**
  String get statementsNoImportsHelp;

  /// No description provided for @statementsDownloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Excel template'**
  String get statementsDownloadTemplate;

  /// No description provided for @statementsViewExample.
  ///
  /// In en, this message translates to:
  /// **'View example'**
  String get statementsViewExample;

  /// No description provided for @statementsUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload XLS/XLSX statements to parse, dedupe, and link entries to clients. Duplicates are auto-skipped and reported separately.'**
  String get statementsUploadDescription;

  /// No description provided for @statementsChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose XLS/XLSX'**
  String get statementsChooseFile;

  /// No description provided for @statementsNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get statementsNoFileSelected;

  /// No description provided for @statementsSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected: {fileName}'**
  String statementsSelectedFile(String fileName);

  /// No description provided for @statementsUploadParse.
  ///
  /// In en, this message translates to:
  /// **'Upload & parse'**
  String get statementsUploadParse;

  /// No description provided for @statementsUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get statementsUploadFailed;

  /// No description provided for @statementsUploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete'**
  String get statementsUploadComplete;

  /// No description provided for @statementsFileReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read file bytes'**
  String get statementsFileReadError;

  /// No description provided for @statementsBatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch: {batchId}'**
  String statementsBatchLabel(String batchId);

  /// No description provided for @statementsSheetLabel.
  ///
  /// In en, this message translates to:
  /// **'Sheet: {sheet}'**
  String statementsSheetLabel(String sheet);

  /// No description provided for @statementsInsertedLabel.
  ///
  /// In en, this message translates to:
  /// **'Inserted: {count}'**
  String statementsInsertedLabel(String count);

  /// No description provided for @statementsSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped: {count}'**
  String statementsSkippedLabel(String count);

  /// No description provided for @statementsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview (first {count} entries)'**
  String statementsPreviewTitle(int count);

  /// No description provided for @statementsNoDescription.
  ///
  /// In en, this message translates to:
  /// **'(no description)'**
  String get statementsNoDescription;

  /// No description provided for @statementsAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'amount: {amount}'**
  String statementsAmountLabel(String amount);

  /// No description provided for @statementsPastImports.
  ///
  /// In en, this message translates to:
  /// **'Past imports'**
  String get statementsPastImports;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @statementsNoImports.
  ///
  /// In en, this message translates to:
  /// **'No imports yet.'**
  String get statementsNoImports;

  /// No description provided for @statementsBatchFallback.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get statementsBatchFallback;

  /// No description provided for @statementsBatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch {batchId}'**
  String statementsBatchTitle(String batchId);

  /// No description provided for @statementsUploadedAt.
  ///
  /// In en, this message translates to:
  /// **'uploaded: {uploadedAt}'**
  String statementsUploadedAt(String uploadedAt);

  /// No description provided for @statementsFileLabel.
  ///
  /// In en, this message translates to:
  /// **'file: {fileName}'**
  String statementsFileLabel(String fileName);

  /// No description provided for @statementsChecksumLabel.
  ///
  /// In en, this message translates to:
  /// **'checksum: {checksum}'**
  String statementsChecksumLabel(String checksum);

  /// No description provided for @statementsUploaderLabel.
  ///
  /// In en, this message translates to:
  /// **'uploader: {uploader}'**
  String statementsUploaderLabel(String uploader);

  /// No description provided for @statementsEntryCount.
  ///
  /// In en, this message translates to:
  /// **'entries: {count}'**
  String statementsEntryCount(String count);

  /// No description provided for @statementsBatchEntries.
  ///
  /// In en, this message translates to:
  /// **'Batch entries'**
  String get statementsBatchEntries;

  /// No description provided for @statementsBatchChip.
  ///
  /// In en, this message translates to:
  /// **'batch: {batchId}'**
  String statementsBatchChip(String batchId);

  /// No description provided for @statementsSelectBatch.
  ///
  /// In en, this message translates to:
  /// **'Select a batch to view entries.'**
  String get statementsSelectBatch;

  /// No description provided for @statementsHeaderDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get statementsHeaderDate;

  /// No description provided for @statementsHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get statementsHeaderDescription;

  /// No description provided for @statementsHeaderDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get statementsHeaderDetails;

  /// No description provided for @statementsHeaderAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get statementsHeaderAmount;

  /// No description provided for @statementsHeaderBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get statementsHeaderBalance;

  /// No description provided for @statementsHeaderClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get statementsHeaderClient;

  /// No description provided for @statementsHeaderActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get statementsHeaderActions;

  /// No description provided for @statementsHeaderBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get statementsHeaderBatch;

  /// No description provided for @statementsActionSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get statementsActionSuggest;

  /// No description provided for @statementsActionLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get statementsActionLink;

  /// No description provided for @statementsUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get statementsUnlinked;

  /// No description provided for @statementsAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'All statements'**
  String get statementsAllDataTitle;

  /// No description provided for @statementsAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review all movements, link clients, and keep data clean.'**
  String get statementsAllDataSubtitle;

  /// No description provided for @statementsAllDataEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Import an Excel file to review movements here.'**
  String get statementsAllDataEmpty;

  /// No description provided for @statementsFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get statementsFiltersTitle;

  /// No description provided for @statementsPaginationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pagination'**
  String get statementsPaginationTitle;

  /// No description provided for @statementsPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick ranges'**
  String get statementsPresetsTitle;

  /// No description provided for @statementsPickRange.
  ///
  /// In en, this message translates to:
  /// **'Pick range'**
  String get statementsPickRange;

  /// No description provided for @statementsPanelCollapse.
  ///
  /// In en, this message translates to:
  /// **'Hide guidance panel'**
  String get statementsPanelCollapse;

  /// No description provided for @statementsPanelExpand.
  ///
  /// In en, this message translates to:
  /// **'Show guidance panel'**
  String get statementsPanelExpand;

  /// No description provided for @statementsStepContextUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1 · Upload file'**
  String get statementsStepContextUploadTitle;

  /// No description provided for @statementsStepContextReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2 · Review data'**
  String get statementsStepContextReviewTitle;

  /// No description provided for @statementsStepContextConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3 · Confirm import'**
  String get statementsStepContextConfirmTitle;

  /// No description provided for @statementsImportSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import summary'**
  String get statementsImportSummaryTitle;

  /// No description provided for @statementsConfirmChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Final checklist'**
  String get statementsConfirmChecklistTitle;

  /// No description provided for @statementsConfirmChecklistItem1.
  ///
  /// In en, this message translates to:
  /// **'Verify duplicates and totals before confirming.'**
  String get statementsConfirmChecklistItem1;

  /// No description provided for @statementsConfirmChecklistItem2.
  ///
  /// In en, this message translates to:
  /// **'You can still link clients after import.'**
  String get statementsConfirmChecklistItem2;

  /// No description provided for @statementsPresetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statementsPresetThisMonth;

  /// No description provided for @statementsPresetLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get statementsPresetLast30Days;

  /// No description provided for @statementsPresetThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get statementsPresetThisYear;

  /// No description provided for @statementsFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'Active filters'**
  String get statementsFiltersActive;

  /// No description provided for @statementsFiltersNone.
  ///
  /// In en, this message translates to:
  /// **'No active filters'**
  String get statementsFiltersNone;

  /// No description provided for @statementsColumnBatchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Batch id'**
  String get statementsColumnBatchTooltip;

  /// No description provided for @statementsColumnBatchCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy batch id'**
  String get statementsColumnBatchCopy;

  /// No description provided for @statementsActionsTooltipSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest a client based on description'**
  String get statementsActionsTooltipSuggest;

  /// No description provided for @statementsActionsTooltipLink.
  ///
  /// In en, this message translates to:
  /// **'Manually link a client'**
  String get statementsActionsTooltipLink;

  /// No description provided for @statementsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String statementsSelectedCount(int count);

  /// No description provided for @statementsBulkSuggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest for selected'**
  String get statementsBulkSuggest;

  /// No description provided for @statementsBulkLink.
  ///
  /// In en, this message translates to:
  /// **'Link in bulk'**
  String get statementsBulkLink;

  /// No description provided for @statementsClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get statementsClearSelection;

  /// No description provided for @statementsBulkSuggestResult.
  ///
  /// In en, this message translates to:
  /// **'{withSuggestions} suggestions found · {linked} linked'**
  String statementsBulkSuggestResult(int withSuggestions, int linked);

  /// No description provided for @statementsBulkLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Link selected entries'**
  String get statementsBulkLinkTitle;

  /// No description provided for @statementsTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get statementsTotalAmount;

  /// No description provided for @statementsTotalCount.
  ///
  /// In en, this message translates to:
  /// **'Total movements'**
  String get statementsTotalCount;

  /// No description provided for @statementsLastBalance.
  ///
  /// In en, this message translates to:
  /// **'Latest balance'**
  String get statementsLastBalance;

  /// No description provided for @statementsLastBalanceDate.
  ///
  /// In en, this message translates to:
  /// **'as of {date}'**
  String statementsLastBalanceDate(String date);

  /// No description provided for @statementsNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get statementsNavTitle;

  /// No description provided for @statementsNavCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse menu'**
  String get statementsNavCollapse;

  /// No description provided for @statementsNavExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand menu'**
  String get statementsNavExpand;

  /// No description provided for @statementsAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statements Analytics'**
  String get statementsAnalyticsTitle;

  /// No description provided for @statementsAnalyticsBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get statementsAnalyticsBatch;

  /// No description provided for @statementsAnalyticsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statementsAnalyticsMonth;

  /// No description provided for @statementsAnalyticsMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get statementsAnalyticsMode;

  /// No description provided for @statementsAnalyticsCompareMode.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get statementsAnalyticsCompareMode;

  /// No description provided for @statementsAnalyticsCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Dual-period comparison'**
  String get statementsAnalyticsCompareTitle;

  /// No description provided for @statementsAnalyticsCompareHelp.
  ///
  /// In en, this message translates to:
  /// **'Compare calendar month vs settlement window totals for each month in the selected year.'**
  String get statementsAnalyticsCompareHelp;

  /// No description provided for @statementsAnalyticsComparePickYear.
  ///
  /// In en, this message translates to:
  /// **'Select a year to see the comparison.'**
  String get statementsAnalyticsComparePickYear;

  /// No description provided for @statementsAnalyticsCompareBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get statementsAnalyticsCompareBoth;

  /// No description provided for @statementsAnalyticsCompareCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get statementsAnalyticsCompareCalendar;

  /// No description provided for @statementsAnalyticsCompareSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get statementsAnalyticsCompareSettlement;

  /// No description provided for @statementsAnalyticsCompareDelta.
  ///
  /// In en, this message translates to:
  /// **'Delta'**
  String get statementsAnalyticsCompareDelta;

  /// No description provided for @statementsAnalyticsModeCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar month'**
  String get statementsAnalyticsModeCalendar;

  /// No description provided for @statementsAnalyticsModeSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement window'**
  String get statementsAnalyticsModeSettlement;

  /// No description provided for @statementsAnalyticsModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String statementsAnalyticsModeLabel(Object mode);

  /// No description provided for @statementsAnalyticsSettlementStart.
  ///
  /// In en, this message translates to:
  /// **'Start day'**
  String get statementsAnalyticsSettlementStart;

  /// No description provided for @statementsAnalyticsSettlementEnd.
  ///
  /// In en, this message translates to:
  /// **'End day'**
  String get statementsAnalyticsSettlementEnd;

  /// No description provided for @statementsAnalyticsPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period: {from} – {to}'**
  String statementsAnalyticsPeriodLabel(Object from, Object to);

  /// No description provided for @statementsAnalyticsPeriodPending.
  ///
  /// In en, this message translates to:
  /// **'Period: select a year and month'**
  String get statementsAnalyticsPeriodPending;

  /// No description provided for @statementsAnalyticsTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get statementsAnalyticsTop;

  /// No description provided for @statementsAnalyticsTopHelp.
  ///
  /// In en, this message translates to:
  /// **'Top {count}'**
  String statementsAnalyticsTopHelp(int count);

  /// No description provided for @statementsAnalyticsTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get statementsAnalyticsTrends;

  /// No description provided for @statementsAnalyticsTrendsHelp.
  ///
  /// In en, this message translates to:
  /// **'Compare income, expense, and net across the selected range.'**
  String get statementsAnalyticsTrendsHelp;

  /// No description provided for @statementsAnalyticsYearAverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Year average'**
  String get statementsAnalyticsYearAverageTitle;

  /// No description provided for @statementsAnalyticsYearAveragesTitle.
  ///
  /// In en, this message translates to:
  /// **'Average monthly income & expense by year'**
  String get statementsAnalyticsYearAveragesTitle;

  /// No description provided for @statementsAnalyticsAverageIncome.
  ///
  /// In en, this message translates to:
  /// **'Avg income'**
  String get statementsAnalyticsAverageIncome;

  /// No description provided for @statementsAnalyticsAverageExpense.
  ///
  /// In en, this message translates to:
  /// **'Avg expense'**
  String get statementsAnalyticsAverageExpense;

  /// No description provided for @statementsAnalyticsTotalsTab.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get statementsAnalyticsTotalsTab;

  /// No description provided for @statementsAnalyticsAverageTab.
  ///
  /// In en, this message translates to:
  /// **'Average per entry'**
  String get statementsAnalyticsAverageTab;

  /// No description provided for @statementsAnalyticsTopMerchants.
  ///
  /// In en, this message translates to:
  /// **'Top merchants'**
  String get statementsAnalyticsTopMerchants;

  /// No description provided for @statementsAnalyticsTopHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Largest merchants by total amount for the selected filters.'**
  String get statementsAnalyticsTopHelpSubtitle;

  /// No description provided for @statementsAnalyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'No analytics data yet.'**
  String get statementsAnalyticsNoData;

  /// No description provided for @statementsAnalyticsNoMerchants.
  ///
  /// In en, this message translates to:
  /// **'No merchant data for this range.'**
  String get statementsAnalyticsNoMerchants;

  /// No description provided for @statementsAnalyticsNoBatches.
  ///
  /// In en, this message translates to:
  /// **'No statement batches available yet.'**
  String get statementsAnalyticsNoBatches;

  /// No description provided for @statementsAnalyticsAllBatches.
  ///
  /// In en, this message translates to:
  /// **'All batches'**
  String get statementsAnalyticsAllBatches;

  /// No description provided for @statementsAnalyticsAllYears.
  ///
  /// In en, this message translates to:
  /// **'All years'**
  String get statementsAnalyticsAllYears;

  /// No description provided for @statementsAnalyticsAllMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get statementsAnalyticsAllMonths;

  /// No description provided for @statementsAnalyticsNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Select a batch to load analytics.'**
  String get statementsAnalyticsNoSelection;

  /// No description provided for @statementsAnalyticsMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Month {month} selected'**
  String statementsAnalyticsMonthHint(int month);

  /// No description provided for @statementsAnalyticsExpand.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get statementsAnalyticsExpand;

  /// No description provided for @statementsAnalyticsCollapse.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get statementsAnalyticsCollapse;

  /// No description provided for @statementsFreshnessThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold (days)'**
  String get statementsFreshnessThreshold;

  /// No description provided for @statementsFreshnessLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading freshness...'**
  String get statementsFreshnessLoading;

  /// No description provided for @statementsFreshnessNoData.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get statementsFreshnessNoData;

  /// No description provided for @statementsFreshnessStale.
  ///
  /// In en, this message translates to:
  /// **'Last entry: {date} ({days} days ago)'**
  String statementsFreshnessStale(Object date, Object days);

  /// No description provided for @statementsFreshnessUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date (Last entry: {date})'**
  String statementsFreshnessUpToDate(Object date);

  /// No description provided for @statementsFreshnessSendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send reminder'**
  String get statementsFreshnessSendReminder;

  /// No description provided for @statementsFreshnessReminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent'**
  String get statementsFreshnessReminderSent;

  /// No description provided for @statementsFreshnessReminderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reminder'**
  String get statementsFreshnessReminderFailed;

  /// No description provided for @statementsFreshnessNotStale.
  ///
  /// In en, this message translates to:
  /// **'Data is not stale. No notification sent.'**
  String get statementsFreshnessNotStale;

  /// No description provided for @statementsReminderSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings'**
  String get statementsReminderSettingsTitle;

  /// No description provided for @statementsReminderSettingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading reminder settings...'**
  String get statementsReminderSettingsLoading;

  /// No description provided for @statementsReminderSettingsAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto reminders'**
  String get statementsReminderSettingsAuto;

  /// No description provided for @statementsReminderSettingsThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold (days)'**
  String get statementsReminderSettingsThreshold;

  /// No description provided for @statementsReminderSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings saved'**
  String get statementsReminderSettingsSaved;

  /// No description provided for @statementsReminderSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save reminder settings'**
  String get statementsReminderSettingsFailed;

  /// No description provided for @statementsReminderStatusOn.
  ///
  /// In en, this message translates to:
  /// **'Auto reminders ON ({days} days)'**
  String statementsReminderStatusOn(Object days);

  /// No description provided for @statementsReminderStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Auto reminders OFF'**
  String get statementsReminderStatusOff;

  /// No description provided for @statementsReminderStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Auto reminders: N/A'**
  String get statementsReminderStatusUnknown;

  /// No description provided for @statementsAllDataSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary for current range'**
  String get statementsAllDataSummaryTitle;

  /// No description provided for @dashboardNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get dashboardNavTitle;

  /// No description provided for @dashboardNavCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse menu'**
  String get dashboardNavCollapse;

  /// No description provided for @dashboardNavExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand menu'**
  String get dashboardNavExpand;

  /// No description provided for @groupInvoicesNavCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse menu'**
  String get groupInvoicesNavCollapse;

  /// No description provided for @groupInvoicesNavExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand menu'**
  String get groupInvoicesNavExpand;

  /// No description provided for @statementsRowDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement details'**
  String get statementsRowDetailsTitle;

  /// No description provided for @statementsRowDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Batch {batchId}'**
  String statementsRowDetailsSubtitle(String batchId);

  /// No description provided for @statementsRowDetailsRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw data'**
  String get statementsRowDetailsRaw;

  /// No description provided for @statementsNoSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No client suggestions found'**
  String get statementsNoSuggestions;

  /// No description provided for @statementsSuggestedClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested clients'**
  String get statementsSuggestedClientsTitle;

  /// No description provided for @statementsLinkClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Link client'**
  String get statementsLinkClientTitle;

  /// No description provided for @statementsSearchClients.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get statementsSearchClients;

  /// No description provided for @statementsNoClientsMatch.
  ///
  /// In en, this message translates to:
  /// **'No clients match your search'**
  String get statementsNoClientsMatch;

  /// No description provided for @statementsClearLink.
  ///
  /// In en, this message translates to:
  /// **'Clear link'**
  String get statementsClearLink;

  /// No description provided for @statementsUnnamedClient.
  ///
  /// In en, this message translates to:
  /// **'(unnamed)'**
  String get statementsUnnamedClient;

  /// No description provided for @statementsImportExcelTab.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get statementsImportExcelTab;
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
