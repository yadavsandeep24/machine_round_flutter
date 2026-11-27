import 'package:equatable/equatable.dart';

import 'txn.dart';

/// Filters for the transaction history API. Every field is optional:
/// a null field means "do not filter on this".
class TxnFilter extends Equatable {
  const TxnFilter({this.query, this.status, this.minAmountPaise, this.since, this.limit = 20});

  final String? query;
  final TxnStatus? status;
  final int? minAmountPaise;
  final DateTime? since;
  final int limit;

  /// Blank search text is the same as no search text.
  String? get normalizedQuery {
    final trimmed = query?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  bool get hasActiveFilters => normalizedQuery != null || status != null || minAmountPaise != null || since != null;

  /// NEW WAY (Dart 3.8 null-aware elements): `?expr` adds the entry only when
  /// `expr` is non-null. One line per parameter, no repeated null checks,
  /// and no `!` even though public fields are not type-promoted.
  Map<String, Object> toQueryParameters() => {
    'q': ?normalizedQuery,
    'status': ?status?.name,
    'min_amount': ?minAmountPaise,
    'since': ?since?.toUtc().toIso8601String(),
    'limit': limit,
  };

  /// OLD WAY (before Dart 3.8), kept for comparison. Each entry repeats the
  /// expression in an `if`, and public fields need `!` because Dart cannot
  /// promote them (a getter could return a different value the second time).
  Map<String, Object> toQueryParametersLegacy() {
    final q = normalizedQuery;
    return {
      // The use_null_aware_elements lint flags this line (q is a promotable
      // local). It cannot flag the field lines below because of the `!`.
      // ignore: use_null_aware_elements
      if (q != null) 'q': q,
      if (status != null) 'status': status!.name,
      if (minAmountPaise != null) 'min_amount': minAmountPaise!,
      if (since != null) 'since': since!.toUtc().toIso8601String(),
      'limit': limit,
    };
  }

  /// `copyWith` cannot tell "not passed" from "set to null", so nullable
  /// fields take a function. Null-aware elements do not change this.
  TxnFilter copyWith({
    String? Function()? query,
    TxnStatus? Function()? status,
    int? Function()? minAmountPaise,
    DateTime? Function()? since,
  }) => TxnFilter(
    query: query != null ? query() : this.query,
    status: status != null ? status() : this.status,
    minAmountPaise: minAmountPaise != null ? minAmountPaise() : this.minAmountPaise,
    since: since != null ? since() : this.since,
    limit: limit,
  );

  @override
  List<Object?> get props => [query, status, minAmountPaise, since, limit];
}
