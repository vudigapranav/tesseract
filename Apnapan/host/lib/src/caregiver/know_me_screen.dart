import 'package:flutter/material.dart';

import '../host_flow_state.dart';
import 'caregiver_home_screen.dart';

/// C3 Know Me: People & Places, Familiar Words, plus interests. 15-20
/// meaningful words is a target, not a requirement — fewer or skipped is
/// fine.
///
/// Personal content reaches games through opaque-id GameItems. Upload is an
/// explicit version-checked replacement; local saving also works offline.
class KnowMeScreen extends StatefulWidget {
  const KnowMeScreen({super.key, required this.flowState});

  final HostFlowState flowState;

  @override
  State<KnowMeScreen> createState() => _KnowMeScreenState();
}

class _KnowMeScreenState extends State<KnowMeScreen> {
  bool _busy = false;
  String _kind = 'person';
  String? _message;
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
      widget.flowState.knowMePeoplePlaces
          .add(KnowMeItem(label: text, kind: _kind));
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
    try {
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
    } catch (_) {
      if (mounted) {
        setState(() =>
            _message = 'Could not save on this device. Please try again.');
      }
    }
  }

  Future<void> _reviewServer() async {
    setState(() => _busy = true);
    try {
      final content = await widget.flowState.readServerPersonalization();
      if (!mounted) return;
      final useServer = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Review personalization'),
                content: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      const Text('On this device'),
                      Text(widget.flowState.knowMeWords.join(', ')),
                      Text(widget.flowState.knowMePeoplePlaces
                          .map((p) => p.label)
                          .join(', ')),
                      const SizedBox(height: 16),
                      Text('Server version ${content['version']}'),
                      Text((content['personal_words'] as List)
                          .map((w) => w['text'])
                          .join(', ')),
                      Text((content['people_places'] as List)
                          .map((p) => p['label'])
                          .join(', ')),
                      const SizedBox(height: 16),
                      const Text(
                          'Using the server copy replaces the words and people/places shown here. A local backup is retained. Reminders and activity settings stay as they are.'),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep local edits')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Use server copy'))
                ],
              ));
      if (useServer == true) {
        await widget.flowState.useReviewedPersonalization(content);
        if (mounted) {
          setState(() => _message =
              'Server copy loaded. You can review and edit it before uploading.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Could not load the server copy. Local edits remain available.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.flowState.uploadPersonalization();
      if (mounted) setState(() => _message = 'Personalization uploaded.');
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Upload not confirmed. Local edits are retained. Check connection and entry types. A version conflict requires review with the other caregiver; retrying will not overwrite their changes.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            if (_message != null) Text(_message!),
            const Text(
                'Reminders should be written in the patient’s language. Personal text is kept as entered.'),
            DropdownButtonFormField<String>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'New entry type'),
                items: const [
                  DropdownMenuItem(value: 'person', child: Text('Person')),
                  DropdownMenuItem(value: 'place', child: Text('Place'))
                ],
                onChanged: (value) => setState(() => _kind = value!)),
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
                    (KnowMeItem item) => InputChip(
                      label: Text(item.label),
                      onPressed: () => setState(() => item.kind =
                          item.kind == 'person' ? 'place' : 'person'),
                      avatar: Icon(item.kind == 'person'
                          ? Icons.person
                          : item.kind == 'place'
                              ? Icons.place
                              : Icons.question_mark),
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
            const Text(
                'Tap an entry to choose Person or Place. A question mark means it needs a type before upload.'),
            if (widget.flowState.api != null &&
                widget.flowState.patientId.isNotEmpty)
              OutlinedButton(
                  onPressed: _busy ? null : _reviewServer,
                  child: const Text('Review server copy')),
            if (widget.flowState.api != null &&
                widget.flowState.patientId.isNotEmpty)
              OutlinedButton(
                  onPressed: _busy ? null : _upload,
                  child: Text(_busy ? 'Uploading…' : 'Upload personalization')),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                  onPressed: _busy ? null : _done, child: const Text('Done')),
            ),
          ],
        ),
      ),
    );
  }
}
