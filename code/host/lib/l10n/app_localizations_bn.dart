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
      'এই বিল্ডে সাইন-ইন কনফিগার করা নেই। এর জন্য একটি Firebase প্রকল্প ও একটি ব্যাকএন্ড ঠিকানা দরকার, যা বিল্ডের সময় দেওয়া হয়। ততক্ষণ কিছুই সাইন-ইন হবে না — অফলাইনে এর কোনো বিকল্প নেই।';

  @override
  String get signInPatientNote =>
      'যিনি কাজগুলি করবেন তাঁকে সাইন ইন করতে হয় না। একজন যত্নকারী সব ঠিক করে দিয়ে ফোনটি হাতে দেন।';

  @override
  String get openPreview => 'কৃত্রিম ডেভেলপমেন্ট প্রিভিউ খুলুন';

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
    return 'নমস্কার, $name';
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
    return '$game: স্তর $from থেকে স্তর $to';
  }

  @override
  String useLevel(int level) {
    return 'স্তর $level ব্যবহার করুন';
  }

  @override
  String get chooseLevel => 'স্তর বেছে নিন';

  @override
  String get keepAsIs => 'যেমন আছে থাক';

  @override
  String get suggestionCaveat =>
      'এটি কেবল রেকর্ড করা কাজের ভিত্তিতে একটি প্রস্তাব, এমন সেটিংস দিয়ে যা এখনও পরীক্ষা করা হচ্ছে। সিদ্ধান্ত আপনার।';

  @override
  String get decisionApproved => 'অনুমোদিত। পরের বার নতুন কাজটি করা যাবে।';

  @override
  String get decisionModified =>
      'আপনার পছন্দ সংরক্ষণ করা হয়েছে। পরের বার এটিই দেখানো হবে।';

  @override
  String get decisionRejected => 'বর্তমান কাজটিই রাখা হল। কিছু বদলায়নি।';

  @override
  String get decisionFailed => 'সংরক্ষণ করা যায়নি। কিছু বদলায়নি।';

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
  String get settingsSubtitle => 'লেখার আকার, শব্দ, ভাষা, সাইন আউট';

  @override
  String get handOver => 'রোগীর হাতে দিন';

  @override
  String get previewDataWarning => 'নমুনা তথ্য। এটি কোনও আসল রোগীর রেকর্ড নয়।';

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
  String get withPlacesYouKnow => 'আপনার চেনা জায়গা নিয়ে।';

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
    return 'আপনি $game খেলেছেন';
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
      'ফোনটি আরাম করে ধরে রাখুন যতক্ষণ না এটি স্থির হয়, তারপর আলতো করে কাত করে মার্বেলটিকে উজ্জ্বল লক্ষ্যে নিয়ে যান। কাত করা সম্ভব না হলে আঙুল ব্যবহার করুন। সাহায্য পথটি দেখায়।';

  @override
  String get howToPlayMarbleMazeTouch =>
      'আঙুল দিয়ে মার্বেলটিকে কাঠের পথ ধরে নিয়ে যান। উজ্জ্বল লক্ষ্যে পৌঁছান। সাহায্য পথটি দেখায়।';

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
      'সময় নিন। প্রয়োজন হলে সাহায্য পাবেন, আর যখন ইচ্ছে বিরতি নিতে পারেন।';

  @override
  String get gameRouteQuest => 'পথের খোঁজ';

  @override
  String get gameMarbleMaze => 'মার্বেল গোলকধাঁধা';

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
      'অ্যান্ড্রয়েডের লেখার আকারের সেটিংসের সঙ্গে সঙ্গে এটি প্রযোজ্য হবে।';

  @override
  String get synchronization => 'সিঙ্ক করা';

  @override
  String get syncNow => 'এখন সিঙ্ক করুন';

  @override
  String get pendingUploads => 'আপলোডের অপেক্ষায় থাকা খেলার সেশন';

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
    return 'সংস্করণ $version (বিল্ড $build)';
  }

  @override
  String get languagesLabel => 'ভাষা';

  @override
  String get myPatients => 'আমার রোগীরা';

  @override
  String get assignedToYou => 'আপনার দায়িত্বে থাকা রোগীরা।';

  @override
  String get noPatientsAssigned =>
      'এখনও আপনার নামে কোনো রোগী নির্ধারিত হয়নি। নির্ধারণ সার্ভারে হয়, এই অ্যাপ থেকে নয়।';

  @override
  String get observedMeasures => 'পর্যবেক্ষণ করা পরিমাপ';

  @override
  String get sessionHistory => 'খেলার সেশনের ইতিহাস';

  @override
  String get draftReport => 'খসড়া প্রতিবেদন';

  @override
  String get generate => 'তৈরি করুন';

  @override
  String get notes => 'নোট';

  @override
  String get addNote => 'নোট যোগ করুন';

  @override
  String get noNotes => 'এখনও কোনও নোট নেই।';

  @override
  String get doctorDisclaimer =>
      'অ্যাপে দেখা কার্যকলাপ। এটি কোনো জ্ঞানীয় স্কোর, রোগনির্ণয়, বা রোগের অগ্রগতির পরিমাপ নয়।';

  @override
  String notMeasured(String metrics) {
    return 'পরিমাপ করা হয়নি: $metrics।';
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

  @override
  String get reminderNotificationTitle => 'একটি ছোট মনে করিয়ে দেওয়া';

  @override
  String get reminderChannelName => 'দৈনন্দিন মনে করিয়ে দেওয়া';

  @override
  String get reminderChannelDescription =>
      'যত্নকারীর তৈরি দৈনন্দিন মনে করিয়ে দেওয়া';

  @override
  String get speakThis => 'পড়ে শোনান';

  @override
  String get stopSpeaking => 'থামান';

  @override
  String get readAloudAgain => 'আবার পড়ুন';

  @override
  String speechUnavailableForLanguage(String language) {
    return 'এই ফোনে $language ভাষায় পড়ে শোনানো যায় না। উপরের লেখা স্ক্রিনেই থাকবে।';
  }

  @override
  String get speechNoEngine =>
      'এই ফোনে কোনো টেক্সট-টু-স্পিচ কণ্ঠ ইনস্টল করা নেই, তাই কিছু পড়ে শোনানো যাবে না।';

  @override
  String get speechAudioOff =>
      'সেটিংসে শব্দ বন্ধ করা আছে, তাই কিছু পড়ে শোনানো হচ্ছে না।';

  @override
  String get speechFailed => 'এখন লেখাটি পড়ে শোনানো গেল না।';

  @override
  String get tapToSpeak => 'বলতে ট্যাপ করুন';

  @override
  String get listening => 'শোনা হচ্ছে…';

  @override
  String get listeningHint => 'আপনি যা চান বলুন, তারপর একটু অপেক্ষা করুন।';

  @override
  String get stopListening => 'থামান';

  @override
  String get cancelListening => 'বাতিল করুন';

  @override
  String get youSaid => 'আপনি বলেছেন';

  @override
  String get useThis => 'এটি ব্যবহার করুন';

  @override
  String get voiceNeedsConfirmation =>
      '‘এটি ব্যবহার করুন’ না বাছাই করা পর্যন্ত কিছুই সংরক্ষণ হবে না।';

  @override
  String get voicePermissionDenied =>
      'শোনার আগে Tesseract-এর মাইক্রোফোন ব্যবহারের অনুমতি দরকার।';

  @override
  String get voicePermissionBlocked =>
      'মাইক্রোফোনের অনুমতি বন্ধ আছে। ফোনের সেটিংস থেকে আবার চালু করতে পারেন।';

  @override
  String get voiceUnavailable =>
      'এই ফোনে কথা শনাক্ত করার সুবিধা নেই, তাই বলা যাবে না। আপনি লিখতে পারেন।';

  @override
  String voiceLanguageUnavailable(String language) {
    return 'এই ফোনে $language ভাষায় বলা যায় না। আপনি লিখতে পারেন।';
  }

  @override
  String get voiceNothingHeard =>
      'কিছু শোনা যায়নি। আবার চেষ্টা করতে পারেন, বা লিখতে পারেন।';

  @override
  String get voiceNetworkNeeded =>
      'কথা শনাক্ত করতে এখন সংযোগ দরকার, কিন্তু সংযোগ পাওয়া যায়নি।';

  @override
  String get voiceError =>
      'এখন কথা শনাক্ত করা গেল না। আবার চেষ্টা করতে পারেন, বা লিখতে পারেন।';

  @override
  String get speechSettingsTitle => 'বলা ও শোনা';

  @override
  String get speechSettingsSubtitle =>
      'ঐচ্ছিক। এখানকার সবকিছু স্ক্রিনে পড়াও যায় এবং ছুঁয়েও করা যায়।';

  @override
  String get speechCheckThisPhone => 'এই ফোনে কী কী চলে দেখুন';

  @override
  String get speechReadAloudAvailable => 'পড়ে শোনানো: আছে';

  @override
  String get speechReadAloudUnavailable => 'পড়ে শোনানো: নেই';

  @override
  String get speechListeningAvailable => 'অ্যাপকে বলা: আছে';

  @override
  String get speechListeningUnavailable => 'অ্যাপকে বলা: নেই';

  @override
  String get speechNotCheckedYet => 'এই ফোনে এখনও পরীক্ষা করা হয়নি';

  @override
  String get speechDraftWarning =>
      'এই ভাষায় সাবলীল কোনো ব্যক্তি এখনও কথা বলার সুবিধাটি পরীক্ষা করেননি।';
}
