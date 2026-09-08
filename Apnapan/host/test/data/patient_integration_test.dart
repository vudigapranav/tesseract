import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tesseract_host/src/caregiver/patient_basics_screen.dart';
import 'package:tesseract_host/src/caregiver/know_me_screen.dart';
import 'package:tesseract_host/src/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tesseract_host/src/data/api_client.dart';
import 'package:tesseract_host/src/data/local_repository.dart';
import 'package:tesseract_host/src/host_flow_state.dart';
import 'package:tesseract_host/src/session_controller.dart';
import 'package:tesseract_host/games/game_registry.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  late LocalRepository repo;
  late HostFlowState flow;
  late List<http.Request> requests;
  int putStatus = 200;
  setUp(() async {
    repo = await LocalRepository.open(path: inMemoryDatabasePath);
    flow = HostFlowState(repository: repo);
    requests = [];
    putStatus = 200;
    flow.api = ApiClient(
        baseUrl: Uri.parse('https://example.test'),
        token: () async => 'test',
        client: MockClient((request) async {
          requests.add(request);
          final id = request.url.path.contains('/b') ? 'b' : 'a';
          if (request.method == 'POST') {
            return http.Response(
                jsonEncode(
                    {'patient_id': 'a', 'version': 1, 'display_name': 'A'}),
                201);
          }
          if (request.method == 'PUT') {
            return http.Response(
                jsonEncode(putStatus == 200
                    ? {'version': 8}
                    : {
                        'error': {'code': 'revision_conflict'}
                      }),
                putStatus);
          }
          if (request.url.path.endsWith('/personalization')) {
            return http.Response(
                jsonEncode({
                  'version': 7,
                  'personal_words': [
                    {'text': 'word-$id', 'locale': 'bn'}
                  ],
                  'people_places': [
                    {
                      'label': 'Place $id',
                      'kind': 'place',
                      'media_asset_id': 'asset-$id'
                    }
                  ],
                  'preferences': {'unexposed': 'retain'},
                }),
                200);
          }
          return http.Response(
              jsonEncode({
                'patient_id': id,
                'display_name': id,
                'language': 'bn',
                'version': 7
              }),
              200);
        }));
    flow.availablePatients = [
      {'patient_id': 'a'},
      {'patient_id': 'b'}
    ];
  });
  tearDown(() async {
    await repo.db.close();
  });

  test(
      'switching patients and restarting retains separate offline edits and revisions',
      () async {
    await flow.selectPatient('a');
    flow.knowMeWords.add('offline-a');
    flow.approvedActivity = gameRegistry.first;
    flow.approvedLevel = 3;
    await flow.setPatientLanguage('as');
    await flow.selectPatient('b');
    expect(flow.knowMeWords, ['word-b']);
    expect(flow.approvedActivity, isNull);
    await flow.setInterfaceLanguage('en');
    await flow.selectPatient('a');
    expect(flow.knowMeWords, ['word-a', 'offline-a']);
    expect(flow.interfaceLanguageCode, 'en');
    expect(flow.effectivePatientLanguageCode, 'as');
    expect(flow.approvedLevel, 3);
    final restored = HostFlowState(repository: repo);
    await restored.restore();
    expect(restored.knowMeWords, flow.knowMeWords);
    expect(restored.profileVersion, 7);
    expect(restored.contentVersion, flow.contentVersion);
    expect(restored.personalizationDirty, isTrue);
  });

  test(
      'upload preserves entry kinds, media, word locales and hidden preferences',
      () async {
    await flow.selectPatient('a');
    await flow.uploadPersonalization();
    final body = jsonDecode(requests.last.body) as Map;
    expect(body['version'], 7);
    expect(body['people_places'][0]['media_asset_id'], 'asset-a');
    expect(body['people_places'][0]['kind'], 'place');
    expect(body['personal_words'][0]['locale'], 'bn');
    expect(body['preferences'], {'unexposed': 'retain'});
    expect(flow.profileVersion, 8);
    expect(flow.personalizationDirty, isFalse);
  });

  test('conflict retains edited content and original revision across retry',
      () async {
    await flow.selectPatient('a');
    flow.knowMeWords.add('local');
    putStatus = 409;
    await expectLater(flow.uploadPersonalization(), throwsA(isA<ApiFailure>()));
    await expectLater(flow.uploadPersonalization(), throwsA(isA<ApiFailure>()));
    expect(flow.profileVersion, 7);
    expect(flow.knowMeWords, contains('local'));
    expect(flow.personalizationDirty, isTrue);
    expect(
        requests
            .where((r) => r.method == 'PUT')
            .map((r) => jsonDecode(r.body)['version']),
        [7, 7]);
  });

  test('unverified patient selection performs no network request or mutation',
      () async {
    await expectLater(flow.selectPatient('unknown'), throwsStateError);
    expect(requests, isEmpty);
    expect(flow.patientId, isEmpty);
  });

  test('failed patient fetch leaves selected draft intact', () async {
    await flow.selectPatient('a');
    flow.knowMeWords.add('local');
    flow.api = ApiClient(
        baseUrl: Uri.parse('https://example.test'),
        token: () async => 'test',
        client: MockClient(
            (_) async => http.Response('{"error":{"code":"forbidden"}}', 403)));
    await expectLater(flow.selectPatient('b'), throwsA(isA<ApiFailure>()));
    expect(flow.patientId, 'a');
    expect(flow.knowMeWords, contains('local'));
  });

  test('creation uses supported contract fields and remembers returned id',
      () async {
    flow.patientName = 'A';
    flow.patientAge = 70;
    await flow.createPatient();
    expect(flow.patientId, 'a');
    final body = jsonDecode(requests.single.body) as Map;
    expect(body['display_name'], 'A');
    expect(body.containsKey('age'), isFalse);
    await expectLater(flow.createPatient(), throwsStateError);
    expect(requests.length, 1);
  });

  test('untyped legacy entries cannot replace server personalization',
      () async {
    await flow.selectPatient('a');
    flow.knowMePeoplePlaces.add(KnowMeItem(label: 'Unclassified'));
    await expectLater(flow.uploadPersonalization(), throwsStateError);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  test('reviewing server content is read-only until caregiver chooses it',
      () async {
    await flow.selectPatient('a');
    flow.knowMeWords.add('local-draft');
    final remote = await flow.readServerPersonalization();
    expect(flow.knowMeWords, contains('local-draft'));
    await flow.useReviewedPersonalization(remote);
    expect(flow.knowMeWords, ['word-a']);
    final backup =
        jsonDecode((await repo.readMeta('personalization_backup:a'))!) as Map;
    expect(backup['words'], contains('local-draft'));
    expect(flow.profileVersion, 7);
    expect(flow.personalizationDirty, isFalse);
  });

  testWidgets(
      'patient form creates through API and opens Know Me at large text',
      (tester) async {
    flow = HostFlowState()..api = flow.api;
    await tester.pumpWidget(MaterialApp(
        theme: TesseractDesign.theme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: PatientBasicsScreen(flowState: flow)));
    await tester.enterText(find.byType(TextField).first, 'A');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(flow.patientId, 'a');
    expect(find.byType(KnowMeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('session freezes supplied server revisions and actual parameters', () {
    final controller = SessionController(
        registration: gameRegistry.first,
        level: 2,
        isTutorial: false,
        configVersion: '12',
        contentVersion: '8',
        approvedParams: {'reviewed_parameter': 4});
    final config = controller.buildConfig(textScale: 1);
    expect(config.configVersion, '12');
    expect(config.contentVersion, '8');
    expect(config.difficultyParams['reviewed_parameter'], 4);
    expect(identical(config, controller.buildConfig(textScale: 2)), isTrue);
  });
}
