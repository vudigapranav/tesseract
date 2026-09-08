// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Assamese (`as`).
class AppLocalizationsAs extends AppLocalizations {
  AppLocalizationsAs([String locale = 'as']) : super(locale);

  @override
  String get appName => 'Tesseract';

  @override
  String get languageName => 'অসমীয়া';

  @override
  String get signInTitle => 'এটি চিনাকি মুহূৰ্ত।\nএষাৰ আনন্দ।';

  @override
  String get signInSubtitle =>
      'একেলগে অৰ্থপূৰ্ণ কাম আৰু দৈনন্দিন মনত পেলোৱা ব্যৱস্থা কৰক।';

  @override
  String get roleCaregiver => 'যত্নকাৰী';

  @override
  String get roleDoctor => 'ডাক্তৰ';

  @override
  String get emailCaregiver => 'যত্নকাৰীৰ ইমেইল';

  @override
  String get emailDoctor => 'ডাক্তৰৰ ইমেইল';

  @override
  String get password => 'পাছৱৰ্ড';

  @override
  String get signIn => 'ছাইন ইন';

  @override
  String get signingIn => 'পৰীক্ষা কৰা হৈছে…';

  @override
  String get signInFailed =>
      'ছাইন ইন পৰীক্ষা কৰিব পৰা নগ\'ল। আপোনাৰ তথ্য আৰু সংযোগ চাওক।';

  @override
  String get signInNotConfigured =>
      'Sign-in is not configured in this build. It needs a Firebase project and a backend address, which are supplied at build time. Nothing is signed in until then — there is no offline substitute.';

  @override
  String get signInPatientNote =>
      'যিয়ে কামবোৰ কৰিব তেওঁ ছাইন ইন নকৰে। এজন যত্নকাৰীয়ে সাজু কৰি ফোনটো হাতত দিয়ে।';

  @override
  String get openPreview => 'Open synthetic development preview';

  @override
  String get languageLabel => 'ভাষা';

  @override
  String get chooseLanguage => 'আপোনাৰ ভাষা বাছনি কৰক';

  @override
  String get interfaceLanguage => 'এপৰ ভাষা';

  @override
  String get interfaceLanguageHelp => 'আপোনাৰ বাবে মেনু আৰু বুটামৰ ভাষা।';

  @override
  String get patientLanguage => 'যিয়ে খেলিব তেওঁৰ ভাষা';

  @override
  String get patientLanguageHelp =>
      'কাম আৰু নিৰ্দেশ এই ভাষাত হ\'ব। ই আপোনাৰ ভাষাতকৈ পৃথক হ\'ব পাৰে।';

  @override
  String get draftTranslationNotice =>
      'খচৰা অনুবাদ। এতিয়াও কোনো সাৱলীল বক্তাই পৰীক্ষা কৰা নাই।';

  @override
  String translationCoverage(int percent) {
    return '$percent% অনূদিত';
  }

  @override
  String get awaitingReview => 'স্থানীয় পৰ্যালোচনাৰ অপেক্ষাত';

  @override
  String get fallsBackToEnglish =>
      'যিবোৰ এতিয়াও অনুবাদ হোৱা নাই সেয়া ইংৰাজীত দেখুওৱা হ\'ব।';

  @override
  String caregiverGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get welcomeBack => 'পুনৰ স্বাগতম';

  @override
  String get noPatientYet => 'এতিয়াও কাকো যোগ কৰা হোৱা নাই';

  @override
  String get needsYourDecision => 'আপোনাৰ সিদ্ধান্ত লাগে';

  @override
  String get suggestedChange => 'এটি প্ৰস্তাৱিত সালসলনি';

  @override
  String levelChange(String game, int from, int to) {
    return '$game: from level $from to level $to';
  }

  @override
  String useLevel(int level) {
    return 'Use level $level';
  }

  @override
  String get chooseLevel => 'স্তৰ বাছনি কৰক';

  @override
  String get keepAsIs => 'যেনেকৈ আছে থাকক';

  @override
  String get suggestionCaveat =>
      'এইটো কেৱল ৰেকৰ্ড কৰা কামৰ ভিত্তিত এটি প্ৰস্তাৱ, এনে ছেটিংছেৰে যিবোৰ এতিয়াও পৰীক্ষা কৰা হৈ আছে। সিদ্ধান্ত আপোনাৰ।';

  @override
  String get decisionApproved =>
      'Approved. The new activity is ready for the next session.';

  @override
  String get decisionModified =>
      'Saved your choice. That is what will be offered next.';

  @override
  String get decisionRejected =>
      'বৰ্তমানৰ কামটোৱেই ৰখা হ\'ল। একো সলনি হোৱা নাই।';

  @override
  String get decisionFailed => 'That could not be saved. Nothing was changed.';

  @override
  String get recentActivity => 'শেহতীয়া কাম';

  @override
  String get noActivityYet =>
      'এতিয়াও কোনো কাম ৰেকৰ্ড হোৱা নাই। এবাৰ খেলিলে ইয়াত দেখা যাব।';

  @override
  String get setUp => 'সাজু কৰক';

  @override
  String get patientBasics => 'মূল তথ্য';

  @override
  String get patientBasicsSubtitle => 'নাম, বয়স, ভাষা';

  @override
  String get knowMe => 'মোক জানক';

  @override
  String get reminders => 'মনত পেলোৱা';

  @override
  String get settingsAndSync => 'ছেটিংছ আৰু ছিংক';

  @override
  String get settingsSubtitle => 'Text size, sound, language, sign out';

  @override
  String get handOver => 'ৰোগীৰ হাতত দিয়ক';

  @override
  String get previewDataWarning =>
      'Preview data. This is not a real patient record.';

  @override
  String get patientHello => 'নমস্কাৰ!';

  @override
  String get patientReady => 'অলপ কিবা কৰিবলৈ মন গৈছে নেকি?';

  @override
  String get start => 'আৰম্ভ কৰক';

  @override
  String get suggestedForToday => 'আজিৰ বাবে প্ৰস্তাৱিত';

  @override
  String get yourActivityToday => 'আজি আপোনাৰ কাম';

  @override
  String get withPlacesYouKnow => 'With places you know.';

  @override
  String get chooseSomethingElse => 'আন কিবা বাছনি কৰক';

  @override
  String get whatWouldYouLikeToDo => 'আপুনি কি কৰিব বিচাৰে?';

  @override
  String get takeYourTime => 'সময় লওক। যেতিয়া ইচ্ছা কৰে ৰ\'ব পাৰে।';

  @override
  String get seeRecentActivities => 'শেহতীয়া কাম চাওক';

  @override
  String get todaysReminders => 'আজিৰ মনত পেলোৱা';

  @override
  String get whatYouHaveBeenDoing => 'আপুনি যি কৰিছে';

  @override
  String get nothingYetToday =>
      'আজি এতিয়াও একো হোৱা নাই। যেতিয়া মন যায়, এটা কাম অপেক্ষা কৰি আছে।';

  @override
  String youPlayed(String game) {
    return 'You played $game';
  }

  @override
  String get allDone => 'আপাততঃ সকলো শেষ!';

  @override
  String get resting => 'বিশ্ৰাম';

  @override
  String get comeBackWhenReady => 'যেতিয়া সাজু বুলি ভাবিব, ঘূৰি আহিব।';

  @override
  String get readyToPlay => 'খেলিবলৈ সাজু';

  @override
  String get home => 'ঘৰ';

  @override
  String get rest => 'বিশ্ৰাম';

  @override
  String get playAgain => 'পুনৰ খেলক';

  @override
  String get goBack => 'পিছলৈ যাওক';

  @override
  String get help => 'সহায়';

  @override
  String get breakLabel => 'বিৰতি';

  @override
  String get takingABreak => 'অলপ বিৰতি';

  @override
  String get takingABreakBody => 'সময় লওক। সাজু হ\'লে আগবাঢ়ক টিপক।';

  @override
  String get continueLabel => 'আগবাঢ়ক';

  @override
  String get finishForNow => 'আপাততঃ শেষ কৰক';

  @override
  String get howToPlayRouteQuest =>
      'পতাকাৰ ফালে বাটেৰে যাওক। যাবলৈ ওচৰৰ ঠাইত টিপক। পতাকা তুলি লৈ ঘৰলৈ ঘূৰি আহক। সহায়ে বাট দেখুৱাব।';

  @override
  String get howToPlayMarbleMazeTilt =>
      'Hold your phone comfortably while it settles, then gently tilt to guide the marble to the glowing goal. If tilt is unavailable, use your finger. Help shows the route.';

  @override
  String get howToPlayMarbleMazeTouch =>
      'Guide the marble along the wooden paths with your finger. Reach the glowing goal. Help shows the route.';

  @override
  String get howToPlayWordSearch =>
      'আখৰৰ মাজত শব্দবোৰ বিচাৰক। প্ৰথম আখৰত টিপক, তাৰ পিছত শেষ আখৰত। সহায়ে এটা শব্দ দেখুৱাব।';

  @override
  String get howToPlayRoutineRecall =>
      'দিনটোৰ এটা স্তৰ দেখুওৱা হ\'ব। ইয়াৰ পিছত সাধাৰণতে কি হয় বাছনি কৰক। ভুল হ\'লে পুনৰ চেষ্টা কৰক।';

  @override
  String get howToPlayPictureSorting =>
      'ছবিখন চাওক, তাৰ পিছত সেয়া কোন দলত যায় বাছনি কৰক। ভুল হ\'লে পুনৰ চেষ্টা কৰক।';

  @override
  String get howToPlayGeneric =>
      'Take your time. Help is always there if you need it, and you can take a break whenever you like.';

  @override
  String get gameRouteQuest => 'Route Quest';

  @override
  String get gameMarbleMaze => 'Marble Maze';

  @override
  String get gameWordSearch => 'শব্দ বিচৰা';

  @override
  String get gameRoutineRecall => 'দৈনন্দিন কাম';

  @override
  String get gamePictureSorting => 'ছবি সজোৱা';

  @override
  String get aboutRouteQuest => 'এটা ঠাইলৈ গৈ পুনৰ ঘূৰি আহক।';

  @override
  String get aboutMarbleMaze => 'মাৰ্বেলটো লাহে লাহে শেষলৈ লৈ যাওক।';

  @override
  String get aboutWordSearch => 'আখৰৰ মাজত লুকাই থকা চিনাকি শব্দ বিচাৰক।';

  @override
  String get aboutRoutineRecall => 'দিনটোত ইয়াৰ পিছত কি হয় মনত পেলাওক।';

  @override
  String get aboutPictureSorting => 'প্ৰতিখন ছবি তাৰ দৰে ছবিৰ লগত ৰাখক।';

  @override
  String get reminderSeenIt => 'ঠিক আছে, মই দেখিলোঁ';

  @override
  String get reminderLater => 'অলপ পিছত মনত পেলাব';

  @override
  String get reminderSeen => 'আপুনি এইটো দেখিছে।';

  @override
  String get nothingToRemember => 'এতিয়া মনত ৰখাৰ একো নাই।';

  @override
  String get today => 'আজি';

  @override
  String get reminderSound => 'মনত পেলোৱাৰ শব্দ';

  @override
  String get reduceMotion => 'লৰচৰ কমাওক';

  @override
  String get textSize => 'লেখাৰ আকাৰ';

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
  String get signOut => 'ছাইন আউট';

  @override
  String get notConnected => 'সংযোগ নাই। আপোনাৰ সালসলনি এই ফোনতে থাকিব।';

  @override
  String get savedOnDevice => 'এই ফোনত ৰখা আছে। এতিয়া সংযোগ নাই।';

  @override
  String get aboutTesseract => 'টেছাৰেক্টৰ বিষয়ে';

  @override
  String get aboutDescription =>
      'টেছাৰেক্টে ডিমেনচিয়াত ভোগা লোকৰ বাবে সহজ মানসিক কাম আৰু দৈনন্দিন মনত পেলোৱাৰ ব্যৱস্থা কৰে, যিবোৰ তেওঁলোকৰ যত্নকাৰীয়ে সাজু কৰি চাই থাকে।';

  @override
  String get builtBy => 'Built and developed by the Tesseract Team.';

  @override
  String versionLabel(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get languagesLabel => 'ভাষা';

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
  String get save => 'সংৰক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get add => 'যোগ কৰক';

  @override
  String get tryAgain => 'পুনৰ চেষ্টা কৰক';

  @override
  String get couldNotSave => 'এই ফোনত সংৰক্ষণ কৰিব পৰা নগ\'ল। পুনৰ চেষ্টা কৰক।';

  @override
  String get outcomeFinished => 'শেষ হৈছে';

  @override
  String get outcomeStoppedEarly => 'আগতেই ৰ\'ল';

  @override
  String get outcomeInterrupted => 'বাধা পৰিছে';
}
