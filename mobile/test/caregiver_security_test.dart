import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/features/caregiver/caregiver_screen.dart';
import 'package:hopely_care/features/caregiver/quick_help_screen.dart';
import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

Json summary(String id) => {
  'patient_id': id,
  'permissions': {'can_view_activity_status': true},
  'activity_status': {'completed_count': id == 'a' ? 111 : 222},
};

class SecurityApi extends FixtureApi {
  SecurityApi(super.session);
  bool denied = false,
      failPatients = false,
      failNotifications = false,
      failAlerts = false;
  bool active = true;
  String status = 'ACTIVE';
  Completer<dynamic>? pendingSummary, pendingCoach, pendingAction;
  @override
  Future<dynamic> get(String path) async {
    if (path.endsWith('/summary')) {
      if (denied) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 403,
          ),
        );
      }
      if (path.contains('/a/')) return pendingSummary?.future ?? summary('a');
      return summary('b');
    }
    if (path == '/caregiver/patients' && failPatients) {
      throw Exception('patients unavailable');
    }
    if (path == '/notifications' && failNotifications) {
      throw Exception('notifications unavailable');
    }
    if (path == '/caregiver/support-alerts') {
      if (failAlerts) throw Exception('alerts unavailable');
      return {
        'alerts': [
          if (active)
            {
              'id': 'sos',
              'patient_name': 'Pasien Sintetis',
              'status': status,
              'acknowledged_name': 'Kerabat Sintetis',
            },
        ],
      };
    }
    return super.get(path);
  }

  @override
  Future<dynamic> post(String path, [Json? data]) async {
    if (path.endsWith('/coach')) {
      return pendingCoach?.future ??
          {
            'support_message': 'Konteks privat sintetis',
            'communication_tip': 'Dengarkan',
            'suggested_action': 'Tanyakan izin',
          };
    }
    if (path.startsWith('/support-alerts/')) {
      if (pendingAction != null) await pendingAction!.future;
      if (path.endsWith('/acknowledge')) status = 'ACKNOWLEDGED';
      if (path.endsWith('/resolve')) active = false;
      return {'status': status};
    }
    return super.post(path, data ?? {});
  }
}

void main() {
  FlutterSecureStorage.setMockInitialValues({});
  Future<void> mount(WidgetTester tester, SecurityApi api, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => api.session),
          apiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ask(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Bagaimana mendampingi?');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Minta saran komunikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minta saran komunikasi'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'revocation clears summary and coach on refresh without cached fallback',
    (tester) async {
      final api = SecurityApi(fixtureSession(caregiver: true));
      await mount(tester, api, const CaregiverPatientScreen(patientId: 'a'));
      expect(find.text('Aktivitas selesai: 111'), findsOneWidget);
      await ask(tester);
      expect(find.text('Konteks privat sintetis'), findsOneWidget);
      api.denied = true;
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(find.text('Aktivitas selesai: 111'), findsNothing);
      expect(find.text('Konteks privat sintetis'), findsNothing);
      expect(find.text('Coba lagi'), findsOneWidget);
    },
  );
  testWidgets('late patient A response cannot overwrite patient B', (
    tester,
  ) async {
    final api = SecurityApi(fixtureSession(caregiver: true))
      ..pendingSummary = Completer<dynamic>();
    // Pump manually while summary remains pending.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => api.session),
          apiProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(home: CaregiverPatientScreen(patientId: 'a')),
      ),
    );
    await tester.pump();
    await mount(tester, api, const CaregiverPatientScreen(patientId: 'b'));
    api.pendingSummary!.complete(summary('a'));
    await tester.pumpAndSettle();
    expect(find.text('Aktivitas selesai: 222'), findsOneWidget);
    expect(find.text('Aktivitas selesai: 111'), findsNothing);
  });
  testWidgets('resume revalidates and logout invalidates pending coach', (
    tester,
  ) async {
    final api = SecurityApi(fixtureSession(caregiver: true));
    await mount(tester, api, const CaregiverPatientScreen(patientId: 'a'));
    api.pendingCoach = Completer<dynamic>();
    await ask(tester);
    api.session.token = null;
    api.session.user = null;
    api.session.notifyListeners();
    api.pendingCoach!.complete({
      'support_message': 'LATE PRIVATE',
      'communication_tip': '',
      'suggested_action': '',
    });
    await tester.pump();
    expect(find.text('LATE PRIVATE'), findsNothing);
    expect(find.text('Aktivitas selesai: 111'), findsNothing);
    api.denied = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Aktivitas selesai: 111'), findsNothing);
  });
  testWidgets(
    'background clears data immediately and resume checks revoked permission',
    (tester) async {
      final api = SecurityApi(fixtureSession(caregiver: true));
      await mount(tester, api, const CaregiverPatientScreen(patientId: 'a'));
      await ask(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Konteks privat sintetis'), findsNothing);
      api.denied = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Aktivitas selesai: 111'), findsNothing);
      expect(find.text('Coba lagi'), findsOneWidget);
    },
  );
  testWidgets('periodic access validation clears revoked data while open', (
    tester,
  ) async {
    final api = SecurityApi(fixtureSession(caregiver: true));
    await mount(tester, api, const CaregiverPatientScreen(patientId: 'a'));
    api.denied = true;
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    expect(find.text('Aktivitas selesai: 111'), findsNothing);
  });
  testWidgets('late coach result is rejected after permission changes', (
    tester,
  ) async {
    final api = SecurityApi(fixtureSession(caregiver: true))
      ..pendingCoach = Completer<dynamic>();
    await mount(tester, api, const CaregiverPatientScreen(patientId: 'a'));
    await ask(tester);
    api.denied = true;
    api.pendingCoach!.complete({
      'support_message': 'LATE PRIVATE',
      'communication_tip': '',
      'suggested_action': '',
    });
    await tester.pumpAndSettle();
    expect(find.text('LATE PRIVATE'), findsNothing);
    expect(find.text('Aktivitas selesai: 111'), findsNothing);
  });
  for (final failed in ['patients', 'notifications']) {
    testWidgets('SOS survives $failed dashboard failure', (tester) async {
      final api = SecurityApi(fixtureSession(caregiver: true))
        ..failPatients = failed == 'patients'
        ..failNotifications = failed == 'notifications';
      await mount(tester, api, const CaregiverScreen());
      expect(
        find.text('Pasien Sintetis meminta bantuan sekarang.'),
        findsOneWidget,
      );
      expect(find.text('Saya Tanggapi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('SOS error retry empty and confirmed actions remain distinct', (
    tester,
  ) async {
    final api = SecurityApi(fixtureSession(caregiver: true))..failAlerts = true;
    await mount(
      tester,
      api,
      const Scaffold(
        body: SingleChildScrollView(child: QuickHelpPanel(caregiver: true)),
      ),
    );
    expect(
      find.text('Tidak ada permintaan Bantuan Cepat aktif.'),
      findsNothing,
    );
    api.failAlerts = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    api.pendingAction = Completer<dynamic>();
    await tester.tap(find.text('Saya Tanggapi'));
    await tester.pump();
    expect(find.text('Sedang ditangani oleh Kerabat Sintetis'), findsNothing);
    api.pendingAction!.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Sedang ditangani oleh Kerabat Sintetis'), findsOneWidget);
    api.pendingAction = null;
    await tester.ensureVisible(find.text('Tandai Selesai'));
    await tester.tap(find.text('Tandai Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Selesaikan permintaan bantuan?'), findsOneWidget);
    await tester.tap(find.text('Selesaikan'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tidak ada permintaan Bantuan Cepat aktif.'),
      findsOneWidget,
    );
  });
}
