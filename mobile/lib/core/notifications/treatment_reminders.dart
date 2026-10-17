import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../api/api.dart';

Future<String> enableTreatmentReminders(Api api) async {
  final reminders = TreatmentReminders.instance;
  if (!reminders.supported) {
    return 'Pengingat perangkat tersedia di aplikasi Android dan iOS.';
  }
  if (!await reminders.enable()) {
    return 'Izinkan notifikasi Hopely Care melalui pengaturan perangkat.';
  }
  await reminders.refresh(api);
  return 'Pengingat jadwal diaktifkan. Izinkan alarm tepat waktu agar sesuai jam jadwal.';
}

class TreatmentReminders {
  static final instance = TreatmentReminders();
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  Future<void> _queue = Future.value();
  int _revision = 0;
  void Function(String)? onOpen;
  String? pendingPath;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!supported) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final path = response.payload;
        if (path != null) {
          pendingPath = path;
          onOpen?.call(path);
        }
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      pendingPath = launch?.notificationResponse?.payload;
    }
  }

  Future<bool> enable() async {
    if (!supported) return false;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;
      final granted = await android.requestNotificationsPermission() ?? false;
      if (granted && await android.canScheduleExactNotifications() != true) {
        await android.requestExactAlarmsPermission();
      }
      return granted;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()!
            .requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  // Serialize reconciliation so a logout or later edit wins over an older fetch.
  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> clear() {
    _revision++;
    return _serial(() async {
      pendingPath = null;
      if (!supported) return;
      await initialize();
      await _plugin.cancelAll();
    });
  }

  Future<void> refresh(Api api, {bool Function()? isCurrent}) async {
    if (!supported) return;
    final revision = ++_revision;
    final user = api.session.user?['id'];
    bool valid() =>
        api.session.loggedIn &&
        !api.session.caregiver &&
        !api.session.needsConsent &&
        api.session.user?['id'] == user &&
        revision == _revision &&
        (isCurrent?.call() ?? true);
    if (!valid()) return;
    final records = <Json>[];
    var page = 1;
    while (true) {
      final data = await api.get('/treatments?page=$page');
      records.addAll(items(data));
      if (page >= (data['last_page'] as int? ?? 1)) break;
      page++;
    }
    await _serial(() async {
      if (!valid()) return;
      await initialize();
      if (!valid()) return;
      await _plugin.cancelAll();
      final upcoming =
          records
              .where(
                (row) =>
                    row['status'] == 'scheduled' &&
                    (DateTime.tryParse(
                          row['scheduled_at']?.toString() ?? '',
                        )?.isAfter(DateTime.now()) ??
                        false),
              )
              .toList()
            ..sort(
              (a, b) => DateTime.parse(
                a['scheduled_at'],
              ).compareTo(DateTime.parse(b['scheduled_at'])),
            );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      // iOS keeps at most 64 pending notifications; reserve a few slots.
      for (var index = 0; index < upcoming.length && index < 60; index++) {
        if (!valid()) {
          await _plugin.cancelAll();
          return;
        }
        final row = upcoming[index];
        final at = DateTime.parse(row['scheduled_at']).toUtc();
        if (!at.isAfter(DateTime.now())) continue;
        await _plugin.zonedSchedule(
          index + 1,
          'Pengingat Hopely Care',
          'Waktu jadwal perjalananmu telah tiba. Buka aplikasi untuk melihat detail.',
          tz.TZDateTime.from(at, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'treatment_schedule',
              'Jadwal perjalanan',
              channelDescription: 'Pengingat jadwal perawatan yang kamu simpan',
              importance: Importance.high,
              priority: Priority.high,
              visibility: NotificationVisibility.private,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: '/treatment/${row['id']}',
        );
      }
    });
  }
}
