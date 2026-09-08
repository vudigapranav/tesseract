import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_kha.dart';
import 'app_localizations_lus.dart';
import 'app_localizations_mni.dart';

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
    Locale('as'),
    Locale('bn'),
    Locale('en'),
    Locale('kha'),
    Locale('lus'),
    Locale('mni')
  ];

  /// Product name. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Tesseract'**
  String get appName;

  /// This language's own name, in its own script, for the language selector.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'A familiar moment.\nA little joy.'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up meaningful activities and everyday reminders, together.'**
  String get signInSubtitle;

  /// No description provided for @roleCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get roleCaregiver;

  /// No description provided for @roleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get roleDoctor;

  /// No description provided for @emailCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver email'**
  String get emailCaregiver;

  /// No description provided for @emailDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor email'**
  String get emailDoctor;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Verifying access…'**
  String get signingIn;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify sign-in and access. Check your details and connection.'**
  String get signInFailed;

  /// No description provided for @signInNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not configured in this build. It needs a Firebase project and a backend address, which are supplied at build time. Nothing is signed in until then — there is no offline substitute.'**
  String get signInNotConfigured;

  /// No description provided for @signInPatientNote.
  ///
  /// In en, this message translates to:
  /// **'The person using the activities does not sign in. A caregiver sets things up and hands the device over.'**
  String get signInPatientNote;

  /// No description provided for @openPreview.
  ///
  /// In en, this message translates to:
  /// **'Open synthetic development preview'**
  String get openPreview;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @interfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get interfaceLanguage;

  /// No description provided for @interfaceLanguageHelp.
  ///
  /// In en, this message translates to:
  /// **'The language of menus and buttons for you.'**
  String get interfaceLanguageHelp;

  /// No description provided for @patientLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language for the person playing'**
  String get patientLanguage;

  /// No description provided for @patientLanguageHelp.
  ///
  /// In en, this message translates to:
  /// **'Activities and instructions use this. It can be different from your own.'**
  String get patientLanguageHelp;

  /// No description provided for @draftTranslationNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft translation. Not yet checked by a fluent speaker.'**
  String get draftTranslationNotice;

  /// No description provided for @translationCoverage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% translated'**
  String translationCoverage(int percent);

  /// No description provided for @awaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting native review'**
  String get awaitingReview;

  /// No description provided for @fallsBackToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Anything not yet translated is shown in English.'**
  String get fallsBackToEnglish;

  /// No description provided for @caregiverGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String caregiverGreeting(String name);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @noPatientYet.
  ///
  /// In en, this message translates to:
  /// **'No patient set up yet'**
  String get noPatientYet;

  /// No description provided for @needsYourDecision.
  ///
  /// In en, this message translates to:
  /// **'Needs your decision'**
  String get needsYourDecision;

  /// No description provided for @suggestedChange.
  ///
  /// In en, this message translates to:
  /// **'A suggested change'**
  String get suggestedChange;

  /// No description provided for @levelChange.
  ///
  /// In en, this message translates to:
  /// **'{game}: from level {from} to level {to}'**
  String levelChange(String game, int from, int to);

  /// No description provided for @useLevel.
  ///
  /// In en, this message translates to:
  /// **'Use level {level}'**
  String useLevel(int level);

  /// No description provided for @chooseLevel.
  ///
  /// In en, this message translates to:
  /// **'Choose level'**
  String get chooseLevel;

  /// No description provided for @keepAsIs.
  ///
  /// In en, this message translates to:
  /// **'Keep as is'**
  String get keepAsIs;

  /// No description provided for @suggestionCaveat.
  ///
  /// In en, this message translates to:
  /// **'This is a suggestion from recorded activity only, using settings that are still being tested. You decide.'**
  String get suggestionCaveat;

  /// No description provided for @decisionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved. The new activity is ready for the next session.'**
  String get decisionApproved;

  /// No description provided for @decisionModified.
  ///
  /// In en, this message translates to:
  /// **'Saved your choice. That is what will be offered next.'**
  String get decisionModified;

  /// No description provided for @decisionRejected.
  ///
  /// In en, this message translates to:
  /// **'Kept the current activity. Nothing has changed.'**
  String get decisionRejected;

  /// No description provided for @decisionFailed.
  ///
  /// In en, this message translates to:
  /// **'That could not be saved. Nothing was changed.'**
  String get decisionFailed;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activities recorded yet. Once a session is played it will appear here.'**
  String get noActivityYet;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUp;

  /// No description provided for @patientBasics.
  ///
  /// In en, this message translates to:
  /// **'Patient basics'**
  String get patientBasics;

  /// No description provided for @patientBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, age, language'**
  String get patientBasicsSubtitle;

  /// No description provided for @knowMe.
  ///
  /// In en, this message translates to:
  /// **'Know Me'**
  String get knowMe;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @settingsAndSync.
  ///
  /// In en, this message translates to:
  /// **'Settings & sync'**
  String get settingsAndSync;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text size, sound, language, sign out'**
  String get settingsSubtitle;

  /// No description provided for @handOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over to patient'**
  String get handOver;

  /// No description provided for @previewDataWarning.
  ///
  /// In en, this message translates to:
  /// **'Preview data. This is not a real patient record.'**
  String get previewDataWarning;

  /// No description provided for @patientHello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get patientHello;

  /// No description provided for @patientReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for a little activity?'**
  String get patientReady;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @suggestedForToday.
  ///
  /// In en, this message translates to:
  /// **'Suggested for today'**
  String get suggestedForToday;

  /// No description provided for @yourActivityToday.
  ///
  /// In en, this message translates to:
  /// **'Your activity today'**
  String get yourActivityToday;

  /// No description provided for @withPlacesYouKnow.
  ///
  /// In en, this message translates to:
  /// **'With places you know.'**
  String get withPlacesYouKnow;

  /// No description provided for @chooseSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Choose something else'**
  String get chooseSomethingElse;

  /// No description provided for @whatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// No description provided for @takeYourTime.
  ///
  /// In en, this message translates to:
  /// **'Take your time. You can stop whenever you like.'**
  String get takeYourTime;

  /// No description provided for @seeRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'See recent activities'**
  String get seeRecentActivities;

  /// No description provided for @todaysReminders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reminders'**
  String get todaysReminders;

  /// No description provided for @whatYouHaveBeenDoing.
  ///
  /// In en, this message translates to:
  /// **'What you have been doing'**
  String get whatYouHaveBeenDoing;

  /// No description provided for @nothingYetToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet today. Whenever you feel like it, there is an activity waiting.'**
  String get nothingYetToday;

  /// No description provided for @youPlayed.
  ///
  /// In en, this message translates to:
  /// **'You played {game}'**
  String youPlayed(String game);

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All done for now!'**
  String get allDone;

  /// No description provided for @resting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get resting;

  /// No description provided for @comeBackWhenReady.
  ///
  /// In en, this message translates to:
  /// **'Come back whenever you feel ready.'**
  String get comeBackWhenReady;

  /// No description provided for @readyToPlay.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get readyToPlay;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @breakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakLabel;

  /// No description provided for @takingABreak.
  ///
  /// In en, this message translates to:
  /// **'Taking a break'**
  String get takingABreak;

  /// No description provided for @takingABreakBody.
  ///
  /// In en, this message translates to:
  /// **'Take your time. Tap Continue when you are ready.'**
  String get takingABreakBody;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @finishForNow.
  ///
  /// In en, this message translates to:
  /// **'Finish for now'**
  String get finishForNow;

  /// No description provided for @howToPlayRouteQuest.
  ///
  /// In en, this message translates to:
  /// **'Follow the road to the flag. Tap a connected place to move. Pick up the flag, then return home. Help shows the way.'**
  String get howToPlayRouteQuest;

  /// No description provided for @howToPlayMarbleMazeTilt.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone comfortably while it settles, then gently tilt to guide the marble to the glowing goal. If tilt is unavailable, use your finger. Help shows the route.'**
  String get howToPlayMarbleMazeTilt;

  /// No description provided for @howToPlayMarbleMazeTouch.
  ///
  /// In en, this message translates to:
  /// **'Guide the marble along the wooden paths with your finger. Reach the glowing goal. Help shows the route.'**
  String get howToPlayMarbleMazeTouch;

  /// No description provided for @howToPlayWordSearch.
  ///
  /// In en, this message translates to:
  /// **'Find each word in the letters. Tap the first letter, then tap the last letter. Words go across, down, and sometimes at an angle. Help points out a word.'**
  String get howToPlayWordSearch;

  /// No description provided for @howToPlayRoutineRecall.
  ///
  /// In en, this message translates to:
  /// **'You will see a step from the day. Choose what usually comes next. If it is not the one, just try again. Help shows the answer.'**
  String get howToPlayRoutineRecall;

  /// No description provided for @howToPlayPictureSorting.
  ///
  /// In en, this message translates to:
  /// **'Look at the picture, then choose the group it belongs to. If it is not the one, just try again. Help shows the group.'**
  String get howToPlayPictureSorting;

  /// No description provided for @howToPlayGeneric.
  ///
  /// In en, this message translates to:
  /// **'Take your time. Help is always there if you need it, and you can take a break whenever you like.'**
  String get howToPlayGeneric;

  /// No description provided for @gameRouteQuest.
  ///
  /// In en, this message translates to:
  /// **'Route Quest'**
  String get gameRouteQuest;

  /// No description provided for @gameMarbleMaze.
  ///
  /// In en, this message translates to:
  /// **'Marble Maze'**
  String get gameMarbleMaze;

  /// No description provided for @gameWordSearch.
  ///
  /// In en, this message translates to:
  /// **'Word Search'**
  String get gameWordSearch;

  /// No description provided for @gameRoutineRecall.
  ///
  /// In en, this message translates to:
  /// **'Daily Routine'**
  String get gameRoutineRecall;

  /// No description provided for @gamePictureSorting.
  ///
  /// In en, this message translates to:
  /// **'Picture Sorting'**
  String get gamePictureSorting;

  /// No description provided for @aboutRouteQuest.
  ///
  /// In en, this message translates to:
  /// **'Find your way to a place and back again.'**
  String get aboutRouteQuest;

  /// No description provided for @aboutMarbleMaze.
  ///
  /// In en, this message translates to:
  /// **'Guide the marble gently to the end.'**
  String get aboutMarbleMaze;

  /// No description provided for @aboutWordSearch.
  ///
  /// In en, this message translates to:
  /// **'Find familiar words hidden in the letters.'**
  String get aboutWordSearch;

  /// No description provided for @aboutRoutineRecall.
  ///
  /// In en, this message translates to:
  /// **'Remember what comes next in the day.'**
  String get aboutRoutineRecall;

  /// No description provided for @aboutPictureSorting.
  ///
  /// In en, this message translates to:
  /// **'Put each picture with the ones like it.'**
  String get aboutPictureSorting;

  /// No description provided for @reminderSeenIt.
  ///
  /// In en, this message translates to:
  /// **'OK, I have seen this'**
  String get reminderSeenIt;

  /// No description provided for @reminderLater.
  ///
  /// In en, this message translates to:
  /// **'Remind me a bit later'**
  String get reminderLater;

  /// No description provided for @reminderSeen.
  ///
  /// In en, this message translates to:
  /// **'You have seen this one.'**
  String get reminderSeen;

  /// No description provided for @nothingToRemember.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remember right now.'**
  String get nothingToRemember;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @reminderSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get reminderSound;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies straight away, on top of the Android text-size setting.'**
  String get textSizeHelp;

  /// No description provided for @synchronization.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get synchronization;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @pendingUploads.
  ///
  /// In en, this message translates to:
  /// **'Pending session uploads'**
  String get pendingUploads;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected. Your changes remain on this device.'**
  String get notConnected;

  /// No description provided for @savedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Not connected right now.'**
  String get savedOnDevice;

  /// No description provided for @aboutTesseract.
  ///
  /// In en, this message translates to:
  /// **'About Tesseract'**
  String get aboutTesseract;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Tesseract offers gentle cognitive activities and everyday reminders for people living with dementia, set up and reviewed by the people who care for them.'**
  String get aboutDescription;

  /// No description provided for @builtBy.
  ///
  /// In en, this message translates to:
  /// **'Built and developed by the Tesseract Team.'**
  String get builtBy;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String versionLabel(String version, String build);

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My patients'**
  String get myPatients;

  /// No description provided for @assignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Patients assigned to you.'**
  String get assignedToYou;

  /// No description provided for @noPatientsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No patients are assigned to you yet. Assignment is done on the server, not from this app.'**
  String get noPatientsAssigned;

  /// No description provided for @observedMeasures.
  ///
  /// In en, this message translates to:
  /// **'Observed measures'**
  String get observedMeasures;

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session history'**
  String get sessionHistory;

  /// No description provided for @draftReport.
  ///
  /// In en, this message translates to:
  /// **'Draft report'**
  String get draftReport;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @doctorDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Observed activity in the app. Not a cognitive score, diagnosis, or measure of disease progression.'**
  String get doctorDisclaimer;

  /// No description provided for @notMeasured.
  ///
  /// In en, this message translates to:
  /// **'Not measured: {metrics}.'**
  String notMeasured(String metrics);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save on this device. Please try again.'**
  String get couldNotSave;

  /// No description provided for @outcomeFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get outcomeFinished;

  /// No description provided for @outcomeStoppedEarly.
  ///
  /// In en, this message translates to:
  /// **'Stopped early'**
  String get outcomeStoppedEarly;

  /// No description provided for @outcomeInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get outcomeInterrupted;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Routine reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Caregiver-created everyday reminders'**
  String get reminderChannelDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'as',
        'bn',
        'en',
        'kha',
        'lus',
        'mni'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'kha':
      return AppLocalizationsKha();
    case 'lus':
      return AppLocalizationsLus();
    case 'mni':
      return AppLocalizationsMni();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
