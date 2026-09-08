// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Assamese (`as`).
class AppLocalizationsAs extends AppLocalizations {
  AppLocalizationsAs([String locale = 'as']) : super(locale);

  @override
  String get appName => 'Apnapan';

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
      'এই বিল্ডত ছাইন-ইন কনফিগাৰ কৰা হোৱা নাই। ইয়াৰ বাবে এটা Firebase প্ৰকল্প আৰু এটা বেকএণ্ড ঠিকনা লাগে, যিবোৰ বিল্ডৰ সময়ত দিয়া হয়। তেতিয়ালৈকে একোৱেই ছাইন-ইন নহয় — অফলাইনত ইয়াৰ কোনো বিকল্প নাই।';

  @override
  String get signInPatientNote =>
      'যিয়ে কামবোৰ কৰিব তেওঁ ছাইন ইন নকৰে। এজন যত্নকাৰীয়ে সাজু কৰি ফোনটো হাতত দিয়ে।';

  @override
  String get openPreview => 'কৃত্ৰিম ডেভেলপমেণ্ট প্ৰিভিউ খোলক';

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
    return 'নমস্কাৰ, $name';
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
    return '$game: স্তৰ $from ৰ পৰা স্তৰ $to লৈ';
  }

  @override
  String useLevel(int level) {
    return 'স্তৰ $level ব্যৱহাৰ কৰক';
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
      'অনুমোদিত। নতুন কাৰ্যকলাপটো পৰৱৰ্তী ছেছনৰ বাবে সাজু।';

  @override
  String get decisionModified =>
      'আপোনাৰ পছন্দ ৰক্ষা কৰা হ\'ল। পৰৱৰ্তী সময়ত সেইটোৱেই আগবঢ়োৱা হ\'ব।';

  @override
  String get decisionRejected =>
      'বৰ্তমানৰ কামটোৱেই ৰখা হ\'ল। একো সলনি হোৱা নাই।';

  @override
  String get decisionFailed => 'সংৰক্ষণ কৰিব পৰা নগ’ল। একো সলনি হোৱা নাই।';

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
  String get settingsSubtitle => 'লেখাৰ আকাৰ, শব্দ, ভাষা, ছাইন আউট';

  @override
  String get handOver => 'ৰোগীৰ হাতত দিয়ক';

  @override
  String get previewDataWarning => 'নমুনা তথ্য। এইটো প্ৰকৃত ৰোগীৰ ৰেকৰ্ড নহয়।';

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
  String get withPlacesYouKnow => 'আপুনি চিনি পোৱা ঠাইৰ সৈতে।';

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
    return 'আপুনি $game খেলিলে';
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
      'ফোনটো আৰামেৰে ধৰি ৰাখক যেতিয়ালৈকে ই স্থিৰ নহয়, তাৰ পিছত লাহেকৈ কাত কৰি মাৰ্বেলটো উজ্জ্বল লক্ষ্যলৈ লৈ যাওক। কাত কৰিব নোৱাৰিলে আঙুলি ব্যৱহাৰ কৰক। সহায়ে বাটটো দেখুৱায়।';

  @override
  String get howToPlayMarbleMazeTouch =>
      'আঙুলিৰে মাৰ্বেলটো কাঠৰ বাটেৰে লৈ যাওক। উজ্জ্বল লক্ষ্যত উপনীত হওক। সহায়ে বাটটো দেখুৱায়।';

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
      'সময় লওক। প্ৰয়োজন হ’লে সহায় পাব, আৰু যেতিয়া ইচ্ছা বিৰতি ল’ব পাৰে।';

  @override
  String get gameRouteQuest => 'বাটৰ সন্ধান';

  @override
  String get gameMarbleMaze => 'মাৰ্বেল গোলকধাঁধা';

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
      'লগে লগে প্ৰয়োগ হয়, এণ্ড্ৰইডৰ লিখাৰ আকাৰৰ ছেটিঙৰ ওপৰত।';

  @override
  String get synchronization => 'ছিংক কৰা';

  @override
  String get syncNow => 'এতিয়া ছিংক কৰক';

  @override
  String get pendingUploads => 'আপলোডৰ অপেক্ষাত থকা খেলৰ ছেছন';

  @override
  String get signOut => 'ছাইন আউট';

  @override
  String get notConnected => 'সংযোগ নাই। আপোনাৰ সালসলনি এই ফোনতে থাকিব।';

  @override
  String get savedOnDevice => 'এই ফোনত ৰখা আছে। এতিয়া সংযোগ নাই।';

  @override
  String get aboutTesseract => 'অপনাপনৰ বিষয়ে';

  @override
  String get aboutDescription =>
      'অপনাপনে ডিমেনচিয়াত ভোগা মানুহৰ বাবে মৃদু জ্ঞানমূলক কাৰ্যকলাপ আৰু দৈনন্দিন মনত পেলোৱা দিয়ে, যিবোৰ তেওঁলোকৰ যত্ন লওঁতাসকলে সাজি দিয়ে আৰু চায়।';

  @override
  String get builtBy => 'Built and developed by the Tesseract Team.';

  @override
  String versionLabel(String version, String build) {
    return 'সংস্কৰণ $version (বিল্ড $build)';
  }

  @override
  String get languagesLabel => 'ভাষা';

  @override
  String get myPatients => 'মোৰ ৰোগীসকল';

  @override
  String get assignedToYou => 'আপোনাৰ দায়িত্বত থকা ৰোগীসকল।';

  @override
  String get noPatientsAssigned =>
      'এতিয়ালৈকে আপোনাৰ নামত কোনো ৰোগী নিৰ্ধাৰিত হোৱা নাই। নিৰ্ধাৰণ চাৰ্ভাৰত হয়, এই এপৰ পৰা নহয়।';

  @override
  String get observedMeasures => 'লক্ষ্য কৰা পৰিমাপ';

  @override
  String get sessionHistory => 'খেলৰ ছেছনৰ ইতিহাস';

  @override
  String get draftReport => 'খচৰা প্ৰতিবেদন';

  @override
  String get generate => 'তৈয়াৰ কৰক';

  @override
  String get notes => 'টোকা';

  @override
  String get addNote => 'টোকা যোগ কৰক';

  @override
  String get noNotes => 'এতিয়াও কোনো টোকা নাই।';

  @override
  String get doctorDisclaimer =>
      'এপত লক্ষ্য কৰা কাৰ্যকলাপ। ই কোনো জ্ঞানীয় স্ক\'ৰ, ৰোগনিৰ্ণয়, বা ৰোগৰ অগ্ৰগতিৰ পৰিমাপ নহয়।';

  @override
  String notMeasured(String metrics) {
    return 'জোখা হোৱা নাই: $metrics।';
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

  @override
  String get reminderNotificationTitle => 'এটি সৰু মনত পেলোৱা';

  @override
  String get reminderChannelName => 'দৈনন্দিন মনত পেলোৱা';

  @override
  String get reminderChannelDescription =>
      'যত্নকাৰীয়ে তৈয়াৰ কৰা দৈনন্দিন মনত পেলোৱা';

  @override
  String get speakThis => 'পঢ়ি শুনাওক';

  @override
  String get stopSpeaking => 'বন্ধ কৰক';

  @override
  String get readAloudAgain => 'পুনৰ পঢ়ক';

  @override
  String speechUnavailableForLanguage(String language) {
    return 'এই ফোনত $language ভাষাত পঢ়ি শুনোৱা নাযায়। ওপৰৰ কথাখিনি স্ক্ৰীণতে থাকিব।';
  }

  @override
  String get speechNoEngine =>
      'এই ফোনত কোনো টেক্সট-টু-স্পীচ কণ্ঠ ইনষ্টল কৰা নাই, সেয়েহে একো পঢ়ি শুনাব নোৱাৰি।';

  @override
  String get speechAudioOff =>
      'ছেটিঙত শব্দ বন্ধ কৰা আছে, সেয়েহে একো পঢ়ি শুনোৱা হোৱা নাই।';

  @override
  String get speechFailed => 'এতিয়া কথাখিনি পঢ়ি শুনাব পৰা নগ\'ল।';

  @override
  String get tapToSpeak => 'ক\'বলৈ টিপক';

  @override
  String get listening => 'শুনি আছে…';

  @override
  String get listeningHint => 'আপুনি যি বিচাৰে কওক, তাৰ পিছত অলপ ৰৈ থাকক।';

  @override
  String get stopListening => 'বন্ধ কৰক';

  @override
  String get cancelListening => 'বাতিল কৰক';

  @override
  String get youSaid => 'আপুনি ক\'লে';

  @override
  String get useThis => 'এইটো ব্যৱহাৰ কৰক';

  @override
  String get voiceNeedsConfirmation =>
      '‘এইটো ব্যৱহাৰ কৰক’ নোবোলালৈকে একোৱেই ৰক্ষা কৰা নহ\'ব।';

  @override
  String get voicePermissionDenied =>
      'শুনাৰ আগতে Tesseract-ৰ মাইক্ৰ\'ফোন ব্যৱহাৰৰ অনুমতি লাগে।';

  @override
  String get voicePermissionBlocked =>
      'মাইক্ৰ\'ফোনৰ অনুমতি বন্ধ কৰা আছে। ফোনৰ ছেটিঙৰ পৰা পুনৰ খুলিব পাৰে।';

  @override
  String get voiceUnavailable =>
      'এই ফোনত কথা চিনাক্ত কৰাৰ সুবিধা নাই, সেয়েহে ক\'ব নোৱাৰি। আপুনি লিখিব পাৰে।';

  @override
  String voiceLanguageUnavailable(String language) {
    return 'এই ফোনত $language ভাষাত ক\'ব নোৱাৰি। আপুনি লিখিব পাৰে।';
  }

  @override
  String get voiceNothingHeard =>
      'একো শুনা নগ\'ল। পুনৰ চেষ্টা কৰিব পাৰে, বা লিখিব পাৰে।';

  @override
  String get voiceNetworkNeeded =>
      'কথা চিনাক্ত কৰিবলৈ এতিয়া সংযোগ লাগে, কিন্তু সংযোগ পোৱা নগ\'ল।';

  @override
  String get voiceError =>
      'এতিয়া কথা চিনাক্ত কৰিব পৰা নগ\'ল। পুনৰ চেষ্টা কৰিব পাৰে, বা লিখিব পাৰে।';

  @override
  String get speechSettingsTitle => 'কোৱা আৰু শুনা';

  @override
  String get speechSettingsSubtitle =>
      'ঐচ্ছিক। ইয়াৰ সকলোবোৰ স্ক্ৰীণত পঢ়িবও পাৰি আৰু স্পৰ্শ কৰিও কৰিব পাৰি।';

  @override
  String get speechCheckThisPhone => 'এই ফোনত কি কি চলে চাওক';

  @override
  String get speechReadAloudAvailable => 'পঢ়ি শুনোৱা: আছে';

  @override
  String get speechReadAloudUnavailable => 'পঢ়ি শুনোৱা: নাই';

  @override
  String get speechListeningAvailable => 'এপক কোৱা: আছে';

  @override
  String get speechListeningUnavailable => 'এপক কোৱা: নাই';

  @override
  String get speechNotCheckedYet => 'এই ফোনত এতিয়াও পৰীক্ষা কৰা হোৱা নাই';

  @override
  String get speechDraftWarning =>
      'এই ভাষাত সুন্দৰকৈ ক\'ব পৰা কোনো ব্যক্তিয়ে এতিয়াও কথা কোৱাৰ সুবিধাটো পৰীক্ষা কৰা নাই।';

  @override
  String get appNameHindi => 'अपनापन';

  @override
  String get appTagline =>
      'AI-ভিত্তিক জ্ঞানমূলক কাৰ্যকলাপ আৰু দৈনন্দিনৰ সহায়।';
}
