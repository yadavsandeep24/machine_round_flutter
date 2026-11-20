import 'package:dio/dio.dart';

import '../../core/di/injector.dart';
import '../../core/network/dio_client.dart';
import 'data/auth_api.dart';
import 'data/auth_interceptor.dart';
import 'data/auth_repository.dart';
import 'data/token_store.dart';
import 'presentation/auth_cubit.dart';
import 'presentation/login_cubit.dart';

void registerAuthModule() {
  final authApi = AuthApi(buildDio(baseUrl: kAuthBaseUrl));
  final tokens = TokenStore(sl());
  final authedDio = buildDio(baseUrl: kAuthBaseUrl);
  late final AuthRepository repository;
  authedDio.interceptors.insert(
    0,
    AuthInterceptor(
      tokens: tokens,
      authApi: authApi,
      retryClient: authedDio,
      onSessionExpired: () => repository.notifySessionExpired(),
    ),
  );
  repository = AuthRepository(api: authApi, tokens: tokens, authedDio: authedDio);

  sl
    ..registerSingleton<TokenStore>(tokens)
    ..registerSingleton<AuthRepository>(repository)
    ..registerSingleton<Dio>(authedDio, instanceName: 'authed')
    ..registerLazySingleton(() => AuthCubit(sl())..restore())
    ..registerFactory(() => LoginCubit(sl()));
}
