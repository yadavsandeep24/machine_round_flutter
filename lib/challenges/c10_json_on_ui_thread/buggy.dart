import 'package:flutter/material.dart';

import 'shared.dart';

/// SLOW: parsing a big response on the UI isolate. jsonDecode + mapping
/// 60k objects takes hundreds of ms; the frame budget is 16 ms (8 ms at
/// 120 Hz), so the spinner freezes and taps are ignored ("jank").
class CatalogBuggy extends StatefulWidget {
  const CatalogBuggy({super.key});

  @override
  State<CatalogBuggy> createState() => _CatalogBuggyState();
}

class _CatalogBuggyState extends State<CatalogBuggy> {
  late final String _body = buildCatalogJson(60000);
  String _status = 'Tap Load and watch the spinner';

  Future<void> _load() async {
    final watch = Stopwatch()..start();
    final products = parseProducts(_body); // blocks the UI thread
    setState(() => _status = 'Parsed ${products.length} in ${watch.elapsedMilliseconds} ms');
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(), // freezes while parsing
      const SizedBox(height: 16),
      Text(_status),
      const SizedBox(height: 16),
      FilledButton(onPressed: _load, child: const Text('Load')),
    ],
  );
}
