import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/shop/data/shop_repository_impl.dart';
import 'package:machine_round/features/shop/domain/models.dart';
import 'package:machine_round/features/shop/presentation/cart/cart_cubit.dart';

import 'fakes.dart';

void main() {
  late CartCubit cart;
  setUp(() => cart = CartCubit(InMemoryCartStorage()));
  tearDown(() => cart.close());

  test('adding the same product increases its quantity', () {
    final p = fakeProduct(1, priceCents: 999);
    cart
      ..add(p)
      ..add(p)
      ..add(p);
    expect(cart.state.items, hasLength(1));
    expect(cart.state.itemCount, 3);
    expect(cart.state.totalCents, 2997); // exact, no floating point drift
  });

  test('quantity is capped at stock', () {
    final p = fakeProduct(1, stock: 2);
    expect(cart.add(p), CartChange.added);
    expect(cart.add(p), CartChange.added);
    expect(cart.add(p), CartChange.limitReached);
    expect(cart.state.quantityOf(1), 2);
  });

  test('out-of-stock products cannot be added', () {
    expect(cart.add(fakeProduct(1, stock: 0)), CartChange.outOfStock);
    expect(cart.state.isEmpty, isTrue);
  });

  test('decrement to zero removes the line, order is kept', () {
    final a = fakeProduct(1);
    final b = fakeProduct(2);
    cart
      ..add(a)
      ..add(b)
      ..add(a)
      ..decrement(b);
    expect(cart.state.items.map((i) => i.product.id), [1]);
    cart.decrement(a);
    expect(cart.state.quantityOf(1), 1);
  });

  test('cart survives a restart through storage', () async {
    final store = InMemoryStore();
    final first = CartCubit(LocalCartStorage(store))..add(fakeProduct(7, priceCents: 1234));
    await Future<void>.delayed(Duration.zero);
    await first.close();

    final restored = CartCubit(LocalCartStorage(store));
    expect(restored.state.quantityOf(7), 1);
    expect(restored.state.totalCents, 1234);
    await restored.close();
  });

  test('formatCents', () {
    expect(formatCents(0), r'$0.00');
    expect(formatCents(2997), r'$29.97');
    expect(formatCents(123456789), r'$1,234,567.89');
    expect(toCents(0.1 + 0.2), 30);
  });
}
