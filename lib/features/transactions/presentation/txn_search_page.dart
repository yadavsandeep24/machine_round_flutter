import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/ui/view_status.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../domain/txn.dart';
import '../domain/txn_filter.dart';
import 'txn_search_cubit.dart';

class TxnSearchPage extends StatelessWidget {
  const TxnSearchPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<TxnSearchCubit>()..load(), child: const TxnSearchView());
}

class TxnSearchView extends StatelessWidget {
  const TxnSearchView({super.key});

  static const highValuePaise = 100000; // Rs 1,000

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TxnSearchCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: BlocBuilder<TxnSearchCubit, TxnSearchState>(
        builder: (context, state) {
          final filter = state.filter;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  key: const Key('txn-search'),
                  decoration: const InputDecoration(hintText: 'Search merchant', prefixIcon: Icon(Icons.search)),
                  onChanged: cubit.setQuery,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  spacing: 8,
                  children: [
                    for (final status in TxnStatus.values)
                      FilterChip(
                        label: Text(status.name),
                        selected: filter.status == status,
                        onSelected: (on) => cubit.setStatus(on ? status : null),
                      ),
                    FilterChip(
                      label: const Text('Over Rs 1,000'),
                      selected: filter.minAmountPaise != null,
                      onSelected: (on) => cubit.setMinAmount(on ? highValuePaise : null),
                    ),
                  ],
                ),
              ),
              ActiveFiltersBar(filter: filter, cubit: cubit),
              if (state.status.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: _Results(state: state, onRetry: cubit.load),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows one removable chip per active filter.
///
/// NEW WAY: each helper returns `Widget?`, and `?` in the `children` list
/// drops the nulls. Before Dart 3.8 you wrote
/// `if (filter.status != null) InputChip(...)` and repeated the condition.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({required this.filter, required this.cubit, super.key});

  final TxnFilter filter;
  final TxnSearchCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (!filter.hasActiveFilters) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ?_chip('"${filter.normalizedQuery}"', filter.normalizedQuery, () => cubit.setQuery('')),
          ?_chip('Status: ${filter.status?.name}', filter.status, () => cubit.setStatus(null)),
          ?_chip(
            'Min Rs ${(filter.minAmountPaise ?? 0) ~/ 100}',
            filter.minAmountPaise,
            () => cubit.setMinAmount(null),
          ),
          TextButton(onPressed: cubit.clearAll, child: const Text('Clear all')),
        ],
      ),
    );
  }

  /// Returns null when [value] is null, so the caller can use `?`.
  Widget? _chip(String label, Object? value, VoidCallback onDeleted) => value == null
      ? null
      : InputChip(
          key: ValueKey('active-$label'),
          label: Text(label),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: onDeleted,
        );
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.onRetry});

  final TxnSearchState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    if (state.status.isFailure && error != null) {
      return ErrorView(message: error.userMessage, onRetry: onRetry);
    }
    if (state.status.isSuccess && state.items.isEmpty) {
      return const EmptyView(message: 'No transactions match these filters');
    }
    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final txn = state.items[index];
        return ListTile(
          title: Text(txn.merchant),
          subtitle: Text(txn.status.name),
          trailing: Text('Rs ${(txn.amountPaise / 100).toStringAsFixed(2)}'),
        );
      },
    );
  }
}
