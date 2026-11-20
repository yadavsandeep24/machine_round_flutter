import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/network/safe_call.dart';
import '../../../core/result/result.dart';
import '../domain/auth_models.dart';
import 'auth_api.dart';
import 'token_store.dart';

class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStore tokens, required Dio authedDio})
    : _api = api,
      _tokens = tokens,
      _authedDio = authedDio;

  final AuthApi _api;
  final TokenStore _tokens;
  final Dio _authedDio;
  final _expired = StreamController<void>.broadcast();

  bool get hasSession => _tokens.session != null;

  /// Fires when the refresh token is rejected (wired from the interceptor).
  Stream<void> get sessionExpired => _expired.stream;
  void notifySessionExpired() => _expired.add(null);

  Future<Result<AuthUser>> login(String username, String password) => safeCall(() async {
    final (session, user) = await _api.login(username, password);
    await _tokens.save(session);
    return user;
  });

  /// GET /auth/me with the bearer token (refreshed automatically on 401).
  Future<Result<AuthUser>> me() => safeCall(() async {
    final res = await _authedDio.get<Map<String, dynamic>>('auth/me');
    return AuthUser.fromJson(res.data!);
  });

  Future<void> logout() => _tokens.clear();
}
