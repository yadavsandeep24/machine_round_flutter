import 'package:flutter/material.dart';

/// FIX: create long-lived objects once in State (field or initState) and
/// dispose them. build() must be cheap and side-effect free: it can run
/// 60 times a second.
class SearchFixed extends StatefulWidget {
  const SearchFixed({super.key});

  @override
  State<SearchFixed> createState() => _SearchFixedState();
}

class _SearchFixedState extends State<SearchFixed> {
  final _controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Search'),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 12),
          Text('Searching for: "$query"'),
        ],
      ),
    );
  }
}
