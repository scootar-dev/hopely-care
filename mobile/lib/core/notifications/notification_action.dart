import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api.dart';
import 'push_service.dart';

class NotificationAction extends ConsumerStatefulWidget {
  const NotificationAction({super.key});
  @override
  ConsumerState<NotificationAction> createState() => _NotificationActionState();
}

class _NotificationActionState extends ConsumerState<NotificationAction> {
  int count = 0;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    PushService.changes.addListener(load);
    load();
  }

  Future<void> load() async {
    final request = ++generation;
    final session = ref.read(sessionProvider);
    final token = session.token;
    try {
      final data = await ref.read(apiProvider).get('/notification-count');
      if (mounted && request == generation && token == session.token) {
        setState(() => count = data['unread_count'] as int);
      }
    } catch (_) {
      if (mounted) setState(() => count = 0);
    }
  }

  @override
  void dispose() {
    PushService.changes.removeListener(load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: count > 0 ? 'Notifikasi, $count belum dibaca' : 'Notifikasi',
    icon: Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: const Icon(Icons.notifications_none),
    ),
    onPressed: () async {
      await context.push('/notifications');
      if (mounted) load();
    },
  );
}
