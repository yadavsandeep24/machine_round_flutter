import 'package:flutter/material.dart';

/// FIX: create the Future once (initState or a `late final` field) and give
/// FutureBuilder the same instance on every build. To reload on purpose,
/// assign a new Future inside setState.
class ProfileFutureFixed extends StatefulWidget {
  const ProfileFutureFixed({required this.fetch, super.key});

  final Future<String> Function() fetch;

  @override
  State<ProfileFutureFixed> createState() => _ProfileFutureFixedState();
}

class _ProfileFutureFixedState extends State<ProfileFutureFixed> {
  late final Future<String> _profile = widget.fetch();
  int likes = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FutureBuilder<String>(
          future: _profile,
          // The usual way people write it: spinner while waiting.
          builder: (context, snapshot) => snapshot.connectionState == ConnectionState.waiting
              ? const CircularProgressIndicator()
              : Text('Profile: ${snapshot.data}'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => setState(() => likes++), child: Text('Like ($likes)')),
      ],
    );
  }
}
