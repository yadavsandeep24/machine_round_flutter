import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'features/shop/presentation/cart/cart_cubit.dart';
import 'ui/theme.dart';

class App extends StatefulWidget {
  const App({super.key, this.router});

  /// Tests can inject a router; production builds its own.
  final GoRouter? router;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  Widget build(BuildContext context) {
    // The cart lives above the router: every screen reads the same instance.
    // BlocProvider is lazy, so it is created on first read.
    return BlocProvider(
      create: (_) => sl<CartCubit>(),
      child: MaterialApp.router(
        title: 'Machine Round',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        routerConfig: _router,
      ),
    );
  }
}
