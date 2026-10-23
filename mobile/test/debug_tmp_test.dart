import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';
import 'package:hopely_care/features/settings/profile_photo.dart';
import 'package:hopely_care/main.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_photo_test.dart' show PhotoApi, FixturePhotoPicker, photoBytes;
import 'stitch_v2_test.dart' show fixtureSession;

void main() {
  testWidgets('debug image remains', (tester) async {
    final session = fixtureSession();
    final api = PhotoApi(session);
    final picker = FixturePhotoPicker();
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith((ref) => session),
        apiProvider.overrideWithValue(api),
        photoPickerProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HopelyApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan foto'));
    await tester.pumpAndSettle();
    print('After upload: ${find.byType(Image).evaluate().length} images');
    await tester.tap(find.text('Hapus foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus foto'));
    await tester.pumpAndSettle();
    final images = find.byType(Image).evaluate();
    print('After delete: ${images.length} images');
    for (final e in images) {
      final img = e.widget as Image;
      print('  image: ${img.image}');
    }
    debugDumpApp();
  });
}
