import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/ui/view_status.dart';
import '../../../../core/ui/widgets/state_views.dart';
import '../../domain/models.dart';
import '../cart/cart_widgets.dart';
import 'products_cubit.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<ProductsCubit>()..start(), child: const ProductsView());
}

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: const [_SortMenu(), CartBadgeButton()],
        bottom: const PreferredSize(preferredSize: Size.fromHeight(56), child: _Filters()),
      ),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        buildWhen: (a, b) => a.status != b.status || a.visible != b.visible || a.error != b.error,
        builder: (context, state) => switch (state.status) {
          ViewStatus.initial || ViewStatus.loading => const LoadingView(),
          ViewStatus.failure => ErrorView(
            message: state.error?.userMessage ?? 'Something went wrong',
            onRetry: context.read<ProductsCubit>().retry,
          ),
          ViewStatus.success when state.visible.isEmpty => const EmptyView(
            message: 'No products match these filters',
          ),
          ViewStatus.success => LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              padding: const EdgeInsets.all(12),
              // Responsive: more columns on tablets and web.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (constraints.maxWidth / 220).floor().clamp(2, 6),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: state.visible.length,
              itemBuilder: (context, i) {
                final product = state.visible[i];
                return ProductCard(key: ValueKey(product.id), product: product);
              },
            ),
          ),
        },
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      buildWhen: (a, b) =>
          a.categories != b.categories ||
          a.category != b.category ||
          a.inStockOnly != b.inStockOnly,
      builder: (context, state) {
        final cubit = context.read<ProductsCubit>();
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              FilterChip(
                label: const Text('In stock'),
                selected: state.inStockOnly,
                onSelected: cubit.setInStockOnly,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All'),
                selected: state.category == null,
                onSelected: (_) => cubit.selectCategory(null),
              ),
              for (final c in state.categories) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(c.name),
                  selected: state.category == c.slug,
                  onSelected: (_) => cubit.selectCategory(c.slug),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    final sort = context.select((ProductsCubit c) => c.state.sort);
    return PopupMenuButton<ProductSort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort),
      initialValue: sort,
      onSelected: context.read<ProductsCubit>().sortBy,
      itemBuilder: (_) => [
        for (final s in ProductSort.values) PopupMenuItem(value: s, child: Text(s.label)),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}', extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ProductImage(url: product.thumbnail)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(formatCents(product.priceCents), style: text.titleMedium),
                  const Spacer(),
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(product.rating.toStringAsFixed(1), style: text.bodySmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Center(child: AddToCartControl(product: product)),
            ),
          ],
        ),
      ),
    );
  }
}
