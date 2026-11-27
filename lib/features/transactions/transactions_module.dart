import '../../core/di/injector.dart';
import 'data/in_memory_txn_repository.dart';
import 'domain/txn_repository.dart';
import 'presentation/txn_search_cubit.dart';

void registerTransactionsModule() {
  // Swap for TxnRepositoryImpl(sl()) when there is a real API.
  sl
    ..registerLazySingleton<TxnRepository>(InMemoryTxnRepository.new)
    ..registerFactory(() => TxnSearchCubit(sl()));
}
