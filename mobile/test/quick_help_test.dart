import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/features/caregiver/quick_help_screen.dart';

class HelpApi extends Api {
  HelpApi() : super(Session());
  int eligible = 1, sends = 0;
  bool fail = false;
  List<Json> alerts = [];
  @override
  Future<dynamic> get(String path) async => {
    'alerts': alerts,
    'eligible_count': eligible,
  };
  @override
  Future<dynamic> post(String path, [dynamic data]) async {
    if (fail) throw Exception('offline');
    if (path.endsWith('/cancel')) {
      alerts = [];
      return {};
    }
    sends++;
    alerts = [
      {'id': 'a', 'status': 'ACTIVE', 'recipient_count': 1},
    ];
    return alerts.first;
  }
}

void main() {
  Future<void> mount(WidgetTester tester, HelpApi api) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(api)],
        child: const MaterialApp(home: QuickHelpScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('confirmation precedes send, success and cancellation', (
    tester,
  ) async {
    final api = HelpApi();
    await mount(tester, api);
    await tester.tap(find.text('Kirim Bantuan Sekarang'));
    await tester.pumpAndSettle();
    expect(api.sends, 0);
    await tester.tap(find.text('Kirim Alert'));
    await tester.pumpAndSettle();
    expect(find.text('Permintaan bantuan tercatat'), findsOneWidget);
    expect(find.text('Pendampingmu sudah diberi tahu.'), findsNothing);
    await tester.tap(find.text('Batalkan Alert'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan Alert').last);
    await tester.pumpAndSettle();
    expect(find.text('Kirim Bantuan Sekarang'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('failed request never claims success', (tester) async {
    final api = HelpApi()..fail = true;
    await mount(tester, api);
    await tester.tap(find.text('Kirim Bantuan Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim Alert'));
    await tester.pumpAndSettle();
    expect(find.text('Alert belum berhasil dikirim.'), findsOneWidget);
    expect(find.text('Bantuan sudah dikirim'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('no caregiver has no send action and fits narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, HelpApi()..eligible = 0);
    expect(find.text('Tambah Pendamping'), findsOneWidget);
    expect(find.text('Kirim Bantuan Sekarang'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
