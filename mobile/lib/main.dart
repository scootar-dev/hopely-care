import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api.dart';
import 'core/routing/router.dart';
import 'core/theme/theme.dart';
import 'features/settings/profile_photo.dart';
import 'features/community/data/community_photo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const HopelyApp()),
  );
  await container.read(sessionProvider).restore();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Android may recreate the activity while the system photo picker is open.
    // Recover a selection for preview only; never upload it without confirmation.
    try {
      final lost = await container.read(photoPickerProvider).retrieveLostData();
      final session = container.read(sessionProvider);
      final intent = await session.storage.read(key: communityPhotoIntentKey);
      await session.storage.delete(key: communityPhotoIntentKey);
      if (container.read(sessionProvider).loggedIn &&
          lost.files?.isNotEmpty == true) {
        if (intent != null) {
          final target = jsonDecode(intent) as Map;
          if (target['user_id'] == session.user?['id']) {
            container
                .read(recoveredCommunityPhotoProvider.notifier)
                .state = RecoveredCommunityPhoto(
              target['user_id'],
              target['community_id'],
              lost.files!.first,
            );
            container
                .read(routerProvider)
                .go(
                  '/community/compose?community=${Uri.encodeQueryComponent(target['community_id'])}',
                );
          }
        } else {
          container.read(recoveredPhotoProvider.notifier).state =
              lost.files!.first;
          container.read(routerProvider).go('/profile');
        }
      }
    } catch (_) {
      // A failed recovery does not prevent sign-in or a fresh photo selection.
    }
  }
}

class HopelyApp extends ConsumerWidget {
  const HopelyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Hopely Care',
    debugShowCheckedModeBanner: false,
    theme: hopelyTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}
