import '../../../core/result/result.dart';
import 'models.dart';

abstract interface class ShopRepository {
  Future<Result<List<Category>>> getCategories();

  /// All products, or only [categorySlug] when given.
  Future<Result<List<Product>>> getProducts({String? categorySlug});

  Future<Result<Product>> getProduct(int id);
}

/// Persists the cart across app restarts.
abstract interface class CartStorage {
  List<CartItem> load();
  Future<void> save(List<CartItem> items);
}
