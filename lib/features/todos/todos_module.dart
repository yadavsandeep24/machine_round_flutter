import '../../core/di/injector.dart';
import 'data/todo_local_store.dart';
import 'data/todo_remote.dart';
import 'data/todo_repository.dart';
import 'presentation/todos_cubit.dart';
import 'sync/connectivity.dart';
import 'sync/sync_engine.dart';

void registerTodosModule() {
  sl
    ..registerLazySingleton<Connectivity>(ManualConnectivity.new)
    ..registerLazySingleton<TodoRemote>(FakeTodoRemote.new)
    ..registerLazySingleton(() => TodoLocalStore(sl()))
    ..registerLazySingleton(
      () => SyncEngine(local: sl(), remote: sl(), connectivity: sl())..sync(), // flush on launch
    )
    ..registerLazySingleton(() => TodoRepository(sl(), sl()))
    ..registerFactory(() => TodosCubit(sl(), sl()));
}
