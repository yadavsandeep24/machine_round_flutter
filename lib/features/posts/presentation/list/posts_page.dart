import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/ui/view_status.dart';
import '../../../../core/ui/widgets/state_views.dart';
import '../../domain/post.dart';
import 'posts_bloc.dart';

/// Route widget: creates the bloc. [PostsView] stays free of DI so tests can
/// pump it with any bloc.
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<PostsBloc>()..add(const PostsStarted()),
    child: const PostsView(),
  );
}

class PostsView extends StatelessWidget {
  const PostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: BlocConsumer<PostsBloc, PostsState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error && curr.error != null && curr.posts.isNotEmpty,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!.userMessage))),
        builder: (context, state) {
          final bloc = context.read<PostsBloc>();
          return switch (state.status) {
            ViewStatus.initial || ViewStatus.loading => const LoadingView(),
            ViewStatus.failure => ErrorView(
              message: state.error?.userMessage ?? 'Something went wrong',
              onRetry: () => bloc.add(const PostsRefreshed()),
            ),
            ViewStatus.success => RefreshIndicator(
              onRefresh: () {
                bloc.add(const PostsRefreshed());
                return bloc.stream.firstWhere((s) => !s.isRefreshing);
              },
              child: state.posts.isEmpty
                  // Scrollable so pull-to-refresh still works when empty.
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        EmptyView(message: 'No posts yet'),
                      ],
                    )
                  : _PostList(state: state),
            ),
          };
        },
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({required this.state});

  final PostsState state;

  /// Start loading the next page this many pixels before the end.
  static const _prefetchExtent = 400.0;

  @override
  Widget build(BuildContext context) {
    final posts = state.posts;
    final showFooter = !state.hasReachedEnd;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < _prefetchExtent) {
          // droppable() + guards in the bloc make repeated calls harmless.
          context.read<PostsBloc>().add(const PostsNextPageRequested());
        }
        return false;
      },
      child: ListView.separated(
        // Always scrollable so a short first page can still trigger refresh.
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return LoadMoreFooter(
              isLoading: state.isLoadingMore,
              errorMessage: state.loadMoreError?.userMessage,
              onRetry: () =>
                  context.read<PostsBloc>().add(const PostsNextPageRequested(isRetry: true)),
            );
          }
          final post = posts[index];
          return PostTile(
            key: ValueKey(post.id),
            post: post,
            onTap: () => context.go(Routes.postDetail(post.id)),
          );
        },
      ),
    );
  }
}

class PostTile extends StatelessWidget {
  const PostTile({required this.post, this.onTap, this.trailing, super.key});

  final Post post;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    leading: CircleAvatar(child: Text('${post.id}')),
    trailing: trailing,
    onTap: onTap,
  );
}
