import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/main.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';

// Synthetic data only. These tests never contact Laravel, Firebase or an LLM.
class FixtureApi extends Api {
  FixtureApi(super.session);
  final writes = <(String, Json)>[];
  Json get checkin => {
    'id': 'checkin-1',
    'checkin_date': dateOnly(DateTime.now()),
    'mood_score': 3,
    'anxiety_score': 2,
    'energy_score': 3,
    'sleep_score': 4,
    'pain_score': 2,
    'optional_note': '',
    'ai_analysis_allowed': false,
  };
  Json page(List<Json> rows) => {
    'items': rows,
    'total': rows.length,
    'page': 1,
    'last_page': 1,
  };
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/checkins')) {
      return page([checkin]);
    }
    if (path.startsWith('/treatments')) {
      return page([
        {
          'id': 'treatment-1',
          'title': 'Konsultasi terjadwal',
          'treatment_type': 'consultation',
          'scheduled_at': DateTime.now()
              .add(const Duration(days: 2))
              .toUtc()
              .toIso8601String(),
          'status': 'scheduled',
        },
      ]);
    }
    if (path.startsWith('/journals')) {
      return page([
        {
          'id': 'journal-1',
          'title': 'Catatan Hari Ini',
          'content': 'Aku ingin meluangkan waktu untuk beristirahat.',
          'journal_date': dateOnly(DateTime.now()),
          'ai_analysis_allowed': false,
        },
      ]);
    }
    if (path.startsWith('/symptoms')) {
      return page([
        {
          'id': 'symptom-1',
          'logged_at': DateTime.now().toUtc().toIso8601String(),
          'pain': 2,
          'fatigue': 3,
          'nausea': 2,
          'dizziness': 1,
          'appetite': 3,
          'sleep_quality': 4,
        },
      ]);
    }
    if (path.startsWith('/insights')) {
      return {
        'recorded_days': 7,
        'contains_mock_signals': false,
        'overall_direction': 'stable',
        'series': [
          for (var i = 6; i >= 0; i--)
            {
              ...checkin,
              'checkin_date': dateOnly(
                DateTime.now().subtract(Duration(days: i)),
              ),
            },
        ],
        'metrics': {
          for (final k in ['mood', 'anxiety', 'energy', 'sleep', 'pain'])
            k: {'mean': 3.0, 'direction': 'stable'},
        },
        'contextual_patterns': [],
      };
    }
    if (path == '/caregiver/patients') {
      return [
        {
          'patient_id': 'patient-1',
          'name': 'Pasien Contoh',
          'relationship_label': 'Keluarga',
        },
      ];
    }
    if (path == '/caregiver/patients/patient-1/summary') {
      return {
        'patient_id': 'patient-1',
        'permissions': {'can_view_wellbeing_summary': true},
        'wellbeing_summary': {
          'recorded_days': 7,
          'mood': 3.0,
          'anxiety': 2.0,
          'energy': 3.0,
          'sleep': 4.0,
        },
      };
    }
    if (path == '/notifications') {
      return [
        {
          'id': 'notice-1',
          'notification_type': 'support_alert',
          'title': 'Hopely Care',
          'body': 'Ada pengingat baru.',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'read_at': null,
        },
      ];
    }
    if (path == '/caregivers') {
      return [];
    }
    if (path == '/chat/sessions') {
      return [
        {'id': 'chat-1'},
      ];
    }
    if (path == '/chat/sessions/chat-1/messages') {
      return [
        {'sender': 'user', 'content': 'Aku ingin bercerita hari ini.'},
        {
          'sender': 'assistant',
          'content': 'Aku mendengarkan. Apa yang ingin kamu ceritakan?',
        },
      ];
    }
    if (path.startsWith('/activities')) {
      return [];
    }
    throw StateError('Unexpected fixture request: $path');
  }

  @override
  Future<dynamic> put(String path, Json data) async {
    writes.add((path, data));
    return {'id': 'checkin-1', ...data};
  }

  @override
  Future<dynamic> post(String path, [Json data = const {}]) async {
    writes.add((path, data));
    return {'id': 'checkin-1', ...data};
  }
}

Session fixtureSession({bool caregiver = false, bool guest = false}) =>
    Session()
      ..initialized = true
      ..token = guest ? null : 'synthetic-test-token'
      ..user = guest
          ? null
          : {
              'id': 'user-1',
              'name': 'Alya Contoh',
              'role': caregiver ? 'CAREGIVER' : 'PATIENT',
            }
      ..profile = {'display_name': 'Alya Contoh', 'timezone': 'Asia/Jakarta'}
      ..consents = {'HEALTH_DATA_PROCESSING', 'AI_CHAT_CONTEXT'};

Future<void> savePreview(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final picture = await boundary.toImage(pixelRatio: 1);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('test-output')..createSync(recursive: true);
    File(
      '${directory.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use the shipped typeface and icons instead of the test-only Ahem font,
    // so layout checks and review images exercise the actual text metrics.
    await (FontLoader(
      'DejaVuSans',
    )..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('onboarding completes and skip both reach role selection', (
    tester,
  ) async {
    final session = fixtureSession(guest: true);
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith((ref) => session),
        apiProvider.overrideWithValue(FixtureApi(session)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HopelyApp()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mulai Sekarang'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.scrollUntilVisible(
        find.text('Lanjutkan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      find.text('Mulai Perjalanan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mulai Perjalanan'));
    await tester.pumpAndSettle();
    expect(find.text('Lanjut sebagai pasien'), findsOneWidget);
    container.read(routerProvider).go('/onboarding');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Lanjut sebagai pendamping'), findsOneWidget);
  });

  testWidgets(
    'caregiver route guard blocks patient tools and accepts dedicated invite route',
    (tester) async {
      final session = fixtureSession(caregiver: true);
      final api = FixtureApi(session);
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => session),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HopelyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/tools');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/caregiver');
      router.go('/caregiver/connect');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'synthetic-invitation');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Hubungkan Sekarang'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hubungkan Sekarang').hitTestable());
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, '/caregivers/accept');
      expect(api.writes.single.$2, {'token': 'synthetic-invitation'});
      expect(router.routeInformationProvider.value.uri.path, '/caregiver');
    },
  );

  testWidgets(
    'checkin keeps 1-5 values and opt-out when saved through V2 flow',
    (tester) async {
      final session = fixtureSession();
      final api = FixtureApi(session);
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => session),
          apiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HopelyApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/checkin');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Simpan Ringkasan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Simpan Ringkasan'));
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, '/checkins/checkin-1');
      expect(api.writes.single.$2['ai_analysis_allowed'], false);
      for (final k in ['mood', 'anxiety', 'energy', 'sleep', 'pain']) {
        expect(api.writes.single.$2['${k}_score'], inInclusiveRange(1, 5));
      }
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/checkin/saved',
      );
    },
  );

  testWidgets(
    'revoking AI consent updates composer without recreating router',
    (tester) async {
      final session = fixtureSession();
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith((ref) => session),
          apiProvider.overrideWithValue(FixtureApi(session)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HopelyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/chat');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, true);
      session.consents.remove('AI_CHAT_CONTEXT');
      session.notifyListeners();
      await tester.pumpAndSettle();
      expect(container.read(routerProvider), same(router));
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    },
  );

  for (final role in ['guest', 'patient', 'caregiver']) {
    testWidgets(
      'V2 $role routes render at phone width and produce review images',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = fixtureSession(
          guest: role == 'guest',
          caregiver: role == 'caregiver',
        );
        final container = ProviderContainer(
          overrides: [
            sessionProvider.overrideWith((ref) => session),
            apiProvider.overrideWithValue(FixtureApi(session)),
          ],
        );
        addTearDown(container.dispose);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: UncontrolledProviderScope(
              container: container,
              child: const HopelyApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final routes = role == 'guest'
            ? ['/welcome', '/onboarding', '/login', '/role', '/register']
            : role == 'patient'
            ? [
                '/home',
                '/checkin',
                '/chat',
                '/insights',
                '/journal',
                '/profile',
                '/tools',
                '/care-circle',
              ]
            : [
                '/caregiver',
                '/caregiver/connect',
                '/caregiver/patient-1',
                '/caregiver/alerts/notice-1',
              ];
        for (final route in routes) {
          container.read(routerProvider).go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          await savePreview(
            tester,
            key,
            '$role-${route.substring(1).replaceAll('/', '-')}',
          );
        }
      },
    );
  }
}
