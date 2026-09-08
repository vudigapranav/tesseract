import 'package:flutter/material.dart';

import '../host_flow_state.dart';
import 'caregiver_home_screen.dart';

/// C3 Know Me: People & Places, Familiar Words, plus interests. 15-20
/// meaningful words is a target, not a requirement — fewer or skipped is
/// fine.
///
/// Content collected here is not yet wired into any game's `GameItem`s —
/// that connection is later integration work, not part of this skeleton.
class KnowMeScreen extends StatefulWidget {
  const KnowMeScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<KnowMeScreen> createState() => _KnowMeScreenState();
}

class _KnowMeScreenState extends State<KnowMeScreen> {
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();

  @override
  void dispose() {
    _personController.dispose();
    _wordController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final String text = _personController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.flowState.knowMePeoplePlaces.add(KnowMeItem(label: text));
      _personController.clear();
    });
  }

  void _addWord() {
    final String text = _wordController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.flowState.knowMeWords.add(text);
      _wordController.clear();
    });
  }

  Future<void> _done() async {
    await widget.flowState.save();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CaregiverHomeScreen(flowState: widget.flowState),
      ),
      (Route<void> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Know me')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('People & places', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _personController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Daughter Priya, the tea garden',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    onPressed: _addPerson, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.flowState.knowMePeoplePlaces
                  .map(
                    (KnowMeItem item) => Chip(
                      label: Text(item.label),
                      onDeleted: () => setState(() =>
                          widget.flowState.knowMePeoplePlaces.remove(item)),
                    ),
                  )
                  .toList(),
            ),
            const Divider(height: 32),
            Text('Familiar words', style: theme.textTheme.titleMedium),
            Text(
              '15-20 meaningful words is a target — fewer or skipped is fine.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                        hintText: 'e.g. home', border: OutlineInputBorder()),
                    onSubmitted: (_) => _addWord(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    onPressed: _addWord, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.flowState.knowMeWords
                  .map(
                    (String word) => Chip(
                      label: Text(word),
                      onDeleted: () => setState(
                          () => widget.flowState.knowMeWords.remove(word)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(onPressed: _done, child: const Text('Done')),
            ),
          ],
        ),
      ),
    );
  }
}
