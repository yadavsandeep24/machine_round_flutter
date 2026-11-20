import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/profile/profile_page.dart';
import '../ui/widgets/state_views.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/';
}

/// Every auth change re-runs `redirect`: login, logout and an expired
/// refresh token all route correctly without manual navigation calls.
GoRouter buildRouter(AuthCubit auth) => GoRouter(
  initialLocation: Routes.splash,
  refreshListenable: _StreamListenable(auth.stream),
  redirect: (context, state) => authRedirect(auth.state.status, state.matchedLocation),
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (_, __) => const Scaffold(body: LoadingView()),
    ),
    GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
    GoRoute(path: Routes.home, builder: (_, __) => const ProfilePage()),
  ],
);

/// Pure function, so the routing rules are unit-testable.
String? authRedirect(AuthStatus status, String location) {
  return switch (status) {
    AuthStatus.unknown => location == Routes.splash ? null : Routes.splash,
    AuthStatus.unauthenticated => location == Routes.login ? null : Routes.login,
    AuthStatus.authenticated =>
      (location == Routes.login || location == Routes.splash) ? Routes.home : null,
  };
}

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
