import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// A collapsible (off by default) live JSON log of every [GameEvent] — with
/// no backend to inspect yet, this is how to watch `seq` stay gap-free and
/// `elapsedMs` freeze while paused. A small toggle button; the log panel
/// itself only appears once opened.
class EventLogPanel extends StatefulWidget {
  const EventLogPanel({super.key, required this.events});

  final List<GameEvent> events;

  @override
  State<EventLogPanel> createState() => _EventLogPanelState();
}

class _EventLogPanelState extends State<EventLogPanel> {
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  bool _expanded = false;
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant EventLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expanded && widget.events.length != oldWidget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpTo(_controller.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 48,
                width: 48,
                child: FloatingActionButton.small(
                  heroTag: 'eventLogToggle',
                  tooltip: 'Event log',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Icon(_expanded ? Icons.close : Icons.terminal),
                ),
              ),
            ),
            if (_expanded)
              Container(
                width: double.infinity,
                height: 220,
                color: const Color(0xFF101418),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        'Event log (JSON)',
                        style: TextStyle(
                            color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: widget.events.isEmpty
                          ? const Center(
                              child: Text('No events yet',
                                  style: TextStyle(color: Colors.white38)),
                            )
                          : ListView.builder(
                              controller: _controller,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: widget.events.length,
                              itemBuilder: (BuildContext context, int index) {
                                final GameEvent event = widget.events[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: SelectableText(
                                    _encoder.convert(event.toJson()),
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
