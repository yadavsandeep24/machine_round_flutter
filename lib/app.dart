import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'features/favorites/favorites_cubit.dart';
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
    // App-wide blocs live above the router so every route shares them.
    // BlocProvider is lazy: the cubit is created on first read.
    return BlocProvider(
      create: (_) => sl<FavoritesCubit>(),
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
