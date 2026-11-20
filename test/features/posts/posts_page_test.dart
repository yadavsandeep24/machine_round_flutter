import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/features/posts/presentation/list/posts_bloc.dart';
import 'package:machine_round/features/posts/presentation/list/posts_page.dart';

import '../../helpers/fake_post_repository.dart';

/// The widget tree owns the bloc, so it is closed when the tree is disposed.
/// Do not `await bloc.close()` inside testWidgets: a bloc whose transformer
/// uses switchMap/asyncExpand never finishes closing in the fake-async zone.
Widget _host(FakePostRepository repo) => MaterialApp(
  home: BlocProvider(
    create: (_) => PostsBloc(repo, debounce: Duration.zero)..add(const PostsStarted()),
    child: const PostsView(),
  ),
);

void main() {
  testWidgets('shows posts after loading', (tester) async {
    await tester.pumpWidget(_host(FakePostRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
  });

  testWidgets('shows error with retry, and retry recovers', (tester) async {
    final repo = FakePostRepository()..failWith = const NoInternetException();
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();
    expect(find.text(const NoInternetException().userMessage), findsOneWidget);

    repo.failWith = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(_host(FakePostRepository()..remote = []));
    await tester.pumpAndSettle();
    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('typing searches and clearing returns to the list', (tester) async {
    await tester.pumpWidget(_host(FakePostRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Post 42');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Post 42'), findsOneWidget);
    expect(find.text('Post 1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results for "zzz"'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
  });
}
