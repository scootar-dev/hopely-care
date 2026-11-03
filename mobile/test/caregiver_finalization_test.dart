import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';

void main() {
  test('account update notifies immediately and rejects another account', () {
    final session = Session()..user = {'id': 'one', 'name': 'Lama'};
    var updates = 0;
    session.addListener(() => updates++);
    session.updateAccount({'id': 'one', 'name': 'Baru'});
    expect(session.user!['name'], 'Baru');
    expect(updates, 1);
    session.updateAccount({'id': 'two', 'name': 'Akun lain'});
    expect(session.user!['name'], 'Baru');
    expect(updates, 1);
    session.dispose();
  });
}
