import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import '../host_flow_state.dart';

/// Turns caregiver-entered Know Me content into the `GameItem`s a game plays
/// with.
///
/// Two rules matter here and are the reason this is a separate seam rather
/// than inline code in the play screen:
///
/// 1. **Ids are opaque and stable.** A `GameItem.id` is the only part of an
///    item that may appear in a `GameEvent` payload, so it must never be
///    derived from the person's or place's name. Ids are positional
///    (`place_1`, `place_2`), which keeps telemetry free of personal content
///    while staying stable for as long as the caregiver's list order is.
/// 2. **Fewer entries, or none, is valid.** Know Me is optional and a
///    caregiver may skip it. A game still needs a full set of items, so the
///    list is topped up with neutral placeholders rather than failing or
///    showing an empty board.
abstract final class KnowMeContent {
  /// Neutral fallbacks used when the caregiver has not supplied enough
  /// content. Deliberately generic: never a guess at someone's real life.
  static const List<String> _neutralPlaces = <String>[
    'The garden',
    'The market',
    'The temple',
    'The park',
    'The shop',
    'Home',
  ];

  /// Items for [registration]'s content needs, drawn from Know Me first.
  ///
  /// [count] is how many the game's level actually needs; Route Quest's
  /// level 3 map is the largest current requirement at 6.
  static List<GameItem> itemsFor(HostFlowState flow, {int count = 6}) {
    final List<GameItem> items = <GameItem>[];

    for (final KnowMeItem entry in flow.knowMePeoplePlaces) {
      if (items.length >= count) {
        break;
      }
      final String label = entry.label.trim();
      if (label.isEmpty) {
        continue;
      }
      items.add(GameItem(
        id: 'place_${items.length + 1}',
        label: label,
        // `caption` is caregiver context for the caregiver's own screens, not
        // something a game should render or a payload should carry.
      ));
    }

    // Top up so the board is always complete, even when Know Me was skipped.
    int neutral = 0;
    while (items.length < count) {
      items.add(GameItem(
        id: 'place_${items.length + 1}',
        label: _neutralPlaces[neutral % _neutralPlaces.length],
      ));
      neutral++;
    }

    return items;
  }

  /// Whether the patient will actually see their own content this session.
  ///
  /// Used to tell the caregiver the truth on the hand-over screen rather than
  /// implying personalisation that is not happening.
  static bool hasPersonalContent(HostFlowState flow) => flow.knowMePeoplePlaces
      .any((KnowMeItem entry) => entry.label.trim().isNotEmpty);
}
