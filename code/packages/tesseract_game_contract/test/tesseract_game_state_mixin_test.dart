import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

GameConfig _config() => GameConfig(
  gameId: 'route_quest',
  gameVersion: '1.0.0',
  schemaVersion: '1',
  configVersion: '1',
  contentVersion: '1',
  metricVersion: '1',
  level: 1,
  difficultyParams: const <String, Object?>{'nodeCount': 3},
  items: const <GameItem>[],
  strings: const GameStrings(
    helpButtonLabel: 'Help',
    breakButtonLabel: 'Break',
    pausedTitle: 'Taking a break',
    pausedBody: 'Take your time',
    resumeButtonLabel: 'Continue',
    finishNowButtonLabel: 'Finish for now',
  ),
  textScale: 1.0,
  inputMode: GameInputMode.touch,
  showLabels: true,
  locale: 'en',
);

class _TestGame extends TesseractGame {
  const _TestGame({
    required super.config,
    required super.onEvent,
    required super.onFinish,
    required this.recorder,
  });

  final TesseractEventRecorder recorder;

  @override
  State<_TestGame> createState() => _TestGameState();
}

class _TestGameState extends State<_TestGame>
    with WidgetsBindingObserver, TesseractGameStateMixin<_TestGame> {
  @override
  TesseractEventRecorder get eventRecorder => widget.recorder;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('backgrounding pauses the session and foregrounding resumes it', (tester) async {
    final recorder = TesseractEventRecorder();
    recorder.sessionStarted();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _TestGame(config: _config(), onEvent: (_) {}, onFinish: (_) {}, recorder: recorder),
      ),
    );

    expect(recorder.isPaused, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(recorder.isPaused, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(recorder.isPaused, isFalse);
  });

  testWidgets('does not touch a pause it did not cause (a manual Break)', (tester) async {
    final recorder = TesseractEventRecorder();
    recorder.sessionStarted();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _TestGame(config: _config(), onEvent: (_) {}, onFinish: (_) {}, recorder: recorder),
      ),
    );

    // The patient taps the game's own Break control first.
    recorder.paused(reason: 'break');
    expect(recorder.isPaused, isTrue);

    // The OS also backgrounds the app while the break overlay is showing.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(recorder.isPaused, isTrue);

    // Returning to the foreground must NOT auto-resume a manual break — only
    // the game's own Continue control does that.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(recorder.isPaused, isTrue);
  });

  testWidgets('ignores lifecycle changes before the session has started', (tester) async {
    final recorder = TesseractEventRecorder();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _TestGame(config: _config(), onEvent: (_) {}, onFinish: (_) {}, recorder: recorder),
      ),
    );

    // No session_started yet — backgrounding must not emit a stray first
    // event ahead of it.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(recorder.lastSeq, 0);
  });
}
