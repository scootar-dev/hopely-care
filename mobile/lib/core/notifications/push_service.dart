import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> hopelyBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // OS displays notification payloads. No health data or navigation in isolate.
}

class PushService {
  static const configured = bool.fromEnvironment(
    'FCM_ENABLED',
    defaultValue: false,
  );
  static final changes = ValueNotifier<int>(0);
  static final opens = StreamController<String>.broadcast();
  static final foreground = StreamController<String>.broadcast();
  static final _seen = <String>{};
  static Future<void>? _initializing;
  static Api? _api;
  static String? _registered;
  static Future<void>? _queue;
  static int _generation = 0;
  @visibleForTesting
  static void resetTestQueue() { _queue = null; }
  @visibleForTesting
  static Future<void> Function(Duration) retryDelay = (duration) => Future<void>.delayed(duration);

  static void receive(
    Map<String, dynamic> data, {
    required bool opened,
    String? messageId,
  }) {
    final id = data['notification_id'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 100 ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      return;
    }
    final key = '${opened ? 'open' : 'receive'}:${messageId ?? id}';
    if (!_seen.add(key)) return;
    if (_seen.length > 200) _seen.remove(_seen.first);
    changes.value++;
    if (opened) opens.add(id);
    if (!opened) foreground.add(id);
  }

  static Future<void> initialize() => _initializing ??= _initialize();
  static Future<void> _initialize() async {
    if (!configured || kIsWeb) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(hopelyBackgroundMessage);
      FirebaseMessaging.onMessage.listen(
        (m) => receive(m.data, opened: false, messageId: m.messageId),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => receive(m.data, opened: true, messageId: m.messageId),
      );
      listenTokenRefresh(FirebaseMessaging.instance.onTokenRefresh);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        receive(initial.data, opened: true, messageId: initial.messageId);
      }
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  static StreamSubscription<String> listenTokenRefresh(Stream<String> tokens) => tokens.listen((token) {
        final api = _api;
        if (api != null) {
          unawaited(register(api, token).catchError((Object _) {}));
        }
      });

  static Future<void> register(Api api, String token) {
    final identity = api.session.token;
    final generation = _generation;
    final key = '$identity:$token';
    final work = (_queue ?? Future<void>.value()).catchError((Object _) {}).then((_) async {
      if (identity == null ||
          identity != api.session.token ||
          !api.session.loggedIn ||
          _registered == key) {
        return;
      }
      dynamic result;
      for (var attempt = 0; attempt < 4; attempt++) {
        if (generation != _generation || identity != api.session.token) return;
        try {
          result = await api.post('/devices', {
            'token': token,
            'platform': defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          });
          break;
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          final transient = status == null || status == 429 || status >= 500;
          if (!transient || attempt == 3) rethrow;
          await retryDelay(Duration(seconds: 1 << attempt));
        }
      }
      if (identity != api.session.token || generation != _generation) {
        // Logout waits for this cleanup; never leave a newly registered token behind.
        if (identity == api.session.token) await api.delete('/devices/${result['id']}');
        return;
      }
      api.session.deviceId = result['id'];
      await api.session.storage.write(
        key: 'hopely.device_id',
        value: result['id'],
      );
      _registered = key;
    });
    _queue = work;
    return work;
  }

  static Future<void> unregister(Api api) async {
    _generation++;
    _api = null;
    await _queue?.catchError((Object _) {});
    final id =
        api.session.deviceId ??
        await api.session.storage.read(key: 'hopely.device_id');
    if (id != null) await api.delete('/devices/$id');
    await api.session.storage.delete(key: 'hopely.device_id');
    api.session.deviceId = null;
    detach();
  }

  static void detach() {
    _generation++;
    _api = null;
    _registered = null;
    _seen.clear();
  }

  static Future<void> sync(Api api) async {
    _api = api;
    if (!configured || kIsWeb) return;
    await initialize();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await register(api, token);
  }

  static Future<void> enable(Api api) async {
    if (!configured || kIsWeb) {
      throw StateError('FCM belum dikonfigurasi untuk platform/build ini.');
    }
    await initialize();
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      throw StateError(
        'Izin notifikasi perangkat ditolak. Aktifkan melalui pengaturan perangkat.',
      );
    }
    await sync(api);
    if (api.session.deviceId == null) {
      throw StateError('Token perangkat belum tersedia. Coba lagi.');
    }
  }
}

/// Fetch from owner-scoped API before trusting an incoming notification ID.
Future<String> openNotification(Api api, String id) async {
  final identity = api.session.token;
  if (!api.session.loggedIn) {
    throw StateError('Masuk untuk membuka notifikasi.');
  }
  final n = await api.get('/notifications/${Uri.encodeComponent(id)}') as Json;
  if (identity != api.session.token || !api.session.loggedIn) {
    throw StateError('Sesi berubah.');
  }
  if (n['read_at'] == null) {
    try {
      await api.put('/notifications/$id/read', {});
    } catch (_) {
      /* Opening help remains available. */
    }
  }
  if (identity != api.session.token || !api.session.loggedIn) {
    throw StateError('Sesi berubah.');
  }
  PushService.changes.value++;
  final type = n['notification_type']?.toString() ?? '';
  if (api.session.caregiver && type.startsWith('emergency_support')) {
    return '/caregiver/sos/$id';
  }
  if (api.session.caregiver && type == 'support_alert') {
    return '/caregiver/alerts/$id';
  }
  return '/notifications';
}
