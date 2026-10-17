import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';
import 'package:hopely_care/core/theme/theme.dart';
import 'package:hopely_care/features/auth/auth_screen.dart';
import 'package:hopely_care/features/community/presentation/community_widgets.dart';
import 'package:hopely_care/features/doctor_summary/summary_report.dart';
import 'package:hopely_care/main.dart';
import 'community_test.dart' show CommunityFixtureApi;
import 'stitch_v2_test.dart' show fixtureSession, savePreview;

class RevisionApi extends CommunityFixtureApi {
  RevisionApi(super.session) {
    joined = true;
  }
  @override
  Json get homeData => {
    ...super.homeData,
    'stats': {'shared_posts': 12, 'support_received': 27},
  };
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/treatments')) return page([]);
    if (path.endsWith('/image')) {
      reads.add(path);
      return {
        'base64':
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      };
    }
    return super.get(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });

  Future<(ProviderContainer, RevisionApi)> open(
    WidgetTester tester,
    String path, {
    bool photo = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = fixtureSession();
    final api = RevisionApi(session);
    api.story['has_image'] = photo;
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith((ref) => session),
        apiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HopelyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
    return (container, api);
  }

  testWidgets(
    'community is a bottom tab and AI popup closes back to the page',
    (tester) async {
      final (container, _) = await open(tester, '/home');
      await tester.tap(find.text('Komunitas').last);
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/community',
      );
      expect(find.text('Perjalanan'), findsOneWidget);
      await tester.tap(find.byTooltip('Buka Hopely AI'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Hadir mendengarkan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Tutup Hopely AI'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/community',
      );
    },
  );

  testWidgets(
    'feed support toggles and comment button opens working composer',
    (tester) async {
      final (_, api) = await open(tester, '/community/feed');
      await tester.ensureVisible(find.text('Dukung'));
      await tester.tap(find.text('Dukung'));
      await tester.pumpAndSettle();
      expect(api.story['my_reaction'], 'support');
      await tester.tap(find.text('Dukung'));
      await tester.pumpAndSettle();
      expect(api.story['my_reaction'], isNull);
      await tester.tap(find.text('Komentar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('community-comment-content')),
        'Semangat, kami menemanimu.',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(api.comments.single['content'], 'Semangat, kami menemanimu.');
      expect(api.writes.last.$2['sharing_acknowledged'], true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('community feed loads the private photo before opening detail', (
    tester,
  ) async {
    final (_, api) = await open(tester, '/community/feed', photo: true);
    await tester.ensureVisible(find.byType(CommunityImage));
    await tester.pumpAndSettle();
    expect(api.reads, contains('/community/posts/p1/image'));
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets(
    'sharing history uses server counts rather than membership count',
    (tester) async {
      await open(tester, '/community');
      await tester.tap(find.text('Komunitasku'));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
      expect(find.text('38'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('forgot password sits below the password input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: hopelyTheme(), home: const AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(
      tester.getTopLeft(find.text('Lupa kata sandi?')).dy,
      greaterThan(tester.getBottomLeft(fields.last).dy),
    );
  });

  testWidgets('summary renders readable sections on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = <String, dynamic>{
      'period': '2026-10-10 - 2026-10-17',
      'recorded_days': 7,
      'wellbeing': {
        'mood': {'mean': 3.42857, 'direction': 'stable'},
      },
      'reported_concerns': ['Ingin mendiskusikan kualitas tidur.'],
    };
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: hopelyTheme(),
          home: Scaffold(
            body: SingleChildScrollView(child: SummaryReport(report)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kesejahteraan harian'), findsOneWidget);
    expect(find.textContaining('Suasana hati: 3.4 / 5'), findsOneWidget);
    expect(find.textContaining('insufficient_data'), findsNothing);
    expect(tester.takeException(), isNull);
    await savePreview(tester, key, 'revision-summary');
  });
}
