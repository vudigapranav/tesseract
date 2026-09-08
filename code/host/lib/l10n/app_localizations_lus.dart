// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lushai (`lus`).
class AppLocalizationsLus extends AppLocalizations {
  AppLocalizationsLus([String locale = 'lus']) : super(locale);

  @override
  String get appName => 'Tesseract';

  @override
  String get languageName => 'Mizo ṭawng';

  @override
  String get signInTitle => 'A familiar moment.\nA little joy.';

  @override
  String get signInSubtitle =>
      'Set up meaningful activities and everyday reminders, together.';

  @override
  String get roleCaregiver => 'Enkawltu';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get emailCaregiver => 'Caregiver email';

  @override
  String get emailDoctor => 'Doctor email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Lut';

  @override
  String get signingIn => 'Verifying access…';

  @override
  String get signInFailed =>
      'Could not verify sign-in and access. Check your details and connection.';

  @override
  String get signInNotConfigured =>
      'Sign-in is not configured in this build. It needs a Firebase project and a backend address, which are supplied at build time. Nothing is signed in until then — there is no offline substitute.';

  @override
  String get signInPatientNote =>
      'The person using the activities does not sign in. A caregiver sets things up and hands the device over.';

  @override
  String get openPreview => 'Open synthetic development preview';

  @override
  String get languageLabel => 'Ṭawng';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get interfaceLanguage => 'App language';

  @override
  String get interfaceLanguageHelp =>
      'The language of menus and buttons for you.';

  @override
  String get patientLanguage => 'Language for the person playing';

  @override
  String get patientLanguageHelp =>
      'Activities and instructions use this. It can be different from your own.';

  @override
  String get draftTranslationNotice =>
      'Draft translation. Not yet checked by a fluent speaker.';

  @override
  String translationCoverage(int percent) {
    return '$percent% translated';
  }

  @override
  String get awaitingReview => 'Awaiting native review';

  @override
  String get fallsBackToEnglish =>
      'Anything not yet translated is shown in English.';

  @override
  String caregiverGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get noPatientYet => 'No patient set up yet';

  @override
  String get needsYourDecision => 'Needs your decision';

  @override
  String get suggestedChange => 'A suggested change';

  @override
  String levelChange(String game, int from, int to) {
    return '$game: from level $from to level $to';
  }

  @override
  String useLevel(int level) {
    return 'Use level $level';
  }

  @override
  String get chooseLevel => 'Choose level';

  @override
  String get keepAsIs => 'Keep as is';

  @override
  String get suggestionCaveat =>
      'This is a suggestion from recorded activity only, using settings that are still being tested. You decide.';

  @override
  String get decisionApproved =>
      'Approved. The new activity is ready for the next session.';

  @override
  String get decisionModified =>
      'Saved your choice. That is what will be offered next.';

  @override
  String get decisionRejected =>
      'Kept the current activity. Nothing has changed.';

  @override
  String get decisionFailed => 'That could not be saved. Nothing was changed.';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get noActivityYet =>
      'No activities recorded yet. Once a session is played it will appear here.';

  @override
  String get setUp => 'Set up';

  @override
  String get patientBasics => 'Patient basics';

  @override
  String get patientBasicsSubtitle => 'Name, age, language';

  @override
  String get knowMe => 'Know Me';

  @override
  String get reminders => 'Reminders';

  @override
  String get settingsAndSync => 'Settings & sync';

  @override
  String get settingsSubtitle => 'Text size, sound, language, sign out';

  @override
  String get handOver => 'Hand over to patient';

  @override
  String get previewDataWarning =>
      'Preview data. This is not a real patient record.';

  @override
  String get patientHello => 'Hello!';

  @override
  String get patientReady => 'Ready for a little activity?';

  @override
  String get start => 'Ṭan';

  @override
  String get suggestedForToday => 'Suggested for today';

  @override
  String get yourActivityToday => 'Your activity today';

  @override
  String get withPlacesYouKnow => 'With places you know.';

  @override
  String get chooseSomethingElse => 'Choose something else';

  @override
  String get whatWouldYouLikeToDo => 'What would you like to do?';

  @override
  String get takeYourTime => 'Take your time. You can stop whenever you like.';

  @override
  String get seeRecentActivities => 'See recent activities';

  @override
  String get todaysReminders => 'Today\'s reminders';

  @override
  String get whatYouHaveBeenDoing => 'What you have been doing';

  @override
  String get nothingYetToday =>
      'Nothing yet today. Whenever you feel like it, there is an activity waiting.';

  @override
  String youPlayed(String game) {
    return 'You played $game';
  }

  @override
  String get allDone => 'All done for now!';

  @override
  String get resting => 'Resting';

  @override
  String get comeBackWhenReady => 'Come back whenever you feel ready.';

  @override
  String get readyToPlay => 'Ready to play';

  @override
  String get home => 'In';

  @override
  String get rest => 'Rest';

  @override
  String get playAgain => 'Play again';

  @override
  String get goBack => 'Go back';

  @override
  String get help => 'Ṭanpuina';

  @override
  String get breakLabel => 'Break';

  @override
  String get takingABreak => 'Taking a break';

  @override
  String get takingABreakBody =>
      'Take your time. Tap Continue when you are ready.';

  @override
  String get continueLabel => 'Chhunzawm';

  @override
  String get finishForNow => 'Finish for now';

  @override
  String get howToPlayRouteQuest =>
      'Follow the road to the flag. Tap a connected place to move. Pick up the flag, then return home. Help shows the way.';

  @override
  String get howToPlayMarbleMazeTilt =>
      'Hold your phone comfortably while it settles, then gently tilt to guide the marble to the glowing goal. If tilt is unavailable, use your finger. Help shows the route.';

  @override
  String get howToPlayMarbleMazeTouch =>
      'Guide the marble along the wooden paths with your finger. Reach the glowing goal. Help shows the route.';

  @override
  String get howToPlayWordSearch =>
      'Find each word in the letters. Tap the first letter, then tap the last letter. Words go across, down, and sometimes at an angle. Help points out a word.';

  @override
  String get howToPlayRoutineRecall =>
      'You will see a step from the day. Choose what usually comes next. If it is not the one, just try again. Help shows the answer.';

  @override
  String get howToPlayPictureSorting =>
      'Look at the picture, then choose the group it belongs to. If it is not the one, just try again. Help shows the group.';

  @override
  String get howToPlayGeneric =>
      'Take your time. Help is always there if you need it, and you can take a break whenever you like.';

  @override
  String get gameRouteQuest => 'Route Quest';

  @override
  String get gameMarbleMaze => 'Marble Maze';

  @override
  String get gameWordSearch => 'Word Search';

  @override
  String get gameRoutineRecall => 'Daily Routine';

  @override
  String get gamePictureSorting => 'Picture Sorting';

  @override
  String get aboutRouteQuest => 'Find your way to a place and back again.';

  @override
  String get aboutMarbleMaze => 'Guide the marble gently to the end.';

  @override
  String get aboutWordSearch => 'Find familiar words hidden in the letters.';

  @override
  String get aboutRoutineRecall => 'Remember what comes next in the day.';

  @override
  String get aboutPictureSorting => 'Put each picture with the ones like it.';

  @override
  String get reminderSeenIt => 'OK, I have seen this';

  @override
  String get reminderLater => 'Remind me a bit later';

  @override
  String get reminderSeen => 'You have seen this one.';

  @override
  String get nothingToRemember => 'Nothing to remember right now.';

  @override
  String get today => 'Vawiin';

  @override
  String get reminderSound => 'Reminder sound';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeHelp =>
      'Applies straight away, on top of the Android text-size setting.';

  @override
  String get synchronization => 'Synchronization';

  @override
  String get syncNow => 'Sync now';

  @override
  String get pendingUploads => 'Pending session uploads';

  @override
  String get signOut => 'Chhuak';

  @override
  String get notConnected =>
      'Not connected. Your changes remain on this device.';

  @override
  String get savedOnDevice => 'Saved on this device. Not connected right now.';

  @override
  String get aboutTesseract => 'About Tesseract';

  @override
  String get aboutDescription =>
      'Tesseract offers gentle cognitive activities and everyday reminders for people living with dementia, set up and reviewed by the people who care for them.';

  @override
  String get builtBy => 'Built and developed by the Tesseract Team.';

  @override
  String versionLabel(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get languagesLabel => 'Languages';

  @override
  String get myPatients => 'My patients';

  @override
  String get assignedToYou => 'Patients assigned to you.';

  @override
  String get noPatientsAssigned =>
      'No patients are assigned to you yet. Assignment is done on the server, not from this app.';

  @override
  String get observedMeasures => 'Observed measures';

  @override
  String get sessionHistory => 'Session history';

  @override
  String get draftReport => 'Draft report';

  @override
  String get generate => 'Generate';

  @override
  String get notes => 'Notes';

  @override
  String get addNote => 'Add a note';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get doctorDisclaimer =>
      'Observed activity in the app. Not a cognitive score, diagnosis, or measure of disease progression.';

  @override
  String notMeasured(String metrics) {
    return 'Not measured: $metrics.';
  }

  @override
  String get save => 'Dah';

  @override
  String get cancel => 'Bansan';

  @override
  String get add => 'Add';

  @override
  String get tryAgain => 'Try again';

  @override
  String get couldNotSave => 'Could not save on this device. Please try again.';

  @override
  String get outcomeFinished => 'Finished';

  @override
  String get outcomeStoppedEarly => 'Stopped early';

  @override
  String get outcomeInterrupted => 'Interrupted';

  @override
  String get reminderNotificationTitle => 'A gentle reminder';

  @override
  String get reminderChannelName => 'Routine reminders';

  @override
  String get reminderChannelDescription =>
      'Caregiver-created everyday reminders';

  @override
  String get speakThis => 'Read aloud';

  @override
  String get stopSpeaking => 'Stop';

  @override
  String get readAloudAgain => 'Read again';

  @override
  String speechUnavailableForLanguage(String language) {
    return 'Reading aloud is not available in $language on this phone. The words above stay on the screen.';
  }

  @override
  String get speechNoEngine =>
      'This phone has no text-to-speech voice installed, so nothing can be read aloud.';

  @override
  String get speechAudioOff =>
      'Sound is turned off in Settings, so nothing is read aloud.';

  @override
  String get speechFailed => 'The words could not be read aloud just now.';

  @override
  String get tapToSpeak => 'Tap to speak';

  @override
  String get listening => 'Listening…';

  @override
  String get listeningHint => 'Say what you would like, then wait a moment.';

  @override
  String get stopListening => 'Stop';

  @override
  String get cancelListening => 'Cancel';

  @override
  String get youSaid => 'You said';

  @override
  String get useThis => 'Use this';

  @override
  String get voiceNeedsConfirmation =>
      'Nothing is saved until you choose Use this.';

  @override
  String get voicePermissionDenied =>
      'Tesseract needs permission to use the microphone before it can listen.';

  @override
  String get voicePermissionBlocked =>
      'Microphone access is blocked. You can turn it back on in the phone\'s Settings.';

  @override
  String get voiceUnavailable =>
      'This phone has no speech recognition, so speaking is not available. You can still type.';

  @override
  String voiceLanguageUnavailable(String language) {
    return 'Speaking is not available in $language on this phone. You can still type.';
  }

  @override
  String get voiceNothingHeard =>
      'Nothing was heard. You can try again or type instead.';

  @override
  String get voiceNetworkNeeded =>
      'Speech recognition needs a connection right now and could not reach it.';

  @override
  String get voiceError =>
      'Speech did not work just now. You can try again or type instead.';

  @override
  String get speechSettingsTitle => 'Speaking and listening';

  @override
  String get speechSettingsSubtitle =>
      'Optional. Everything here can also be read on screen and done by touch.';

  @override
  String get speechCheckThisPhone => 'Check what this phone supports';

  @override
  String get speechReadAloudAvailable => 'Reading aloud: available';

  @override
  String get speechReadAloudUnavailable => 'Reading aloud: not available';

  @override
  String get speechListeningAvailable => 'Speaking to the app: available';

  @override
  String get speechListeningUnavailable => 'Speaking to the app: not available';

  @override
  String get speechNotCheckedYet => 'Not checked on this phone yet';

  @override
  String get speechDraftWarning =>
      'Speech has not been checked by a fluent speaker of this language.';
}
