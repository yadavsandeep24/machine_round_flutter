import '../../core/di/injector.dart';
import '../../core/network/dio_client.dart';
import 'data/user_repository_impl.dart';
import 'domain/user_repository.dart';
import 'presentation/users_cubit.dart';

void registerUsersModule() {
  sl
    ..registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(buildDio(baseUrl: kUsersBaseUrl)),
    )
    ..registerFactory(() => UsersCubit(sl()));
}
