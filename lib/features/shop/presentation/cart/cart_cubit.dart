import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models.dart';
import '../../domain/shop_repository.dart';

class CartState extends Equatable {
  const CartState([this.items = const []]);

  /// Insertion order is the display order.
  final List<CartItem> items;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get totalCents => items.fold(0, (sum, i) => sum + i.totalCents);
  bool get isEmpty => items.isEmpty;

  int quantityOf(int productId) {
    for (final item in items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  @override
  List<Object?> get props => [items];
}

enum CartChange { added, limitReached, outOfStock }

/// One instance for the whole app (provided above the router), so the list,
/// detail and cart screens always agree.
class CartCubit extends Cubit<CartState> {
  CartCubit(this._storage) : super(CartState(_storage.load()));

  final CartStorage _storage;

  CartChange add(Product product) {
    if (!product.inStock) return CartChange.outOfStock;
    final current = state.quantityOf(product.id);
    if (current >= product.stock) return CartChange.limitReached;
    _setQuantity(product, current + 1);
    return CartChange.added;
  }

  void decrement(Product product) => _setQuantity(product, state.quantityOf(product.id) - 1);

  void remove(Product product) => _setQuantity(product, 0);

  void clear() => _commit(const []);

  void _setQuantity(Product product, int quantity) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (quantity <= 0) {
      if (index >= 0) items.removeAt(index);
    } else if (index >= 0) {
      items[index] = items[index].withQuantity(quantity);
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }
    _commit(items);
  }

  void _commit(List<CartItem> items) {
    emit(CartState(List.unmodifiable(items)));
    _storage.save(items); // fire and forget; the in-memory state is the source of truth
  }
}
