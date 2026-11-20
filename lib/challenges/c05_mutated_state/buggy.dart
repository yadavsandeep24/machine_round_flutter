import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BUG: "add-to-cart items don't refresh after tapping Add". The list is
/// mutated in place and the SAME instance is emitted. Bloc skips an emit
/// when `newState == state`, and a list is equal to itself, so after the
/// first emit nothing rebuilds. (Same bug with Equatable states holding a
/// mutated list, with ValueNotifier, and with Riverpod/Provider.)
class CartCubitBuggy extends Cubit<List<String>> {
  CartCubitBuggy() : super(<String>[]);

  void add(String item) {
    state.add(item);
    emit(state);
  }
}

class CartBuggy extends StatelessWidget {
  const CartBuggy({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CartCubitBuggy(),
    child: Builder(
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocBuilder<CartCubitBuggy, List<String>>(
            builder: (_, items) => Text('Items in cart: ${items.length}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<CartCubitBuggy>().add('Shoe'),
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
