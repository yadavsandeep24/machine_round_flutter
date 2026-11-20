import 'package:dio/dio.dart';

import '../domain/post.dart';

class PostApi {
  PostApi(this._dio);
  final Dio _dio;

  Future<List<Post>> getPosts({int page = 1, int limit = 20, String? query}) async {
    final response = await _dio.get<List<dynamic>>(
      'posts',
      queryParameters: {
        '_page': page,
        '_limit': limit,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return (response.data ?? const [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Post> getPost(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('posts/$id');
    return Post.fromJson(response.data!);
  }
}
