import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/app.dart';

void main() {
  testWidgets('app shell renders the home route', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('Machine Round'), findsOneWidget);
  });
}
