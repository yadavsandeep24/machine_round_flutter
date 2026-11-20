import 'package:go_router/go_router.dart';

import '../../features/shop/domain/models.dart';
import '../../features/shop/presentation/cart/cart_page.dart';
import '../../features/shop/presentation/products/product_detail_page.dart';
import '../../features/shop/presentation/products/products_page.dart';

abstract final class Routes {
  static const home = '/';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (context, state) => const ProductsPage()),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) => ProductDetailPage(
        productId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        initial: state.extra is Product ? state.extra! as Product : null,
      ),
    ),
    GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
  ],
);
