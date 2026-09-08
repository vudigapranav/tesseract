import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import 'event_log_panel.dart';
import 'fake_content.dart';
import 'game_choice.dart';
import 'how_to_play_screen.dart';
import 'phone_frame.dart';
import 'session_finished_screen.dart';

enum _Phase { howToPlay, playing, finished }

/// Screen 2 (+3): hosts the chosen game inside a fixed phone frame, and an
/// event log panel beside it. Owns the how-to-play and finished screens
/// around the game — the game itself only ever draws its own pause overlay.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.choice,
    required this.level,
    required this.inputMode,
    required this.textScale,
  });

  final GameChoice choice;
  final int level;
  final String inputMode;
  final double textScale;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  _Phase _phase = _Phase.howToPlay;
  GameResult? _result;
  final List<GameEvent> _events = <GameEvent>[];
  late final GameStrings _strings = buildFakeStrings();
  late final GameConfig _config = GameConfig(
    gameId: widget.choice.gameId,
    gameVersion: widget.choice.gameVersion,
    schemaVersion: '1',
    configVersion: '1',
    contentVersion: '1',
    metricVersion: '1',
    level: widget.level,
    difficultyParams: widget.choice.difficultyParamsForLevel(widget.level),
    items: buildFakeItems(),
    strings: _strings,
    textScale: widget.textScale,
    inputMode: widget.inputMode,
    showLabels: true,
    locale: 'en',
  );

  void _onEvent(GameEvent event) {
    // The harness has no backend — printing here is the entire verification
    // path for "seq is gap-free" and "elapsedMs excludes pauses".
    // ignore: avoid_print
    print('GameEvent: ${event.toJson()}');
    setState(() => _events.add(event));
  }

  void _onFinish(GameResult result) {
    setState(() {
      _result = result;
      _phase = _Phase.finished;
    });
  }

  Widget _buildPhoneContent() {
    switch (_phase) {
      case _Phase.howToPlay:
        return HowToPlayScreen(
          gameName: widget.choice.displayName,
          instructions: _strings.text('how_to_play_body'),
          onStart: () => setState(() => _phase = _Phase.playing),
        );
      case _Phase.playing:
        return widget.choice.build(config: _config, onEvent: _onEvent, onFinish: _onFinish);
      case _Phase.finished:
        return SessionFinishedScreen(
          gameName: widget.choice.displayName,
          result: _result!,
          onHome: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.choice.displayName} — level ${widget.level}'),
      ),
      body: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          final Widget frame = Expanded(
            flex: 3,
            child: PhoneFrame(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: const Size(kPhoneWidth, kPhoneHeight),
                  textScaler: TextScaler.linear(widget.textScale),
                ),
                child: _buildPhoneContent(),
              ),
            ),
          );
          final Widget log = Expanded(flex: 2, child: EventLogPanel(events: _events));

          // Side-by-side on a wide harness window, stacked on a narrow one —
          // this is the harness's own dev-tool chrome, not the simulated
          // patient screen, so it may reflow; the phone frame inside it
          // never does.
          final bool wide = MediaQuery.of(context).size.width > 760;
          return wide ? Row(children: <Widget>[frame, log]) : Column(children: <Widget>[frame, log]);
        },
      ),
    );
  }
}
