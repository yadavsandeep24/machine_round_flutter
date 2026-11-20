import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/';
}

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.home,
  routes: [GoRoute(path: Routes.home, builder: (context, state) => const _HomePlaceholder())],
);

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Machine Round')),
    body: const Center(child: Text('Add your first feature in lib/features/')),
  );
}
