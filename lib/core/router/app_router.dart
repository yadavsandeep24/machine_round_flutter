import 'package:go_router/go_router.dart';

import '../../challenges/challenges_page.dart';

abstract final class Routes {
  static const home = '/';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, __) => const ChallengesPage()),
    GoRoute(
      path: '/challenge/:n',
      builder: (_, state) =>
          ChallengeDetailPage(number: int.tryParse(state.pathParameters['n'] ?? '') ?? -1),
    ),
  ],
);
