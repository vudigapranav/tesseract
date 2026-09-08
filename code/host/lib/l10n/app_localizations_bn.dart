// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'Tesseract';

  @override
  String get languageName => 'বাংলা';

  @override
  String get signInTitle => 'একটি চেনা মুহূর্ত।\nএকটু আনন্দ।';

  @override
  String get signInSubtitle =>
      'একসাথে অর্থপূর্ণ কাজ এবং প্রতিদিনের মনে করিয়ে দেওয়া সাজিয়ে নিন।';

  @override
  String get roleCaregiver => 'যত্নকারী';

  @override
  String get roleDoctor => 'ডাক্তার';

  @override
  String get emailCaregiver => 'যত্নকারীর ইমেল';

  @override
  String get emailDoctor => 'ডাক্তারের ইমেল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get signingIn => 'যাচাই করা হচ্ছে…';

  @override
  String get signInFailed =>
      'সাইন ইন যাচাই করা যায়নি। আপনার তথ্য এবং সংযোগ দেখে নিন।';

  @override
  String get signInNotConfigured =>
      'Sign-in is not configured in this build. It needs a Firebase project and a backend address, which are supplied at build time. Nothing is signed in until then — there is no offline substitute.';

  @override
  String get signInPatientNote =>
      'যিনি কাজগুলি করবেন তাঁকে সাইন ইন করতে হয় না। একজন যত্নকারী সব ঠিক করে দিয়ে ফোনটি হাতে দেন।';

  @override
  String get openPreview => 'Open synthetic development preview';

  @override
  String get languageLabel => 'ভাষা';

  @override
  String get chooseLanguage => 'আপনার ভাষা বেছে নিন';

  @override
  String get interfaceLanguage => 'অ্যাপের ভাষা';

  @override
  String get interfaceLanguageHelp => 'আপনার জন্য মেনু ও বোতামের ভাষা।';

  @override
  String get patientLanguage => 'যিনি খেলবেন তাঁর ভাষা';

  @override
  String get patientLanguageHelp =>
      'কাজ ও নির্দেশ এই ভাষায় হবে। এটি আপনার ভাষার থেকে আলাদা হতে পারে।';

  @override
  String get draftTranslationNotice =>
      'খসড়া অনুবাদ। এখনও কোনও সাবলীল বক্তা যাচাই করেননি।';

  @override
  String translationCoverage(int percent) {
    return '$percent% অনূদিত';
  }

  @override
  String get awaitingReview => 'স্থানীয় পর্যালোচনার অপেক্ষায়';

  @override
  String get fallsBackToEnglish =>
      'যা এখনও অনুবাদ হয়নি তা ইংরেজিতে দেখানো হবে।';

  @override
  String caregiverGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get welcomeBack => 'আবার স্বাগতম';

  @override
  String get noPatientYet => 'এখনও কেউ যোগ করা হয়নি';

  @override
  String get needsYourDecision => 'আপনার সিদ্ধান্ত দরকার';

  @override
  String get suggestedChange => 'একটি প্রস্তাবিত পরিবর্তন';

  @override
  String levelChange(String game, int from, int to) {
    return '$game: from level $from to level $to';
  }

  @override
  String useLevel(int level) {
    return 'Use level $level';
  }

  @override
  String get chooseLevel => 'স্তর বেছে নিন';

  @override
  String get keepAsIs => 'যেমন আছে থাক';

  @override
  String get suggestionCaveat =>
      'এটি কেবল রেকর্ড করা কাজের ভিত্তিতে একটি প্রস্তাব, এমন সেটিংস দিয়ে যা এখনও পরীক্ষা করা হচ্ছে। সিদ্ধান্ত আপনার।';

  @override
  String get decisionApproved =>
      'Approved. The new activity is ready for the next session.';

  @override
  String get decisionModified =>
      'Saved your choice. That is what will be offered next.';

  @override
  String get decisionRejected => 'বর্তমান কাজটিই রাখা হল। কিছু বদলায়নি।';

  @override
  String get decisionFailed => 'That could not be saved. Nothing was changed.';

  @override
  String get recentActivity => 'সাম্প্রতিক কাজ';

  @override
  String get noActivityYet =>
      'এখনও কোনও কাজ রেকর্ড হয়নি। একবার খেলা হলে তা এখানে দেখা যাবে।';

  @override
  String get setUp => 'সাজিয়ে নিন';

  @override
  String get patientBasics => 'মূল তথ্য';

  @override
  String get patientBasicsSubtitle => 'নাম, বয়স, ভাষা';

  @override
  String get knowMe => 'আমাকে চেনো';

  @override
  String get reminders => 'মনে করিয়ে দেওয়া';

  @override
  String get settingsAndSync => 'সেটিংস ও সিঙ্ক';

  @override
  String get settingsSubtitle => 'Text size, sound, language, sign out';

  @override
  String get handOver => 'রোগীর হাতে দিন';

  @override
  String get previewDataWarning =>
      'Preview data. This is not a real patient record.';

  @override
  String get patientHello => 'নমস্কার!';

  @override
  String get patientReady => 'একটু কিছু করতে ইচ্ছে করছে?';

  @override
  String get start => 'শুরু করুন';

  @override
  String get suggestedForToday => 'আজকের জন্য প্রস্তাবিত';

  @override
  String get yourActivityToday => 'আজ আপনার কাজ';

  @override
  String get withPlacesYouKnow => 'With places you know.';

  @override
  String get chooseSomethingElse => 'অন্য কিছু বেছে নিন';

  @override
  String get whatWouldYouLikeToDo => 'আপনি কী করতে চান?';

  @override
  String get takeYourTime => 'সময় নিন। যখন খুশি থামতে পারেন।';

  @override
  String get seeRecentActivities => 'সাম্প্রতিক কাজ দেখুন';

  @override
  String get todaysReminders => 'আজকের মনে করিয়ে দেওয়া';

  @override
  String get whatYouHaveBeenDoing => 'আপনি যা করেছেন';

  @override
  String get nothingYetToday =>
      'আজ এখনও কিছু হয়নি। যখন ইচ্ছে হবে, একটি কাজ অপেক্ষা করছে।';

  @override
  String youPlayed(String game) {
    return 'You played $game';
  }

  @override
  String get allDone => 'আপাতত সব শেষ!';

  @override
  String get resting => 'বিশ্রাম';

  @override
  String get comeBackWhenReady => 'যখন তৈরি মনে হবে, ফিরে আসবেন।';

  @override
  String get readyToPlay => 'খেলতে তৈরি';

  @override
  String get home => 'বাড়ি';

  @override
  String get rest => 'বিশ্রাম';

  @override
  String get playAgain => 'আবার খেলুন';

  @override
  String get goBack => 'পিছনে যান';

  @override
  String get help => 'সাহায্য';

  @override
  String get breakLabel => 'বিরতি';

  @override
  String get takingABreak => 'একটু বিরতি';

  @override
  String get takingABreakBody => 'সময় নিন। তৈরি হলে চালিয়ে যান চাপুন।';

  @override
  String get continueLabel => 'চালিয়ে যান';

  @override
  String get finishForNow => 'আপাতত শেষ করুন';

  @override
  String get howToPlayRouteQuest =>
      'পতাকার দিকে রাস্তা ধরে যান। যেতে হলে পাশের জায়গায় চাপ দিন। পতাকা তুলে নিয়ে বাড়ি ফিরুন। সাহায্য পথ দেখাবে।';

  @override
  String get howToPlayMarbleMazeTilt =>
      'Hold your phone comfortably while it settles, then gently tilt to guide the marble to the glowing goal. If tilt is unavailable, use your finger. Help shows the route.';

  @override
  String get howToPlayMarbleMazeTouch =>
      'Guide the marble along the wooden paths with your finger. Reach the glowing goal. Help shows the route.';

  @override
  String get howToPlayWordSearch =>
      'অক্ষরের মধ্যে শব্দগুলি খুঁজুন। প্রথম অক্ষরে চাপ দিন, তারপর শেষ অক্ষরে। সাহায্য একটি শব্দ দেখিয়ে দেবে।';

  @override
  String get howToPlayRoutineRecall =>
      'দিনের একটি ধাপ দেখানো হবে। এরপর সাধারণত কী হয় বেছে নিন। ভুল হলে আবার চেষ্টা করুন। সাহায্য উত্তর দেখাবে।';

  @override
  String get howToPlayPictureSorting =>
      'ছবিটি দেখুন, তারপর সেটি কোন দলে যায় বেছে নিন। ভুল হলে আবার চেষ্টা করুন।';

  @override
  String get howToPlayGeneric =>
      'Take your time. Help is always there if you need it, and you can take a break whenever you like.';

  @override
  String get gameRouteQuest => 'Route Quest';

  @override
  String get gameMarbleMaze => 'Marble Maze';

  @override
  String get gameWordSearch => 'শব্দ খোঁজা';

  @override
  String get gameRoutineRecall => 'দৈনন্দিন রুটিন';

  @override
  String get gamePictureSorting => 'ছবি সাজানো';

  @override
  String get aboutRouteQuest => 'একটি জায়গায় গিয়ে আবার ফিরে আসুন।';

  @override
  String get aboutMarbleMaze => 'মার্বেলটিকে ধীরে ধীরে শেষ পর্যন্ত নিয়ে যান।';

  @override
  String get aboutWordSearch => 'অক্ষরের মধ্যে লুকানো চেনা শব্দ খুঁজুন।';

  @override
  String get aboutRoutineRecall => 'দিনে এরপর কী হয় মনে করুন।';

  @override
  String get aboutPictureSorting => 'প্রতিটি ছবি তার মতো ছবির সাথে রাখুন।';

  @override
  String get reminderSeenIt => 'ঠিক আছে, আমি দেখেছি';

  @override
  String get reminderLater => 'একটু পরে মনে করিয়ে দিন';

  @override
  String get reminderSeen => 'আপনি এটি দেখেছেন।';

  @override
  String get nothingToRemember => 'এখন মনে রাখার কিছু নেই।';

  @override
  String get today => 'আজ';

  @override
  String get reminderSound => 'মনে করিয়ে দেওয়ার শব্দ';

  @override
  String get reduceMotion => 'নড়াচড়া কমান';

  @override
  String get textSize => 'লেখার আকার';

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
  String get signOut => 'সাইন আউট';

  @override
  String get notConnected => 'সংযোগ নেই। আপনার পরিবর্তন এই ফোনেই থাকবে।';

  @override
  String get savedOnDevice => 'এই ফোনে রাখা আছে। এখন সংযোগ নেই।';

  @override
  String get aboutTesseract => 'টেসারেক্ট সম্পর্কে';

  @override
  String get aboutDescription =>
      'টেসারেক্ট ডিমেনশিয়ায় আক্রান্ত মানুষের জন্য সহজ মানসিক কাজ এবং প্রতিদিনের মনে করিয়ে দেওয়ার ব্যবস্থা করে, যা তাঁদের যত্নকারীরা সাজিয়ে দেন ও দেখে নেন।';

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
  String get save => 'সংরক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get add => 'যোগ করুন';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get couldNotSave => 'এই ফোনে সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get outcomeFinished => 'শেষ হয়েছে';

  @override
  String get outcomeStoppedEarly => 'আগেই থেমেছে';

  @override
  String get outcomeInterrupted => 'বাধা পড়েছে';
}
