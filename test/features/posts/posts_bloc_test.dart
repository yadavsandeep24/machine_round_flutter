import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/ui/view_status.dart';
import 'package:machine_round/features/posts/presentation/list/posts_bloc.dart';

import '../../helpers/fake_post_repository.dart';

void main() {
  late FakePostRepository repo;

  setUp(() => repo = FakePostRepository());

  blocTest<PostsBloc, PostsState>(
    'loads from network into an empty cache',
    build: () => PostsBloc(repo),
    act: (bloc) => bloc.add(const PostsStarted()),
    verify: (bloc) {
      expect(bloc.state.status, ViewStatus.success);
      expect(bloc.state.posts, hasLength(20));
      expect(bloc.state.isRefreshing, isFalse);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'network error with empty cache shows full-screen failure',
    setUp: () => repo.failWith = const NoInternetException(),
    build: () => PostsBloc(repo),
    act: (bloc) => bloc.add(const PostsStarted()),
    verify: (bloc) {
      expect(bloc.state.status, ViewStatus.failure);
      expect(bloc.state.error, isA<NoInternetException>());
    },
  );

  blocTest<PostsBloc, PostsState>(
    'network error with cached data keeps the data and reports the error',
    setUp: () {
      repo = FakePostRepository(cached: [fakePost(99)]);
      repo.failWith = const TimeoutAppException();
    },
    build: () => PostsBloc(repo),
    act: (bloc) => bloc.add(const PostsStarted()),
    verify: (bloc) {
      expect(bloc.state.status, ViewStatus.success);
      expect(bloc.state.posts.single.id, 99);
      expect(bloc.state.error, isA<TimeoutAppException>());
    },
  );

  blocTest<PostsBloc, PostsState>(
    'retry after failure recovers',
    setUp: () => repo.failWith = const NoInternetException(),
    build: () => PostsBloc(repo),
    act: (bloc) async {
      bloc.add(const PostsStarted());
      await Future<void>.delayed(Duration.zero);
      repo.failWith = null;
      bloc.add(const PostsRefreshed());
    },
    verify: (bloc) {
      expect(bloc.state.status, ViewStatus.success);
      expect(bloc.state.error, isNull);
      expect(bloc.state.posts, hasLength(20));
    },
  );

  blocTest<PostsBloc, PostsState>(
    'refresh taps while one is in flight are dropped',
    setUp: () => repo.gate = Completer<void>(),
    build: () => PostsBloc(repo),
    act: (bloc) async {
      bloc.add(const PostsStarted());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const PostsRefreshed())
        ..add(const PostsRefreshed());
      await Future<void>.delayed(Duration.zero);
      repo.gate!.complete();
    },
    verify: (bloc) {
      expect(repo.refreshCalls, 1);
      expect(bloc.state.posts, hasLength(20));
    },
  );
}
