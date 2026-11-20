import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'favorites_cubit.dart';

/// `context.select` rebuilds this button only when *its* id flips, not the
/// whole list. That is the answer to "how do you avoid rebuilding every row?"
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select((FavoritesCubit c) => c.state.contains(id));
    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: isFavorite ? Colors.redAccent : null,
      onPressed: () => context.read<FavoritesCubit>().toggle(id),
    );
  }
}
