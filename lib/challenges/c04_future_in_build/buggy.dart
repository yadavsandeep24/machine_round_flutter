import 'package:flutter/material.dart';

/// BUG: "profile screen flashes a spinner" / "list flashes when the keyboard
/// opens". `fetch()` is called inside build(), so every rebuild (a setState,
/// the keyboard resizing the screen, a theme change) starts a NEW request and
/// FutureBuilder goes back to the waiting state.
class ProfileFutureBuggy extends StatefulWidget {
  const ProfileFutureBuggy({required this.fetch, super.key});

  final Future<String> Function() fetch;

  @override
  State<ProfileFutureBuggy> createState() => _ProfileFutureBuggyState();
}

class _ProfileFutureBuggyState extends State<ProfileFutureBuggy> {
  int likes = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FutureBuilder<String>(
          future: widget.fetch(),
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
