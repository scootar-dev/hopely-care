import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../api/api.dart';
import '../routing/router.dart';
import 'treatment_reminders.dart';

final reminderRevisionProvider = StateProvider<int>((ref) => 0);
final reminderErrorProvider = StateProvider<String?>((ref) => null);

class ReminderHost extends ConsumerStatefulWidget {
  const ReminderHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ReminderHost> createState() => _ReminderHostState();
}

class _ReminderHostState extends ConsumerState<ReminderHost>
    with WidgetsBindingObserver {
  String? identity;
  int generation = 0;
  final reminders = TreatmentReminders.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reminders.onOpen = open;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reconcile();
    });
  }

  void open(String path) {
    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (session.loggedIn && !session.caregiver && !session.needsConsent) {
      reminders.pendingPath = null;
      ref.read(routerProvider).push(path);
    }
  }

  Future<void> reconcile() async {
    final run = ++generation;
    final session = ref.read(sessionProvider);
    if (!session.initialized) return;
    final active =
        session.loggedIn && !session.caregiver && !session.needsConsent;
    identity = active ? session.user!['id'].toString() : null;
    try {
      if (active) {
        await reminders.initialize();
        if (mounted && run == generation && reminders.pendingPath != null) {
          open(reminders.pendingPath!);
        }
        await reminders.refresh(
          ref.read(apiProvider),
          isCurrent: () => mounted && run == generation,
        );
        if (mounted && run == generation && reminders.pendingPath != null) {
          open(reminders.pendingPath!);
        }
      } else {
        await reminders.clear();
      }
      if (mounted && run == generation) {
        ref.read(reminderErrorProvider.notifier).state = null;
      }
    } catch (_) {
      if (mounted && run == generation) {
        ref.read(reminderErrorProvider.notifier).state =
            'Pengingat perangkat belum tersinkron. Buka Perjalanan dan aktifkan kembali pengingat.';
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reconcile();
  }

  @override
  void dispose() {
    generation++;
    reminders.onOpen = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (_, session) {
      final next =
          session.loggedIn && !session.caregiver && !session.needsConsent
          ? session.user!['id'].toString()
          : null;
      if (session.initialized && (next != identity || next == null)) reconcile();
    });
    ref.listen(reminderRevisionProvider, (_, _) => reconcile());
    return widget.child;
  }
}
