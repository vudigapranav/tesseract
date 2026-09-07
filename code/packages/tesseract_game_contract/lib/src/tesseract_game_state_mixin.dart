import 'package:flutter/widgets.dart';

import 'event_recorder.dart';
import 'tesseract_game.dart';

/// Mixes automatic backgrounding-pause behaviour into a [TesseractGame]'s
/// [State].
///
/// "Backgrounding pauses the session and that interval is excluded from
/// active time" applies to every game, so this lives once here instead of
/// being reimplemented per game. A game only needs to expose the
/// [TesseractEventRecorder] driving its session through [eventRecorder];
/// backgrounding and returning to the foreground are then handled
/// automatically.
///
/// This mixin only ever resumes a pause **it** caused. If the session was
/// already paused for another reason — the patient tapped the game's own
/// Break control — when the app is backgrounded, this leaves that pause
/// alone and does not auto-resume it when the app returns to the
/// foreground: the game's own Continue control still owns resuming from a
/// manual break, matching "Resume exact state to P4" being a patient action,
/// not something that happens just because a notification shade closed.
///
/// Usage — mix this in alongside [WidgetsBindingObserver] itself, so its
/// default no-op callbacks are available for every lifecycle method this
/// mixin does not care about:
///
/// ```dart
/// class _RouteQuestGameState extends State<RouteQuestGame>
///     with WidgetsBindingObserver, TesseractGameStateMixin<RouteQuestGame> {
///   final _recorder = TesseractEventRecorder();
///
///   @override
///   TesseractEventRecorder get eventRecorder => _recorder;
/// }
/// ```
mixin TesseractGameStateMixin<T extends TesseractGame> on State<T>, WidgetsBindingObserver {
  /// The recorder driving this session's events.
  TesseractEventRecorder get eventRecorder;

  bool _pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool sessionIsLive = eventRecorder.lastSeq > 0 && !eventRecorder.isFinished;
    if (!sessionIsLive) {
      return;
    }
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (!eventRecorder.isPaused) {
          eventRecorder.paused(reason: 'backgrounded');
          _pausedByLifecycle = true;
        }
        break;
      case AppLifecycleState.resumed:
        if (_pausedByLifecycle) {
          eventRecorder.resumed();
          _pausedByLifecycle = false;
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }
}
