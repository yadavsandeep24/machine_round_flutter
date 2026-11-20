import 'package:dio/dio.dart';

import '../../../core/network/safe_call.dart';
import '../../../core/result/result.dart';
import '../domain/user.dart';
import '../domain/user_repository.dart';

const kUsersBaseUrl = 'https://dummyjson.com/';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._dio);
  final Dio _dio;

  static const _fields = 'firstName,lastName,email,phone,age,image,company,address';

  @override
  Future<Result<List<User>>> getUsers() => safeCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      'users',
      queryParameters: {'limit': 100, 'select': _fields},
    );
    return (res.data!['users'] as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  });

  @override
  Future<Result<User>> getUser(int id) => safeCall(() async {
    final res = await _dio.get<Map<String, dynamic>>('users/$id');
    return User.fromJson(res.data!);
  });
}
