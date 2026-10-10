import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/widgets/ui.dart';
import 'package:hopely_care/core/theme/theme.dart';
import 'package:hopely_care/core/api/api.dart';

void main() {
  test('check-in serializes stable 1-5 metric keys', () {
    final c = Checkin(
      date: '2026-10-07',
      scores: {'mood': 2, 'anxiety': 4, 'energy': 2, 'sleep': 2, 'pain': 3},
    );
    expect(Checkin.fromJson(c.toJson()).scores['anxiety'], 4);
    expect(c.toJson().containsKey('mood_score'), true);
  });
  testWidgets('mock output is clearly disclosed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hopelyTheme(),
        home: const Scaffold(body: MockNotice({'mode': 'mock'})),
      ),
    );
    expect(find.textContaining('bukan hasil AI nyata'), findsOneWidget);
  });
  testWidgets('score selector supports 1 to 5 and selection', (tester) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: hopelyTheme(),
        home: Scaffold(
          body: MetricSelector(
            label: 'Suasana Hati',
            value: 2,
            onChanged: (v) => selected = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('4'));
    expect(selected, 4);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });
  testWidgets('failed data load displays retry instead of private error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hopelyTheme(),
        home: Scaffold(
          body: DataPage(
            load: () => Future.error(Exception('PRIVATE PAYLOAD')),
            builder: (_, _) => const Text('Loaded'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('PRIVATE PAYLOAD'), findsNothing);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
