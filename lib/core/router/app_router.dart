import 'package:go_router/go_router.dart';

import '../../features/users/domain/user.dart';
import '../../features/users/presentation/user_detail_page.dart';
import '../../features/users/presentation/users_page.dart';

abstract final class Routes {
  static const home = '/';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (context, state) => const UsersPage()),
    GoRoute(
      path: '/users/:id',
      builder: (context, state) => UserDetailPage(
        userId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        initial: state.extra is User ? state.extra! as User : null,
      ),
    ),
  ],
);
