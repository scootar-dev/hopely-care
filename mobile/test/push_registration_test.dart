import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/notifications/push_service.dart';
import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

class TokenApi extends FixtureApi {
  TokenApi(super.session);
  int calls = 0, failures = 0;
  final deleted = <String>[];
  Completer<dynamic>? pending;
  @override
  Future<dynamic> post(String path, [Json data = const {}]) async {
    calls++;
    if (calls <= failures) throw DioException(requestOptions: RequestOptions(path: path), type: DioExceptionType.connectionError);
    return pending?.future ?? {'id': 'device-$calls'};
  }
  @override
  Future<dynamic> delete(String path, [Json data = const {}]) async { deleted.add(path); return {}; }
}
void main() {
  setUp(() { FlutterSecureStorage.setMockInitialValues({}); PushService.detach(); PushService.resetTestQueue(); });
  testWidgets('temporary registration failure retries on fake clock', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true))..failures = 1;
    final work = PushService.register(api, 'token');
    await t.pump(); expect(api.calls, 1);
    await t.pump(const Duration(seconds: 1)); await work;
    expect(api.calls, 2);
  });
  testWidgets('registration stops after four attempts', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true))..failures = 9;
    final delay = PushService.retryDelay;
    PushService.retryDelay = (_) async {};
    addTearDown(() => PushService.retryDelay = delay);
    Object? failure;
    await t.runAsync(() async {
      try { await PushService.register(api, 'token'); } catch (e) { failure = e; }
    });
    expect(api.calls, 4); expect(failure, isA<DioException>());
  });
  testWidgets('SDK token stream rotates registered device', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true));
    await PushService.sync(api);
    final stream = StreamController<String>(sync: true);
    final sub = PushService.listenTokenRefresh(stream.stream);
    stream.add('first'); await t.pump();
    stream.add('second'); await t.pump();
    expect(api.calls, 2);
    unawaited(sub.cancel()); unawaited(stream.close());
  });
  testWidgets('logout cleans a registration that completes late', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true))..pending = Completer<dynamic>();
    final work = PushService.register(api, 'token'); await t.pump();
    final logout = PushService.unregister(api);
    api.pending!.complete({'id':'late'}); await t.pump(); await work; await logout;
    expect(api.deleted, contains('/devices/late')); expect(api.session.deviceId, isNull);
  });
  testWidgets('account change rejects pending registration result', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true))..pending = Completer<dynamic>();
    final work = PushService.register(api, 'token'); await t.pump();
    api.session.token = 'new-account'; PushService.detach();
    api.pending!.complete({'id':'old'}); await t.pump(); await work;
    expect(api.session.deviceId, isNull);
  });
  testWidgets('duplicate token registered once', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true));
    await PushService.register(api, 'token'); await PushService.register(api, 'token'); expect(api.calls, 1);
  });
  testWidgets('session cancellation stops scheduled retry', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true))..failures = 9;
    final work = PushService.register(api, 'token'); await t.pump();
    PushService.detach(); await t.pump(const Duration(seconds: 8)); await work;
    expect(api.calls, 1);
  });
  testWidgets('late old response cannot overwrite newer device', (t) async {
    final api = TokenApi(fixtureSession(caregiver: true))..pending = Completer<dynamic>();
    final old = PushService.register(api, 'old'); await t.pump();
    PushService.detach(); final next = PushService.register(api, 'new');
    api.pending!.complete({'id':'old'}); api.pending = null;
    await t.pump(); await old; await next;
    expect(api.session.deviceId, 'device-2');
  });
}
