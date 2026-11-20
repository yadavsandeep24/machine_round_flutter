import 'package:flutter/material.dart';

/// BUG: "the search input keeps clearing itself". The controller is created
/// inside build(), so every setState (here: on each keystroke) makes a new,
/// empty controller. It also leaks the old controllers (never disposed).
class SearchBuggy extends StatefulWidget {
  const SearchBuggy({super.key});

  @override
  State<SearchBuggy> createState() => _SearchBuggyState();
}

class _SearchBuggyState extends State<SearchBuggy> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
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
