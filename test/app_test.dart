import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/app.dart';

void main() {
  testWidgets('gallery lists the 10 challenges and opens one', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('Bugs & optimisation: top 10'), findsOneWidget);

    await tester.tap(find.text('Missing keys in a dynamic list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixed'));
    await tester.pumpAndSettle();
    expect(find.text('Task A'), findsOneWidget);
    await tester.tap(find.text('Show answer'));
    await tester.pump();
    expect(find.text('Root cause'), findsOneWidget);
  });
}
