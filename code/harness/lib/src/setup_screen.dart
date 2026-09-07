import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import 'game_choice.dart';
import 'play_screen.dart';

/// Screen 1: pick a game, level, input mode and text scale, then Play.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  GameChoice _game = GameChoice.routeQuest;
  int _level = 1;
  String _inputMode = GameInputMode.touch;
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tesseract harness')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Game', style: theme.textTheme.titleMedium),
          RadioGroup<GameChoice>(
            groupValue: _game,
            onChanged: (GameChoice? v) => setState(() => _game = v!),
            child: Column(
              children: GameChoice.values
                  .map((GameChoice g) => RadioListTile<GameChoice>(title: Text(g.displayName), value: g))
                  .toList(),
            ),
          ),
          const Divider(),
          Text('Level', style: theme.textTheme.titleMedium),
          RadioGroup<int>(
            groupValue: _level,
            onChanged: (int? v) => setState(() => _level = v!),
            child: Column(
              children: <int>[
                1,
                2,
                3,
              ].map((int l) => RadioListTile<int>(title: Text('Level $l'), value: l)).toList(),
            ),
          ),
          const Divider(),
          Text('Input mode', style: theme.textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: _inputMode,
            onChanged: (String? v) => setState(() => _inputMode = v!),
            child: const Column(
              children: <Widget>[
                RadioListTile<String>(title: Text('Touch'), value: GameInputMode.touch),
                RadioListTile<String>(title: Text('Tilt'), value: GameInputMode.tilt),
              ],
            ),
          ),
          const Divider(),
          Text('Text scale', style: theme.textTheme.titleMedium),
          RadioGroup<double>(
            groupValue: _textScale,
            onChanged: (double? v) => setState(() => _textScale = v!),
            child: const Column(
              children: <Widget>[
                RadioListTile<double>(title: Text('1.0'), value: 1.0),
                RadioListTile<double>(title: Text('2.0'), value: 2.0),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        PlayScreen(choice: _game, level: _level, inputMode: _inputMode, textScale: _textScale),
                  ),
                );
              },
              child: const Text('Play'),
            ),
          ),
        ],
      ),
    );
  }
}
