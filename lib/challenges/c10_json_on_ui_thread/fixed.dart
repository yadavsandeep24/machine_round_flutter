import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'shared.dart';

/// Moves heavy CPU work to a background isolate so the UI keeps 60 fps.
/// `compute` also works on the web (it runs inline there), `Isolate.run`
/// does not. Dio users: set a custom `Transformer` that decodes in compute.
Future<List<Product>> parseProductsInBackground(String body) => compute(parseProducts, body);

/// FAST: same work, done off the UI isolate. The spinner keeps spinning.
class CatalogFixed extends StatefulWidget {
  const CatalogFixed({super.key});

  @override
  State<CatalogFixed> createState() => _CatalogFixedState();
}

class _CatalogFixedState extends State<CatalogFixed> {
  late final String _body = buildCatalogJson(60000);
  String _status = 'Tap Load and watch the spinner';

  Future<void> _load() async {
    final watch = Stopwatch()..start();
    final products = await parseProductsInBackground(_body);
    if (!mounted) return;
    setState(() => _status = 'Parsed ${products.length} in ${watch.elapsedMilliseconds} ms');
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(_status),
      const SizedBox(height: 16),
      FilledButton(onPressed: _load, child: const Text('Load')),
    ],
  );
}
