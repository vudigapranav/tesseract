// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Apnapan';

  @override
  String get languageName => 'हिन्दी';

  @override
  String get signInTitle => 'एक जाना-पहचाना पल।\nथोड़ी-सी खुशी।';

  @override
  String get signInSubtitle =>
      'साथ मिलकर सार्थक गतिविधियाँ और रोज़ की याद-दिलाएँ तय कीजिए।';

  @override
  String get roleCaregiver => 'देखभाल करने वाले';

  @override
  String get roleDoctor => 'डॉक्टर';

  @override
  String get emailCaregiver => 'देखभाल करने वाले का ईमेल';

  @override
  String get emailDoctor => 'डॉक्टर का ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signingIn => 'पहुँच जाँची जा रही है…';

  @override
  String get signInFailed =>
      'साइन-इन और पहुँच की पुष्टि नहीं हो सकी। अपनी जानकारी और कनेक्शन देखिए।';

  @override
  String get signInNotConfigured =>
      'इस बिल्ड में साइन-इन सेट नहीं है। इसके लिए एक Firebase प्रोजेक्ट और बैकएंड पता चाहिए, जो बिल्ड के समय दिए जाते हैं। तब तक कोई साइन-इन नहीं होगा — ऑफ़लाइन कोई विकल्प नहीं है।';

  @override
  String get signInPatientNote =>
      'गतिविधियाँ करने वाला व्यक्ति साइन इन नहीं करता। देखभाल करने वाले सब तैयार करके फ़ोन उन्हें दे देते हैं।';

  @override
  String get openPreview => 'कृत्रिम डेवलपमेंट प्रीव्यू खोलें';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनिए';

  @override
  String get interfaceLanguage => 'ऐप की भाषा';

  @override
  String get interfaceLanguageHelp => 'आपके लिए मेन्यू और बटनों की भाषा।';

  @override
  String get patientLanguage => 'खेलने वाले व्यक्ति की भाषा';

  @override
  String get patientLanguageHelp =>
      'गतिविधियाँ और निर्देश इसी भाषा में आएँगे। यह आपकी भाषा से अलग हो सकती है।';

  @override
  String get draftTranslationNotice =>
      'मसौदा अनुवाद। किसी धाराप्रवाह वक्ता ने अभी जाँचा नहीं है।';

  @override
  String translationCoverage(int percent) {
    return '$percent% अनूदित';
  }

  @override
  String get awaitingReview => 'मातृभाषी समीक्षा बाकी है';

  @override
  String get fallsBackToEnglish =>
      'जो अभी अनूदित नहीं है वह अंग्रेज़ी में दिखेगा।';

  @override
  String caregiverGreeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get welcomeBack => 'फिर से स्वागत है';

  @override
  String get noPatientYet => 'अभी कोई मरीज़ नहीं जोड़ा गया';

  @override
  String get needsYourDecision => 'आपका निर्णय चाहिए';

  @override
  String get suggestedChange => 'एक सुझाया गया बदलाव';

  @override
  String levelChange(String game, int from, int to) {
    return '$game: स्तर $from से स्तर $to तक';
  }

  @override
  String useLevel(int level) {
    return 'स्तर $level रखें';
  }

  @override
  String get chooseLevel => 'स्तर चुनें';

  @override
  String get keepAsIs => 'जैसा है वैसा ही रहने दें';

  @override
  String get suggestionCaveat =>
      'यह सुझाव केवल दर्ज गतिविधि से बना है, और जिन सेटिंग्स पर यह आधारित है वे अभी परखी जा रही हैं। निर्णय आपका है।';

  @override
  String get decisionApproved =>
      'स्वीकृत। नई गतिविधि अगली बार के लिए तैयार है।';

  @override
  String get decisionModified =>
      'आपका चुनाव सहेज लिया। अगली बार वही दिया जाएगा।';

  @override
  String get decisionRejected => 'मौजूदा गतिविधि वैसी ही रखी। कुछ नहीं बदला।';

  @override
  String get decisionFailed => 'यह सहेजा नहीं जा सका। कुछ भी नहीं बदला।';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get noActivityYet =>
      'अभी कोई गतिविधि दर्ज नहीं है। एक बार खेलने पर वह यहाँ दिखेगी।';

  @override
  String get setUp => 'तैयार करें';

  @override
  String get patientBasics => 'मरीज़ की बुनियादी जानकारी';

  @override
  String get patientBasicsSubtitle => 'नाम, उम्र, भाषा';

  @override
  String get knowMe => 'मुझे जानिए';

  @override
  String get reminders => 'याद-दिलाएँ';

  @override
  String get settingsAndSync => 'सेटिंग्स और सिंक';

  @override
  String get settingsSubtitle => 'लिखाई का आकार, ध्वनि, भाषा, साइन आउट';

  @override
  String get handOver => 'मरीज़ को सौंपें';

  @override
  String get previewDataWarning =>
      'प्रीव्यू डेटा। यह किसी असली मरीज़ का रिकॉर्ड नहीं है।';

  @override
  String get patientHello => 'नमस्ते!';

  @override
  String get patientReady => 'थोड़ी-सी गतिविधि के लिए तैयार हैं?';

  @override
  String get start => 'शुरू करें';

  @override
  String get suggestedForToday => 'आज के लिए सुझाव';

  @override
  String get yourActivityToday => 'आज की आपकी गतिविधि';

  @override
  String get withPlacesYouKnow => 'उन जगहों के साथ जिन्हें आप जानते हैं।';

  @override
  String get chooseSomethingElse => 'कुछ और चुनें';

  @override
  String get whatWouldYouLikeToDo => 'आप क्या करना चाहेंगे?';

  @override
  String get takeYourTime => 'आराम से कीजिए। जब चाहें रुक सकते हैं।';

  @override
  String get seeRecentActivities => 'हाल की गतिविधियाँ देखें';

  @override
  String get todaysReminders => 'आज की याद-दिलाएँ';

  @override
  String get whatYouHaveBeenDoing => 'आप क्या-क्या करते रहे हैं';

  @override
  String get nothingYetToday =>
      'आज अभी कुछ नहीं। जब मन हो, एक गतिविधि तैयार है।';

  @override
  String youPlayed(String game) {
    return 'आपने $game खेला';
  }

  @override
  String get allDone => 'अभी के लिए हो गया!';

  @override
  String get resting => 'आराम';

  @override
  String get comeBackWhenReady => 'जब भी तैयार लगे, लौट आइए।';

  @override
  String get readyToPlay => 'खेलने के लिए तैयार';

  @override
  String get home => 'घर';

  @override
  String get rest => 'आराम';

  @override
  String get playAgain => 'फिर से खेलें';

  @override
  String get goBack => 'वापस जाएँ';

  @override
  String get help => 'मदद';

  @override
  String get breakLabel => 'विराम';

  @override
  String get takingABreak => 'थोड़ा विराम';

  @override
  String get takingABreakBody => 'आराम से कीजिए। तैयार हों तो जारी रखें दबाइए।';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get finishForNow => 'अभी के लिए समाप्त करें';

  @override
  String get howToPlayRouteQuest =>
      'रास्ते पर चलते हुए झंडे तक पहुँचिए। बढ़ने के लिए जुड़ी हुई जगह दबाइए। झंडा उठाइए, फिर घर लौटिए। मदद रास्ता दिखाती है।';

  @override
  String get howToPlayMarbleMazeTilt =>
      'फ़ोन को आराम से पकड़े रहिए जब तक वह स्थिर न हो जाए, फिर धीरे से झुकाकर कंचे को चमकते लक्ष्य तक ले जाइए। झुकाना संभव न हो तो उँगली से कीजिए। मदद रास्ता दिखाती है।';

  @override
  String get howToPlayMarbleMazeTouch =>
      'उँगली से कंचे को लकड़ी के रास्तों पर ले जाइए। चमकते लक्ष्य तक पहुँचिए। मदद रास्ता दिखाती है।';

  @override
  String get howToPlayWordSearch =>
      'अक्षरों में से हर शब्द ढूँढिए। पहला अक्षर दबाइए, फिर आख़िरी अक्षर दबाइए। शब्द आड़े, खड़े और कभी-कभी तिरछे होते हैं। मदद एक शब्द दिखा देती है।';

  @override
  String get howToPlayRoutineRecall =>
      'आपको दिन का एक काम दिखेगा। चुनिए कि आमतौर पर उसके बाद क्या होता है। अगर वह न हो तो फिर से कोशिश कीजिए। मदद उत्तर दिखा देती है।';

  @override
  String get howToPlayPictureSorting =>
      'तस्वीर देखिए, फिर वह समूह चुनिए जिसमें वह आती है। अगर वह न हो तो फिर से कोशिश कीजिए। मदद समूह दिखा देती है।';

  @override
  String get howToPlayGeneric =>
      'आराम से कीजिए। ज़रूरत हो तो मदद हमेशा मौजूद है, और जब चाहें विराम ले सकते हैं।';

  @override
  String get gameRouteQuest => 'रास्ते की खोज';

  @override
  String get gameMarbleMaze => 'कंचे की भूलभुलैया';

  @override
  String get gameWordSearch => 'शब्द खोज';

  @override
  String get gameRoutineRecall => 'रोज़ की दिनचर्या';

  @override
  String get gamePictureSorting => 'तस्वीर छँटाई';

  @override
  String get aboutRouteQuest => 'किसी जगह तक जाइए और वापस आइए।';

  @override
  String get aboutMarbleMaze => 'कंचे को धीरे-धीरे अंत तक पहुँचाइए।';

  @override
  String get aboutWordSearch => 'अक्षरों में छिपे जाने-पहचाने शब्द ढूँढिए।';

  @override
  String get aboutRoutineRecall => 'याद कीजिए कि दिन में आगे क्या आता है।';

  @override
  String get aboutPictureSorting =>
      'हर तस्वीर को उसके जैसी तस्वीरों के साथ रखिए।';

  @override
  String get reminderSeenIt => 'ठीक है, मैंने देख लिया';

  @override
  String get reminderLater => 'थोड़ी देर बाद याद दिलाइए';

  @override
  String get reminderSeen => 'आपने इसे देख लिया है।';

  @override
  String get nothingToRemember => 'अभी याद रखने को कुछ नहीं है।';

  @override
  String get today => 'आज';

  @override
  String get reminderSound => 'याद-दिलाने की ध्वनि';

  @override
  String get reduceMotion => 'हलचल कम करें';

  @override
  String get textSize => 'लिखाई का आकार';

  @override
  String get textSizeHelp =>
      'तुरंत लागू होता है, फ़ोन की लिखाई-आकार सेटिंग के ऊपर।';

  @override
  String get synchronization => 'सिंक';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get pendingUploads => 'अपलोड बाकी सत्र';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get notConnected => 'कनेक्ट नहीं है। आपके बदलाव इसी फ़ोन में रहेंगे।';

  @override
  String get savedOnDevice => 'इसी फ़ोन में सहेजा गया। अभी कनेक्ट नहीं है।';

  @override
  String get aboutTesseract => 'अपनापन के बारे में';

  @override
  String get aboutDescription =>
      'अपनापन डिमेंशिया के साथ जी रहे लोगों के लिए सौम्य संज्ञानात्मक गतिविधियाँ और रोज़ की याद-दिलाएँ देता है, जिन्हें उनकी देखभाल करने वाले तैयार करते और देखते हैं।';

  @override
  String get builtBy => 'Built and developed by the Tesseract Team.';

  @override
  String versionLabel(String version, String build) {
    return 'संस्करण $version (बिल्ड $build)';
  }

  @override
  String get languagesLabel => 'भाषाएँ';

  @override
  String get myPatients => 'मेरे मरीज़';

  @override
  String get assignedToYou => 'आपको सौंपे गए मरीज़।';

  @override
  String get noPatientsAssigned =>
      'अभी आपको कोई मरीज़ नहीं सौंपा गया है। यह सर्वर पर तय होता है, इस ऐप से नहीं।';

  @override
  String get observedMeasures => 'देखी गई माप';

  @override
  String get sessionHistory => 'सत्रों का इतिहास';

  @override
  String get draftReport => 'मसौदा रिपोर्ट';

  @override
  String get generate => 'बनाएँ';

  @override
  String get notes => 'टिप्पणियाँ';

  @override
  String get addNote => 'टिप्पणी जोड़ें';

  @override
  String get noNotes => 'अभी कोई टिप्पणी नहीं।';

  @override
  String get doctorDisclaimer =>
      'ऐप में देखी गई गतिविधि। यह कोई संज्ञानात्मक अंक, निदान, या रोग की प्रगति की माप नहीं है।';

  @override
  String notMeasured(String metrics) {
    return 'मापा नहीं गया: $metrics।';
  }

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get couldNotSave =>
      'इस फ़ोन में सहेजा नहीं जा सका। कृपया फिर कोशिश कीजिए।';

  @override
  String get outcomeFinished => 'पूरा हुआ';

  @override
  String get outcomeStoppedEarly => 'जल्दी रोका गया';

  @override
  String get outcomeInterrupted => 'बीच में रुका';

  @override
  String get reminderNotificationTitle => 'एक सौम्य याद';

  @override
  String get reminderChannelName => 'दिनचर्या की याद-दिलाएँ';

  @override
  String get reminderChannelDescription =>
      'देखभाल करने वालों की बनाई रोज़ की याद-दिलाएँ';

  @override
  String get speakThis => 'पढ़कर सुनाएँ';

  @override
  String get stopSpeaking => 'रोकें';

  @override
  String get readAloudAgain => 'फिर पढ़ें';

  @override
  String speechUnavailableForLanguage(String language) {
    return 'इस फ़ोन पर $language में पढ़कर सुनाना उपलब्ध नहीं है। ऊपर की बात स्क्रीन पर बनी रहेगी।';
  }

  @override
  String get speechNoEngine =>
      'इस फ़ोन में कोई टेक्स्ट-टू-स्पीच आवाज़ नहीं है, इसलिए कुछ पढ़कर नहीं सुनाया जा सकता।';

  @override
  String get speechAudioOff =>
      'सेटिंग्स में ध्वनि बंद है, इसलिए कुछ पढ़कर नहीं सुनाया जा रहा।';

  @override
  String get speechFailed => 'अभी यह पढ़कर नहीं सुनाया जा सका।';

  @override
  String get tapToSpeak => 'बोलने के लिए दबाएँ';

  @override
  String get listening => 'सुना जा रहा है…';

  @override
  String get listeningHint => 'जो कहना है कहिए, फिर थोड़ा ठहरिए।';

  @override
  String get stopListening => 'रोकें';

  @override
  String get cancelListening => 'रद्द करें';

  @override
  String get youSaid => 'आपने कहा';

  @override
  String get useThis => 'यही रखें';

  @override
  String get voiceNeedsConfirmation =>
      'जब तक आप ‘यही रखें’ नहीं चुनते, कुछ भी सहेजा नहीं जाएगा।';

  @override
  String get voicePermissionDenied =>
      'सुनने से पहले अपनापन को माइक्रोफ़ोन की अनुमति चाहिए।';

  @override
  String get voicePermissionBlocked =>
      'माइक्रोफ़ोन की अनुमति बंद है। आप इसे फ़ोन की सेटिंग्स से फिर चालू कर सकते हैं।';

  @override
  String get voiceUnavailable =>
      'इस फ़ोन में बोली पहचानने की सुविधा नहीं है, इसलिए बोलना उपलब्ध नहीं है। आप लिख सकते हैं।';

  @override
  String voiceLanguageUnavailable(String language) {
    return 'इस फ़ोन पर $language में बोलना उपलब्ध नहीं है। आप लिख सकते हैं।';
  }

  @override
  String get voiceNothingHeard =>
      'कुछ सुनाई नहीं दिया। आप फिर कोशिश कर सकते हैं, या लिख सकते हैं।';

  @override
  String get voiceNetworkNeeded =>
      'बोली पहचानने के लिए अभी कनेक्शन चाहिए, जो नहीं मिला।';

  @override
  String get voiceError =>
      'अभी बोली पहचानी नहीं जा सकी। आप फिर कोशिश कर सकते हैं, या लिख सकते हैं।';

  @override
  String get speechSettingsTitle => 'बोलना और सुनना';

  @override
  String get speechSettingsSubtitle =>
      'वैकल्पिक। यहाँ का सब कुछ स्क्रीन पर पढ़ा भी जा सकता है और छूकर किया भी जा सकता है।';

  @override
  String get speechCheckThisPhone => 'देखें यह फ़ोन क्या-क्या कर सकता है';

  @override
  String get speechReadAloudAvailable => 'पढ़कर सुनाना: उपलब्ध';

  @override
  String get speechReadAloudUnavailable => 'पढ़कर सुनाना: उपलब्ध नहीं';

  @override
  String get speechListeningAvailable => 'ऐप से बोलना: उपलब्ध';

  @override
  String get speechListeningUnavailable => 'ऐप से बोलना: उपलब्ध नहीं';

  @override
  String get speechNotCheckedYet => 'इस फ़ोन पर अभी जाँचा नहीं गया';

  @override
  String get speechDraftWarning =>
      'इस भाषा के किसी धाराप्रवाह वक्ता ने बोलने की सुविधा अभी जाँची नहीं है।';

  @override
  String get appNameHindi => 'अपनापन';

  @override
  String get appTagline =>
      'AI-आधारित संज्ञानात्मक गतिविधियाँ और रोज़मर्रा का सहारा।';
}
