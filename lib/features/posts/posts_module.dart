import '../../core/di/injector.dart';
import 'data/post_api.dart';
import 'data/post_local_source.dart';
import 'data/post_repository_impl.dart';
import 'domain/post_repository.dart';
import 'presentation/list/posts_bloc.dart';

void registerPostsModule() {
  sl
    ..registerLazySingleton(() => PostApi(sl()))
    ..registerLazySingleton(() => PostLocalSource(sl()))
    ..registerLazySingleton<PostRepository>(() => PostRepositoryImpl(sl(), sl()))
    ..registerFactory(() => PostsBloc(sl()));
}
