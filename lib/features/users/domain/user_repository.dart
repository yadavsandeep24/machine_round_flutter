import '../../../core/result/result.dart';
import 'user.dart';

abstract interface class UserRepository {
  Future<Result<List<User>>> getUsers();
  Future<Result<User>> getUser(int id);
}
