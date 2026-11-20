import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/widgets/state_views.dart';
import '../../domain/models.dart';
import 'cart_cubit.dart';
import 'cart_widgets.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const EmptyView(
              message: 'Your cart is empty',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = cart.items[i];
                    return Dismissible(
                      key: ValueKey(item.product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) => context.read<CartCubit>().remove(item.product),
                      child: ListTile(
                        leading: ProductImage(url: item.product.thumbnail, size: 48),
                        title: Text(
                          item.product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(formatCents(item.totalCents)),
                        trailing: AddToCartControl(product: item.product),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total ${formatCents(cart.totalCents)}',
                          key: const ValueKey('cart-total'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          context.read<CartCubit>().clear();
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Order placed')));
                        },
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
