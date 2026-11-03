import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/notifications/push_service.dart';
import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

class PushApi extends FixtureApi {
  PushApi(super.session);
  bool failRead = false, switchAccount = false;
  int reads = 0;
  @override
  Future<dynamic> get(String path) async {
    if (switchAccount) session.token = 'another-account';
    return {'id': 'notice-1', 'notification_type': 'emergency_support', 'read_at': null};
  }
  @override
  Future<dynamic> put(String path, Json data) async {
    reads++;
    if (failRead) throw Exception('offline');
    return {};
  }
}

void main() {
  test('foreground and tap deduplicate separately and reject invalid payload', () async {
    PushService.detach();
    final before = PushService.changes.value;
    final opened = <String>[];
    final subscription = PushService.opens.stream.listen(opened.add);
    PushService.receive({}, opened: true);
    PushService.receive({'notification_id': '../secret'}, opened: true);
    for (var i = 0; i < 2; i++) {
      PushService.receive({'notification_id': 'notice-1'}, opened: false);
      PushService.receive({'notification_id': 'notice-1'}, opened: true);
    }
    await Future<void>.delayed(Duration.zero);
    expect(PushService.changes.value - before, 2);
    expect(opened, ['notice-1']);
    await subscription.cancel();
  });
  test('verified SOS opens correct notification and marks read', () async {
    final api = PushApi(fixtureSession(caregiver: true));
    expect(await openNotification(api, 'notice-1'), '/caregiver/sos/notice-1');
    expect(api.reads, 1);
  });
  test('read failure does not block SOS', () async {
    final api = PushApi(fixtureSession(caregiver: true))..failRead = true;
    expect(await openNotification(api, 'notice-1'), '/caregiver/sos/notice-1');
  });
  test('account switch prevents read and navigation', () async {
    final api = PushApi(fixtureSession(caregiver: true))..switchAccount = true;
    await expectLater(openNotification(api, 'notice-1'), throwsStateError);
    expect(api.reads, 0);
  });
  test('logged out notification cannot fetch private data', () async {
    final api = PushApi(fixtureSession(guest: true));
    await expectLater(openNotification(api, 'notice-1'), throwsStateError);
  });
}
