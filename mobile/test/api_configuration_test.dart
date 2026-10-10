import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopely_care/core/api/api.dart';

DioException responseError(String path, int status) {
  final request = RequestOptions(path: path);
  return DioException(
    requestOptions: request,
    response: Response(
      requestOptions: request,
      statusCode: status,
      data: {'message': 'private diagnostic payload'},
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('development API reaches the computer from Android Emulator', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(apiBaseUrl, 'http://10.0.2.2:8000/api');
  });

  test('desktop development keeps its loopback API', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(apiBaseUrl, 'http://127.0.0.1:8000/api');
  });

  test('auth errors describe account problems without exposing responses', () {
    final invalid = friendlyError(responseError('/auth/login', 401));
    expect(invalid, contains('akun yang sudah terdaftar'));
    expect(invalid, isNot(contains('private diagnostic payload')));
    final validation = friendlyError(responseError('/auth/login', 422));
    expect(validation, contains('email'));
    expect(validation, isNot(contains('Catatan hari ini')));
    final registration = friendlyError(responseError('/auth/register', 422));
    expect(registration, contains('12 karakter'));
    final unavailable = friendlyError(responseError('/auth/login', 503));
    expect(unavailable, contains('Layanan akun'));
    expect(unavailable, isNot(contains('AI')));
    expect(
      friendlyError(responseError('/ai/chat', 503)),
      contains('Layanan AI'),
    );
  });
}
