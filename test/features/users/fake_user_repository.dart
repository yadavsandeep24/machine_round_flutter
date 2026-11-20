import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/result/result.dart';
import 'package:machine_round/features/users/domain/user.dart';
import 'package:machine_round/features/users/domain/user_repository.dart';

User fakeUser(int id, {String first = 'User', String? last}) => User(
  id: id,
  firstName: first,
  lastName: last ?? '$id',
  email: 'user$id@mail.com',
  phone: '123',
  age: 30,
  image: '',
  company: 'Acme',
  city: 'Pune',
);

class FakeUserRepository implements UserRepository {
  List<User> users = List.generate(30, (i) => fakeUser(i + 1));
  AppException? failWith;
  int calls = 0;

  @override
  Future<Result<List<User>>> getUsers() async {
    calls++;
    if (failWith != null) return Failure(failWith!);
    return Success(users);
  }

  @override
  Future<Result<User>> getUser(int id) async {
    final match = users.where((u) => u.id == id);
    return match.isEmpty ? const Failure(NotFoundException()) : Success(match.first);
  }
}
