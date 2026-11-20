import 'package:flutter/material.dart';

/// BUG: the user taps back before the request finishes. The State is
/// disposed, then `setState` runs and throws
/// "setState() called after dispose()".
class ProfileBuggy extends StatefulWidget {
  const ProfileBuggy({required this.load, super.key});

  final Future<String> Function() load;

  @override
  State<ProfileBuggy> createState() => ProfileBuggyState();
}

class ProfileBuggyState extends State<ProfileBuggy> {
  String? name;

  /// Exposed so the test can observe the failure.
  Future<void>? pending;

  @override
  void initState() {
    super.initState();
    pending = _fetch();
  }

  Future<void> _fetch() async {
    final result = await widget.load();
    setState(() => name = result);
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(name == null ? 'Loading profile…' : 'Hello, $name'));
}
