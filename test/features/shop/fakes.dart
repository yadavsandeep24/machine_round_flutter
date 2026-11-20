import 'dart:async';

import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/result/result.dart';
import 'package:machine_round/features/shop/domain/models.dart';
import 'package:machine_round/features/shop/domain/shop_repository.dart';

Product fakeProduct(
  int id, {
  int priceCents = 1000,
  String category = 'beauty',
  int stock = 10,
  double rating = 4,
}) => Product(
  id: id,
  title: 'Product $id',
  priceCents: priceCents,
  category: category,
  stock: stock,
  rating: rating,
);

class FakeShopRepository implements ShopRepository {
  List<Product> products = [
    fakeProduct(1, priceCents: 999, rating: 3),
    fakeProduct(2, priceCents: 250, category: 'groceries', rating: 5),
    fakeProduct(3, priceCents: 5000, stock: 0, rating: 4),
  ];
  AppException? failWith;

  /// Per-category gates, to finish responses out of order.
  final Map<String?, Completer<void>> gates = {};

  @override
  Future<Result<List<Category>>> getCategories() async => const Success([
    Category(slug: 'beauty', name: 'Beauty'),
    Category(slug: 'groceries', name: 'Groceries'),
  ]);

  @override
  Future<Result<List<Product>>> getProducts({String? categorySlug}) async {
    await gates[categorySlug]?.future;
    if (failWith != null) return Failure(failWith!);
    return Success([
      for (final p in products)
        if (categorySlug == null || p.category == categorySlug) p,
    ]);
  }

  @override
  Future<Result<Product>> getProduct(int id) async =>
      Success(products.firstWhere((p) => p.id == id));
}

class InMemoryCartStorage implements CartStorage {
  List<CartItem> saved = [];

  @override
  List<CartItem> load() => saved;

  @override
  Future<void> save(List<CartItem> items) async => saved = items;
}
