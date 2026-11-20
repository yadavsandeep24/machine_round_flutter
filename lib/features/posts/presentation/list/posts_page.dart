import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/ui/view_status.dart';
import '../../../../core/ui/widgets/state_views.dart';
import '../../../favorites/favorite_button.dart';
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
      appBar: AppBar(
        title: const Text('Posts'),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(64), child: _SearchField()),
      ),
      body: BlocConsumer<PostsBloc, PostsState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error && curr.error != null && curr.posts.isNotEmpty,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!.userMessage))),
        builder: (context, state) {
          final bloc = context.read<PostsBloc>();
          if (state.isSearching) return _SearchResults(state: state);
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
            trailing: FavoriteButton(id: post.id),
          );
        },
      ),
    );
  }
}

/// Owns its TextEditingController so typing never waits for the bloc
/// (no cursor jumps, no lag while the debounce runs).
class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    context.read<PostsBloc>().add(PostsQueryChanged(value));
    setState(() {}); // show or hide the clear button
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search posts',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.state});

  final PostsState state;

  @override
  Widget build(BuildContext context) {
    final results = state.searchResults;
    final loading = state.searchStatus.isLoading;
    if (state.searchStatus.isFailure) {
      return ErrorView(
        message: state.searchError?.userMessage ?? 'Search failed',
        onRetry: () => context.read<PostsBloc>().add(PostsQueryChanged(state.query, force: true)),
      );
    }
    if (loading && results.isEmpty) return const LoadingView();
    if (!loading && results.isEmpty) {
      return EmptyView(message: 'No results for "${state.query}"', icon: Icons.search_off);
    }
    return Column(
      children: [
        // Old results stay visible while the new query loads.
        if (loading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final post = results[index];
              return PostTile(
                key: ValueKey(post.id),
                post: post,
                onTap: () => context.go(Routes.postDetail(post.id)),
                trailing: FavoriteButton(id: post.id),
              );
            },
          ),
        ),
      ],
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
