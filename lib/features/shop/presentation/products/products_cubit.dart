import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/ui/view_status.dart';
import '../../domain/models.dart';
import '../../domain/shop_repository.dart';

class ProductsState extends Equatable {
  ProductsState({
    this.status = ViewStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.category,
    this.sort = ProductSort.relevance,
    this.inStockOnly = false,
    this.error,
  }) : visible = _apply(products, sort, inStockOnly);

  final ViewStatus status;
  final List<Product> products;
  final List<Category> categories;

  /// Selected category slug; null means all.
  final String? category;
  final ProductSort sort;
  final bool inStockOnly;
  final AppException? error;

  /// Sorted and filtered once per state, never inside build().
  final List<Product> visible;

  static List<Product> _apply(List<Product> products, ProductSort sort, bool inStockOnly) {
    final list = [
      for (final p in products)
        if (!inStockOnly || p.inStock) p,
    ];
    switch (sort) {
      case ProductSort.relevance:
        break;
      case ProductSort.priceLowHigh:
        list.sort((a, b) => a.priceCents.compareTo(b.priceCents));
      case ProductSort.priceHighLow:
        list.sort((a, b) => b.priceCents.compareTo(a.priceCents));
      case ProductSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return List.unmodifiable(list);
  }

  ProductsState copyWith({
    ViewStatus? status,
    List<Product>? products,
    List<Category>? categories,
    String? Function()? category,
    ProductSort? sort,
    bool? inStockOnly,
    AppException? Function()? error,
  }) => ProductsState(
    status: status ?? this.status,
    products: products ?? this.products,
    categories: categories ?? this.categories,
    category: category != null ? category() : this.category,
    sort: sort ?? this.sort,
    inStockOnly: inStockOnly ?? this.inStockOnly,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [status, products, categories, category, sort, inStockOnly, error];
}

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(ProductsState());

  final ShopRepository _repository;

  /// Incremented per request. A response for an older category is ignored, so
  /// tapping chips quickly never shows the wrong category's products.
  int _request = 0;

  Future<void> start() async {
    final categories = _repository.getCategories();
    await _loadProducts();
    final result = await categories;
    if (!isClosed) emit(state.copyWith(categories: result.dataOrNull ?? const []));
  }

  Future<void> retry() => _loadProducts();

  Future<void> selectCategory(String? slug) async {
    if (slug == state.category) return;
    emit(state.copyWith(category: () => slug));
    await _loadProducts();
  }

  void sortBy(ProductSort sort) => emit(state.copyWith(sort: sort));

  void setInStockOnly(bool value) => emit(state.copyWith(inStockOnly: value));

  Future<void> _loadProducts() async {
    final request = ++_request;
    emit(state.copyWith(status: ViewStatus.loading, error: () => null));
    final result = await _repository.getProducts(categorySlug: state.category);
    if (isClosed || request != _request) return; // stale response
    emit(switch (result) {
      Success(:final data) => state.copyWith(status: ViewStatus.success, products: data),
      Failure(:final error) => state.copyWith(status: ViewStatus.failure, error: () => error),
    });
  }
}
