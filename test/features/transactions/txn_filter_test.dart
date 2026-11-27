import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/features/transactions/domain/txn.dart';
import 'package:machine_round/features/transactions/domain/txn_filter.dart';

void main() {
  group('TxnFilter.toQueryParameters (null-aware elements)', () {
    test('an empty filter sends only the limit', () {
      expect(const TxnFilter().toQueryParameters(), {'limit': 20});
    });

    test('only non-null filters become parameters', () {
      final filter = TxnFilter(query: '  amazon ', status: TxnStatus.pending, since: DateTime.utc(2026, 11, 1));
      expect(filter.toQueryParameters(), {
        'q': 'amazon',
        'status': 'pending',
        'since': '2026-11-01T00:00:00.000Z',
        'limit': 20,
      });
      expect(filter.toQueryParameters().containsKey('min_amount'), isFalse);
    });

    test('blank search text is dropped, not sent as an empty string', () {
      expect(const TxnFilter(query: '   ').toQueryParameters().containsKey('q'), isFalse);
    });

    test('keeps insertion order so URLs are stable', () {
      const filter = TxnFilter(query: 'a', status: TxnStatus.failed, minAmountPaise: 100);
      expect(filter.toQueryParameters().keys, ['q', 'status', 'min_amount', 'limit']);
    });
  });

  group('old vs new', () {
    final cases = <TxnFilter>[
      const TxnFilter(),
      const TxnFilter(query: 'swiggy'),
      const TxnFilter(status: TxnStatus.success, minAmountPaise: 50000),
      TxnFilter(query: ' x ', status: TxnStatus.failed, minAmountPaise: 1, since: DateTime.utc(2026)),
    ];

    for (final (index, filter) in cases.indexed) {
      test('case $index: legacy if-null-check map equals null-aware map', () {
        expect(filter.toQueryParameters(), filter.toQueryParametersLegacy());
      });
    }
  });

  test('copyWith can set a field back to null', () {
    const filter = TxnFilter(status: TxnStatus.failed, minAmountPaise: 100);
    final cleared = filter.copyWith(status: () => null);
    expect(cleared.status, isNull);
    expect(cleared.minAmountPaise, 100);
  });
}
