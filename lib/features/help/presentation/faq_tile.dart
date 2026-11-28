import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/faq_item.dart';
import 'faq_cubit.dart';

/// NEW (Flutter 3.32): a custom-styled expandable row built on the
/// design-agnostic [Expansible] widget, driven by an [ExpansibleController].
///
/// Before 3.32 the only built-in option was Material's ExpansionTile
/// (with ExpansionTileController). For a non-Material look you had to
/// write your own AnimationController + SizeTransition + ClipRect.
class FaqTile extends StatefulWidget {
  const FaqTile({required this.item, super.key});

  final FaqItem item;

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> {
  final _controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
    // Safe here: the Expansible is not built yet, so this only sets the start value.
    if (context.read<FaqCubit>().state.isExpanded(widget.item.id)) _controller.expand();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.item.id;
    final colors = Theme.of(context).colorScheme;
    // expand()/collapse() rebuild the Expansible, so they must not run inside build.
    // BlocListener calls us from the stream, outside the build phase.
    return BlocListener<FaqCubit, FaqState>(
      listenWhen: (previous, current) => previous.isExpanded(id) != current.isExpanded(id),
      listener: (context, state) => state.isExpanded(id) ? _controller.expand() : _controller.collapse(),
      child: Card.outlined(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: Expansible(
          controller: _controller,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          headerBuilder: (context, animation) => InkWell(
            key: Key('faq-header-$id'),
            onTap: () => context.read<FaqCubit>().toggle(id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text(widget.item.question, style: Theme.of(context).textTheme.titleSmall)),
                  // The same animation value (0 collapsed → 1 expanded) drives the chevron.
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.5).animate(animation),
                    child: Icon(Icons.expand_more, color: colors.primary),
                  ),
                ],
              ),
            ),
          ),
          bodyBuilder: (context, animation) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.item.answer, key: Key('faq-answer-$id')),
          ),
        ),
      ),
    );
  }
}
