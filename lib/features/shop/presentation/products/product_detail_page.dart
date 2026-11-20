import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/result/result.dart';
import '../../../../core/ui/widgets/state_views.dart';
import '../../domain/models.dart';
import '../../domain/shop_repository.dart';
import '../cart/cart_widgets.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.productId, this.initial, super.key});

  final int productId;
  final Product? initial;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Result<Product>> _future = _load();

  Future<Result<Product>> _load() async => widget.initial != null
      ? Success(widget.initial!)
      : sl<ShopRepository>().getProduct(widget.productId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product'), actions: const [CartBadgeButton()]),
      body: FutureBuilder<Result<Product>>(
        future: _future,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const LoadingView(),
          Failure(:final error) => ErrorView(
            message: error.userMessage,
            onRetry: () => setState(() => _future = _load()),
          ),
          Success(data: final p) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(aspectRatio: 1, child: ProductImage(url: p.thumbnail)),
              const SizedBox(height: 16),
              Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(formatCents(p.priceCents), style: Theme.of(context).textTheme.titleLarge),
              Text('${p.stock} in stock · ★ ${p.rating.toStringAsFixed(1)}'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: AddToCartControl(product: p),
              ),
            ],
          ),
        },
      ),
    );
  }
}
