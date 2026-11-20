part of 'posts_bloc.dart';

sealed class PostsEvent {
  const PostsEvent();
}

/// Starts observing the cache and triggers the first refresh.
final class PostsStarted extends PostsEvent {
  const PostsStarted();
}

/// Pull-to-refresh or full-screen Retry.
final class PostsRefreshed extends PostsEvent {
  const PostsRefreshed();
}

/// The user scrolled near the end of the list, or tapped Retry in the footer.
final class PostsNextPageRequested extends PostsEvent {
  const PostsNextPageRequested({this.isRetry = false});
  final bool isRetry;
}

/// Every keystroke. Debounced (300 ms, blank is instant) and restartable:
/// a newer query cancels the older search.
final class PostsQueryChanged extends PostsEvent {
  const PostsQueryChanged(this.query, {this.force = false});
  final String query;

  /// Retry: run the same query again even though it did not change.
  final bool force;
}
