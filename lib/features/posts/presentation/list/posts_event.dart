part of 'posts_bloc.dart';

sealed class PostsEvent {
  const PostsEvent();
}

/// Starts observing the cache and triggers the first refresh.
final class PostsStarted extends PostsEvent {
  const PostsStarted();
}

/// Pull-to-refresh or Retry.
final class PostsRefreshed extends PostsEvent {
  const PostsRefreshed();
}
