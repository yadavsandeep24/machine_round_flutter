import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/features/transactions/data/in_memory_txn_repository.dart';
import 'package:machine_round/features/transactions/presentation/txn_search_cubit.dart';
import 'package:machine_round/features/transactions/presentation/txn_search_page.dart';

void main() {
  Future<TxnSearchCubit> pumpPage(WidgetTester tester) async {
    final cubit = TxnSearchCubit(InMemoryTxnRepository(latency: Duration.zero));
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const TxnSearchView()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('no active-filter chips when nothing is filtered', (tester) async {
    await pumpPage(tester);

    expect(find.byType(InputChip), findsNothing);
    expect(find.text('Clear all'), findsNothing);
    expect(find.text('Swiggy'), findsOneWidget);
  });

  testWidgets('only the filters that are set get a chip', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'failed'));
    await tester.pumpAndSettle();

    expect(find.byType(InputChip), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Status: failed'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);
    expect(find.text('Swiggy'), findsNothing);

    await tester.enterText(find.byKey(const Key('txn-search')), 'irc');
    await tester.pumpAndSettle();

    expect(find.byType(InputChip), findsNWidgets(2));
    expect(find.text('IRCTC'), findsOneWidget);
  });

  testWidgets('deleting a chip removes that filter', (tester) async {
    final cubit = await pumpPage(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Over Rs 1,000'));
    await tester.pumpAndSettle();
    expect(cubit.state.filter.minAmountPaise, isNotNull);

    await tester.tap(find.descendant(of: find.byType(InputChip), matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();

    expect(cubit.state.filter.minAmountPaise, isNull);
    expect(find.byType(InputChip), findsNothing);
  });
}
