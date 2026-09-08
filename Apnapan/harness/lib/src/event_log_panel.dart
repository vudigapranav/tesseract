import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tesseract_game_contract/tesseract_game_contract.dart';

/// Prints every [GameEvent] as JSON as it arrives, so seq gaplessness and
/// paused-time exclusion from elapsedMs can be checked by eye, with no
/// backend involved.
class EventLogPanel extends StatefulWidget {
  const EventLogPanel({super.key, required this.events});

  final List<GameEvent> events;

  @override
  State<EventLogPanel> createState() => _EventLogPanelState();
}

class _EventLogPanelState extends State<EventLogPanel> {
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant EventLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length != oldWidget.events.length) {
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
    return ColoredBox(
      color: const Color(0xFF101418),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'Event log (JSON)',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: widget.events.isEmpty
                ? const Center(
                    child: Text('No events yet', style: TextStyle(color: Colors.white38)),
                  )
                : ListView.builder(
                    controller: _controller,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
