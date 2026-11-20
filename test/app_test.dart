import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:machine_round/app.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/auth/data/auth_api.dart';
import 'package:machine_round/features/auth/data/auth_repository.dart';
import 'package:machine_round/features/auth/data/token_store.dart';
import 'package:machine_round/features/auth/presentation/auth_cubit.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('app renders an injected router', (tester) async {
    final dio = Dio();
    final auth = AuthCubit(
      AuthRepository(api: AuthApi(dio), tokens: TokenStore(InMemoryStore()), authedDio: dio),
    );
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const Text('home'))],
    );
    await tester.pumpWidget(App(router: router, authCubit: auth));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
