part of 'posts_bloc.dart';

class PostsState extends Equatable {
  const PostsState({
    this.status = ViewStatus.loading,
    this.posts = const [],
    this.isRefreshing = false,
    this.error,
    this.nextPage = 2,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.loadMoreError,
    this.query = '',
    this.searchStatus = ViewStatus.initial,
    this.searchResults = const [],
    this.searchError,
  });

  final ViewStatus status;
  final List<Post> posts;
  final bool isRefreshing;

  /// Full-screen error when [posts] is empty, otherwise shown as a snackbar
  /// over cached data.
  final AppException? error;

  final int nextPage;
  final bool isLoadingMore;
  final bool hasReachedEnd;

  /// Shown in the list footer. While set, scrolling does not retry
  /// automatically; the user taps Retry.
  final AppException? loadMoreError;

  /// The trimmed query the search results belong to. Empty means browse mode.
  final String query;
  final ViewStatus searchStatus;
  final List<Post> searchResults;
  final AppException? searchError;

  bool get isSearching => query.isNotEmpty;

  PostsState copyWith({
    ViewStatus? status,
    List<Post>? posts,
    bool? isRefreshing,
    AppException? Function()? error,
    int? nextPage,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    AppException? Function()? loadMoreError,
    String? query,
    ViewStatus? searchStatus,
    List<Post>? searchResults,
    AppException? Function()? searchError,
  }) => PostsState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    error: error != null ? error() : this.error,
    nextPage: nextPage ?? this.nextPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
    query: query ?? this.query,
    searchStatus: searchStatus ?? this.searchStatus,
    searchResults: searchResults ?? this.searchResults,
    searchError: searchError != null ? searchError() : this.searchError,
  );

  @override
  List<Object?> get props => [
    status,
    posts,
    isRefreshing,
    error,
    nextPage,
    isLoadingMore,
    hasReachedEnd,
    loadMoreError,
    query,
    searchStatus,
    searchResults,
    searchError,
  ];
}
