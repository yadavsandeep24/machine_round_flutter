import 'dart:async';

import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/result/result.dart';
import 'package:machine_round/features/posts/domain/comment.dart';
import 'package:machine_round/features/posts/domain/post.dart';
import 'package:machine_round/features/posts/domain/post_repository.dart';

Post fakePost(int id, {String? title}) =>
    Post(id: id, userId: 1, title: title ?? 'Post $id', body: 'Body $id');

/// In-memory repository honoring the same contract as the real one.
class FakePostRepository implements PostRepository {
  FakePostRepository({List<Post> cached = const []}) : _cache = cached;

  List<Post> _cache;
  final _changes = StreamController<List<Post>>.broadcast(sync: true);

  /// What the next refresh returns from the "network".
  List<Post> remote = List.generate(20, (i) => fakePost(i + 1));
  AppException? failWith;
  int refreshCalls = 0;
  Completer<void>? gate;

  @override
  Stream<List<Post>> watchPosts() async* {
    yield _cache;
    yield* _changes.stream;
  }

  @override
  Future<Result<void>> refresh() async {
    refreshCalls++;
    await gate?.future;
    final error = failWith;
    if (error != null) return Failure(error);
    _cache = remote;
    _changes.add(_cache);
    return const Success(null);
  }

  /// Posts only the "network" knows about (not in the cache).
  Map<int, Post> remoteById = {};
  AppException? commentsFailWith;
  AppException? postFailWith;

  @override
  Future<Result<Post>> getPost(int id) async {
    for (final p in _cache) {
      if (p.id == id) return Success(p);
    }
    if (postFailWith != null) return Failure(postFailWith!);
    final remotePost = remoteById[id];
    return remotePost != null ? Success(remotePost) : const Failure(NotFoundException());
  }

  @override
  Future<Result<List<Comment>>> getComments(int postId) async {
    if (commentsFailWith != null) return Failure(commentsFailWith!);
    return Success([Comment(id: postId * 10, name: 'Commenter', email: 'a@b.c', body: 'Nice')]);
  }
}
