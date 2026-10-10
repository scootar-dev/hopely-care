import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';
import 'package:hopely_care/core/routing/router.dart';
import 'package:hopely_care/features/settings/profile_photo.dart';
import 'package:hopely_care/main.dart';
import 'package:image_picker/image_picker.dart';

import 'stitch_v2_test.dart' show FixtureApi, fixtureSession;

final photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGPUCj/GwMDAxMDAwMDAAAAO4gFLKvoKdQAAAABJRU5ErkJggg==',
);

class PhotoApi extends FixtureApi {
  PhotoApi(super.session);
  final photos = <String, Uint8List>{};
  int uploads = 0;

  @override
  Future<dynamic> get(String path) async {
    if (path == '/me/avatar') {
      final bytes = photos[session.user!['id']];
      return bytes == null ? null : {'base64': base64Encode(bytes), 'mime_type': 'image/png'};
    }
    return super.get(path);
  }

  @override
  Future<void> uploadProfilePhoto(List<int> bytes) async {
    uploads++;
    photos[session.user!['id']] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(String path, [Json data = const {}]) async {
    expect(path, '/me/avatar');
    photos.remove(session.user!['id']);
  }
}

class FixturePhotoPicker extends ImagePicker {
  XFile? selection = XFile.fromData(photoBytes, name: 'profile.png', mimeType: 'image/png');

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => selection;
}

Future<(ProviderContainer, PhotoApi, FixturePhotoPicker)> openProfile(WidgetTester tester) async {
  final session = fixtureSession();
  final api = PhotoApi(session);
  final picker = FixturePhotoPicker();
  final container = ProviderContainer(overrides: [
    sessionProvider.overrideWith((ref) => session),
    apiProvider.overrideWithValue(api),
    photoPickerProvider.overrideWithValue(picker),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HopelyApp()));
  await tester.pumpAndSettle();
  container.read(routerProvider).go('/profile');
  await tester.pumpAndSettle();
  return (container, api, picker);
}

void main() {
  testWidgets('photo is confirmed, uploaded, replaced, reloaded and removed', (tester) async {
    final (container, api, _) = await openProfile(tester);
    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.tap(find.text('Pilih foto'));
      await tester.pumpAndSettle();
      expect(find.text('Gunakan foto ini?'), findsOneWidget);
      expect(api.uploads, attempt - 1);
      await tester.tap(find.text('Simpan foto'));
      await tester.pumpAndSettle();
      expect(api.uploads, attempt);
      expect(find.text('Foto profil berhasil diperbarui.'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2)); // Header and profile.
    }
    container.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    await tester.tap(find.text('Hapus foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus foto'));
    await tester.pumpAndSettle();
    expect(api.photos, isEmpty);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled selection or preview never uploads a photo', (tester) async {
    final (_, api, picker) = await openProfile(tester);
    await tester.tap(find.text('Pilih foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    picker.selection = null;
    await tester.tap(find.text('Pilih foto'));
    await tester.pumpAndSettle();
    expect(api.uploads, 0);
    expect(api.photos, isEmpty);
  });

  testWidgets('changing account does not display the previous profile photo', (tester) async {
    final (container, api, _) = await openProfile(tester);
    api.photos['user-1'] = photoBytes;
    container.invalidate(profilePhotoProvider('user-1'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    final session = container.read(sessionProvider);
    session.user = {...session.user!, 'id': 'user-2'};
    session.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
  });
}
