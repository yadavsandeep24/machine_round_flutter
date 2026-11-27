import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/txn_search_page.dart';

abstract final class Routes {
  static const home = '/';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [GoRoute(path: Routes.home, builder: (context, state) => const TxnSearchPage())],
);
