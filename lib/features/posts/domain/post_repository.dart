import '../../../core/result/result.dart';
import 'post.dart';

/// Owned by the domain, implemented by the data layer.
/// Offline-first: the UI only observes [watchPosts]; the network only writes
/// into the cache.
abstract interface class PostRepository {
  Stream<List<Post>> watchPosts();

  /// Fetches the first page from the network and replaces the cache.
  Future<Result<void>> refresh();
}
