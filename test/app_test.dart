import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:machine_round/app.dart';

void main() {
  testWidgets('app renders an injected router', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('home'))],
    );
    await tester.pumpWidget(App(router: router));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
