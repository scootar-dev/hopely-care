import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef Json = Map<String, dynamic>;
const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

// Android Emulator reaches the development computer through 10.0.2.2.
// Physical devices and hosted APIs still need an explicit API_BASE_URL.
String get apiBaseUrl => _configuredApiBaseUrl.isNotEmpty
    ? _configuredApiBaseUrl
    : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8000/api'
    : 'http://127.0.0.1:8000/api';
final sessionProvider = ChangeNotifierProvider<Session>((ref) => Session());
final apiProvider = Provider<Api>((ref) => Api(ref.read(sessionProvider)));

class Session extends ChangeNotifier {
  final storage = const FlutterSecureStorage();
  String? token;
  Json? user;
  Json? profile;
  Set<String> consents = {};
  String? deviceId;
  bool initialized = false;
  bool get loggedIn => token != null && user != null;
  bool get caregiver => user?['role'] == 'CAREGIVER';
  bool get needsConsent =>
      !caregiver && !consents.contains('HEALTH_DATA_PROCESSING');
  Future<void> restore() async {
    try {
      token = await storage.read(key: 'hopely.token');
      deviceId = await storage.read(key: 'hopely.device_id');
      if (token != null) {
        await refresh();
      }
    } catch (_) {
      user = null;
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final api = Api(this);
    final result = await api.get('/me') as Json;
    user = result['user'] as Json;
    profile = result['profile'] as Json?;
    final rows = await api.get('/consents') as List;
    consents = rows
        .where((c) => c['accepted'] == true && c['revoked_at'] == null)
        .map((c) => c['consent_type'] as String)
        .toSet();
    notifyListeners();
  }

  Future<void> setAuth(Json result, {bool remember = true}) async {
    token = result['token'] as String;
    user = result['user'] as Json;
    if (remember) {
      await storage.write(key: 'hopely.token', value: token);
    } else {
      await storage.delete(key: 'hopely.token');
    }
    await refresh();
  }

  Future<void> clear() async {
    token = null;
    user = null;
    profile = null;
    consents = {};
    deviceId = null;
    await storage.delete(key: 'hopely.token');
    notifyListeners();
  }
}

class Api {
  Api(this.session) {
    if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
      throw StateError('Release builds require HTTPS API_BASE_URL.');
    }
    dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (session.token != null) {
            options.headers['Authorization'] = 'Bearer ${session.token}';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            session.clear();
          }
          handler.next(e);
        },
      ),
    );
  }
  final Session session;
  late final Dio dio;
  Future<dynamic> get(String path) async =>
      (await dio.get<dynamic>(path)).data['data'];
  Future<dynamic> post(String path, [Json data = const {}]) async =>
      (await dio.post<dynamic>(path, data: data)).data['data'];
  Future<dynamic> put(String path, Json data) async =>
      (await dio.put<dynamic>(path, data: data)).data['data'];
  Future<void> delete(String path, [Json data = const {}]) async {
    await dio.delete<dynamic>(path, data: data);
  }
}

String friendlyError(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    final path = Uri.tryParse(error.requestOptions.path)?.path ?? '';
    final login = path.endsWith('/auth/login');
    final register = path.endsWith('/auth/register');
    if (login || register) {
      if (code == 401) {
        return 'Email atau kata sandi belum sesuai. Gunakan akun yang sudah terdaftar di Hopely Care.';
      }
      if (code == 422) {
        return register
            ? 'Periksa nama, email, dan konfirmasi kata sandi. Gunakan minimal 12 karakter; email mungkin sudah terdaftar.'
            : 'Periksa format email dan isi kata sandi.';
      }
      if (code != null && code >= 500) {
        return 'Layanan akun sedang bermasalah. Silakan coba lagi nanti.';
      }
    }
    if (code == 403) {
      return 'Izin belum aktif. Periksa pengaturan privasi atau izin pendamping.';
    }
    if (code == 401) {
      return 'Sesi berakhir atau email dan kata sandi belum sesuai.';
    }
    if (code == 422) {
      return 'Periksa isian dan tanggal. Catatan hari ini mungkin sudah tersimpan.';
    }
    if (code == 409) {
      return 'Data atau persetujuan berubah. Muat ulang dan coba lagi.';
    }
    if (code == 429) {
      return 'Jeda sebentar, lalu coba lagi.';
    }
    if (code == 503) {
      return 'Layanan AI belum tersedia. Catatan yang sudah disimpan tetap tersedia.';
    }
    return 'Belum bisa terhubung. Periksa koneksi, lalu coba lagi.';
  }
  return 'Ada kendala. Silakan coba lagi.';
}

String dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
List<Json> items(dynamic value) =>
    ((value is Map ? value['items'] : value) as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

class Checkin {
  Checkin({required this.date, required this.scores});
  final String date;
  final Map<String, int> scores;
  factory Checkin.fromJson(Json json) => Checkin(
    date: json['checkin_date'] as String,
    scores: {
      for (final k in ['mood', 'anxiety', 'energy', 'sleep', 'pain'])
        k: (json['${k}_score'] as num).toInt(),
    },
  );
  Json toJson() => {
    'checkin_date': date,
    for (final entry in scores.entries) '${entry.key}_score': entry.value,
  };
}
