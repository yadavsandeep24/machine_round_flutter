import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import 'auth_api.dart';
import 'token_store.dart';

/// Adds `Authorization: Bearer <token>` and refreshes once on a 401.
///
/// Single-flight: if 5 requests fail with 401 together, only ONE refresh call
/// is made; the other 4 wait for it and retry with the new token.
/// Only a 400/401/403 from the refresh endpoint logs the user out; a network
/// error during refresh keeps the session (the user may just be offline).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokens,
    required AuthApi authApi,
    required Dio retryClient,
    required void Function() onSessionExpired,
  }) : _tokens = tokens,
       _authApi = authApi,
       _retryClient = retryClient,
       _onSessionExpired = onSessionExpired;

  static const _retriedKey = 'auth_retried';

  final TokenStore _tokens;
  final AuthApi _authApi;
  final Dio _retryClient;
  final void Function() _onSessionExpired;

  Completer<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.session?.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final sentToken = (options.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
    final current = _tokens.session?.accessToken;
    // Someone else already refreshed while this request was in flight.
    final newToken = (current != null && current != sentToken) ? current : await _refreshOnce();

    if (newToken == null) {
      return handler.next(
        DioException(
          requestOptions: options,
          response: err.response,
          error: const UnauthorizedException(),
        ),
      );
    }
    try {
      options
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra[_retriedKey] = true;
      handler.resolve(await _retryClient.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Returns the new access token, or null when the session is over.
  Future<String?> _refreshOnce() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;
    final completer = _refreshing = Completer<String?>();
    () async {
      try {
        final session = _tokens.session;
        if (session == null) return completer.complete(null);
        final fresh = await _authApi.refresh(session.refreshToken);
        await _tokens.save(fresh);
        completer.complete(fresh.accessToken);
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 400 || code == 401 || code == 403) {
          await _tokens.clear();
          _onSessionExpired();
        }
        completer.complete(null);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }
}
