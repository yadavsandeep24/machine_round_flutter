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
