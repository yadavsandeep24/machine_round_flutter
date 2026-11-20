import 'package:flutter/material.dart';

/// FIX: after every `await`, check `mounted` before touching state or context.
/// (Same rule for Cubits: check `isClosed` before `emit`.)
class ProfileFixed extends StatefulWidget {
  const ProfileFixed({required this.load, super.key});

  final Future<String> Function() load;

  @override
  State<ProfileFixed> createState() => ProfileFixedState();
}

class ProfileFixedState extends State<ProfileFixed> {
  String? name;
  Future<void>? pending;

  @override
  void initState() {
    super.initState();
    pending = _fetch();
  }

  Future<void> _fetch() async {
    final result = await widget.load();
    if (!mounted) return; // the user already left
    setState(() => name = result);
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(name == null ? 'Loading profile…' : 'Hello, $name'));
}
