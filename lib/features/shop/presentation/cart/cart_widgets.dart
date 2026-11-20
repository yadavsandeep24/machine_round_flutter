import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import 'cart_cubit.dart';

/// App bar action shown on every screen. Rebuilds only when the count changes.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select((CartCubit c) => c.state.itemCount);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

/// "Add" button that turns into a - qty + stepper once the product is in the
/// cart. Selects only this product's quantity.
class AddToCartControl extends StatelessWidget {
  const AddToCartControl({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final quantity = context.select((CartCubit c) => c.state.quantityOf(product.id));
    final cart = context.read<CartCubit>();

    void add() {
      final change = cart.add(product);
      final message = switch (change) {
        CartChange.added => null,
        CartChange.limitReached => 'Only ${product.stock} in stock',
        CartChange.outOfStock => 'Out of stock',
      };
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    if (!product.inStock) {
      return const OutlinedButton(onPressed: null, child: Text('Out of stock'));
    }
    if (quantity == 0) {
      return FilledButton.tonal(onPressed: add, child: const Text('Add'));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease',
          visualDensity: VisualDensity.compact,
          onPressed: () => cart.decrement(product),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$quantity', key: ValueKey('qty-${product.id}')),
        IconButton(
          tooltip: 'Increase',
          visualDensity: VisualDensity.compact,
          onPressed: quantity >= product.stock ? null : add,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.url, this.size, super.key});

  final String url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_outlined),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Decode at display size, not full resolution: big memory win in grids.
      cacheWidth: size == null ? 300 : (size! * 2).round(),
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
