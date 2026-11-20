import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../core/result/result.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../domain/user.dart';
import '../domain/user_repository.dart';

/// Gets the user from `extra` when navigating from the list (instant), and
/// fetches by id otherwise (deep link, web refresh: `extra` is gone then).
/// A FutureBuilder is enough for a one-shot read; the future is created in
/// initState so rebuilds never refetch.
class UserDetailPage extends StatefulWidget {
  const UserDetailPage({required this.userId, this.initial, super.key});

  final int userId;
  final User? initial;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<Result<User>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Result<User>> _load() async => widget.initial != null
      ? Success(widget.initial!)
      : sl<UserRepository>().getUser(widget.userId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: FutureBuilder<Result<User>>(
        future: _future,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (result == null) return const LoadingView();
          return switch (result) {
            Failure(:final error) => ErrorView(
              message: error.userMessage,
              onRetry: () => setState(() => _future = _load()),
            ),
            Success(data: final user) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    child: ClipOval(
                      child: Image.network(
                        user.image,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Text(user.initials, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _Info(icon: Icons.email_outlined, text: user.email),
                _Info(icon: Icons.phone_outlined, text: user.phone),
                _Info(icon: Icons.cake_outlined, text: '${user.age} years'),
                _Info(icon: Icons.business_outlined, text: user.company),
                _Info(icon: Icons.location_city_outlined, text: user.city),
              ],
            ),
          };
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      ListTile(leading: Icon(icon), title: Text(text.isEmpty ? '—' : text));
}
