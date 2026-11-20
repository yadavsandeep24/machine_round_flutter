import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/features/users/presentation/users_cubit.dart';
import 'package:machine_round/features/users/presentation/users_page.dart';

import 'fake_user_repository.dart';

Widget _host(FakeUserRepository repo) => MaterialApp(
  home: BlocProvider(create: (_) => UsersCubit(repo)..load(), child: const UsersView()),
);

void main() {
  setUp(UserRow.debugBuilds.clear);

  testWidgets('loading, then success', (tester) async {
    await tester.pumpWidget(_host(FakeUserRepository()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('User 1'), findsOneWidget);
  });

  testWidgets('error, then retry', (tester) async {
    final repo = FakeUserRepository()..failWith = const ServerException(500);
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    repo.failWith = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('User 1'), findsOneWidget);
  });

  testWidgets('liking a user rebuilds only its heart, not the rows', (tester) async {
    await tester.pumpWidget(_host(FakeUserRepository()));
    await tester.pumpAndSettle();
    final before = Map.of(UserRow.debugBuilds);

    await tester.tap(find.byTooltip('Like').first);
    await tester.pump();

    expect(UserRow.debugBuilds, before, reason: 'no UserRow should rebuild');
    expect(find.byTooltip('Unlike'), findsOneWidget);
    expect(find.text('Users · 1 liked'), findsOneWidget);
  });

  testWidgets('search shows an empty state', (tester) async {
    await tester.pumpWidget(_host(FakeUserRepository()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump();
    expect(find.text('No users match "nobody"'), findsOneWidget);
  });
}
