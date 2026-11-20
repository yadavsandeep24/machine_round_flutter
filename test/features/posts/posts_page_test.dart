import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/features/posts/presentation/list/posts_bloc.dart';
import 'package:machine_round/features/posts/presentation/list/posts_page.dart';

import '../../helpers/fake_post_repository.dart';

Widget _host(PostsBloc bloc) => MaterialApp(
  home: BlocProvider.value(value: bloc, child: const PostsView()),
);

void main() {
  testWidgets('shows posts after loading', (tester) async {
    final bloc = PostsBloc(FakePostRepository())..add(const PostsStarted());
    await tester.pumpWidget(_host(bloc));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
    await bloc.close();
  });

  testWidgets('shows error with retry, and retry recovers', (tester) async {
    final repo = FakePostRepository()..failWith = const NoInternetException();
    final bloc = PostsBloc(repo)..add(const PostsStarted());
    await tester.pumpWidget(_host(bloc));
    await tester.pumpAndSettle();
    expect(find.text(const NoInternetException().userMessage), findsOneWidget);

    repo.failWith = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Post 1'), findsOneWidget);
    await bloc.close();
  });

  testWidgets('shows empty state', (tester) async {
    final repo = FakePostRepository()..remote = [];
    final bloc = PostsBloc(repo)..add(const PostsStarted());
    await tester.pumpWidget(_host(bloc));
    await tester.pumpAndSettle();
    expect(find.text('No posts yet'), findsOneWidget);
    await bloc.close();
  });
}
