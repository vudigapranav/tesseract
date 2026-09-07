import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Fake [GameItem]s so the harness never needs a backend or real caregiver
/// content.
List<GameItem> buildFakeItems() {
  return List<GameItem>.generate(
    6,
    (int i) => GameItem(id: 'loc_${i + 1}', label: 'Location ${i + 1}'),
  );
}

/// A fully populated fake [GameStrings] — every named field filled in, plus
/// a handful of generic keys in [GameStrings.values] so a game can look up
/// arbitrary display text without the harness needing to know its
/// vocabulary in advance.
GameStrings buildFakeStrings() {
  return const GameStrings(
    helpButtonLabel: 'Help',
    breakButtonLabel: 'Break',
    pausedTitle: 'Taking a break',
    pausedBody: 'Take your time. Tap Continue when you are ready.',
    resumeButtonLabel: 'Continue',
    finishNowButtonLabel: 'Finish for now',
    values: <String, String>{
      'how_to_play_body': "Let's try together. Tap Start when you are ready.",
      'destination_reached_body': 'You made it!',
      'session_finished_body': 'All done for now.',
    },
  );
}
