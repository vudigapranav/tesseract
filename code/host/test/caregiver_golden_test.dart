import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesseract_host/src/caregiver/caregiver_home_screen.dart';
import 'package:tesseract_host/src/host_flow_state.dart';

import 'test_helpers.dart';

/// Screenshots of the settled caregiver design.
///
/// The visual language under test is the warm ground, white rounded cards,
/// black pill actions and the peach "needs your decision" card. Regenerate
/// with `flutter test --update-goldens` after an intentional change.
void main() {
  setUpAll(loadAppFonts);

  HostFlowState populatedFlow({bool withProposal = true}) {
    final HostFlowState flow = HostFlowState();
    flow.caregiverName = 'Asha';
    flow.patientName = 'Meera Devi';
    flow.patientId = 'patient-1';
    // No ApiClient is attached in this fixture, so the status must say so;
    // the icon and the words are driven by the same fact.
    flow.syncStatus = 'Saved on this device. Not connected right now.';
    flow.knowMeWords.addAll(<String>['chai', 'garden', 'temple', 'radio']);
    flow.knowMePeoplePlaces.add(KnowMeItem(label: 'Daughter'));
    flow.activityHistory.addAll(<ActivityRecord>[
      ActivityRecord(
        gameId: 'route_quest',
        displayNameKey: 'route_quest_name',
        completedAt: DateTime(2026, 9, 8, 10, 15),
        status: 'completed',
      ),
      ActivityRecord(
        gameId: 'marble_maze',
        displayNameKey: 'marble_maze_name',
        completedAt: DateTime(2026, 9, 8, 9, 5),
        status: 'stopped_by_user',
      ),
    ]);
    if (withProposal) {
      flow.recommendations = <Map<String, dynamic>>[
        <String, dynamic>{
          'recommendation_id': 'rec-1',
          'status': 'pending',
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
            'summary': 'The last 3 comparable sessions were completed '
                'without help.',
            'thresholds_status': 'prototype_unreviewed',
          },
        }
      ];
    }
    return flow;
  }

  Widget app(HostFlowState flow) => CaregiverHomeScreen(flowState: flow);

  testWidgets('Caregiver home with a pending suggestion', (tester) async {
    await pumpForGolden(tester, app(populatedFlow()));
    await expectLater(find.byType(CaregiverHomeScreen),
        matchesGoldenFile('goldens/caregiver_home.png'));
  });

  testWidgets('Caregiver home without a suggestion', (tester) async {
    await pumpForGolden(tester, app(populatedFlow(withProposal: false)));
    await expectLater(find.byType(CaregiverHomeScreen),
        matchesGoldenFile('goldens/caregiver_home_no_proposal.png'));
  });

  testWidgets('Caregiver home at textScale 2.0', (tester) async {
    // Large text is a supported setting, not an edge case: the layout must
    // still be readable and must not overflow.
    await pumpForGolden(tester, app(populatedFlow()), textScale: 2.0);
    await expectLater(find.byType(CaregiverHomeScreen),
        matchesGoldenFile('goldens/caregiver_home_textscale_2x.png'));
  });
}
