import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api.dart';
import 'core/routing/router.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: const HopelyApp()),
  );
  await container.read(sessionProvider).restore();
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
