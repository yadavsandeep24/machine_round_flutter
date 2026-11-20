import '../../core/di/injector.dart';
import '../../core/network/dio_client.dart';
import 'data/shop_repository_impl.dart';
import 'domain/shop_repository.dart';
import 'presentation/cart/cart_cubit.dart';
import 'presentation/products/products_cubit.dart';

void registerShopModule() {
  sl
    ..registerLazySingleton<ShopRepository>(
      () => ShopRepositoryImpl(buildDio(baseUrl: kShopBaseUrl)),
    )
    ..registerLazySingleton<CartStorage>(() => LocalCartStorage(sl()))
    ..registerFactory(() => CartCubit(sl()))
    ..registerFactory(() => ProductsCubit(sl()));
}
