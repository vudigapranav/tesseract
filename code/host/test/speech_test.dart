import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_host/src/speech/speech_capability.dart';
import 'package:tesseract_host/src/speech/speech_engine.dart';
import 'package:tesseract_host/src/speech/speech_output_service.dart';
import 'package:tesseract_host/src/speech/voice_input_service.dart';
import 'package:tesseract_host/src/speech/voice_input_sheet.dart';

/// A stand-in for the phone's TTS engine.
///
/// It records what it was asked to say and in which language, which is how
/// these tests can assert the thing that actually matters: that the app never
/// speaks a language it was not asked for.
class FakeTts implements TtsEngine {
  FakeTts(this._languages, {this.refuseToBind = false});

  final List<String> _languages;

  /// Reproduces an engine that enumerates a language and then declines it.
  final bool refuseToBind;

  final List<String> spoken = <String>[];
  final List<String> boundLanguages = <String>[];
  int stops = 0;
  String? current;

  /// When true, the next utterance hangs until something stops it, standing in
  /// for a long sentence still being read out.
  bool holdNextUtterance = false;
  Completer<void>? _held;

  @override
  Future<List<String>> languages() async => _languages;

  @override
  Future<bool> setLanguage(String tag) async {
    if (refuseToBind) return false;
    boundLanguages.add(tag);
    current = tag;
    return true;
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (!holdNextUtterance) return;
    holdNextUtterance = false;
    // Held until stop() releases it. Created here, not before the call, so
    // that speak()'s own leading stop() cannot cancel the hold it is about
    // to set up.
    _held = Completer<void>();
    await _held!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (_held != null && !_held!.isCompleted) _held!.complete();
    _held = null;
  }

  @override
  Future<String?> engineName() async => 'fake.engine';

  @override
  Future<void> setSpeechRate(double rate) async {}
}

class FakeStt implements SttEngine {
  FakeStt({
    this.locales_ = const <String>['en-IN', 'bn-IN'],
    this.canInitialize = true,
    this.permission = true,
    this.grantOnRequest = true,
    this.result,
  });

  final List<String> locales_;
  final bool canInitialize;
  bool permission;
  final bool grantOnRequest;
  VoiceInputResult? result;

  int listens = 0;
  int cancels = 0;
  bool permissionAsked = false;
  Completer<VoiceInputResult>? gate;

  @override
  bool get isListening => gate != null && !gate!.isCompleted;

  @override
  Future<bool> initialize() async => canInitialize;

  @override
  Future<List<String>> locales() async => canInitialize ? locales_ : <String>[];

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async {
    permissionAsked = true;
    permission = grantOnRequest;
    return permission;
  }

  @override
  Future<VoiceInputResult> listenOnce({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
  }) async {
    listens++;
    if (gate != null) return gate!.future;
    return result ??
        const VoiceInputResult.failed(VoiceInputFailure.engineError);
  }

  @override
  Future<void> cancel() async {
    cancels++;
    gate = null;
  }
}

/// Yields to the event loop until [check] passes or the turns run out.
///
/// `speak` awaits the engine's language enumeration before it starts, so a
/// single microtask hop is not enough to observe the speaking state.
Future<void> settleUntil(bool Function() check, {int turns = 50}) async {
  for (int i = 0; i < turns && !check(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('engine tag resolution', () {
    test('matches regardless of case and separator', () {
      expect(resolveEngineTag('bn-IN', <String>['bn_in']), 'bn_in');
      expect(resolveEngineTag('en-US', <String>['en-US']), 'en-US');
    });

    test('a bare tag accepts any region of the same language', () {
      expect(resolveEngineTag('bn', <String>['bn-BD']), 'bn-BD');
    });

    test('a regional tag does not accept a different region', () {
      expect(resolveEngineTag('bn-IN', <String>['bn-BD']), isNull);
    });

    test('never resolves across languages', () {
      // The one that matters most. Mizo and Khasi are written in Latin
      // script, so an engine list full of European locales must still not
      // produce a match for them.
      for (final String code in <String>['lus', 'kha', 'mni', 'as']) {
        for (final String tag in SpeechMatrix.tagsFor(code)) {
          expect(
            resolveEngineTag(tag, <String>['en-US', 'en-IN', 'en-GB', 'hi-IN']),
            isNull,
            reason: '$code resolved to an English voice',
          );
        }
      }
    });
  });

  group('the documented matrix is background, not a claim', () {
    test('covers every language the app ships', () {
      for (final String code in <String>[
        'en',
        'as',
        'bn',
        'mni',
        'kha',
        'lus'
      ]) {
        expect(SpeechMatrix.byCode(code), isNotNull,
            reason: '$code has no speech matrix row');
      }
    });

    test('no language is recorded as reviewed by a fluent speaker', () {
      // Nothing has been heard by a native speaker yet. If this ever starts
      // failing it must be because real review evidence was recorded, not
      // because someone flipped an enum.
      for (final SpeechLanguageRow row in SpeechMatrix.rows) {
        expect(row.review, PronunciationReview.notReviewed,
            reason: '${row.englishName} claims pronunciation review');
      }
    });

    test('documentation alone never makes speech available', () async {
      // Bengali is the one language Google documents. On a device whose
      // engine does not offer it, it must still come back unavailable.
      final SpeechOutputService s = SpeechOutputService(
          engine: FakeTts(<String>['en-US']), audioEnabled: () => true);
      final SpeechAvailability a = await s.availability('bn');
      expect(a.isAvailable, isFalse);
      expect(a.reason, SpeechUnavailableReason.noVoiceForLanguage);
    });
  });

  group('spoken output routing', () {
    test('speaks when the engine really offers the language', () async {
      final FakeTts tts = FakeTts(<String>['en-IN', 'bn-IN']);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);
      final SpeechAvailability a =
          await s.speak('ওষুধ খান', languageCode: 'bn');
      expect(a.isAvailable, isTrue);
      expect(a.resolvedTag, 'bn-IN');
      expect(tts.spoken, <String>['ওষুধ খান']);
    });

    test('says nothing at all when the language has no voice', () async {
      final FakeTts tts = FakeTts(<String>['en-IN', 'bn-IN']);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);
      final SpeechAvailability a =
          await s.speak('Tlawmngaihna', languageCode: 'lus');
      expect(a.isAvailable, isFalse);
      expect(a.reason, SpeechUnavailableReason.noVoiceForLanguage);
      // The whole point: not one word came out, in any language.
      expect(tts.spoken, isEmpty);
      expect(tts.boundLanguages, isNot(contains('en-IN')));
    });

    test('an engine that enumerates but refuses to bind is unavailable',
        () async {
      final FakeTts tts = FakeTts(<String>['bn-IN'], refuseToBind: true);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);
      expect((await s.availability('bn')).isAvailable, isFalse);
      expect(tts.spoken, isEmpty);
    });

    test('audio turned off means silence, and says so', () async {
      final FakeTts tts = FakeTts(<String>['bn-IN']);
      bool audio = false;
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => audio);
      final SpeechAvailability off = await s.speak('x', languageCode: 'bn');
      expect(off.reason, SpeechUnavailableReason.audioOff);
      expect(tts.spoken, isEmpty);

      audio = true;
      await s.speak('x', languageCode: 'bn');
      expect(tts.spoken, <String>['x']);
    });

    test('a device with no engine reports no engine, not a language gap',
        () async {
      final SpeechOutputService s = SpeechOutputService(
          engine: FakeTts(<String>[]), audioEnabled: () => true);
      expect((await s.availability('en')).reason,
          SpeechUnavailableReason.noEngine);
    });

    test('a second request stops the first instead of overlapping', () async {
      final FakeTts tts = FakeTts(<String>['en-IN']);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);

      tts.holdNextUtterance = true;
      final Future<void> first = s.speak('one', languageCode: 'en');
      await settleUntil(() => s.isSpeaking);
      expect(s.isSpeaking, isTrue);

      // Asking again while the first is still going must stop it.
      await s.speak('two', languageCode: 'en');
      await first;
      expect(tts.stops, greaterThanOrEqualTo(1));
      expect(tts.spoken, <String>['one', 'two']);
    });

    test('backgrounding stops speech', () async {
      final FakeTts tts = FakeTts(<String>['en-IN']);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);
      tts.holdNextUtterance = true;
      unawaited(s.speak('long sentence', languageCode: 'en'));
      await settleUntil(() => s.isSpeaking);
      await s.handleAppBackgrounded();
      expect(tts.stops, greaterThanOrEqualTo(1));
      expect(s.isSpeaking, isFalse);
    });

    test('a stopped utterance does not later flip the control back', () async {
      final FakeTts tts = FakeTts(<String>['en-IN']);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);
      tts.holdNextUtterance = true;
      final Future<void> f = s.speak('x', languageCode: 'en');
      await settleUntil(() => s.isSpeaking);
      await s.stop();
      await f;
      expect(s.isSpeaking, isFalse);
    });

    test('changing language rebinds rather than continuing in the old voice',
        () async {
      final FakeTts tts = FakeTts(<String>['en-IN', 'bn-IN']);
      final SpeechOutputService s =
          SpeechOutputService(engine: tts, audioEnabled: () => true);
      await s.speak('hello', languageCode: 'en');
      await s.handleLanguageChanged();
      await s.speak('নমস্কার', languageCode: 'bn');
      expect(tts.current, 'bn-IN');
      expect(tts.stops, greaterThanOrEqualTo(1));
    });
  });

  group('voice input', () {
    test('asks for the microphone only when it does not have it', () async {
      final FakeStt stt = FakeStt(
          permission: true,
          result: const VoiceInputResult.heard('water the plants'));
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      expect(stt.permissionAsked, isFalse);

      final FakeStt second = FakeStt(
          permission: false,
          result: const VoiceInputResult.heard('water the plants'));
      await VoiceInputController(engine: second).start('en');
      expect(second.permissionAsked, isTrue);
    });

    test('a refused microphone fails and never listens', () async {
      final FakeStt stt = FakeStt(permission: false, grantOnRequest: false);
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      expect(c.phase, VoicePhase.failed);
      expect(c.failure, VoiceInputFailure.permissionDenied);
      expect(stt.listens, 0);
    });

    test('a device with no recogniser fails before asking for anything',
        () async {
      final FakeStt stt = FakeStt(canInitialize: false);
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      expect(c.failure, VoiceInputFailure.recognitionUnavailable);
      expect(stt.permissionAsked, isFalse);
      expect(stt.listens, 0);
    });

    test('an unsupported language fails instead of listening in another',
        () async {
      final FakeStt stt = FakeStt(locales_: <String>['en-IN', 'bn-IN']);
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('kha');
      expect(c.failure, VoiceInputFailure.languageUnavailable);
      // Never opened the microphone at all, so nothing was captured in a
      // language the user did not choose.
      expect(stt.listens, 0);
    });

    test('a transcript waits for confirmation and is not returned early',
        () async {
      final FakeStt stt =
          FakeStt(result: const VoiceInputResult.heard('take the blue tablet'));
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      expect(c.phase, VoicePhase.awaitingConfirmation);
      expect(c.transcript, 'take the blue tablet');
      expect(c.confirm(), 'take the blue tablet');
      expect(c.phase, VoicePhase.idle);
      // Confirming consumes it, so one utterance cannot be applied twice.
      expect(c.transcript, isEmpty);
    });

    test('discarding a transcript keeps nothing', () async {
      final FakeStt stt =
          FakeStt(result: const VoiceInputResult.heard('something private'));
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      c.discard();
      expect(c.transcript, isEmpty);
      expect(c.phase, VoicePhase.idle);
    });

    test('cancelling stops the engine and drops what was heard', () async {
      final FakeStt stt = FakeStt();
      stt.gate = Completer<VoiceInputResult>();
      final VoiceInputController c = VoiceInputController(engine: stt);
      unawaited(c.start('en'));
      await settleUntil(() => c.phase == VoicePhase.listening);
      await c.cancel();
      expect(stt.cancels, 1);
      expect(c.transcript, isEmpty);
      expect(c.failure, VoiceInputFailure.cancelled);
    });

    test('a timeout is reported as nothing heard', () async {
      final FakeStt stt = FakeStt(
          result: const VoiceInputResult.failed(VoiceInputFailure.timeout));
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      expect(c.failure, VoiceInputFailure.timeout);
      expect(c.transcript, isEmpty);
    });

    test('losing the network is reported as a network problem', () async {
      final FakeStt stt = FakeStt(
          result: const VoiceInputResult.failed(VoiceInputFailure.network));
      final VoiceInputController c = VoiceInputController(engine: stt);
      await c.start('en');
      expect(c.failure, VoiceInputFailure.network);
    });

    test('disposing tears the listen down', () async {
      final FakeStt stt = FakeStt();
      stt.gate = Completer<VoiceInputResult>();
      final VoiceInputController c = VoiceInputController(engine: stt);
      unawaited(c.start('en'));
      await settleUntil(() => c.phase == VoicePhase.listening);
      c.dispose();
      expect(stt.cancels, 1);
    });
  });

  group('the voice sheet never acts on its own', () {
    Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: child),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[]);

    testWidgets('shows what was heard and returns it only after Use this',
        (WidgetTester tester) async {
      final FakeStt stt =
          FakeStt(result: const VoiceInputResult.heard('water the plants'));
      final VoiceInputController c = VoiceInputController(engine: stt);
      await tester
          .pumpWidget(host(VoiceInputSheet(controller: c, languageCode: 'en')));
      await tester.pumpAndSettle();

      // The transcript is on screen, and so is the promise that nothing has
      // been saved yet.
      expect(find.text('water the plants'), findsOneWidget);
      expect(find.text('Nothing is saved until you choose Use this.'),
          findsOneWidget);
      expect(find.text('Use this'), findsOneWidget);
    });

    testWidgets('an unsupported language explains itself in that language',
        (WidgetTester tester) async {
      final FakeStt stt = FakeStt(locales_: <String>['en-IN']);
      final VoiceInputController c = VoiceInputController(engine: stt);
      await tester.pumpWidget(
          host(VoiceInputSheet(controller: c, languageCode: 'lus')));
      await tester.pumpAndSettle();

      // Named language, and a standing offer to type instead. No "Try again",
      // because trying again cannot help.
      expect(find.textContaining('Mizo'), findsWidgets);
      expect(find.text('Try again'), findsNothing);
    });
  });
}
