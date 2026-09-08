import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tesseract_host/src/caregiver/caregiver_home_screen.dart';
import 'package:tesseract_host/src/data/api_client.dart';
import 'package:tesseract_host/src/host_flow_state.dart';

/// The caregiver decision loop.
///
/// A suggested activity change must never apply itself: the whole point of
/// the pending state is that a person chooses. These tests assert what is
/// actually sent to the backend when they do.
void main() {
  late List<Map<String, Object?>> decisions;
  late List<String> calls;

  Map<String, dynamic> proposal({String status = 'pending'}) =>
      <String, dynamic>{
        'recommendation_id': 'rec-1',
        'status': status,
        'rule_version': 'rules-v1',
        'proposed_config': <String, dynamic>{
          'game_id': 'route_quest',
          'level': 2,
          'input_mode': 'touch',
        },
        'current_config': <String, dynamic>{
          'game_id': 'route_quest',
          'level': 1,
          'input_mode': 'touch',
        },
        'reason': <String, dynamic>{
          'code': 'consistent_success',
          'summary':
              'The last 3 comparable sessions were completed without help.',
          'thresholds_status': 'prototype_unreviewed',
        },
      };

  HostFlowState flowWith({List<Map<String, dynamic>>? recommendations}) {
    decisions = <Map<String, Object?>>[];
    calls = <String>[];
    final HostFlowState flow = HostFlowState();
    flow.caregiverName = 'Asha';
    flow.patientName = 'Synthetic Patient';
    flow.patientId = 'patient-1';
    flow.recommendations = recommendations ?? <Map<String, dynamic>>[proposal()];
    flow.api = ApiClient(
      baseUrl: Uri.parse('https://example.invalid'),
      token: () async => 'test-token',
      client: MockClient((http.Request request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/decision')) {
          decisions.add(
              jsonDecode(request.body) as Map<String, Object?>);
          return http.Response(jsonEncode(<String, Object?>{}), 200);
        }
        if (request.url.path.endsWith('/activity')) {
          return http.Response(
              jsonEncode(<String, Object?>{
                'game_id': 'route_quest',
                'level': 2,
                'config_version': 1,
              }),
              200);
        }
        if (request.url.path.endsWith('/recommendations')) {
          // After a decision the proposal is no longer pending.
          return http.Response(
              jsonEncode(<String, Object?>{
                'items': <Object?>[proposal(status: 'accepted')]
              }),
              200);
        }
        return http.Response(jsonEncode(<String, Object?>{}), 200);
      }),
    );
    return flow;
  }

  Widget wrap(HostFlowState flow) =>
      MaterialApp(home: CaregiverHomeScreen(flowState: flow));

  testWidgets('a pending suggestion is shown with its reason', (tester) async {
    await tester.pumpWidget(wrap(flowWith()));
    await tester.pumpAndSettle();

    expect(find.text('A suggested change'), findsOneWidget);
    expect(find.textContaining('level 1'), findsWidgets);
    expect(
        find.textContaining('completed without help'), findsOneWidget);
  });

  testWidgets('the suggestion says it is not a clinical judgement',
      (tester) async {
    await tester.pumpWidget(wrap(flowWith()));
    await tester.pumpAndSettle();

    // Unreviewed thresholds must be disclosed on the caregiver's screen, not
    // only in the API response.
    expect(find.textContaining('still being tested'), findsOneWidget);
    expect(find.textContaining('You decide'), findsOneWidget);
  });

  testWidgets('nothing is sent until the caregiver chooses', (tester) async {
    await tester.pumpWidget(wrap(flowWith()));
    await tester.pumpAndSettle();

    expect(decisions, isEmpty);
    expect(calls.where((c) => c.contains('decision')), isEmpty);
  });

  testWidgets('accepting sends the proposed level', (tester) async {
    final HostFlowState flow = flowWith();
    await tester.pumpWidget(wrap(flow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use level 2'));
    await tester.pumpAndSettle();

    expect(decisions, hasLength(1));
    expect(decisions.single['decision'], 'accept');
    expect(decisions.single.containsKey('modified_config'), isFalse);
    // The guard against a stale proposal overwriting newer config is sent.
    expect(decisions.single.containsKey('expected_config_version'), isTrue);
  });

  testWidgets('rejecting keeps the current activity', (tester) async {
    await tester.pumpWidget(wrap(flowWith()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep as is'));
    await tester.pumpAndSettle();

    expect(decisions.single['decision'], 'reject');
    expect(find.textContaining('Nothing has changed'), findsOneWidget);
  });

  testWidgets('choosing a different level sends modify with that level',
      (tester) async {
    await tester.pumpWidget(wrap(flowWith()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level 3'));
    await tester.pumpAndSettle();

    expect(decisions.single['decision'], 'modify');
    expect((decisions.single['modified_config'] as Map)['level'], 3);
  });

  testWidgets('cancelling the level chooser sends nothing', (tester) async {
    await tester.pumpWidget(wrap(flowWith()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(decisions, isEmpty);
  });

  testWidgets('a failed decision reports it and claims no change',
      (tester) async {
    final HostFlowState flow = flowWith();
    flow.api = ApiClient(
      baseUrl: Uri.parse('https://example.invalid'),
      token: () async => 'test-token',
      client: MockClient((http.Request request) async => http.Response(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{'code': 'revision_conflict'}
          }),
          409)),
    );

    await tester.pumpWidget(wrap(flow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use level 2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing was changed'), findsOneWidget);
  });

  testWidgets('with no pending suggestion the section is absent',
      (tester) async {
    await tester.pumpWidget(
        wrap(flowWith(recommendations: <Map<String, dynamic>>[])));
    await tester.pumpAndSettle();

    expect(find.text('Needs your decision'), findsNothing);
    expect(find.text('A suggested change'), findsNothing);
  });

  testWidgets('an already-decided suggestion is not shown as pending',
      (tester) async {
    await tester.pumpWidget(wrap(flowWith(
        recommendations: <Map<String, dynamic>>[
          proposal(status: 'accepted')
        ])));
    await tester.pumpAndSettle();

    expect(find.text('A suggested change'), findsNothing);
  });

  testWidgets('history shows recorded outcomes in words, not scores',
      (tester) async {
    final HostFlowState flow = flowWith(recommendations: <Map<String, dynamic>>[]);
    flow.activityHistory.addAll(<ActivityRecord>[
      ActivityRecord(
          gameId: 'route_quest',
          displayNameKey: 'route_quest',
          completedAt: DateTime.now(),
          status: 'completed'),
      ActivityRecord(
          gameId: 'marble_maze',
          displayNameKey: 'marble_maze',
          completedAt: DateTime.now(),
          status: 'stopped_by_user'),
    ]);

    await tester.pumpWidget(wrap(flow));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.textContaining('Finished'), findsOneWidget);
    expect(find.textContaining('Stopped early'), findsOneWidget);
  });

  testWidgets('with no history it says so plainly', (tester) async {
    await tester.pumpWidget(
        wrap(flowWith(recommendations: <Map<String, dynamic>>[])));
    await tester.pumpAndSettle();

    expect(find.textContaining('No activities recorded yet'), findsOneWidget);
  });
}
