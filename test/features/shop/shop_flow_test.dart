import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:machine_round/features/shop/presentation/cart/cart_cubit.dart';
import 'package:machine_round/features/shop/presentation/cart/cart_page.dart';
import 'package:machine_round/features/shop/presentation/products/products_cubit.dart';
import 'package:machine_round/features/shop/presentation/products/products_page.dart';

import 'fakes.dart';

void main() {
  testWidgets('add from the grid updates the badge and the cart screen', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider(
            create: (_) => ProductsCubit(FakeShopRepository())..start(),
            child: const ProductsView(),
          ),
        ),
        GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
      ],
    );
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => CartCubit(InMemoryCartStorage()),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pump();
    expect(find.text('2'), findsWidgets); // badge and stepper

    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(find.text(r'Total $19.98'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });
}
