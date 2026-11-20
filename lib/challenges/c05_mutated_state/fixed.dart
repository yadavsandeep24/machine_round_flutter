import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// FIX: treat state as immutable. Emit a NEW list (`[...state, item]`), or a
/// new state object via copyWith. Exposing `List.unmodifiable` makes an
/// accidental `state.add` throw immediately instead of failing silently.
class CartCubitFixed extends Cubit<List<String>> {
  CartCubitFixed() : super(const []);

  void add(String item) => emit(List.unmodifiable([...state, item]));
}

class CartFixed extends StatelessWidget {
  const CartFixed({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CartCubitFixed(),
    child: Builder(
      builder: (context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlocBuilder<CartCubitFixed, List<String>>(
            builder: (_, items) => Text('Items in cart: ${items.length}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<CartCubitFixed>().add('Shoe'),
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
