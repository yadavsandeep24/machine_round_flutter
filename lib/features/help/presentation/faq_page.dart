import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/payment_faqs.dart';
import 'faq_cubit.dart';
import 'faq_tile.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({this.initiallyOpen, super.key});

  /// Deep link target, e.g. the "Need help?" button on a failed payment opens `declined`.
  final String? initiallyOpen;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FaqCubit(paymentFaqs, initiallyOpen: initiallyOpen),
    child: const FaqView(),
  );
}

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FaqCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments help'),
        actions: [
          IconButton(
            tooltip: 'Expand all',
            icon: const Icon(Icons.unfold_more),
            onPressed: cubit.expandAll,
          ),
          IconButton(
            tooltip: 'Collapse all',
            icon: const Icon(Icons.unfold_less),
            onPressed: cubit.collapseAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const Key('faq-search'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search help'),
              onChanged: cubit.setQuery,
            ),
          ),
          BlocSelector<FaqCubit, FaqState, bool>(
            selector: (state) => state.singleOpen,
            builder: (context, singleOpen) => SwitchListTile(
              key: const Key('faq-single-open'),
              title: const Text('One answer at a time'),
              value: singleOpen,
              onChanged: cubit.setSingleOpen,
            ),
          ),
          Expanded(
            child: BlocBuilder<FaqCubit, FaqState>(
              buildWhen: (previous, current) => previous.query != current.query,
              builder: (context, state) {
                final items = state.visible;
                if (items.isEmpty) return const Center(child: Text('No matching questions'));
                return ListView.builder(
                  itemCount: items.length,
                  // Keyed by id so a tile keeps its controller when the filter changes.
                  itemBuilder: (context, index) => FaqTile(key: ValueKey(items[index].id), item: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
