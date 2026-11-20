import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/main.dart';

void main() {
  testWidgets('blank app renders', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Start here'), findsOneWidget);
  });
}
