import 'package:go_router/go_router.dart';

import '../../features/posts/presentation/detail/post_detail_page.dart';
import '../../features/posts/presentation/list/posts_page.dart';

abstract final class Routes {
  static const home = '/';
  static String postDetail(int id) => '/posts/$id';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const PostsPage(),
      routes: [
        GoRoute(
          path: 'posts/:id',
          builder: (context, state) {
            // Deep links can carry garbage: never `int.parse` blindly.
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
            return PostDetailPage(postId: id);
          },
        ),
      ],
    ),
  ],
);
