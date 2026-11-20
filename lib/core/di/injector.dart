import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/users/users_module.dart';
import '../network/dio_client.dart';
import '../storage/key_value_store.dart';

final GetIt sl = GetIt.instance;

/// Registers app-wide singletons. Feature modules add their own
/// registrations below the core ones.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton<KeyValueStore>(SharedPrefsStore(prefs))
    ..registerLazySingleton<Dio>(buildDio);
  registerUsersModule();
}
