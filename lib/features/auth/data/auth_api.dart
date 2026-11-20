import 'package:dio/dio.dart';

import '../domain/auth_models.dart';

const kAuthBaseUrl = 'https://dummyjson.com/';

/// Unauthenticated endpoints. Uses its own Dio WITHOUT the auth interceptor,
/// so a failing refresh can never recurse into another refresh.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  static const _expiresInMins = 30;

  Future<(Session, AuthUser)> login(String username, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'auth/login',
      data: {'username': username, 'password': password, 'expiresInMins': _expiresInMins},
    );
    final json = res.data!;
    return (Session.fromJson(json), AuthUser.fromJson(json));
  }

  Future<Session> refresh(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'auth/refresh',
      data: {'refreshToken': refreshToken, 'expiresInMins': _expiresInMins},
    );
    return Session.fromJson(res.data!);
  }
}
