import '../../../core/network/safe_call.dart';
import '../../../core/result/result.dart';
import '../domain/comment.dart';
import '../domain/page_result.dart';
import '../domain/post.dart';
import '../domain/post_repository.dart';
import 'post_api.dart';
import 'post_local_source.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._api, this._local);

  static const pageSize = 20;

  final PostApi _api;
  final PostLocalSource _local;

  @override
  Stream<List<Post>> watchPosts() => _local.watch();

  /// Bumped by every refresh. A load-more that started under an older
  /// generation must not append onto the new first page.
  int _generation = 0;

  @override
  Future<Result<PageResult>> refresh() => safeCall(() async {
    final generation = ++_generation;
    final posts = await _api.getPosts(page: 1, limit: pageSize);
    if (generation != _generation) return const PageResult(endReached: false, stale: true);
    await _local.replaceAll(posts);
    return PageResult(endReached: posts.length < pageSize);
  });

  @override
  Future<Result<PageResult>> loadPage(int page) => safeCall(() async {
    final generation = _generation;
    final posts = await _api.getPosts(page: page, limit: pageSize);
    if (generation != _generation) return const PageResult(endReached: false, stale: true);
    // Dedupe by id: the server may shift items between pages.
    final merged = {for (final p in _local.read()) p.id: p, for (final p in posts) p.id: p};
    await _local.replaceAll(merged.values.toList());
    return PageResult(endReached: posts.length < pageSize);
  });

  @override
  Future<Result<Post>> getPost(int id) async {
    for (final post in _local.read()) {
      if (post.id == id) return Success(post);
    }
    return safeCall(() => _api.getPost(id));
  }

  @override
  Future<Result<List<Comment>>> getComments(int postId) => safeCall(() => _api.getComments(postId));

  @override
  Future<Result<List<Post>>> search(String query) =>
      safeCall(() => _api.getPosts(page: 1, limit: pageSize, query: query));
}
