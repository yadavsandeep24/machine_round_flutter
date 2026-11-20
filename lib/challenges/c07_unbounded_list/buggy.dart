import 'package:flutter/material.dart';

/// BUG: "feed crashes with a layout error on open":
/// "Vertical viewport was given unbounded height." A Column gives its
/// children unlimited height; a ListView wants to be as tall as possible.
/// Infinite wants infinite: layout fails and nothing renders.
class FeedBuggy extends StatelessWidget {
  const FeedBuggy({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Today\'s feed')),
      ListView.builder(itemCount: 50, itemBuilder: (_, i) => ListTile(title: Text('Story $i'))),
    ],
  );
}
