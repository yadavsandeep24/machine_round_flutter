import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/app.dart';
import 'package:machine_round/core/router/app_router.dart';

void main() {
  testWidgets('app shell renders the help page on the home route', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('Payments help'), findsOneWidget);
  });

  testWidgets('deep link query parameter opens an answer', (tester) async {
    await tester.pumpWidget(App(router: buildRouter(initialLocation: '/?open=pending')));
    await tester.pumpAndSettle();
    expect(find.textContaining('settle within 48 hours'), findsOneWidget);
  });
}
