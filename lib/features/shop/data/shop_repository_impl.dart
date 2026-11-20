import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/safe_call.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/models.dart';
import '../domain/shop_repository.dart';

const kShopBaseUrl = 'https://dummyjson.com/';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._dio);
  final Dio _dio;

  static const _select = 'title,price,thumbnail,category,stock,rating,discountPercentage';

  @override
  Future<Result<List<Category>>> getCategories() => safeCall(() async {
    final res = await _dio.get<List<dynamic>>('products/categories');
    return res.data!
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  });

  @override
  Future<Result<List<Product>>> getProducts({String? categorySlug}) => safeCall(() async {
    final path = categorySlug == null ? 'products' : 'products/category/$categorySlug';
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {'limit': 0, 'select': _select}, // limit=0 returns all
    );
    return (res.data!['products'] as List<dynamic>)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  });

  @override
  Future<Result<Product>> getProduct(int id) => safeCall(() async {
    final res = await _dio.get<Map<String, dynamic>>('products/$id');
    return Product.fromJson(res.data!);
  });
}

class LocalCartStorage implements CartStorage {
  LocalCartStorage(this._store);

  static const _key = 'cart_v1';
  final KeyValueStore _store;

  @override
  List<CartItem> load() {
    final raw = _store.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        return CartItem(
          product: Product.fromJson(map['product'] as Map<String, dynamic>),
          quantity: map['quantity'] as int,
        );
      }).toList();
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(List<CartItem> items) => _store.setString(
    _key,
    jsonEncode([
      for (final i in items) {'product': i.product.toJson(), 'quantity': i.quantity},
    ]),
  );
}
