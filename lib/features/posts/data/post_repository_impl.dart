import '../../../core/network/safe_call.dart';
import '../../../core/result/result.dart';
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

  @override
  Future<Result<void>> refresh() => safeCall(() async {
    final posts = await _api.getPosts(page: 1, limit: pageSize);
    await _local.replaceAll(posts);
  });
}
