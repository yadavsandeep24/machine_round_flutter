import '../../core/di/injector.dart';
import '../favorites/favorites_cubit.dart';
import '../favorites/favorites_repository.dart';
import 'data/post_api.dart';
import 'data/post_local_source.dart';
import 'data/post_repository_impl.dart';
import 'domain/post_repository.dart';
import 'presentation/detail/post_detail_cubit.dart';
import 'presentation/list/posts_bloc.dart';

void registerPostsModule() {
  sl
    ..registerLazySingleton<FavoritesRepository>(() => LocalFavoritesRepository(sl()))
    ..registerFactory(() => FavoritesCubit(sl()))
    ..registerLazySingleton(() => PostApi(sl()))
    ..registerLazySingleton(() => PostLocalSource(sl()))
    ..registerLazySingleton<PostRepository>(() => PostRepositoryImpl(sl(), sl()))
    ..registerFactory(() => PostsBloc(sl()))
    ..registerFactoryParam<PostDetailCubit, int, void>((id, _) => PostDetailCubit(sl(), id));
}
