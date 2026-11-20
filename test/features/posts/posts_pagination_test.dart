import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/features/posts/presentation/list/posts_bloc.dart';

import '../../helpers/fake_post_repository.dart';

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePostRepository repo;
  setUp(() => repo = FakePostRepository());

  blocTest<PostsBloc, PostsState>(
    'loads pages until the end is reached (45 items = 20 + 20 + 5)',
    build: () => PostsBloc(repo),
    act: (bloc) async {
      bloc.add(const PostsStarted());
      await _tick();
      bloc.add(const PostsNextPageRequested());
      await _tick();
      bloc.add(const PostsNextPageRequested());
      await _tick();
      bloc.add(const PostsNextPageRequested()); // ignored: end reached
    },
    verify: (bloc) {
      expect(bloc.state.posts, hasLength(45));
      expect(bloc.state.hasReachedEnd, isTrue);
      expect(repo.requestedPages, [2, 3]);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'load-more error is shown in the footer and blocks auto-retry',
    build: () => PostsBloc(repo),
    act: (bloc) async {
      bloc.add(const PostsStarted());
      await _tick();
      repo.loadMoreFailWith = const NoInternetException();
      bloc.add(const PostsNextPageRequested());
      await _tick();
      bloc.add(const PostsNextPageRequested()); // scroll again: ignored
    },
    verify: (bloc) {
      expect(bloc.state.loadMoreError, isA<NoInternetException>());
      expect(bloc.state.posts, hasLength(20));
      expect(repo.requestedPages, [2]);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'footer retry loads the page again',
    build: () => PostsBloc(repo),
    act: (bloc) async {
      bloc.add(const PostsStarted());
      await _tick();
      repo.loadMoreFailWith = const NoInternetException();
      bloc.add(const PostsNextPageRequested());
      await _tick();
      repo.loadMoreFailWith = null;
      bloc.add(const PostsNextPageRequested(isRetry: true));
    },
    verify: (bloc) {
      expect(bloc.state.loadMoreError, isNull);
      expect(bloc.state.posts, hasLength(40));
      expect(repo.requestedPages, [2, 2]);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'refresh resets paging to page 2',
    build: () => PostsBloc(repo),
    act: (bloc) async {
      bloc.add(const PostsStarted());
      await _tick();
      bloc.add(const PostsNextPageRequested());
      await _tick();
      bloc.add(const PostsRefreshed());
      await _tick();
      bloc.add(const PostsNextPageRequested());
    },
    verify: (bloc) {
      expect(repo.requestedPages, [2, 2]);
      expect(bloc.state.nextPage, 3);
    },
  );
}
