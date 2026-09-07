import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Placeholder content until real caregiver-managed Know Me content exists.
/// Generic enough for any game's `items` — the largest current need is
/// Route Quest's 6-node level-3 map.
List<GameItem> defaultGameItems() {
  return List<GameItem>.generate(
      6, (int i) => GameItem(id: 'item_${i + 1}', label: 'Place ${i + 1}'));
}

/// A fully populated placeholder [GameStrings]. Real, already-localised
/// caregiver-facing copy replaces this once the content pipeline exists.
GameStrings defaultGameStrings() {
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
