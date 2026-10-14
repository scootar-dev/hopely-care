import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';
import 'package:hopely_care/main.dart';
import 'package:hopely_care/features/auth/password_screen.dart';

import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

class RecoveryApi extends FixtureApi {
  RecoveryApi(super.session);
  bool fails = true;
  @override
  Future<dynamic> post(String path, [Json data = const {}]) async {
    writes.add((path, data));
    if (fails) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 503,
        ),
      );
    }
    return {'message': 'Generic recovery response'};
  }
}

void main() {
  testWidgets('guest forms support narrow screens and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final session = fixtureSession(guest: true);
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith((ref) => session),
        apiProvider.overrideWithValue(RecoveryApi(session)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HopelyApp()),
    );
    await tester.pumpAndSettle();
    for (final route in [
      '/welcome',
      '/onboarding',
      '/role',
      '/login',
      '/register',
      '/forgot-password',
    ]) {
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$route scrolled');
    }
  });

  testWidgets(
    'password recovery validates input and never calls failure success',
    (tester) async {
      final session = fixtureSession(guest: true);
      final api = RecoveryApi(session);
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
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordScreen), findsOneWidget);
      expect(container.read(routerProvider).canPop(), isTrue);
      Future<void> send() async {
        await tester.ensureVisible(find.text('Kirim Tautan'));
        await tester.tap(find.text('Kirim Tautan'));
        await tester.pumpAndSettle();
      }

      await send();
      expect(api.writes, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        'own-account@test.invalid',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await send();
      expect(
        find.textContaining('Email pemulihan belum dapat dikirim'),
        findsOneWidget,
      );
      expect(find.text('Periksa kotak masuk dan spam'), findsNothing);
      api.fails = false;
      await send();
      expect(find.text('Periksa kotak masuk dan spam'), findsOneWidget);
      expect(api.writes.last.$1, '/auth/forgot-password');
      expect(api.writes.last.$2, {'email': 'own-account@test.invalid'});
      expect(tester.takeException(), isNull);
    },
  );
}
