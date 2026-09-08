import 'package:flutter/widgets.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import '../l10n/app_localizations.dart';

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

/// The strings a game shows, in the **patient's** language.
///
/// Looked up for [languageCode] rather than taken from the widget tree,
/// because the person playing may not read the caregiver's language. This is
/// the only place patient-facing game text is produced, so Help and Break are
/// translated wherever the game draws them.
GameStrings localizedGameStrings(String languageCode) {
  final AppLocalizations l10n = lookupAppLocalizations(Locale(languageCode));
  return GameStrings(
    helpButtonLabel: l10n.help,
    breakButtonLabel: l10n.breakLabel,
    pausedTitle: l10n.takingABreak,
    pausedBody: l10n.takingABreakBody,
    resumeButtonLabel: l10n.continueLabel,
    finishNowButtonLabel: l10n.finishForNow,
    values: <String, String>{
      'how_to_play_body': l10n.howToPlayGeneric,
      'destination_reached_body': l10n.allDone,
      'session_finished_body': l10n.allDone,
    },
  );
}

/// The instruction shown before an activity starts, in the patient's language.
String localizedInstructions(String languageCode, String gameId,
    {required bool preferTouch}) {
  final AppLocalizations l10n = lookupAppLocalizations(Locale(languageCode));
  switch (gameId) {
    case 'route_quest':
      return l10n.howToPlayRouteQuest;
    case 'marble_maze':
      return preferTouch
          ? l10n.howToPlayMarbleMazeTouch
          : l10n.howToPlayMarbleMazeTilt;
    case 'word_search':
      return l10n.howToPlayWordSearch;
    case 'routine_recall':
      return l10n.howToPlayRoutineRecall;
    case 'picture_sorting':
      return l10n.howToPlayPictureSorting;
    default:
      return l10n.howToPlayGeneric;
  }
}
