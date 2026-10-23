import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../routing/router.dart';
import 'feature_rail.dart';

class AiLauncher extends ConsumerWidget {
  const AiLauncher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final router = ref.watch(routerProvider);
    return ListenableBuilder(
      listenable: router.routeInformationProvider,
      builder: (context, _) {
        final path = router.routeInformationProvider.value.uri.path;
        final visible =
            session.loggedIn &&
            !session.caregiver &&
            !session.needsConsent &&
            !path.startsWith('/chat') &&
            path != '/quick-help' &&
            path != '/splash' &&
            MediaQuery.viewInsetsOf(context).bottom == 0;
        final hasTabs = const [
          '/home',
          '/treatment',
          '/community',
          '/insights',
          '/profile',
        ].contains(path);
        return Stack(
          children: [
            if (session.loggedIn &&
                !session.caregiver &&
                !session.needsConsent &&
                MediaQuery.sizeOf(context).width >= 1024)
              FeatureRail(child: child)
            else
              child,
            if (visible)
              Positioned(
                right: 16,
                bottom:
                    MediaQuery.paddingOf(context).bottom + (hasTabs ? 80 : 96),
                child: FloatingActionButton.small(
                  heroTag: 'hopely-ai-launcher',
                  tooltip: 'Buka Hopely AI',
                  onPressed: () => router.push('/chat'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
              ),
          ],
        );
      },
    );
  }
}
