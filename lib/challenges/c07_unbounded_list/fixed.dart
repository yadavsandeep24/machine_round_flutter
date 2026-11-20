import 'package:flutter/material.dart';

/// FIX: give the list a bounded height: wrap it in `Expanded` (take the
/// remaining space). Avoid `shrinkWrap: true` for long lists: it lays out
/// every item and kills lazy loading. For header + list, a CustomScrollView
/// with slivers is the cleanest.
class FeedFixed extends StatelessWidget {
  const FeedFixed({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Today\'s feed')),
      Expanded(
        child: ListView.builder(
          itemCount: 50,
          itemBuilder: (_, i) => ListTile(title: Text('Story $i')),
        ),
      ),
    ],
  );
}
