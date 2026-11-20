import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/ui/view_status.dart';
import 'package:machine_round/features/posts/presentation/list/posts_bloc.dart';

import '../../helpers/fake_post_repository.dart';

const _debounce = Duration(milliseconds: 50);
Future<void> _wait([int ms = 80]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late FakePostRepository repo;
  setUp(() {
    repo = FakePostRepository()
      ..remote = [
        fakePost(1, title: 'Flutter tips'),
        fakePost(2, title: 'Dart streams'),
        fakePost(3, title: 'Flutter bloc'),
      ];
  });

  PostsBloc build() => PostsBloc(repo, debounce: _debounce);

  blocTest<PostsBloc, PostsState>(
    'debounces fast typing into one request',
    build: build,
    act: (bloc) async {
      bloc
        ..add(const PostsQueryChanged('f'))
        ..add(const PostsQueryChanged('fl'))
        ..add(const PostsQueryChanged('flutter'));
      await _wait();
    },
    verify: (bloc) {
      expect(repo.searchedQueries, ['flutter']);
      expect(bloc.state.searchResults.map((p) => p.id), [1, 3]);
      expect(bloc.state.searchStatus, ViewStatus.success);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'a newer query cancels a slow older one (no stale overwrite)',
    setUp: () => repo.searchDelays = {'dart': const Duration(milliseconds: 200)},
    build: build,
    act: (bloc) async {
      bloc.add(const PostsQueryChanged('dart'));
      await _wait(); // 'dart' request is now in flight
      bloc.add(const PostsQueryChanged('flutter'));
      await _wait(300); // 'dart' would have finished by now
    },
    verify: (bloc) {
      expect(repo.searchedQueries, ['dart', 'flutter']);
      expect(bloc.state.query, 'flutter');
      expect(bloc.state.searchResults.map((p) => p.id), [1, 3]);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'retyping the same query does not search again',
    build: build,
    act: (bloc) async {
      bloc.add(const PostsQueryChanged('dart'));
      await _wait();
      bloc.add(const PostsQueryChanged('dar'));
      bloc.add(const PostsQueryChanged('dart '));
      await _wait();
    },
    verify: (_) => expect(repo.searchedQueries, ['dart']),
  );

  blocTest<PostsBloc, PostsState>(
    'clearing is instant and returns to browse mode',
    build: build,
    act: (bloc) async {
      bloc.add(const PostsQueryChanged('dart'));
      await _wait();
      bloc.add(const PostsQueryChanged(''));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.isSearching, isFalse);
      expect(bloc.state.searchResults, isEmpty);
    },
  );

  blocTest<PostsBloc, PostsState>(
    'error then retry with the same query',
    setUp: () => repo.searchFailWith = const NoInternetException(),
    build: build,
    act: (bloc) async {
      bloc.add(const PostsQueryChanged('dart'));
      await _wait();
      repo.searchFailWith = null;
      bloc.add(const PostsQueryChanged('dart', force: true));
      await _wait();
    },
    verify: (bloc) {
      expect(repo.searchedQueries, ['dart', 'dart']);
      expect(bloc.state.searchStatus, ViewStatus.success);
      expect(bloc.state.searchError, isNull);
    },
  );
}
