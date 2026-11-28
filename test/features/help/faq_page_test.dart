import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/features/help/presentation/faq_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, {String? open}) async {
    await tester.pumpWidget(MaterialApp(home: FaqPage(initiallyOpen: open)));
    await tester.pumpAndSettle();
  }

  // Collapsed bodies are wrapped in Offstage by Expansible, so default finders skip them.
  Finder answer(String id) => find.byKey(Key('faq-answer-$id'));

  testWidgets('tapping a header expands its answer and rotates the chevron', (tester) async {
    await pumpPage(tester);
    expect(answer('declined'), findsNothing);

    await tester.tap(find.byKey(const Key('faq-header-declined')));
    await tester.pumpAndSettle();

    expect(answer('declined'), findsOneWidget);
    final turns = tester.widget<RotationTransition>(
      find.descendant(of: find.byKey(const Key('faq-header-declined')), matching: find.byType(RotationTransition)),
    );
    expect(turns.turns.value, 0.5);
  });

  testWidgets('accordion: opening a second item collapses the first', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('faq-header-declined')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('faq-header-pending')));
    await tester.pumpAndSettle();

    expect(answer('declined'), findsNothing);
    expect(answer('pending'), findsOneWidget);
  });

  testWidgets('deep link opens the target answer on first frame', (tester) async {
    await pumpPage(tester, open: 'refund-time');
    expect(answer('refund-time'), findsOneWidget);
    expect(answer('declined'), findsNothing);
  });

  testWidgets('expand all and collapse all drive every controller', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Expand all'));
    await tester.pumpAndSettle();
    expect(answer('declined'), findsOneWidget);
    expect(answer('pending'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pumpAndSettle();
    expect(answer('declined'), findsNothing);
    expect(answer('pending'), findsNothing);
  });

  testWidgets('search filters the list and keeps open state by id', (tester) async {
    await pumpPage(tester, open: 'card-safe');

    await tester.enterText(find.byKey(const Key('faq-search')), 'card');
    await tester.pumpAndSettle();

    expect(find.text('Why was my payment declined?'), findsNothing);
    expect(answer('card-safe'), findsOneWidget);
  });

  testWidgets('empty search result shows a message', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('faq-search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching questions'), findsOneWidget);
  });

  group('before vs after', () {
    testWidgets('BEFORE: Material ExpansionTile driven by a controller', (tester) async {
      // ExpansionTileController is now a deprecated alias of ExpansibleController (Flutter 3.32),
      // so the same controller type works with both the Material tile and the new widget.
      final controller = ExpansibleController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpansionTile(controller: controller, title: const Text('Q'), children: const [Text('A')]),
          ),
        ),
      );

      expect(find.text('A'), findsNothing);
      controller.expand();
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('AFTER: bare Expansible with no Material styling', (tester) async {
      final controller = ExpansibleController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Expansible(
            controller: controller,
            headerBuilder: (context, animation) => const Text('Q'),
            bodyBuilder: (context, animation) => const Text('A'),
          ),
        ),
      );

      expect(find.text('A'), findsNothing);
      controller.expand();
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(controller.isExpanded, isTrue);
    });
  });
}
