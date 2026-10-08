import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api.dart';

class PushService {
  static Future<void> enable(Api api) async {
    if (!const bool.fromEnvironment('FCM_ENABLED', defaultValue: false)) {
      throw StateError('FCM belum dikonfigurasi untuk build ini.');
    }
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    final permissions = await messaging.requestPermission();
    if (permissions.authorizationStatus != AuthorizationStatus.authorized &&
        permissions.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    Future<void> register(String token) async {
      if (!api.session.loggedIn) {
        return;
      }
      final result = await api.post('/devices', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
      api.session.deviceId = result['id'];
      await api.session.storage.write(
        key: 'hopely.device_id',
        value: result['id'],
      );
    }

    final token = await messaging.getToken();
    if (token != null) {
      await register(token);
    }
    messaging.onTokenRefresh.listen((token) async {
      try {
        await register(token);
      } catch (_) {
        /* Retry on next explicit enable. */
      }
    });
  }
}
