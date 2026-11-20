import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:machine_round/app.dart';
import 'package:machine_round/core/router/app_router.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/auth/data/auth_api.dart';
import 'package:machine_round/features/auth/data/auth_repository.dart';
import 'package:machine_round/features/auth/data/token_store.dart';
import 'package:machine_round/features/auth/domain/auth_models.dart';
import 'package:machine_round/features/auth/presentation/auth_cubit.dart';
import 'package:machine_round/features/auth/presentation/login_cubit.dart';
import 'package:machine_round/features/auth/presentation/login_page.dart';

import 'fake_adapter.dart';

AuthRepository _repo(TokenStore tokens, {int loginStatus = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/'))
    ..httpClientAdapter = FakeAdapter((o) async {
      if (o.path == 'auth/login') {
        if (loginStatus != 200) return (loginStatus, {'message': 'Invalid credentials'});
        return (
          200,
          {
            'id': 1,
            'username': 'demo',
            'firstName': 'Demo',
            'lastName': 'User',
            'email': 'demo@test.dev',
            'accessToken': 'a',
            'refreshToken': 'r',
          },
        );
      }
      return (404, null);
    });
  return AuthRepository(api: AuthApi(dio), tokens: tokens, authedDio: dio);
}

void main() {
  group('authRedirect', () {
    test('unknown always shows the splash', () {
      expect(authRedirect(AuthStatus.unknown, '/'), Routes.splash);
      expect(authRedirect(AuthStatus.unknown, Routes.splash), isNull);
    });
    test('signed out is sent to login', () {
      expect(authRedirect(AuthStatus.unauthenticated, '/'), Routes.login);
      expect(authRedirect(AuthStatus.unauthenticated, Routes.login), isNull);
    });
    test('signed in leaves login and splash', () {
      expect(authRedirect(AuthStatus.authenticated, Routes.login), Routes.home);
      expect(authRedirect(AuthStatus.authenticated, '/'), isNull);
    });
  });

  test('restore: a saved session is authenticated without a network call', () async {
    final tokens = TokenStore(InMemoryStore());
    await tokens.save(const Session(accessToken: 'a', refreshToken: 'r'));
    final cubit = AuthCubit(_repo(tokens))..restore();
    expect(cubit.state.status, AuthStatus.authenticated);
    await cubit.logout();
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(tokens.session, isNull);
    await cubit.close();
  });

  test('session persists across a restart', () async {
    final store = InMemoryStore();
    await _repo(TokenStore(store)).login('demo', 'secret1');
    expect(TokenStore(store).session, isNotNull); // fresh instance = relaunch
  });

  test('wrong credentials show a friendly message', () async {
    final cubit = LoginCubit(_repo(TokenStore(InMemoryStore()), loginStatus: 400));
    await cubit.submit('demo', 'wrongpass');
    expect(cubit.state.error, 'Wrong username or password');
    await cubit.close();
  });

  testWidgets('login form validates, signs in and redirects', (tester) async {
    final tokens = TokenStore(InMemoryStore());
    final repo = _repo(tokens);
    final auth = AuthCubit(repo)..restore();
    final router = GoRouter(
      initialLocation: Routes.login,
      refreshListenable: _CubitListenable(auth),
      redirect: (_, s) => authRedirect(auth.state.status, s.matchedLocation),
      routes: [
        GoRoute(
          path: Routes.login,
          builder: (_, __) =>
              BlocProvider(create: (_) => LoginCubit(repo), child: const LoginView()),
        ),
        GoRoute(path: Routes.home, builder: (_, __) => const Text('HOME')),
        GoRoute(path: Routes.splash, builder: (_, __) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(App(router: router, authCubit: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'demo');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(tokens.session, isNotNull);
  });
}

class _CubitListenable extends ChangeNotifier {
  _CubitListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
