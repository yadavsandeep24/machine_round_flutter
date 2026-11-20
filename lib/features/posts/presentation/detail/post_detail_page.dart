import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/ui/widgets/state_views.dart';
import '../../../favorites/favorite_button.dart';
import '../../domain/comment.dart';
import 'post_detail_cubit.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<PostDetailCubit>(param1: postId)..load(),
    child: const PostDetailView(),
  );
}

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          BlocBuilder<PostDetailCubit, PostDetailState>(
            buildWhen: (a, b) => a.runtimeType != b.runtimeType,
            builder: (context, state) => switch (state) {
              PostDetailLoaded(:final post) => FavoriteButton(id: post.id),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      body: BlocBuilder<PostDetailCubit, PostDetailState>(
        builder: (context, state) => switch (state) {
          PostDetailLoading() => const LoadingView(),
          PostDetailError(:final error) => ErrorView(
            message: error.userMessage,
            onRetry: context.read<PostDetailCubit>().load,
          ),
          PostDetailLoaded(:final post, :final comments, :final commentsError) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(
                  children: [
                    Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Text(post.body),
                    const SizedBox(height: 24),
                    Text('Comments', style: Theme.of(context).textTheme.titleMedium),
                    if (commentsError != null)
                      Text(
                        commentsError.userMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                  ],
                ),
              ),
              SliverList.builder(
                itemCount: comments.length,
                itemBuilder: (context, i) =>
                    _CommentTile(key: ValueKey(comments[i].id), comment: comments[i]),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, super.key});

  final Comment comment;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(comment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text('${comment.email}\n${comment.body}'),
    isThreeLine: true,
  );
}
