import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/notifications/treatment_reminders.dart';
import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

class ScheduleApi extends FixtureApi {
  ScheduleApi(super.session);
  List<Json> records = [];
  Completer<void>? pending;
  @override
  Future<dynamic> get(String path) async {
    if (pending != null) await pending!.future;
    return page(records);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var exact = true;
  setUp(() {
    calls.clear();
    exact = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize' ||
              call.method == 'requestNotificationsPermission') {
            return true;
          }
          if (call.method == 'canScheduleExactNotifications') return exact;
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'schedules UTC time and reconciles completed or cancelled appointments',
    () async {
      final api = ScheduleApi(fixtureSession());
      final at = DateTime.now().toUtc().add(const Duration(hours: 2));
      api.records = [
        {
          'id': 'future',
          'status': 'scheduled',
          'scheduled_at': at.toIso8601String(),
        },
        {
          'id': 'cancelled',
          'status': 'cancelled',
          'scheduled_at': at.toIso8601String(),
        },
        {
          'id': 'done',
          'status': 'completed',
          'scheduled_at': at.toIso8601String(),
        },
        {
          'id': 'past',
          'status': 'scheduled',
          'scheduled_at': at
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
      ];
      final reminders = TreatmentReminders();
      await reminders.refresh(api);
      final schedule =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(schedule['payload'], '/treatment/future');
      expect(schedule['timeZoneName'], 'UTC');
      expect(
        DateTime.parse(
          '${schedule['scheduledDateTime']}Z',
        ).difference(at).inSeconds.abs(),
        lessThan(2),
      );
      calls.clear();
      api.records.first['status'] = 'cancelled';
      await reminders.refresh(api);
      expect(calls.where((c) => c.method == 'cancelAll'), hasLength(1));
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    },
  );

  test('logout during fetch cannot recreate private reminders', () async {
    final session = fixtureSession();
    final api = ScheduleApi(session)..pending = Completer<void>();
    api.records = [
      {
        'id': 'future',
        'status': 'scheduled',
        'scheduled_at': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      },
    ];
    final reminders = TreatmentReminders();
    final refresh = reminders.refresh(api);
    session.user = null;
    await reminders.clear();
    api.pending!.complete();
    await refresh;
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test('denied exact alarm access still permits an inexact reminder', () async {
    exact = false;
    final api = ScheduleApi(fixtureSession());
    api.records = [
      {
        'id': 'future',
        'status': 'scheduled',
        'scheduled_at': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      },
    ];
    await TreatmentReminders().refresh(api);
    final schedule =
        calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
    expect(
      (schedule['platformSpecifics'] as Map)['scheduleMode'],
      'inexactAllowWhileIdle',
    );
  });
}
