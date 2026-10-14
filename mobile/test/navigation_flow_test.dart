import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';
import 'package:hopely_care/features/home/home_screen.dart';
import 'package:hopely_care/main.dart';

import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

class RecommendedActivityApi extends FixtureApi {
  RecommendedActivityApi(super.session);
  @override
  Future<dynamic> get(String path) async {
    if (path == '/activities/recommended') {
      return [
        {
          'id': 'recommendation-42',
          'reason': 'Pilihan pengujian',
          'activity': {
            'title': 'Jeda nyaman',
            'duration_minutes': 3,
            'steps': ['Duduk dengan nyaman.'],
          },
        },
      ];
    }
    return super.get(path);
  }
}

Future<ProviderContainer> openApp(
  WidgetTester tester, {
  bool caregiver = false,
  bool recommendedActivity = false,
}) async {
  final session = fixtureSession(caregiver: caregiver);
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith((ref) => session),
      apiProvider.overrideWithValue(
        recommendedActivity
            ? RecommendedActivityApi(session)
            : FixtureApi(session),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HopelyApp()),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return container;
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'After tapping $label');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'home opens the recommended activity and preserves its completion API',
    (tester) async {
      final container = await openApp(tester, recommendedActivity: true);
      await tapLabel(tester, 'Mulai aktivitas');
      final api = container.read(apiProvider) as FixtureApi;
      expect(api.writes, isEmpty);
      expect(find.text('Duduk dengan nyaman.'), findsOneWidget);
      await tapLabel(tester, 'Tandai selesai');
      expect(api.writes.single.$1, '/activities/recommendation-42/complete');
      expect(find.text('Sudah dicatat selesai'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Opening an activity must not record completion before the user finishes it.
      expect(find.byType(HomeRecommendation), findsNothing);
    },
  );

  for (final origin in ['home', 'profile']) {
    testWidgets('invite from $origin creates a private invitation code', (
      tester,
    ) async {
      final container = await openApp(tester);
      if (origin == 'profile') {
        container.read(routerProvider).go('/profile');
        await tester.pumpAndSettle();
      }
      await tapLabel(
        tester,
        origin == 'home'
            ? 'Undang kerabat tepercaya'
            : 'Undang & kelola kerabat',
      );
      expect(find.text('Undang Kerabat'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'relative@test.invalid',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Keluarga');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Buat undangan');
      await tester.scrollUntilVisible(
        find.text('Kode Undangan Pribadi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('synthetic-invitation'), findsOneWidget);
      final api = container.read(apiProvider) as FixtureApi;
      expect(api.writes.single.$1, '/caregivers/invite');
      expect(api.writes.single.$2['email'], 'relative@test.invalid');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home to Tools to treatment does not duplicate a navigator', (
    tester,
  ) async {
    final container = await openApp(tester);
    await tapLabel(tester, 'Jelajahi Tools Kesehatan');
    await tapLabel(tester, 'Jadwal Perawatan');
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/treatment',
    );
    expect(find.byType(AppShell, skipOffstage: false), findsOneWidget);
    expect(container.read(routerProvider).canPop(), false);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved check-in opens Insight with one application shell', (
    tester,
  ) async {
    final container = await openApp(tester);
    await tapLabel(tester, 'Perbarui Check-In');
    await tapLabel(tester, 'Simpan Ringkasan');
    await tapLabel(tester, 'Lihat pola catatanku');
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/insights',
    );
    expect(find.byType(AppShell, skipOffstage: false), findsOneWidget);
    expect(container.read(routerProvider).canPop(), false);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets('journal editor privacy round trip preserves navigation', (
    tester,
  ) async {
    final container = await openApp(tester);
    await tapLabel(tester, 'Tulis jurnal pribadi');
    await tester.tap(find.text('Tulis Jurnal Baru'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Aktifkan izin analisis di Privasi');
    await tapLabel(tester, 'Lanjutkan');
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('caregiver profile can open privacy and return to dashboard', (
    tester,
  ) async {
    final container = await openApp(tester, caregiver: true);
    final router = container.read(routerProvider);
    unawaited(router.push<void>('/profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapLabel(tester, 'Privasi & persetujuan');
    await tapLabel(tester, 'Lanjutkan');
    expect(router.routeInformationProvider.value.uri.path, '/caregiver');
    expect(find.text('Dashboard Kerabat'), findsOneWidget);
  });
}
