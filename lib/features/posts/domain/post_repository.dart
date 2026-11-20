import '../../../core/result/result.dart';
import 'comment.dart';
import 'page_result.dart';
import 'post.dart';

/// Owned by the domain, implemented by the data layer.
/// Offline-first: the UI only observes [watchPosts]; the network only writes
/// into the cache.
abstract interface class PostRepository {
  Stream<List<Post>> watchPosts();

  /// Fetches page 1 and replaces the cache.
  Future<Result<PageResult>> refresh();

  /// Fetches [page] (2, 3, ...) and appends it to the cache.
  Future<Result<PageResult>> loadPage(int page);

  /// Cache first; falls back to the network for posts that are not cached
  /// (for example a deep link or a search result).
  Future<Result<Post>> getPost(int id);

  Future<Result<List<Comment>>> getComments(int postId);

  /// Server-side search. Not cached: results go straight to the UI.
  Future<Result<List<Post>>> search(String query);
}
