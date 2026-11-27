import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/result/result.dart';
import 'package:machine_round/core/ui/view_status.dart';
import 'package:machine_round/features/transactions/data/in_memory_txn_repository.dart';
import 'package:machine_round/features/transactions/domain/txn.dart';
import 'package:machine_round/features/transactions/domain/txn_filter.dart';
import 'package:machine_round/features/transactions/domain/txn_repository.dart';
import 'package:machine_round/features/transactions/presentation/txn_search_cubit.dart';

/// Lets a test decide when each search completes.
class _ControlledRepository implements TxnRepository {
  final pending = <TxnFilter, Completer<Result<List<Txn>>>>{};

  @override
  Future<Result<List<Txn>>> search(TxnFilter filter) => (pending[filter] = Completer<Result<List<Txn>>>()).future;
}

void main() {
  final seed = [
    Txn(
      id: 'a',
      merchant: 'Amazon',
      amountPaise: 249900,
      status: TxnStatus.pending,
      createdAt: DateTime.utc(2026, 11, 25),
    ),
    Txn(id: 'b', merchant: 'Uber', amountPaise: 31000, status: TxnStatus.failed, createdAt: DateTime.utc(2026, 11, 24)),
  ];

  blocTest<TxnSearchCubit, TxnSearchState>(
    'status filter narrows the list and clearing it restores everything',
    build: () => TxnSearchCubit(InMemoryTxnRepository(seed: seed, latency: Duration.zero)),
    act: (cubit) async {
      await cubit.setStatus(TxnStatus.failed);
      await cubit.setStatus(null);
    },
    skip: 0,
    verify: (cubit) {
      expect(cubit.state.filter.status, isNull);
      expect(cubit.state.items.length, 2);
    },
    expect: () => [
      isA<TxnSearchState>().having((s) => s.status, 'status', ViewStatus.loading),
      isA<TxnSearchState>().having((s) => s.items.map((t) => t.id), 'ids', ['b']),
      isA<TxnSearchState>().having((s) => s.status, 'status', ViewStatus.loading),
      isA<TxnSearchState>().having((s) => s.items.length, 'count', 2),
    ],
  );

  test('a slow older response cannot overwrite a newer one', () async {
    final repo = _ControlledRepository();
    final cubit = TxnSearchCubit(repo);

    final first = cubit.setQuery('am');
    final second = cubit.setQuery('amazon');

    repo.pending[const TxnFilter(query: 'amazon')]!.complete(Success([seed.first]));
    await second;
    repo.pending[const TxnFilter(query: 'am')]!.complete(Success(seed));
    await first;

    expect(cubit.state.filter.normalizedQuery, 'amazon');
    expect(cubit.state.items, [seed.first]);
    await cubit.close();
  });
}
