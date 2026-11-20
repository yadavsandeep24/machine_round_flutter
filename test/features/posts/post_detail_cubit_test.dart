import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/features/posts/presentation/detail/post_detail_cubit.dart';

import '../../helpers/fake_post_repository.dart';

void main() {
  blocTest<PostDetailCubit, PostDetailState>(
    'loads a cached post with its comments',
    build: () => PostDetailCubit(FakePostRepository(cached: [fakePost(1)]), 1),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PostDetailLoading>(),
      isA<PostDetailLoaded>()
          .having((s) => s.post.id, 'post id', 1)
          .having((s) => s.comments, 'comments', hasLength(1)),
    ],
  );

  blocTest<PostDetailCubit, PostDetailState>(
    'falls back to the network for an uncached post',
    build: () => PostDetailCubit(FakePostRepository()..remoteById = {7: fakePost(7)}, 7),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect((cubit.state as PostDetailLoaded).post.id, 7),
  );

  blocTest<PostDetailCubit, PostDetailState>(
    'missing post shows an error',
    build: () => PostDetailCubit(FakePostRepository(), 404),
    act: (cubit) => cubit.load(),
    verify: (cubit) => expect(
      cubit.state,
      isA<PostDetailError>().having((s) => s.error, 'error', isA<NotFoundException>()),
    ),
  );

  blocTest<PostDetailCubit, PostDetailState>(
    'comments failure still shows the post',
    build: () => PostDetailCubit(
      FakePostRepository(cached: [fakePost(1)])..commentsFailWith = const ServerException(500),
      1,
    ),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final state = cubit.state as PostDetailLoaded;
      expect(state.comments, isEmpty);
      expect(state.commentsError, isA<ServerException>());
    },
  );
}
