import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../core/result/result.dart';
import '../../core/ui/widgets/state_views.dart';
import '../auth/data/auth_repository.dart';
import '../auth/domain/auth_models.dart';
import '../auth/presentation/auth_cubit.dart';

/// Protected screen: calls GET /auth/me with the bearer token.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Result<AuthUser>> _me = sl<AuthRepository>().me();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: context.read<AuthCubit>().logout,
          ),
        ],
      ),
      body: FutureBuilder<Result<AuthUser>>(
        future: _me,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const LoadingView(),
          Failure(:final error) => ErrorView(
            message: error.userMessage,
            onRetry: () => setState(() => _me = sl<AuthRepository>().me()),
          ),
          Success(data: final user) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Hello, ${user.fullName}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('@${user.username}'),
              Text(user.email),
            ],
          ),
        },
      ),
    );
  }
}
