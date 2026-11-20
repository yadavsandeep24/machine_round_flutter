import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/ui/view_status.dart';
import 'package:machine_round/features/shop/domain/models.dart';
import 'package:machine_round/features/shop/presentation/products/products_cubit.dart';

import 'fakes.dart';

void main() {
  late FakeShopRepository repo;
  setUp(() => repo = FakeShopRepository());

  blocTest<ProductsCubit, ProductsState>(
    'start loads products and categories',
    build: () => ProductsCubit(repo),
    act: (c) => c.start(),
    verify: (c) {
      expect(c.state.status, ViewStatus.success);
      expect(c.state.visible, hasLength(3));
      expect(c.state.categories, hasLength(2));
    },
  );

  test('sorts by price and rating, filters in-stock', () async {
    final c = ProductsCubit(repo);
    await c.start();
    c.sortBy(ProductSort.priceLowHigh);
    expect(c.state.visible.map((p) => p.id), [2, 1, 3]);
    c.sortBy(ProductSort.rating);
    expect(c.state.visible.map((p) => p.id), [2, 3, 1]);
    c.setInStockOnly(true);
    expect(c.state.visible.map((p) => p.id), [2, 1]);
    await c.close();
  });

  blocTest<ProductsCubit, ProductsState>(
    'a slow response for an older category is ignored',
    build: () => ProductsCubit(repo),
    act: (c) async {
      await c.start();
      repo.gates['beauty'] = Completer<void>();
      final slow = c.selectCategory('beauty');
      final fast = c.selectCategory('groceries');
      await fast;
      repo.gates['beauty']!.complete();
      await slow;
    },
    verify: (c) {
      expect(c.state.category, 'groceries');
      expect(c.state.visible.map((p) => p.id), [2]);
    },
  );

  blocTest<ProductsCubit, ProductsState>(
    'failure then retry',
    setUp: () => repo.failWith = const NoInternetException(),
    build: () => ProductsCubit(repo),
    act: (c) async {
      await c.start();
      repo.failWith = null;
      await c.retry();
    },
    verify: (c) => expect(c.state.status, ViewStatus.success),
  );
}
