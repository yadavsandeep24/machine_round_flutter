part of 'posts_bloc.dart';

class PostsState extends Equatable {
  const PostsState({
    this.status = ViewStatus.loading,
    this.posts = const [],
    this.isRefreshing = false,
    this.error,
  });

  final ViewStatus status;
  final List<Post> posts;
  final bool isRefreshing;

  /// Full-screen error when [posts] is empty, otherwise shown as a snackbar
  /// over cached data.
  final AppException? error;

  PostsState copyWith({
    ViewStatus? status,
    List<Post>? posts,
    bool? isRefreshing,
    AppException? Function()? error,
  }) => PostsState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [status, posts, isRefreshing, error];
}
