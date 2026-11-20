import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/todos/data/todo_local_store.dart';
import 'package:machine_round/features/todos/data/todo_remote.dart';
import 'package:machine_round/features/todos/data/todo_repository.dart';
import 'package:machine_round/features/todos/presentation/todos_cubit.dart';
import 'package:machine_round/features/todos/presentation/todos_page.dart';
import 'package:machine_round/features/todos/sync/connectivity.dart';
import 'package:machine_round/features/todos/sync/sync_engine.dart';

void main() {
  testWidgets('adding offline shows the pending banner; going online clears it', (tester) async {
    final conn = ManualConnectivity(online: false);
    final remote = FakeTodoRemote(latency: Duration.zero);
    final local = TodoLocalStore(InMemoryStore());
    final engine = SyncEngine(local: local, remote: remote, connectivity: conn);
    final repo = TodoRepository(local, engine);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TodosCubit(repo, conn),
          child: TodosView(connectivity: conn, remote: remote),
        ),
      ),
    );
    expect(find.text('Nothing to do'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Write tests');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Write tests'), findsOneWidget);
    expect(find.textContaining('will sync when you reconnect'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.runAsync(engine.sync);
    await tester.pumpAndSettle();
    expect(find.textContaining('will sync'), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    expect(remote.server, hasLength(1));
    await tester.runAsync(engine.dispose);
  });
}
