import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/theme/theme.dart';
import 'package:hopely_care/core/widgets/ui.dart';
import 'package:hopely_care/features/checkin/checkin_screen.dart';

import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

class RetryCheckinApi extends FixtureApi {
  RetryCheckinApi(super.session);
  bool fails = true;
  @override
  Future<dynamic> get(String path) async {
    if (path == '/checkins' && fails) {
      throw Exception('Synthetic unavailable response');
    }
    return super.get(path);
  }
}

void main() {
  testWidgets(
    'failed initial checkin load cannot overwrite an existing record',
    (tester) async {
      final session = fixtureSession();
      final api = RetryCheckinApi(session);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith((ref) => session),
            apiProvider.overrideWithValue(api),
          ],
          child: MaterialApp(theme: hopelyTheme(), home: const CheckinScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MetricSelector), findsNothing);
      expect(find.text('Simpan Ringkasan'), findsNothing);
      expect(api.writes, isEmpty);
      api.fails = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.byType(MetricSelector), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('score targets wrap at narrow widths with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: hopelyTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ListView(
              children: [
                MetricSelector(
                  label: 'Tingkat Kecemasan',
                  value: 3,
                  onChanged: (value) => selected = value,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    expect(selected, 5);
    expect(tester.takeException(), isNull);
  });
}
