import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/ui/view_status.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../domain/user.dart';
import 'users_cubit.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<UsersCubit>()..load(), child: const UsersView());
}

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Only the counter rebuilds when likes change, not the whole scaffold.
        title: const _Title(),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(64), child: _SearchBox()),
      ),
      // buildWhen: rebuild the body only when what it shows changes. Toggling a
      // like does NOT rebuild the list; only that row's heart rebuilds.
      body: BlocBuilder<UsersCubit, UsersState>(
        buildWhen: (a, b) => a.status != b.status || a.visible != b.visible || a.error != b.error,
        builder: (context, state) => switch (state.status) {
          ViewStatus.initial || ViewStatus.loading => const LoadingView(),
          ViewStatus.failure => ErrorView(
            message: state.error?.userMessage ?? 'Something went wrong',
            onRetry: context.read<UsersCubit>().load,
          ),
          ViewStatus.success when state.visible.isEmpty => EmptyView(
            message: state.query.isEmpty ? 'No users' : 'No users match "${state.query}"',
          ),
          ViewStatus.success => RefreshIndicator(
            onRefresh: context.read<UsersCubit>().load,
            child: ListView.builder(
              // Fixed extent: the list can compute scroll offsets without laying
              // out every child. Use prototypeItem when height is unknown.
              itemExtent: 72,
              itemCount: state.visible.length,
              itemBuilder: (context, i) {
                final user = state.visible[i];
                // Keys keep row state attached to the right user when filtering.
                return UserRow(key: ValueKey(user.id), user: user);
              },
            ),
          ),
        },
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final liked = context.select((UsersCubit c) => c.state.likedIds.length);
    return Text(liked == 0 ? 'Users' : 'Users · $liked liked');
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: TextField(
      onChanged: context.read<UsersCubit>().search,
      decoration: const InputDecoration(
        hintText: 'Search by name or email',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

class UserRow extends StatelessWidget {
  const UserRow({required this.user, super.key});

  final User user;

  /// Test hook that proves which widgets rebuild. Only counted in debug.
  @visibleForTesting
  static final Map<int, int> debugBuilds = {};

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugBuilds.update(user.id, (n) => n + 1, ifAbsent: () => 1);
    return ListTile(
      leading: CircleAvatar(child: Text(user.initials)),
      title: Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: LikeButton(userId: user.id),
      onTap: () => context.push('/users/${user.id}', extra: user),
    );
  }
}

class LikeButton extends StatelessWidget {
  const LikeButton({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context) {
    // BlocSelector: rebuilds only when THIS user's liked flag changes.
    return BlocSelector<UsersCubit, UsersState, bool>(
      selector: (state) => state.likedIds.contains(userId),
      builder: (context, liked) => IconButton(
        tooltip: liked ? 'Unlike' : 'Like',
        icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
        onPressed: () => context.read<UsersCubit>().toggleLike(userId),
      ),
    );
  }
}
