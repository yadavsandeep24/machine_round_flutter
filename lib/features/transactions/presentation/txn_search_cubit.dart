import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/result/result.dart';
import '../../../core/ui/view_status.dart';
import '../domain/txn.dart';
import '../domain/txn_filter.dart';
import '../domain/txn_repository.dart';

class TxnSearchState extends Equatable {
  const TxnSearchState({
    this.filter = const TxnFilter(),
    this.status = ViewStatus.initial,
    this.items = const [],
    this.error,
  });

  final TxnFilter filter;
  final ViewStatus status;
  final List<Txn> items;
  final AppException? error;

  @override
  List<Object?> get props => [filter, status, items, error];
}

/// Every filter change triggers a search. A request id makes sure a slow,
/// older response can never overwrite a newer one.
class TxnSearchCubit extends Cubit<TxnSearchState> {
  TxnSearchCubit(this._repository) : super(const TxnSearchState());

  final TxnRepository _repository;
  int _requestId = 0;

  Future<void> load() => _search(state.filter);

  Future<void> setQuery(String text) => _search(state.filter.copyWith(query: () => text));

  Future<void> setStatus(TxnStatus? status) => _search(state.filter.copyWith(status: () => status));

  Future<void> setMinAmount(int? paise) => _search(state.filter.copyWith(minAmountPaise: () => paise));

  Future<void> setSince(DateTime? since) => _search(state.filter.copyWith(since: () => since));

  Future<void> clearAll() => _search(const TxnFilter());

  Future<void> _search(TxnFilter filter) async {
    final id = ++_requestId;
    emit(TxnSearchState(filter: filter, status: ViewStatus.loading, items: state.items));
    final result = await _repository.search(filter);
    if (id != _requestId || isClosed) return;
    emit(switch (result) {
      Success(:final data) => TxnSearchState(filter: filter, status: ViewStatus.success, items: data),
      Failure(:final error) => TxnSearchState(filter: filter, status: ViewStatus.failure, error: error),
    });
  }
}
