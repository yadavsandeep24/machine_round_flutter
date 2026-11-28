import 'package:go_router/go_router.dart';

import '../../features/help/presentation/faq_page.dart';

abstract final class Routes {
  static const home = '/';
}

GoRouter buildRouter({String initialLocation = Routes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: Routes.home,
      // Deep link: /?open=declined opens that answer on arrival.
      builder: (context, state) => FaqPage(initiallyOpen: state.uri.queryParameters['open']),
    ),
  ],
);
