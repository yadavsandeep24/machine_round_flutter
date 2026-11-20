import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'ui/theme.dart';

class App extends StatefulWidget {
  const App({super.key, this.router, this.authCubit});

  /// Tests can inject both; production builds them from get_it.
  final GoRouter? router;
  final AuthCubit? authCubit;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _auth = widget.authCubit ?? sl<AuthCubit>();
  late final GoRouter _router = widget.router ?? buildRouter(_auth);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _auth,
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
