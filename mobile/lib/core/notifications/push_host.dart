import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api.dart';
import '../routing/router.dart';
import 'push_service.dart';

class PushHost extends ConsumerStatefulWidget {
  const PushHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<PushHost> createState() => _PushHostState();
}

class _PushHostState extends ConsumerState<PushHost>
    with WidgetsBindingObserver {
  StreamSubscription<String>? subscription;
  StreamSubscription<String>? foregroundSubscription;
  late Session session;
  String? identity, pending;
  bool opening = false;
  @override
  void initState() {
    super.initState();
    session = ref.read(sessionProvider);
    identity = session.token;
    session.addListener(changed);
    WidgetsBinding.instance.addObserver(this);
    subscription = PushService.opens.stream.listen((id) {
      pending = id;
      drain();
    });
    foregroundSubscription = PushService.foreground.stream.listen((id) async {
      final token = session.token;
      if (!session.loggedIn) return;
      try {
        await ref
            .read(apiProvider)
            .get('/notifications/${Uri.encodeComponent(id)}');
        if (!mounted || token != session.token) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: const Text('Ada pemberitahuan baru dari Hopely Care.'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () {
                pending = id;
                drain();
              },
            ),
          ),
        );
      } catch (_) {
        /* Ignore messages unavailable to the current account. */
      }
    });
    unawaited(PushService.initialize().catchError((Object _) {}));
    changed();
  }

  void changed() {
    if (identity != session.token) {
      // A notification from an earlier account must not survive an account switch.
      if (identity != null || session.initialized) pending = null;
      PushService.detach();
      identity = session.token;
    }
    if (session.initialized && session.loggedIn) {
      unawaited(
        PushService.sync(ref.read(apiProvider)).catchError((Object _) {}),
      );
      drain();
    } else if (session.initialized) {
      pending = null;
    }
  }

  void drain() {
    if (opening || pending == null || !session.initialized || !session.loggedIn) {
      return;
    }
    opening = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final id = pending;
      pending = null;
      try {
        if (id != null) {
          final destination = await openNotification(ref.read(apiProvider), id);
          if (mounted) ref.read(routerProvider).go(destination);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text(
                'Notifikasi tidak tersedia atau akses sudah berubah. Buka daftar notifikasi untuk mencoba lagi.',
              ),
            ),
          );
        }
      } finally {
        opening = false;
        if (mounted) drain();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) changed();
  }

  @override
  void dispose() {
    subscription?.cancel();
    foregroundSubscription?.cancel();
    session.removeListener(changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
