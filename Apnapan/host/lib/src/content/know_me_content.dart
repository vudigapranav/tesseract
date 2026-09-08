import 'package:tesseract_game_contract/tesseract_game_contract.dart';

import '../host_flow_state.dart';

/// Turns caregiver-entered content into the `GameItem`s each game plays with.
///
/// Two rules matter here and are the reason this is a separate seam rather
/// than inline code in the play screen:
///
/// 1. **Ids are opaque and stable.** A `GameItem.id` is the only part of an
///    item that may appear in a `GameEvent` payload, so it must never be
///    derived from the person's name, word or routine text. Ids are
///    positional (`place_1`, `word_2`), which keeps telemetry free of
///    personal content while staying stable for a given list order.
/// 2. **Fewer entries, or none, is valid.** Know Me is optional and a
///    caregiver may skip it. A game still needs a usable set, so lists are
///    topped up with neutral placeholders rather than failing or showing an
///    empty board.
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

  static const List<String> _neutralWords = <String>[
    'HOME',
    'TEA',
    'GARDEN',
    'MUSIC',
    'FAMILY',
  ];

  /// A gentle default day, used only when the caregiver has set no reminders.
  ///
  /// Deliberately contains **no medicine step**. The original implementation
  /// this game was ported from included one; presenting medication as part of
  /// everyone's routine would be showing medical content the caregiver never
  /// entered.
  static const List<({String label, String emoji})> _neutralRoutine =
      <({String label, String emoji})>[
    (label: 'Waking up', emoji: '☀️'),
    (label: 'Brushing teeth', emoji: '🪥'),
    (label: 'Eating breakfast', emoji: '🍳'),
    (label: 'A short walk', emoji: '🚶'),
    (label: 'Afternoon tea', emoji: '☕'),
    (label: 'Eating dinner', emoji: '🍽️'),
    (label: 'Going to sleep', emoji: '🌙'),
  ];

  /// Picture Sorting needs items that already carry a category, which Know Me
  /// does not collect. Until a caregiver-managed picture set exists this is a
  /// neutral built-in set, and the game says so through its placeholder art.
  static const List<({String label, String emoji, String category})>
      _sortingSet = <({String label, String emoji, String category})>[
    (label: 'Apple', emoji: '🍎', category: 'fruit'),
    (label: 'Banana', emoji: '🍌', category: 'fruit'),
    (label: 'Grapes', emoji: '🍇', category: 'fruit'),
    (label: 'Lemon', emoji: '🍋', category: 'fruit'),
    (label: 'Cat', emoji: '🐈', category: 'animal'),
    (label: 'Dog', emoji: '🐕', category: 'animal'),
    (label: 'Fish', emoji: '🐟', category: 'animal'),
    (label: 'Bird', emoji: '🐦', category: 'animal'),
    (label: 'Cup', emoji: '🍵', category: 'household'),
    (label: 'Chair', emoji: '🪑', category: 'household'),
    (label: 'Clock', emoji: '🕰️', category: 'household'),
    (label: 'Umbrella', emoji: '☂️', category: 'household'),
  ];

  /// Items for [gameId], drawn from the caregiver's content where the game
  /// can use it.
  static List<GameItem> itemsFor(HostFlowState flow, String gameId) {
    switch (gameId) {
      case 'word_search':
        return _words(flow);
      case 'routine_recall':
        return _routine(flow);
      case 'picture_sorting':
        return _sorting();
      default:
        return _places(flow);
    }
  }

  /// Map-style games: Route Quest's nodes and anything else place-shaped.
  static List<GameItem> _places(HostFlowState flow, {int count = 6}) {
    final List<GameItem> items = <GameItem>[];
    for (final KnowMeItem entry in flow.knowMePeoplePlaces) {
      if (items.length >= count) {
        break;
      }
      final String label = entry.label.trim();
      if (label.isEmpty) {
        continue;
      }
      items.add(GameItem(id: 'place_${items.length + 1}', label: label));
    }
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

  /// Word Search: the caregiver's familiar words.
  ///
  /// Words longer than the largest grid, or duplicates, are left for the grid
  /// builder to report rather than being silently filtered here.
  static List<GameItem> _words(HostFlowState flow, {int count = 5}) {
    final List<GameItem> items = <GameItem>[];
    final Set<String> seen = <String>{};
    for (final String raw in flow.knowMeWords) {
      if (items.length >= count) {
        break;
      }
      final String word = raw.trim();
      if (word.isEmpty || !seen.add(word.toUpperCase())) {
        continue;
      }
      items.add(GameItem(id: 'word_${items.length + 1}', label: word));
    }
    int neutral = 0;
    while (items.length < count && neutral < _neutralWords.length) {
      final String word = _neutralWords[neutral];
      neutral++;
      if (!seen.add(word)) {
        continue;
      }
      items.add(GameItem(id: 'word_${items.length + 1}', label: word));
    }
    return items;
  }

  /// Daily Routine: built from the caregiver's own reminders, in time order,
  /// because those are the real everyday steps they already entered.
  ///
  /// Falls back to a neutral day when no reminders exist.
  static List<GameItem> _routine(HostFlowState flow) {
    final List<ReminderItem> reminders = flow.reminders
        .where((ReminderItem r) => r.title.trim().isNotEmpty)
        .toList()
      ..sort((ReminderItem a, ReminderItem b) =>
          (a.time.hour * 60 + a.time.minute)
              .compareTo(b.time.hour * 60 + b.time.minute));

    if (reminders.length >= 3) {
      return <GameItem>[
        for (int i = 0; i < reminders.length && i < 6; i++)
          GameItem(
            id: 'step_${i + 1}',
            label: reminders[i].title.trim(),
            extra: const <String, Object?>{'emoji': '🕒'},
          ),
      ];
    }

    return <GameItem>[
      for (int i = 0; i < _neutralRoutine.length; i++)
        GameItem(
          id: 'step_${i + 1}',
          label: _neutralRoutine[i].label,
          extra: <String, Object?>{'emoji': _neutralRoutine[i].emoji},
        ),
    ];
  }

  static List<GameItem> _sorting() => <GameItem>[
        for (int i = 0; i < _sortingSet.length; i++)
          GameItem(
            id: 'pic_${i + 1}',
            label: _sortingSet[i].label,
            extra: <String, Object?>{
              'emoji': _sortingSet[i].emoji,
              'category': _sortingSet[i].category,
            },
          ),
      ];

  /// Whether the patient will actually see their own content in [gameId].
  ///
  /// Used to tell the caregiver the truth rather than implying
  /// personalisation that is not happening.
  static bool hasPersonalContent(HostFlowState flow, String gameId) {
    switch (gameId) {
      case 'word_search':
        return flow.knowMeWords.any((String w) => w.trim().isNotEmpty);
      case 'routine_recall':
        return flow.reminders
                .where((ReminderItem r) => r.title.trim().isNotEmpty)
                .length >=
            3;
      case 'picture_sorting':
        // Built-in neutral picture set; nothing personal yet.
        return false;
      default:
        return flow.knowMePeoplePlaces
            .any((KnowMeItem e) => e.label.trim().isNotEmpty);
    }
  }
}
