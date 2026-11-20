import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/network/safe_call.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/auth/data/auth_api.dart';
import 'package:machine_round/features/auth/data/auth_interceptor.dart';
import 'package:machine_round/features/auth/data/token_store.dart';
import 'package:machine_round/features/auth/domain/auth_models.dart';

import 'fake_adapter.dart';

class _Setup {
  _Setup({required this.refreshStatus}) {
    tokens = TokenStore(InMemoryStore());
    authDio = Dio(BaseOptions(baseUrl: 'https://api.test/'))
      ..httpClientAdapter = FakeAdapter((o) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (refreshStatus != 200) return (refreshStatus, {'message': 'invalid'});
        return (200, {'accessToken': 'new', 'refreshToken': 'r2'});
      });
    api = Dio(BaseOptions(baseUrl: 'https://api.test/'))
      ..httpClientAdapter = FakeAdapter((o) async {
        final auth = o.headers['Authorization'];
        return auth == 'Bearer new' ? (200, {'ok': o.path}) : (401, {'message': 'expired'});
      });
    api.interceptors.add(
      AuthInterceptor(
        tokens: tokens,
        authApi: AuthApi(authDio),
        retryClient: api,
        onSessionExpired: () => expiredCalls++,
      ),
    );
  }

  final int refreshStatus;
  late final TokenStore tokens;
  late final Dio authDio;
  late final Dio api;
  int refreshCalls = 0;
  int expiredCalls = 0;
}

void main() {
  test('attaches the bearer token', () async {
    final s = _Setup(refreshStatus: 200);
    await s.tokens.save(const Session(accessToken: 'new', refreshToken: 'r'));
    final res = await s.api.get<Map<String, dynamic>>('me');
    expect(res.data, {'ok': 'me'});
    expect(s.refreshCalls, 0);
  });

  test('5 parallel 401s cause exactly one refresh, and all retry with the new token', () async {
    final s = _Setup(refreshStatus: 200);
    await s.tokens.save(const Session(accessToken: 'old', refreshToken: 'r1'));

    final results = await Future.wait([
      for (var i = 0; i < 5; i++) s.api.get<Map<String, dynamic>>('item/$i'),
    ]);

    expect(s.refreshCalls, 1);
    expect(results.map((r) => r.data!['ok']), [for (var i = 0; i < 5; i++) 'item/$i']);
    expect(s.tokens.session, const Session(accessToken: 'new', refreshToken: 'r2'));
  });

  test('a rejected refresh token clears the session and reports Unauthorized', () async {
    final s = _Setup(refreshStatus: 401);
    await s.tokens.save(const Session(accessToken: 'old', refreshToken: 'bad'));

    final error = await s.api
        .get<dynamic>('me')
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(mapError(error!), isA<UnauthorizedException>());
    expect(s.tokens.session, isNull);
    expect(s.expiredCalls, 1);
  });

  test('a server error during refresh keeps the session (maybe just offline)', () async {
    final s = _Setup(refreshStatus: 503);
    await s.tokens.save(const Session(accessToken: 'old', refreshToken: 'r1'));

    await expectLater(s.api.get<dynamic>('me'), throwsA(isA<DioException>()));
    expect(s.tokens.session, isNotNull);
    expect(s.expiredCalls, 0);
  });
}
