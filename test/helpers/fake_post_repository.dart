import 'dart:async';

import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/result/result.dart';
import 'package:machine_round/features/posts/domain/comment.dart';
import 'package:machine_round/features/posts/domain/page_result.dart';
import 'package:machine_round/features/posts/domain/post.dart';
import 'package:machine_round/features/posts/domain/post_repository.dart';

Post fakePost(int id, {String? title}) =>
    Post(id: id, userId: 1, title: title ?? 'Post $id', body: 'Body $id');

/// In-memory repository honoring the same contract as the real one.
class FakePostRepository implements PostRepository {
  FakePostRepository({List<Post> cached = const []}) : _cache = cached;

  List<Post> _cache;
  final _changes = StreamController<List<Post>>.broadcast(sync: true);

  static const pageSize = 20;

  /// The whole "server" data set, served in pages of [pageSize].
  List<Post> remote = List.generate(45, (i) => fakePost(i + 1));
  AppException? failWith;
  AppException? loadMoreFailWith;
  int refreshCalls = 0;
  final List<int> requestedPages = [];
  Completer<void>? gate;

  List<Post> _page(int page) => remote.skip((page - 1) * pageSize).take(pageSize).toList();

  @override
  Stream<List<Post>> watchPosts() async* {
    yield _cache;
    yield* _changes.stream;
  }

  @override
  Future<Result<PageResult>> refresh() async {
    refreshCalls++;
    await gate?.future;
    final error = failWith;
    if (error != null) return Failure(error);
    _cache = _page(1);
    _changes.add(_cache);
    return Success(PageResult(endReached: _cache.length < pageSize));
  }

  @override
  Future<Result<PageResult>> loadPage(int page) async {
    requestedPages.add(page);
    await gate?.future;
    final error = loadMoreFailWith;
    if (error != null) return Failure(error);
    final items = _page(page);
    _cache = [..._cache, ...items];
    _changes.add(_cache);
    return Success(PageResult(endReached: items.length < pageSize));
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

  final List<String> searchedQueries = [];
  AppException? searchFailWith;

  /// Per-query artificial latency, to test that a stale response is dropped.
  Map<String, Duration> searchDelays = {};

  @override
  Future<Result<List<Post>>> search(String query) async {
    searchedQueries.add(query);
    final delay = searchDelays[query];
    if (delay != null) await Future<void>.delayed(delay);
    if (searchFailWith != null) return Failure(searchFailWith!);
    return Success(
      remote.where((p) => p.title.toLowerCase().contains(query.toLowerCase())).toList(),
    );
  }
}
