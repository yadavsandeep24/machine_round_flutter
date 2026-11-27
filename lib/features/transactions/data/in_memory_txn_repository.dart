import '../../../core/result/result.dart';
import '../domain/txn.dart';
import '../domain/txn_filter.dart';
import '../domain/txn_repository.dart';

/// Demo data source so the screen runs without a backend. It applies the
/// same filter rules the server would.
class InMemoryTxnRepository implements TxnRepository {
  InMemoryTxnRepository({List<Txn>? seed, this.latency = const Duration(milliseconds: 250)})
    : _all = seed ?? _demoTransactions;

  final List<Txn> _all;
  final Duration latency;

  @override
  Future<Result<List<Txn>>> search(TxnFilter filter) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final q = filter.normalizedQuery?.toLowerCase();
    final matches = _all
        .where((t) => q == null || t.merchant.toLowerCase().contains(q))
        .where((t) => filter.status == null || t.status == filter.status)
        .where((t) => filter.minAmountPaise == null || t.amountPaise >= filter.minAmountPaise!)
        .where((t) => filter.since == null || !t.createdAt.isBefore(filter.since!))
        .take(filter.limit)
        .toList(growable: false);
    return Success(matches);
  }
}

final _demoTransactions = <Txn>[
  Txn(
    id: 't1',
    merchant: 'Swiggy',
    amountPaise: 45000,
    status: TxnStatus.success,
    createdAt: DateTime.utc(2026, 11, 26),
  ),
  Txn(
    id: 't2',
    merchant: 'Amazon',
    amountPaise: 249900,
    status: TxnStatus.pending,
    createdAt: DateTime.utc(2026, 11, 25),
  ),
  Txn(id: 't3', merchant: 'Uber', amountPaise: 31000, status: TxnStatus.failed, createdAt: DateTime.utc(2026, 11, 24)),
  Txn(
    id: 't4',
    merchant: 'Zomato',
    amountPaise: 62000,
    status: TxnStatus.success,
    createdAt: DateTime.utc(2026, 11, 20),
  ),
  Txn(
    id: 't5',
    merchant: 'Amazon Pay',
    amountPaise: 150000,
    status: TxnStatus.success,
    createdAt: DateTime.utc(2026, 11, 2),
  ),
  Txn(
    id: 't6',
    merchant: 'IRCTC',
    amountPaise: 189000,
    status: TxnStatus.failed,
    createdAt: DateTime.utc(2026, 10, 28),
  ),
];
